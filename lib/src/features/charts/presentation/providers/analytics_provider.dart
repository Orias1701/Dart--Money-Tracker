import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics_repository.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(
    transactionRepository: ref.read(transactionRepositoryProvider),
    categoryRepository: ref.read(categoryRepositoryProvider),
  );
});

class ChartsParams {
  const ChartsParams({required this.period, required this.reference});
  final String period;
  final DateTime reference;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartsParams && period == other.period && reference == other.reference;

  @override
  int get hashCode => Object.hash(period, reference);
}

final expenseAnalyticsProvider =
    FutureProvider.family<ExpenseAnalytics, ChartsParams>((ref, params) async {
  return ref.read(analyticsRepositoryProvider).getExpenseAnalytics(
        period: params.period,
        reference: params.reference,
      );
});

final incomeAnalyticsProvider =
    FutureProvider.family<IncomeAnalytics, ChartsParams>((ref, params) async {
  return ref.read(analyticsRepositoryProvider).getIncomeAnalytics(
        period: params.period,
        reference: params.reference,
      );
});

final topIncomeProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getTopRecentTransactions(type: 'income', limit: 5);
});

final topExpenseProvider = FutureProvider<List<Transaction>>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getTopRecentTransactions(type: 'expense', limit: 5);
});
