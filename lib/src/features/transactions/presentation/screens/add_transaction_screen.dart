import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/category_grid_item.dart';
import '../../../../common_widgets/custom_tab_bar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/debug_tap_logger.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../charts/presentation/providers/analytics_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../providers/transactions_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  int _tabIndex = 0; // 0=Expense, 1=Income, 2=Transfer
  Category? _selectedCategory;
  Account? _fromAccount;
  Account? _toAccount;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  var _isLoading = false;

  String get _type {
    if (_tabIndex == 0) return 'expense';
    if (_tabIndex == 1) return 'income';
    return 'transfer';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _showAddCategoryDialog(int orderIndex) async {
    final nameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Thêm danh mục'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên danh mục',
            hintText: 'VD: Lương',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              final repo = ref.read(categoryRepositoryProvider);
              final newCat = await repo.addCategory(
                name: name,
                type: _type,
                orderIndex: orderIndex,
              );
              final type = _type;
              if (!context.mounted) return;
              DebugTapLogger.log(
                'AddTx: AddCategory dialog OK, scheduling invalidate',
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                DebugTapLogger.log(
                  'AddTx: PostFrame invalidate categories + setState',
                );
                ref.invalidate(categoriesByTypeProvider(type));
                if (newCat != null && mounted)
                  setState(() => _selectedCategory = newCat);
                if (mounted && newCat == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thêm được danh mục')),
                  );
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    DebugTapLogger.log('AddTx: _save() called');
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập số tiền hợp lệ')));
      return;
    }
    if (_type == 'transfer') {
      if (_fromAccount == null ||
          _toAccount == null ||
          _fromAccount?.id == _toAccount?.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn Ví nguồn và Ví đích khác nhau')),
        );
        return;
      }
    } else {
      if (_fromAccount == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chọn ví')));
        return;
      }
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chọn danh mục')));
        return;
      }
    }
    setState(() => _isLoading = true);
    final repo = ref.read(transactionRepositoryProvider);
    final tx = await repo.addTransaction(
      accountId: _fromAccount!.id,
      type: _type,
      amount: amount,
      transactionDate: _date,
      toAccountId: _type == 'transfer' ? _toAccount!.id : null,
      categoryId: _type != 'transfer' ? _selectedCategory?.id : null,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (tx != null) {
      DebugTapLogger.log('AddTx: Save OK, scheduling invalidate+pop');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugTapLogger.log('AddTx: PostFrame invalidate+pop');
        if (!mounted) return;
        ref.invalidate(accountsListProvider);
        ref.invalidate(transactionsListProvider);
        ref.invalidate(expenseAnalyticsProvider);
        ref.invalidate(incomeAnalyticsProvider);
        ref.invalidate(topIncomeProvider);
        ref.invalidate(topExpenseProvider);
        context.go('/');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thêm được giao dịch')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(
      categoriesByTypeProvider(_type == 'transfer' ? 'expense' : _type),
    );
    final accountsAsync = ref.watch(accountsListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.close),
          tooltip: 'Hủy',
        ),
        title: const Text('Add'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
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
            CustomTabBar(
              selectedIndex: _tabIndex,
              onChanged: (i) {
                DebugTapLogger.log('AddTx: Tab onChanged i=$i');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  DebugTapLogger.log('AddTx: PostFrame setState tab=$i');
                  if (mounted) {
                    setState(() {
                      _tabIndex = i;
                      _selectedCategory = null;
                      _toAccount = null;
                    });
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            if (_type != 'transfer') ...[
              categoriesAsync.when(
                data: (categories) {
                  const addLabel = 'Thêm danh mục';
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: categories.length + 1,
                    itemBuilder: (_, i) {
                      if (i == categories.length) {
                        return CategoryGridItem(
                          label: addLabel,
                          selected: false,
                          colorHex: '#6B7280',
                          icon: Icons.add,
                          onTap: () {
                            DebugTapLogger.log('AddTx: AddCategory grid tap');
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              DebugTapLogger.log(
                                'AddTx: PostFrame showAddCategoryDialog',
                              );
                              if (mounted)
                                _showAddCategoryDialog(categories.length);
                            });
                          },
                        );
                      }
                      final c = categories[i];
                      return CategoryGridItem(
                        label: c.name,
                        selected: _selectedCategory?.id == c.id,
                        colorHex: c.colorHex,
                        icon: _iconFromName(c.iconName),
                        onTap: () {
                          DebugTapLogger.log(
                            'AddTx: Category grid tap "${c.name}"',
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            DebugTapLogger.log(
                              'AddTx: PostFrame setState category',
                            );
                            if (mounted)
                              setState(
                                () => _selectedCategory =
                                    _selectedCategory?.id == c.id ? null : c,
                              );
                          });
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  'Lỗi: $e',
                  style: const TextStyle(color: AppColors.expense),
                ),
              ),
              const SizedBox(height: 24),
            ],
            accountsAsync.when(
              data: (accounts) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AccountSelector(
                      label: 'Từ ví (From)',
                      accounts: accounts,
                      value: _fromAccount,
                      excludeId: null,
                      onChanged: (a) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _fromAccount = a);
                        });
                      },
                      onCreated: (a) {
                        ref.invalidate(accountsListProvider);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _fromAccount = a);
                        });
                      },
                      ref: ref,
                    ),
                    if (_type == 'transfer') ...[
                      const SizedBox(height: 16),
                      _AccountSelector(
                        label: 'Đến ví (To)',
                        accounts: accounts
                            .where((a) => a.id != _fromAccount?.id)
                            .toList(),
                        value: _toAccount,
                        excludeId: _fromAccount?.id,
                        onChanged: (a) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _toAccount = a);
                          });
                        },
                        onCreated: (a) {
                          ref.invalidate(accountsListProvider);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _toAccount = a);
                          });
                        },
                        ref: ref,
                      ),
                    ],
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                'Lỗi: $e',
                style: const TextStyle(color: AppColors.expense),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                DebugTapLogger.log('AddTx: Amount onChanged');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
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
                if (picked != null) {
                  DebugTapLogger.log('AddTx: Date picked');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _date = picked);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'shopping_cart':
        return Icons.shopping_cart;
      default:
        return Icons.category;
    }
  }
}

class _AccountSelector extends StatelessWidget {
  const _AccountSelector({
    required this.label,
    required this.accounts,
    required this.value,
    required this.excludeId,
    required this.onChanged,
    required this.onCreated,
    required this.ref,
  });

  final String label;
  final List<Account> accounts;
  final Account? value;
  final String? excludeId;
  final ValueChanged<Account?> onChanged;
  final ValueChanged<Account> onCreated;
  final WidgetRef ref;

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Tạo ví mới'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Tên ví',
            hintText: 'VD: Tiền mặt',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              final repo = ref.read(accountRepositoryProvider);
              final newAccount = await repo.addAccount(
                name: name,
                accountType: 'asset',
              );
              if (newAccount != null && context.mounted) onCreated(newAccount);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Tạo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chưa có ví. Tạo nhanh bên dưới.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Tạo ví mới'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Account>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          dropdownColor: AppColors.surface,
          items: [
            ...accounts.map(
              (a) => DropdownMenuItem(value: a, child: Text(a.name)),
            ),
          ],
          onChanged: (a) {
            DebugTapLogger.log('AddTx: Account dropdown changed');
            onChanged(a);
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showCreateDialog(context, ref),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tạo ví mới'),
        ),
      ],
    );
  }
}
