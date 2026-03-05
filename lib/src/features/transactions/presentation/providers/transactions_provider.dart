import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final transactionsListProvider =
    FutureProvider.family<List<Transaction>, TransactionListParams>((ref, params) async {
  return ref.read(transactionRepositoryProvider).getTransactions(
        accountId: params.accountId,
        from: params.from,
        to: params.to,
      );
});

class TransactionListParams {
  const TransactionListParams({this.accountId, this.from, this.to});
  final String? accountId;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionListParams &&
          accountId == other.accountId &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(accountId, from, to);
}
