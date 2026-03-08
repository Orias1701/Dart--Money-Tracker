import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/transaction_tile.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedAccountIds = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final params = TransactionListParams(
      from: _startDate,
      to: _endDate,
      accountIds: _selectedAccountIds.isEmpty ? null : _selectedAccountIds,
    );
    final transactionsAsync = ref.watch(transactionsListProvider(params));
    final accountsAsync = ref.watch(accountsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Records'),
        backgroundColor: AppColors.background,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final accounts = accountsAsync.valueOrNull ?? [];
          _showFilterBottomSheet(accounts);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.filter_list, color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsListProvider);
          ref.invalidate(accountsListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_startDate != null && _endDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      '${FormatHelpers.dateShort(_startDate!)} - ${FormatHelpers.dateShort(_endDate!)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              transactionsAsync.when(
                data: (list) {
                  double income = 0, expense = 0;
                  for (final t in list) {
                    if (t.isIncome) {
                      income += t.amount;
                    } else if (t.isExpense) {
                      expense += t.amount;
                    }
                  }
                  final balance = income - expense;
                  return Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SummaryChip(
                            label: 'Expenses',
                            value: FormatHelpers.currency(expense),
                          ),
                          _SummaryChip(
                            label: 'Income',
                            value: FormatHelpers.currency(income),
                          ),
                          _SummaryChip(
                            label: 'Balance',
                            value: FormatHelpers.currency(balance),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              transactionsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Chưa có giao dịch. Nhấn nút + để thêm.',
                          style: TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final byDate = _groupByDate(list);
                  return accountsAsync.when(
                    data: (accounts) {
                      return categoriesAsync.when(
                        data: (categories) {
                          final accountMap = {
                            for (final a in accounts) a.id: a,
                          };
                          final categoryMap = {
                            for (final c in categories) c.id: c,
                          };
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: byDate.entries.map((e) {
                              return _DaySection(
                                date: e.key,
                                transactions: e.value,
                                accountMap: accountMap,
                                categoryMap: categoryMap,
                              );
                            }).toList(),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, st) => const SizedBox.shrink(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, st) => const SizedBox.shrink(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(
                  'Lỗi: $e',
                  style: const TextStyle(color: AppColors.expense),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<Transaction>> _groupByDate(List<Transaction> list) {
    final map = <DateTime, List<Transaction>>{};
    for (final t in list) {
      final d = DateTime(
        t.transactionDate.year,
        t.transactionDate.month,
        t.transactionDate.day,
      );
      map.putIfAbsent(d, () => []).add(t);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return Map.fromEntries(keys.map((k) => MapEntry(k, map[k]!)));
  }

  Future<void> _showFilterBottomSheet(List<Account> accounts) async {
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;
    List<String> tempAccounts = List.from(_selectedAccountIds);

    int getSelectedTimeIndex() {
      if (tempStart == null && tempEnd == null) return 0;
      final now = DateTime.now();
      if (tempEnd!.year == now.year &&
          tempEnd!.month == now.month &&
          tempEnd!.day == now.day) {
        final diff = tempEnd!.difference(tempStart!).inDays;
        if (diff == 6) return 1; // 7 days (including today)
        if (diff == 29) return 2; // 30 days
      }
      return 3; // Custom
    }

    int selectedTimeIndex = getSelectedTimeIndex();

    void updateTimeByIndex(int index) {
      selectedTimeIndex = index;
      if (index == 0) {
        tempStart = null;
        tempEnd = null;
      } else if (index == 1) {
        final now = DateTime.now();
        tempEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        tempStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
      } else if (index == 2) {
        final now = DateTime.now();
        tempEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        tempStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
      } else if (index == 3) {
        // Will be set by date picker
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bộ lọc',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            updateTimeByIndex(0);
                            tempAccounts.clear();
                          });
                        },
                        child: const Text('Xóa bộ lọc'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Thời gian',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: selectedTimeIndex == 0,
                        onSelected: (val) {
                          if (val) setModalState(() => updateTimeByIndex(0));
                        },
                      ),
                      ChoiceChip(
                        label: const Text('7 ngày qua'),
                        selected: selectedTimeIndex == 1,
                        onSelected: (val) {
                          if (val) setModalState(() => updateTimeByIndex(1));
                        },
                      ),
                      ChoiceChip(
                        label: const Text('30 ngày qua'),
                        selected: selectedTimeIndex == 2,
                        onSelected: (val) {
                          if (val) setModalState(() => updateTimeByIndex(2));
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Tùy chọn'),
                        selected: selectedTimeIndex == 3,
                        onSelected: (val) async {
                          if (!val) return;
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDateRange:
                                tempStart != null && tempEnd != null
                                ? DateTimeRange(
                                    start: tempStart!,
                                    end: tempEnd!,
                                  )
                                : null,
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.black,
                                    surface: AppColors.surface,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            final diff = picked.end
                                .difference(picked.start)
                                .inDays;
                            if (diff > 90) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chỉ được chọn tối đa 90 ngày'),
                                  backgroundColor: AppColors.expense,
                                ),
                              );
                              return;
                            }
                            setModalState(() {
                              selectedTimeIndex = 3;
                              tempStart = picked.start;
                              tempEnd = DateTime(
                                picked.end.year,
                                picked.end.month,
                                picked.end.day,
                                23,
                                59,
                                59,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (selectedTimeIndex == 3 &&
                      tempStart != null &&
                      tempEnd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Từ ${FormatHelpers.dateShort(tempStart!)} đến ${FormatHelpers.dateShort(tempEnd!)}',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tài khoản',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts.map((account) {
                      return FilterChip(
                        label: Text(account.name),
                        selected: tempAccounts.contains(account.id),
                        onSelected: (val) {
                          setModalState(() {
                            if (val) {
                              tempAccounts.add(account.id);
                            } else {
                              tempAccounts.remove(account.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _startDate = tempStart;
                        _endDate = tempEnd;
                        _selectedAccountIds = List.from(tempAccounts);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Áp dụng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.date,
    required this.transactions,
    required this.accountMap,
    required this.categoryMap,
  });

  final DateTime date;
  final List<Transaction> transactions;
  final Map<String, Account> accountMap;
  final Map<String, Category> categoryMap;

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = _weekdays[date.weekday - 1];
    final monthName = monthNames[date.month - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$monthName ${date.day} $weekday',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...transactions.map((t) {
          final cat = t.categoryId != null ? categoryMap[t.categoryId] : null;
          final account = accountMap[t.accountId];
          return TransactionTile(
            title: cat?.name ?? '—',
            subtitle: t.note,
            accountName: account?.name,
            amount: FormatHelpers.currency(t.amount),
            isExpense: t.isExpense,
            colorHex: cat?.colorHex,
          );
        }),
      ],
    );
  }
}
