import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/debug_tap_logger.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.background,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(accountsListProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: accountsAsync.when(
            data: (accounts) {
              final assets = accounts.where((a) => a.isAsset).toList();
              final liabilities = accounts.where((a) => a.isLiability).toList();
              final totalAssets = assets.fold<double>(0, (s, a) => s + a.balance);
              final totalLiabilities =
                  liabilities.fold<double>(0, (s, a) => s + a.balance);
              final netWorth = totalAssets - totalLiabilities;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Worth',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            FormatHelpers.currency(netWorth),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assets',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      FormatHelpers.currency(totalAssets),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Liabilities',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      FormatHelpers.currency(totalLiabilities),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (assets.isNotEmpty) ...[
                    _sectionTitle('Tài sản (Assets)'),
                    const SizedBox(height: 8),
                    ...assets.map((a) => _AccountTile(account: a)),
                    const SizedBox(height: 16),
                  ],
                  if (liabilities.isNotEmpty) ...[
                    _sectionTitle('Nợ (Liabilities / Credit card)'),
                    const SizedBox(height: 8),
                    ...liabilities.map((a) => _AccountTile(account: a)),
                    const SizedBox(height: 16),
                  ],
                  if (accounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Chưa có tài khoản. Nhấn Add Account để thêm.',
                          style: TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddAccountDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Account'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: $e', style: const TextStyle(color: AppColors.expense)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String accountType = 'asset';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Thêm tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  hintText: 'VD: Tiền mặt',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'asset', label: Text('Tài sản')),
                  ButtonSegment(value: 'liability', label: Text('Nợ')),
                ],
                selected: {accountType},
                onSelectionChanged: (s) => setState(() => accountType = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                DebugTapLogger.log('Reports: AddAccount Thêm pressed');
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  await ref.read(accountRepositoryProvider).addAccount(
                        name: name,
                        accountType: accountType,
                      );
                  if (!ctx.mounted) return;
                  DebugTapLogger.log('Reports: AddAccount OK, scheduling invalidate');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    DebugTapLogger.log('Reports: PostFrame invalidate accounts');
                    ref.invalidate(accountsListProvider);
                  });
                } on PostgrestException catch (e) {
                  final isForbidden = e.code == '403' ||
                      (e.message.toLowerCase().contains('403')) ||
                      (e.message.toLowerCase().contains('forbidden'));
                  final msg = isForbidden
                      ? 'Không có quyền thêm tài khoản. Chạy file Assets/SQL/rls_policies.sql trong Supabase SQL Editor.'
                      : 'Lỗi: ${e.message}';
                  if (ctx.mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    });
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Không thể thêm tài khoản: $e')));
                      }
                    });
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.3),
          child: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
        ),
        title: Text(
          account.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        trailing: Text(
          FormatHelpers.currency(account.balance),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
