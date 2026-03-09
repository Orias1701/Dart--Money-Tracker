import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../charts/presentation/providers/analytics_provider.dart';
import '../../domain/transaction.dart';
import '../providers/transactions_provider.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({super.key, required this.transaction});

  final Transaction transaction;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  Account? _fromAccount;
  Account? _toAccount;
  Category? _selectedCategory;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _date;
  var _isLoading = false;
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _amountController.text = FormatHelpers.currency(t.amount);
    _noteController.text = t.note ?? '';
    _date = t.transactionDate;
  }

  static Account? _findAccount(List<Account> accounts, String id) {
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static Category? _findCategory(List<Category> categories, String? id) {
    if (id == null) return null;
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final amount = double.tryParse(
        _amountController.text.replaceAll(',', '').replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhập số tiền hợp lệ')));
      return;
    }
    if (widget.transaction.isTransfer) {
      if (_fromAccount == null ||
          _toAccount == null ||
          _fromAccount?.id == _toAccount?.id) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Chọn Ví nguồn và Ví đích khác nhau')));
        return;
      }
    } else {
      if (_fromAccount == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Chọn ví')));
        return;
      }
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Chọn danh mục')));
        return;
    }
    }
    setState(() => _isLoading = true);
    final repo = ref.read(transactionRepositoryProvider);
    final tx = await repo.updateTransaction(
      transactionId: widget.transaction.id,
      groupId: widget.transaction.groupId,
      accountId: _fromAccount!.id,
      toAccountId: widget.transaction.isTransfer ? _toAccount!.id : null,
      categoryId: widget.transaction.isTransfer ? null : _selectedCategory?.id,
      amount: amount,
      transactionDate: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (tx != null) {
      ref.invalidate(accountsListProvider);
      ref.invalidate(transactionsListProvider);
      ref.invalidate(expenseAnalyticsProvider);
      ref.invalidate(incomeAnalyticsProvider);
      ref.invalidate(topIncomeProvider);
      ref.invalidate(topExpenseProvider);
      if (mounted) context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không cập nhật được giao dịch')));
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xoá giao dịch'),
        content: const Text(
          'Bạn có chắc muốn xoá giao dịch này? Có thể khôi phục sau nếu cần.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(transactionRepositoryProvider).softDeleteTransaction(
          widget.transaction.id,
          widget.transaction.groupId,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    ref.invalidate(accountsListProvider);
    ref.invalidate(transactionsListProvider);
    ref.invalidate(expenseAnalyticsProvider);
    ref.invalidate(incomeAnalyticsProvider);
    ref.invalidate(topIncomeProvider);
    ref.invalidate(topExpenseProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                ok ? 'Đã xoá giao dịch.' : 'Không xoá được giao dịch.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final typeLabel = t.isExpense ? 'Chi' : (t.isIncome ? 'Thu' : 'Chuyển khoản');
    final categoriesAsync = ref.watch(
      categoriesByTypeProvider(t.isTransfer ? 'expense' : t.type),
    );
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Đóng',
        ),
        title: const Text('Sửa giao dịch'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _delete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xoá',
            color: AppColors.expense,
          ),
          TextButton(
            onPressed: _isLoading ? null : _update,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Cập nhật',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                typeLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            accountsAsync.when(
              data: (accounts) {
                if (!_initialized) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _initialized = true;
                        _fromAccount = _findAccount(accounts, t.accountId) ??
                            (accounts.isNotEmpty ? accounts.first : null);
                        if (t.isTransfer && t.toAccountId != null) {
                          _toAccount =
                              _findAccount(accounts, t.toAccountId!);
                        }
                      });
                    }
                  });
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<Account>(
                      initialValue: _fromAccount,
                      decoration: const InputDecoration(
                        labelText: 'Từ ví (From)',
                      ),
                      dropdownColor: AppColors.surface,
                      items: accounts
                          .map((a) =>
                              DropdownMenuItem(value: a, child: Text(a.name)))
                          .toList(),
                      onChanged: (a) => setState(() => _fromAccount = a),
                    ),
                    if (t.isTransfer) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Account>(
                        initialValue: _toAccount,
                        decoration: const InputDecoration(
                          labelText: 'Đến ví (To)',
                        ),
                        dropdownColor: AppColors.surface,
                        items: accounts
                            .where((a) => a.id != _fromAccount?.id)
                            .map((a) => DropdownMenuItem(
                                value: a, child: Text(a.name)))
                            .toList(),
                        onChanged: (a) => setState(() => _toAccount = a),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi: $e',
                  style: const TextStyle(color: AppColors.expense)),
            ),
            if (!t.isTransfer) ...[
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  if (_selectedCategory == null && categories.isNotEmpty) {
                    final match = _findCategory(categories, t.categoryId);
                    if (match != null && mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedCategory = match);
                      });
                    }
                  }
                  return DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                    ),
                    dropdownColor: AppColors.surface,
                    items: categories
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => setState(() => _selectedCategory = c),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Lỗi: $e',
                    style: const TextStyle(color: AppColors.expense)),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Số tiền',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Ngày: ${FormatHelpers.date(_date)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null && mounted) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
