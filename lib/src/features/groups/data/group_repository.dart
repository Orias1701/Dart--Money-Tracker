import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../auth/domain/app_user.dart';
import '../domain/group.dart';
import '../domain/group_invitation.dart';
import '../domain/group_member.dart';

class GroupRepository {
  GroupRepository() : _client = SupabaseService.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Danh sách nhóm user tham gia (active). Dùng RPC để tránh lỗi 500 do RLS.
  Future<List<AppGroup>> getUserGroups() async {
    if (_userId == null) return [];
    try {
      final list = await _client.rpc('get_user_groups');
      if (list == null) return [];
      return (list as List)
          .map((e) => AppGroup.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Nhóm cá nhân (is_personal = true) của user hiện tại.
  Future<AppGroup?> getPersonalGroup() async {
    final list = await getUserGroups();
    for (final g in list) {
      if (g.isPersonal) return g;
    }
    return null;
  }

  /// Thành viên nhóm (có thông tin user). Dùng RPC để tránh lỗi 500 do RLS.
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final res = await _client.rpc('get_group_members', params: {'p_group_id': groupId});
      if (res == null) return [];
      // PostgREST: json array trả về List; khi chỉ 1 phần tử đôi khi trả về 1 object (Map).
      final List<dynamic> list;
      if (res is List) {
        list = List<dynamic>.from(res);
      } else if (res is Map) {
        list = [res]; // Một thành viên duy nhất trả về dạng object
      } else {
        list = [];
      }
      return list
          .map((e) => GroupMember.fromMap(Map<String, dynamic>.from(e is Map ? e : <String, dynamic>{})))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Tạo nhóm mới (is_personal = false) và thêm mình làm admin. Dùng RPC để tránh lỗi RLS.
  Future<AppGroup?> createGroup(String name) async {
    if (name.trim().isEmpty) return null;
    try {
      final row = await _client.rpc('create_group', params: {'p_name': name.trim()}).single();
      return AppGroup.fromMap(Map<String, dynamic>.from(row as Map));
    } catch (_) {
      return null;
    }
  }

  /// Cập nhật tên nhóm (chỉ admin nhóm). RLS: Admins can update own group.
  Future<AppGroup?> updateGroup(String groupId, String name) async {
    if (_userId == null || groupId.isEmpty || name.trim().isEmpty) return null;
    try {
      final res = await _client
          .from('groups')
          .update({'name': name.trim()})
          .eq('id', groupId)
          .select()
          .single();
      return AppGroup.fromMap(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return null;
    }
  }

  /// Xoá mềm nhóm (set status = 'deleted'). Chỉ admin. Nhóm cá nhân không nên xoá.
  Future<String?> deleteGroup(String groupId) async {
    if (_userId == null || groupId.isEmpty) return 'Thiếu thông tin';
    try {
      await _client
          .from('groups')
          .update({'status': 'deleted'})
          .eq('id', groupId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static List<dynamic> _parseJsonList(dynamic value) {
    if (value is List) return List<dynamic>.from(value);
    if (value is String && value.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(value);
        return decoded is List ? List<dynamic>.from(decoded) : [];
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  /// Tìm user theo username/full_name (để mời vào nhóm). Chỉ trả về id, username, full_name, avatar_url.
  /// Ném exception nếu RPC lỗi (để UI hiển thị thông báo).
  Future<List<AppUser>> searchUsers(String query) async {
    if (_userId == null) throw Exception('Chưa đăng nhập');
    if (query.trim().length < 2) return [];
    final res = await _client.rpc('search_users', params: {'p_query': query.trim()});
    if (res == null) return [];
    List<dynamic> list;
    if (res is List) {
      final resList = res;
      final raw = resList.length == 1 ? resList.first : res;
      if (raw is List) {
        list = List<dynamic>.from(raw);
      } else if (raw is Map) {
        list = [];
        for (final v in raw.values) {
          if (v is List) {
            list = List<dynamic>.from(v);
            break;
          }
          if (v is String) {
            list = _parseJsonList(v);
            if (list.isNotEmpty) break;
          }
        }
        if (list.isEmpty && raw.containsKey('id')) {
          list = [raw];
        }
      } else if (raw is String) {
        list = _parseJsonList(raw);
      } else {
        list = [];
      }
    } else if (res is String) {
      list = _parseJsonList(res);
    } else if (res is Map) {
      list = [];
      for (final v in res.values) {
        if (v is List) {
          list = List<dynamic>.from(v);
          break;
        }
      }
    } else {
      list = [];
    }
    final out = <AppUser>[];
    for (final e in list) {
      if (e is! Map) continue;
      try {
        final m = Map<String, dynamic>.from(e);
        if (m['id'] == null) continue;
        out.add(AppUser.fromMap(m));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  /// Mời user vào nhóm (chỉ admin nhóm). Dùng RPC để tránh lỗi RLS.
  Future<String?> inviteUserToGroup(String groupId, String userId) async {
    if (_userId == null) return 'Chưa đăng nhập';
    if (groupId.isEmpty || userId.isEmpty) return 'Thiếu thông tin';
    try {
      final result = await _client.rpc('invite_to_group', params: {
        'p_group_id': groupId,
        'p_user_id': userId,
      });
      final msg = result == null ? '' : result.toString().trim();
      return msg.isEmpty ? null : msg;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('duplicate') || msg.contains('unique')) return 'Người này đã ở trong nhóm';
      return msg;
    }
  }

  /// Danh sách lời mời vào nhóm (pending) của user hiện tại.
  Future<List<GroupInvitation>> getMyInvitations() async {
    if (_userId == null) return [];
    try {
      final res = await _client.rpc('get_my_invitations');
      if (res == null) return [];
      final list = res is List ? List<dynamic>.from(res) : [];
      return list
          .map((e) => GroupInvitation.fromMap(Map<String, dynamic>.from(e is Map ? e : <String, dynamic>{})))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Chấp nhận lời mời vào nhóm.
  Future<String?> acceptInvitation(String invitationId) async {
    if (_userId == null) return 'Chưa đăng nhập';
    try {
      final result = await _client.rpc('accept_invitation', params: {'p_invitation_id': invitationId});
      final msg = result == null ? '' : result.toString().trim();
      return msg.isEmpty ? null : msg;
    } catch (e) {
      return e.toString();
    }
  }

  /// Từ chối lời mời vào nhóm.
  Future<String?> declineInvitation(String invitationId) async {
    if (_userId == null) return 'Chưa đăng nhập';
    try {
      final result = await _client.rpc('decline_invitation', params: {'p_invitation_id': invitationId});
      final msg = result == null ? '' : result.toString().trim();
      return msg.isEmpty ? null : msg;
    } catch (e) {
      return e.toString();
    }
  }

  /// Tham gia nhóm bằng ID. Dùng RPC để kiểm tra is_personal và thêm member (tránh lỗi RLS).
  Future<String?> joinGroupById(String groupId) async {
    if (_userId == null) return 'Chưa đăng nhập';
    final id = groupId.trim();
    if (id.isEmpty) return 'ID nhóm trống';
    try {
      final result = await _client.rpc('join_group', params: {'p_group_id': id});
      final msg = result == null ? '' : result.toString().trim();
      return msg.isEmpty ? null : msg;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('duplicate') || msg.contains('unique')) return 'Bạn đã ở trong nhóm này';
      if (msg.contains('invalid input syntax') && msg.contains('uuid')) return 'ID nhóm không hợp lệ';
      return msg;
    }
  }

  /// Rời nhóm (không áp dụng cho nhóm cá nhân). Trả về thông báo lỗi hoặc null nếu thành công.
  Future<String?> leaveGroup(String groupId) async {
    if (_userId == null) return 'Chưa đăng nhập';
    if (groupId.isEmpty) return 'Thiếu ID nhóm';
    try {
      final result = await _client.rpc('leave_group', params: {'p_group_id': groupId});
      final msg = result == null ? '' : result.toString().trim();
      return msg.isEmpty ? null : msg;
    } catch (e) {
      return e.toString();
    }
  }

  /// Kick thành viên khỏi nhóm (chỉ admin). Trả về thông báo lỗi hoặc null nếu thành công.
  Future<String?> kickMember(String groupId, String userId) async {
    if (_userId == null) return 'Chưa đăng nhập';
    if (groupId.isEmpty || userId.isEmpty) return 'Thiếu thông tin';
    try {
      final result = await _client.rpc('kick_member', params: {
        'p_group_id': groupId,
        'p_user_id': userId,
      });
      final msg = result == null ? '' : result.toString().trim();
      return msg.isEmpty ? null : msg;
    } catch (e) {
      return e.toString();
    }
  }
}
