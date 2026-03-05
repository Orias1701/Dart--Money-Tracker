import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class RecoverCodeScreen extends ConsumerStatefulWidget {
  const RecoverCodeScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<RecoverCodeScreen> createState() => _RecoverCodeScreenState();
}

class _RecoverCodeScreenState extends ConsumerState<RecoverCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  var _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Nhập đủ 6 số từ email');
      return;
    }
    setState(() => _isLoading = true);
    final result = await ref.read(authRepositoryProvider).verifyRecoveryOtp(
          email: widget.email,
          token: code,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result is AuthSuccess) {
      context.go('/reset-password', extra: widget.email);
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
        title: const Text('Nhập mã xác nhận'),
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
                Text(
                  'Mã 6 số đã gửi đến ${widget.email}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'Mã xác nhận',
                    hintText: '123456',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    border: const OutlineInputBorder(),
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  onChanged: (_) => setState(() => _errorMessage = null),
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
                      : const Text('Xác nhận'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
