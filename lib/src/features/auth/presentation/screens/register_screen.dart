import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ref.read(authRepositoryProvider).signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim().isEmpty
              ? null
              : _fullNameController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result is AuthSuccess) {
      context.go('/');
    } else if (result is AuthFailure) {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Đăng ký'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập *',
                    hintText: 'tên đăng nhập',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nhập tên đăng nhập';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Họ tên',
                    hintText: 'Nguyễn Văn A',
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'email@vd.com',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu *',
                    hintText: 'Tối thiểu 6 ký tự',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu *',
                    hintText: 'Nhập lại mật khẩu',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Nhập xác nhận mật khẩu';
                    if (v != _passwordController.text) return 'Mật khẩu không trùng khớp';
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.expense, fontSize: 14),
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
                      : const Text('Đăng ký'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
