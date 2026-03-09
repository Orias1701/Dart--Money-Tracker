import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../../shell/shell_app_bar_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/providers/filter_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/analytics_repository.dart';
import '../providers/analytics_provider.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  void _invalidateAll() {
    ref.invalidate(expenseAnalyticsProvider);
    ref.invalidate(incomeAnalyticsProvider);
    ref.invalidate(topIncomeProvider);
    ref.invalidate(topExpenseProvider);
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final filterState = ref.watch(filterProvider);

    final effectiveStart = filterState.startDate ?? DateTime(2000, 1, 1);
    final effectiveEnd = filterState.endDate ?? DateTime.now();

    final params = ChartsParams(
      groupId: activeGroup?.id ?? '',
      from: effectiveStart,
      to: effectiveEnd,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shellAppBarTitleProvider.notifier).setTitle(
            1,
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Charts',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Thu'),
                Tab(text: 'Chi'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTabContent(
                    params: params,
                    filterState: filterState,
                    onRefresh: () async => _invalidateAll(),
                  ),
                  _ChartTabContent(
                    isIncome: true,
                    params: params,
                    filterState: filterState,
                    onRefresh: () async => _invalidateAll(),
                  ),
                  _ChartTabContent(
                    isIncome: false,
                    params: params,
                    filterState: filterState,
                    onRefresh: () async => _invalidateAll(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartTabContent extends ConsumerStatefulWidget {
  const _ChartTabContent({
    required this.isIncome,
    required this.params,
    required this.filterState,
    required this.onRefresh,
  });

  final bool isIncome;
  final ChartsParams params;
  final FilterState filterState;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_ChartTabContent> createState() => _ChartTabContentState();
}

class _ChartTabContentState extends ConsumerState<_ChartTabContent> {
  @override
  Widget build(BuildContext context) {
    if (widget.isIncome) {
      final topItemsAsync = ref.watch(topIncomeProvider(widget.params));
      return _buildContent(
        context,
        ref.watch(incomeAnalyticsProvider(widget.params)),
        topItemsAsync,
      );
    } else {
      final topItemsAsync = ref.watch(topExpenseProvider(widget.params));
      return _buildContent(
        context,
        ref.watch(expenseAnalyticsProvider(widget.params)),
        topItemsAsync,
      );
    }
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<dynamic> analyticsAsync,
    AsyncValue<List<Transaction>> topItemsAsync,
  ) {
    String chartTitle = widget.isIncome ? 'Thu nhập' : 'Chi tiêu';
    if (widget.filterState.startDate != null &&
        widget.filterState.endDate != null) {
      chartTitle +=
          '\n(từ ${FormatHelpers.dateShort(widget.filterState.startDate!)} đến ${FormatHelpers.dateShort(widget.filterState.endDate!)})';
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chart Section
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: analyticsAsync.when(
                  data: (data) => _ChartAndLegend(
                    total: data.total,
                    items: data.byCategory,
                    title: chartTitle,
                  ),
                  loading: () => const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 300,
                    child: Center(
                      child: Text(
                        'Lỗi: $e',
                        style: const TextStyle(color: AppColors.expense),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Top 5 List
            topItemsAsync.when(
              data: (list) => _Top5List(
                title: widget.isIncome
                    ? 'Thu cao nhất gần đây'
                    : 'Chi cao nhất gần đây',
                transactions: list,
                isIncome: widget.isIncome,
              ),
              loading: () => const Card(
                color: AppColors.surface,
                child: SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                color: AppColors.surface,
                child: SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      'Lỗi: $e',
                      style: const TextStyle(color: AppColors.expense),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTabContent extends ConsumerStatefulWidget {
  const _OverviewTabContent({
    required this.params,
    required this.filterState,
    required this.onRefresh,
  });

  final ChartsParams params;
  final FilterState filterState;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_OverviewTabContent> createState() =>
      _OverviewTabContentState();
}

class _OverviewTabContentState extends ConsumerState<_OverviewTabContent> {
  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeAnalyticsProvider(widget.params));
    final expenseAsync = ref.watch(expenseAnalyticsProvider(widget.params));

    String chartTitle = 'Tổng quan Thu / Chi';
    if (widget.filterState.startDate != null &&
        widget.filterState.endDate != null) {
      chartTitle +=
          '\n(từ ${FormatHelpers.dateShort(widget.filterState.startDate!)} đến ${FormatHelpers.dateShort(widget.filterState.endDate!)})';
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: incomeAsync.when(
          data: (incomeData) => expenseAsync.when(
            data: (expenseData) {
              final totalIncome = incomeData.total;
              final totalExpense = expenseData.total;

              final combinedItems = [
                CategoryAmount(
                  name: 'Thu nhập',
                  amount: totalIncome,
                  colorHex:
                      '#42A5F5', // AppColors.income isn't statically available here without context but we use a known hex
                ),
                CategoryAmount(
                  name: 'Chi tiêu',
                  amount: totalExpense,
                  colorHex: '#F44336', // Fallback hex for expense
                ),
              ];

              return Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _ChartAndLegend(
                    total: totalIncome + totalExpense,
                    items: combinedItems,
                    title: chartTitle,
                  ),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  'Lỗi: $e',
                  style: const TextStyle(color: AppColors.expense),
                ),
              ),
            ),
          ),
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'Lỗi: $e',
                style: const TextStyle(color: AppColors.expense),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartAndLegend extends StatelessWidget {
  const _ChartAndLegend({
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
      return SizedBox(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có dữ liệu',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final threshold = total * 0.03;
    final List<CategoryAmount> displayItems = [];
    double othersAmount = 0;

    for (final item in items) {
      if (item.amount < threshold) {
        othersAmount += item.amount;
      } else {
        displayItems.add(item);
      }
    }

    if (othersAmount > 0) {
      displayItems.add(
        CategoryAmount(
          name: 'Khác',
          amount: othersAmount,
          colorHex: '#808080', // Grey for Others
        ),
      );
    }

    final sections = displayItems.map((e) {
      final isOthers = e.name == 'Khác';
      final pct = total > 0 ? (e.amount / total * 100).toStringAsFixed(1) : '0';

      return PieChartSectionData(
        value: e.amount,
        title: isOthers ? '' : '$pct%',
        color: _parseHex(e.colorHex),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 65,
                  sections: sections,
                ),
                duration: const Duration(milliseconds: 300),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tổng',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    FormatHelpers.currency(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Legend Group
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: displayItems.map((e) {
            String displayName = e.name;
            if (e.name == 'Khác' && total > 0) {
              final pct = (e.amount / total * 100).toStringAsFixed(1);
              displayName = '${e.name} ($pct%)';
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseHex(e.colorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Top5List extends ConsumerWidget {
  const _Top5List({
    required this.title,
    required this.transactions,
    required this.isIncome,
  });

  final String title;
  final List<Transaction> transactions;
  final bool isIncome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Chưa có giao dịch',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...transactions.asMap().entries.map((e) {
                final t = e.value;
                String categoryName = 'Đang tải...';

                categoriesAsync.whenData((categories) {
                  final cat = categories
                      .where((c) => c.id == t.categoryId)
                      .firstOrNull;
                  categoryName = cat?.name ?? 'Khác';
                });

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FormatHelpers.date(t.transactionDate),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        FormatHelpers.currency(t.amount),
                        style: TextStyle(
                          color: isIncome
                              ? AppColors.income
                              : AppColors.expense,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
