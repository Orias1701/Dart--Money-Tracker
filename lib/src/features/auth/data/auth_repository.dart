import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/app_user.dart';

abstract class AuthResult<T> {
  const AuthResult();
}

class AuthSuccess<T> extends AuthResult<T> {
  const AuthSuccess(this.data);
  final T data;
}

class AuthFailure extends AuthResult<Never> {
  const AuthFailure(this.message);
  final String message;
}

class AuthRepository {
  AuthRepository() : _client = SupabaseService.client;

  final SupabaseClient _client;

  User? get currentAuthUser => _client.auth.currentUser;

  Future<AuthResult<AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final profile = await getProfile();
      if (profile != null) return AuthSuccess(profile);
      final fallback = _appUserFromAuthUser(_client.auth.currentUser!);
      if (fallback != null) return AuthSuccess(fallback);
      return const AuthFailure('Không lấy được thông tin người dùng');
    } catch (e) {
      return AuthFailure(_messageFromError(e));
    }
  }

  /// Đăng nhập bằng email hoặc tên hiển thị (full_name). Nếu identifier chứa '@' dùng làm email, ngược lại gọi RPC get_email_for_login.
  Future<AuthResult<AppUser>> signInWithEmailOrUsername({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return const AuthFailure('Nhập email hoặc tên đăng nhập');
    String email = trimmed;
    if (!trimmed.contains('@')) {
      try {
        final res = await _client.rpc('get_email_for_login', params: {'login_id': trimmed});
        if (res == null) return const AuthFailure('Không tìm thấy tài khoản với tên đăng nhập này.');
        if (res is String) {
          email = res;
        } else if (res is List && res.isNotEmpty) {
          email = res.first.toString();
        } else {
          email = res.toString();
        }
        if (email.isEmpty) return const AuthFailure('Không tìm thấy tài khoản với tên đăng nhập này.');
      } catch (_) {
        return const AuthFailure('Chưa cấu hình đăng nhập bằng tên. Dùng email hoặc chạy file Assets/SQL/rpc_get_email_for_login.sql trong Supabase.');
      }
    }
    return signInWithEmail(email: email, password: password);
  }

  Future<AuthResult<AppUser>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      final meta = <String, dynamic>{'username': username.trim()};
      if (fullName != null && fullName.trim().isNotEmpty) meta['full_name'] = fullName.trim();
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: meta.isNotEmpty ? meta : null,
      );
      var session = _client.auth.currentSession;
      if (session == null) {
        await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        session = _client.auth.currentSession;
      }
      if (session == null) {
        return const AuthFailure('Đăng ký thành công. Vui lòng đăng nhập.');
      }
      final profile = await getProfile();
      if (profile != null) return AuthSuccess(profile);
      final fallback = _appUserFromAuthUser(_client.auth.currentUser!);
      if (fallback != null) return AuthSuccess(fallback);
      return const AuthFailure('Đăng ký thành công. Vui lòng đăng nhập.');
    } catch (e) {
      return AuthFailure(_messageFromError(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  /// Gửi email khôi phục mật khẩu (Supabase gửi link + mã 6 số trong email).
  Future<AuthResult<void>> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return const AuthSuccess(null);
    } catch (e) {
      return AuthFailure(_messageFromError(e));
    }
  }

  /// Xác nhận mã OTP 6 số từ email khôi phục.
  Future<AuthResult<void>> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    try {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        token: token.trim(),
        email: email.trim(),
      );
      return const AuthSuccess(null);
    } catch (e) {
      return AuthFailure(_messageFromError(e));
    }
  }

  /// Cập nhật mật khẩu mới (sau khi đã verify OTP recovery).
  Future<AuthResult<void>> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const AuthSuccess(null);
    } catch (e) {
      return AuthFailure(_messageFromError(e));
    }
  }

  Future<AppUser?> getProfile() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    try {
      final res = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (res != null) return AppUser.fromMap(res);
    } catch (_) {}
    return _appUserFromAuthUser(authUser);
  }

  static String _messageFromError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('failed host lookup') ||
        msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('no address associated with hostname')) {
      return 'Không kết nối được máy chủ. Kiểm tra mạng (Wi‑Fi/4G), thử bật dữ liệu di động hoặc đổi mạng rồi thử lại.';
    }
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid') && m.contains('credential')) {
        return 'Email hoặc mật khẩu không đúng.';
      }
      if (m.contains('email not confirmed') || m.contains('confirm your email')) {
        return 'Vui lòng xác nhận email trước khi đăng nhập. Kiểm tra hộp thư (và thư mục spam).';
      }
      if (m.contains('user already registered') || m.contains('already registered')) {
        return 'Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng Quên mật khẩu.';
      }
      return e.message;
    }
    return e.toString();
  }

  /// Cập nhật full name trong profile (username không đổi).
  Future<AuthResult<void>> updateProfile({String? fullName}) async {
    try {
      await _client.from('users').update({'full_name': fullName}).eq('id', _client.auth.currentUser!.id);
      return const AuthSuccess(null);
    } catch (e) {
      return AuthFailure(_messageFromError(e));
    }
  }

  static AppUser? _appUserFromAuthUser(User u) {
    final id = u.id;
    if (id.isEmpty) return null;
    final meta = u.userMetadata ?? {};
    final fullName = meta['full_name'] as String? ?? u.email;
    final username = meta['username'] as String? ?? u.email;
    return AppUser(
      id: id,
      username: username,
      fullName: fullName,
      avatarUrl: meta['avatar_url'] as String?,
    );
  }
}
