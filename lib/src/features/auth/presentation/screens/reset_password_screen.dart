import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final result = await ref.read(authRepositoryProvider).updatePassword(
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result is AuthSuccess) {
      context.go('/login');
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
        title: const Text('Đặt lại mật khẩu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                TextFormField(
                  initialValue: widget.email,
                  readOnly: true,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    hintText: 'Tối thiểu 6 ký tự',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    border: const OutlineInputBorder(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    hintText: 'Nhập lại mật khẩu',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    border: const OutlineInputBorder(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v != _passwordController.text) return 'Mật khẩu không trùng khớp';
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cập nhật mật khẩu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
