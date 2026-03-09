import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/transaction.dart';

class TransactionRepository {
  TransactionRepository() : _client = SupabaseService.client;

  final SupabaseClient _client;

  Future<List<Transaction>> getTransactions({
    required String groupId,
    List<String>? accountIds,
    DateTime? from,
    DateTime? to,
    int limit = 500,
  }) async {
    if (groupId.isEmpty) return [];
    try {
      var query = _client
          .from('transactions')
          .select(
            '*, created_by_user:users!transactions_created_by_fkey(full_name, username, avatar_url), paid_by_user:users!transactions_paid_by_fkey(full_name, username, avatar_url)',
          )
          .eq('group_id', groupId)
          .or('row_status.is.null,row_status.eq.active');
      if (accountIds != null && accountIds.isNotEmpty) {
        query = query.inFilter('account_id', accountIds);
      }
      if (from != null) {
        query = query.gte('transaction_date', from.toIso8601String());
      }
      if (to != null) {
        query = query.lte('transaction_date', to.toIso8601String());
      }
      final res = await query.order('transaction_date', ascending: false).limit(limit);
      return (res as List).map((e) => Transaction.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      try {
        var fallback = _client.from('transactions').select().eq('group_id', groupId);
        if (accountIds != null && accountIds.isNotEmpty) fallback = fallback.inFilter('account_id', accountIds);
        if (from != null) fallback = fallback.gte('transaction_date', from.toIso8601String());
        if (to != null) fallback = fallback.lte('transaction_date', to.toIso8601String());
        final res = await fallback.order('transaction_date', ascending: false).limit(limit);
        return (res as List).map((e) => Transaction.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<Transaction?> addTransaction({
    required String groupId,
    required String accountId,
    required String type,
    required double amount,
    required DateTime transactionDate,
    required String createdBy,
    required String paidBy,
    String? toAccountId,
    String? categoryId,
    double feeAmount = 0,
    String? note,
  }) async {
    if (groupId.isEmpty || amount <= 0) return null;
    try {
      final map = {
        'group_id': groupId,
        'account_id': accountId,
        'type': type,
        'amount': amount,
        'transaction_date': transactionDate.toIso8601String(),
        'fee_amount': feeAmount,
        'note': note,
        'created_by': createdBy,
        'paid_by': paidBy,
      };
      if (toAccountId != null) map['to_account_id'] = toAccountId;
      if (categoryId != null) map['category_id'] = categoryId;
      final res = await _client.from('transactions').insert(map).select().single();
      return Transaction.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  Future<Transaction?> updateTransaction({
    required String transactionId,
    required String groupId,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    String? type,
    double? amount,
    DateTime? transactionDate,
    double? feeAmount,
    String? note,
  }) async {
    try {
      final map = <String, dynamic>{};
      if (accountId != null) map['account_id'] = accountId;
      if (toAccountId != null) map['to_account_id'] = toAccountId;
      if (categoryId != null) map['category_id'] = categoryId;
      if (type != null) map['type'] = type;
      if (amount != null) map['amount'] = amount;
      if (transactionDate != null) {
        map['transaction_date'] = transactionDate.toIso8601String();
      }
      if (feeAmount != null) map['fee_amount'] = feeAmount;
      if (note != null) map['note'] = note;
      if (map.isEmpty) return null;
      final res = await _client
          .from('transactions')
          .update(map)
          .eq('id', transactionId)
          .eq('group_id', groupId)
          .select()
          .single();
      return Transaction.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  /// Xoá mềm: set row_status = 'deleted' (gọi RPC để có kết quả chính xác sau RLS).
  Future<bool> softDeleteTransaction(String transactionId, String groupId) async {
    try {
      final res = await _client.rpc(
        'soft_delete_transaction',
        params: {
          'p_transaction_id': transactionId,
          'p_group_id': groupId,
        },
      );
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
