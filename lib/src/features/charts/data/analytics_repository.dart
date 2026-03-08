import '../../categories/data/category_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction.dart';

class AnalyticsRepository {
  AnalyticsRepository({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
  }) : _txRepo = transactionRepository,
       _catRepo = categoryRepository;

  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;

  Future<ExpenseAnalytics> getExpenseAnalytics({
    required DateTime from,
    required DateTime to,
  }) async {
    final transactions = await _txRepo.getTransactions(from: from, to: to);
    final categories = await _catRepo.getCategories(type: 'expense');
    final catMap = {for (final c in categories) c.id: c};
    final byCategory = <String, double>{};
    for (final tx in transactions) {
      if (tx.type != 'expense' || tx.categoryId == null) continue;
      final name = catMap[tx.categoryId]?.name ?? 'Khác';
      byCategory[name] = (byCategory[name] ?? 0) + tx.amount;
    }
    final list = <CategoryAmount>[];
    for (final e in byCategory.entries) {
      final cat = categories.where((c) => c.name == e.key).firstOrNull;
      list.add(
        CategoryAmount(
          name: e.key,
          amount: e.value,
          colorHex: cat?.colorHex ?? '#A0A0A0',
        ),
      );
    }
    list.sort((a, b) => b.amount.compareTo(a.amount));
    final total = list.fold<double>(0, (s, x) => s + x.amount);
    return ExpenseAnalytics(total: total, byCategory: list);
  }

  Future<IncomeAnalytics> getIncomeAnalytics({
    required DateTime from,
    required DateTime to,
  }) async {
    final transactions = await _txRepo.getTransactions(from: from, to: to);
    final categories = await _catRepo.getCategories(type: 'income');
    final catMap = {for (final c in categories) c.id: c};
    final byCategory = <String, double>{};
    for (final tx in transactions) {
      if (tx.type != 'income' || tx.categoryId == null) continue;
      final name = catMap[tx.categoryId]?.name ?? 'Khác';
      byCategory[name] = (byCategory[name] ?? 0) + tx.amount;
    }
    final list = <CategoryAmount>[];
    for (final e in byCategory.entries) {
      final cat = categories.where((c) => c.name == e.key).firstOrNull;
      list.add(
        CategoryAmount(
          name: e.key,
          amount: e.value,
          colorHex: cat?.colorHex ?? '#A0A0A0',
        ),
      );
    }
    list.sort((a, b) => b.amount.compareTo(a.amount));
    final total = list.fold<double>(0, (s, x) => s + x.amount);
    return IncomeAnalytics(total: total, byCategory: list);
  }

  Future<List<Transaction>> getTopTransactions({
    required DateTime from,
    required DateTime to,
    required String type,
    int limit = 5,
  }) async {
    final tx = await _txRepo.getTransactions(from: from, to: to);
    final filtered = tx.where((t) => t.type == type).toList();
    filtered.sort((a, b) => b.amount.compareTo(a.amount));
    return filtered.take(limit).toList();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class ExpenseAnalytics {
  const ExpenseAnalytics({required this.total, required this.byCategory});
  final double total;
  final List<CategoryAmount> byCategory;
}

class IncomeAnalytics {
  const IncomeAnalytics({required this.total, required this.byCategory});
  final double total;
  final List<CategoryAmount> byCategory;
}

class CategoryAmount {
  const CategoryAmount({
    required this.name,
    required this.amount,
    required this.colorHex,
  });
  final String name;
  final double amount;
  final String colorHex;
}
