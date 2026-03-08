import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final transactionsListProvider =
    FutureProvider.family<List<Transaction>, TransactionListParams>((
      ref,
      params,
    ) async {
      return ref
          .read(transactionRepositoryProvider)
          .getTransactions(
            accountIds: params.accountIds,
            from: params.from,
            to: params.to,
          );
    });

class TransactionListParams {
  const TransactionListParams({this.accountIds, this.from, this.to});
  final List<String>? accountIds;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionListParams &&
          listEquals(accountIds, other.accountIds) &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(
    accountIds == null ? null : Object.hashAll(accountIds!),
    from,
    to,
  );
}
