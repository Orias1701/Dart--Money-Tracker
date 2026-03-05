import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../transactions/domain/transaction.dart';
import '../../data/analytics_repository.dart';
import '../providers/analytics_provider.dart';

const double _kChartCellHeight = 200;

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  int _tabIndex = 1; // 0=Week, 1=Month, 2=Year
  final DateTime _reference = DateTime.now();

  String get _period {
    if (_tabIndex == 0) return 'week';
    if (_tabIndex == 1) return 'month';
    return 'year';
  }

  void _invalidateAll() {
    ref.invalidate(expenseAnalyticsProvider);
    ref.invalidate(incomeAnalyticsProvider);
    ref.invalidate(topIncomeProvider);
    ref.invalidate(topExpenseProvider);
  }

  @override
  Widget build(BuildContext context) {
    final params = ChartsParams(period: _period, reference: _reference);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Charts'),
        backgroundColor: AppColors.background,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _invalidateAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Week')),
                  ButtonSegment(value: 1, label: Text('Month')),
                  ButtonSegment(value: 2, label: Text('Year')),
                ],
                selected: {_tabIndex},
                onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
              ),
              const SizedBox(height: 20),
              LayoutGrid(params: params),
            ],
          ),
        ),
      ),
    );
  }
}

class LayoutGrid extends ConsumerWidget {
  const LayoutGrid({super.key, required this.params});

  final ChartsParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _Top5IncomeCard()),
            const SizedBox(width: 12),
            Expanded(child: _IncomeChartCell(params: params)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ExpenseChartCell(params: params)),
            const SizedBox(width: 12),
            const Expanded(child: _Top5ExpenseCard()),
          ],
        ),
      ],
    );
  }
}

class _Top5IncomeCard extends ConsumerWidget {
  const _Top5IncomeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topIncomeProvider);
    return async.when(
      data: (list) => _Top5List(
        title: 'Top 5 thu gần nhất',
        transactions: list,
        isIncome: true,
      ),
      loading: () => _cardSkeleton(const Text('Top 5 thu')),
      error: (e, _) => _cardSkeleton(Text('Lỗi: $e', style: const TextStyle(color: AppColors.expense, fontSize: 12))),
    );
  }
}

class _Top5ExpenseCard extends ConsumerWidget {
  const _Top5ExpenseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topExpenseProvider);
    return async.when(
      data: (list) => _Top5List(
        title: 'Top 5 chi gần nhất',
        transactions: list,
        isIncome: false,
      ),
      loading: () => _cardSkeleton(const Text('Top 5 chi')),
      error: (e, _) => _cardSkeleton(Text('Lỗi: $e', style: const TextStyle(color: AppColors.expense, fontSize: 12))),
    );
  }
}

Widget _cardSkeleton(Widget child) {
  return Card(
    color: AppColors.surface,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: _kChartCellHeight,
        child: Center(child: child),
      ),
    ),
  );
}

class _Top5List extends StatelessWidget {
  const _Top5List({
    required this.title,
    required this.transactions,
    required this.isIncome,
  });

  final String title;
  final List<Transaction> transactions;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: _kChartCellHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Chưa có giao dịch',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: transactions.asMap().entries.map((e) {
                        final t = e.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Text(
                                '${e.key + 1}.',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  FormatHelpers.currency(t.amount),
                                  style: TextStyle(
                                    color: isIncome ? AppColors.income : AppColors.expense,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                FormatHelpers.date(t.transactionDate),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeChartCell extends ConsumerWidget {
  const _IncomeChartCell({required this.params});

  final ChartsParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incomeAnalyticsProvider(params));
    return async.when(
      data: (data) => _DonutChart(
        total: data.total,
        items: data.byCategory,
        title: 'Thu nhập',
      ),
      loading: () => _cardSkeleton(const CircularProgressIndicator()),
      error: (e, _) => _cardSkeleton(Text('Lỗi: $e', style: const TextStyle(color: AppColors.expense, fontSize: 12))),
    );
  }
}

class _ExpenseChartCell extends ConsumerWidget {
  const _ExpenseChartCell({required this.params});

  final ChartsParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseAnalyticsProvider(params));
    return async.when(
      data: (data) => _DonutChart(
        total: data.total,
        items: data.byCategory,
        title: 'Chi tiêu',
      ),
      loading: () => _cardSkeleton(const CircularProgressIndicator()),
      error: (e, _) => _cardSkeleton(Text('Lỗi: $e', style: const TextStyle(color: AppColors.expense, fontSize: 12))),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.total,
    required this.items,
    required this.title,
  });

  final double total;
  final List<CategoryAmount> items;
  final String title;

  static Color _parseHex(String hex) {
    if (hex.isEmpty) return AppColors.textSecondary;
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length != 6) return AppColors.textSecondary;
    return Color(int.parse(h, radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: _kChartCellHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final sections = items.asMap().entries.map((e) {
      final pct = total > 0 ? (e.value.amount / total * 100).toStringAsFixed(1) : '0';
      return PieChartSectionData(
        value: e.value.amount,
        title: '$pct%',
        color: _parseHex(e.value.colorHex),
        radius: 40,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: _kChartCellHeight,
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        sections: sections,
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 300),
                    ),
                    Text(
                      FormatHelpers.currency(total),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
