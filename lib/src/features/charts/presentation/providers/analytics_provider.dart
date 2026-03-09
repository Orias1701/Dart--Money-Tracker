import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics_repository.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../shared/presentation/providers/filter_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    transactionRepository: ref.read(transactionRepositoryProvider),
    categoryRepository: ref.read(categoryRepositoryProvider),
  );
});

class ChartsParams {
  const ChartsParams({
    required this.groupId,
    required this.from,
    required this.to,
  });
  final String groupId;
  final DateTime from;
  final DateTime to;

  /// Cùng bộ lọc + nhóm luôn ra cùng params (chuẩn hóa ngày), để refresh đúng instance Chart đang watch.
  static ChartsParams fromFilter(FilterState filterState, String groupId) {
    final from = filterState.startDate ?? DateTime(2000, 1, 1);
    final to = filterState.endDate ?? DateTime.now();
    final fromNorm = DateTime(from.year, from.month, from.day);
    final toNorm = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return ChartsParams(groupId: groupId, from: fromNorm, to: toNorm);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartsParams &&
          groupId == other.groupId &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(groupId, from, to);
}

/// Params dùng cho danh sách giao dịch, đồng bộ với ChartsParams để chart tự refetch khi giao dịch thay đổi.
TransactionListParams _txParams(ChartsParams params) {
  return TransactionListParams(
    groupId: params.groupId,
    from: params.from,
    to: params.to,
  );
}

final expenseAnalyticsProvider = FutureProvider.autoDispose
    .family<ExpenseAnalytics, ChartsParams>((ref, params) async {
  if (params.groupId.isEmpty) return const ExpenseAnalytics(total: 0, byCategory: []);
  ref.watch(transactionVersionProvider);
  ref.watch(transactionsListProvider(_txParams(params)));
  return ref.read(analyticsRepositoryProvider).getExpenseAnalytics(
        groupId: params.groupId,
        from: params.from,
        to: params.to,
      );
});

final incomeAnalyticsProvider = FutureProvider.autoDispose
    .family<IncomeAnalytics, ChartsParams>((ref, params) async {
  if (params.groupId.isEmpty) return const IncomeAnalytics(total: 0, byCategory: []);
  ref.watch(transactionVersionProvider);
  ref.watch(transactionsListProvider(_txParams(params)));
  return ref.read(analyticsRepositoryProvider).getIncomeAnalytics(
        groupId: params.groupId,
        from: params.from,
        to: params.to,
      );
});

final topIncomeProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ChartsParams>((ref, params) async {
  if (params.groupId.isEmpty) return [];
  ref.watch(transactionVersionProvider);
  ref.watch(transactionsListProvider(_txParams(params)));
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getTopTransactions(
    groupId: params.groupId,
    from: params.from,
    to: params.to,
    type: 'income',
    limit: 5,
  );
});

final topExpenseProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ChartsParams>((ref, params) async {
  if (params.groupId.isEmpty) return [];
  ref.watch(transactionVersionProvider);
  ref.watch(transactionsListProvider(_txParams(params)));
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getTopTransactions(
    groupId: params.groupId,
    from: params.from,
    to: params.to,
    type: 'expense',
    limit: 5,
  );
});
