import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Tăng khi có thêm/sửa/xóa giao dịch để chart và analytics luôn refetch khi mở lại.
final transactionVersionProvider = StateProvider<int>((ref) => 0);

final transactionsListProvider =
    FutureProvider.family<List<Transaction>, TransactionListParams>((
      ref,
      params,
    ) async {
      if (params.groupId == null || params.groupId!.isEmpty) return [];
      return ref.read(transactionRepositoryProvider).getTransactions(
            groupId: params.groupId!,
            accountIds: params.accountIds,
            from: params.from,
            to: params.to,
          );
    });

class TransactionListParams {
  const TransactionListParams({
    this.groupId,
    this.accountIds,
    this.from,
    this.to,
  });
  final String? groupId;
  final List<String>? accountIds;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionListParams &&
          groupId == other.groupId &&
          listEquals(accountIds, other.accountIds) &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(
        groupId,
        accountIds == null ? null : Object.hashAll(accountIds!),
        from,
        to,
      );
}
