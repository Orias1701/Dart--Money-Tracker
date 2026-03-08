import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/transaction_tile.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../shared/presentation/providers/filter_provider.dart';
import '../../../shared/presentation/widgets/filter_bottom_sheet.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(filterProvider);
    final params = TransactionListParams(
      from: filterState.startDate,
      to: filterState.endDate,
      accountIds: filterState.selectedAccountIds.isEmpty
          ? null
          : filterState.selectedAccountIds,
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
          FilterBottomSheet.show(context);
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
              if (filterState.startDate != null && filterState.endDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      '${FormatHelpers.dateShort(filterState.startDate!)} - ${FormatHelpers.dateShort(filterState.endDate!)}',
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
