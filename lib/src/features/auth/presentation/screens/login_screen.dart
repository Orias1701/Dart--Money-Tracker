import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/last_login_service.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;
  var _isLoading = false;
  String? _errorMessage;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastLogin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadLastLogin() async {
    final id = await LastLoginService.getLastLoginIdentifier();
    if (id != null && id.isNotEmpty && mounted) {
      _identifierController.text = id;
      final shouldClear = await LastLoginService.shouldClearPassword();
      if (shouldClear && mounted) {
        _passwordController.clear();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final diff = DateTime.now().difference(_pausedAt!);
        if (diff.inMinutes >= 5 && mounted) {
          _passwordController.clear();
          LastLoginService.markPasswordCleared();
        }
      }
      _pausedAt = null;
    }
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .signInWithEmailOrUsername(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result is AuthSuccess) {
      ref.invalidate(currentUserProvider);
      await LastLoginService.saveLastLoginIdentifier(
        _identifierController.text.trim(),
      );
      if (mounted) context.go('/');
    } else if (result is AuthFailure) {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 36),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Email hoặc tên đăng nhập *',
                    hintText: 'email@vd.com hoặc tên đăng nhập',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nhập email hoặc tên đăng nhập';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu *',
                    hintText: 'Nhập mật khẩu',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nhập mật khẩu';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.expense,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Đăng nhập'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Chưa có tài khoản? Đăng ký'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
