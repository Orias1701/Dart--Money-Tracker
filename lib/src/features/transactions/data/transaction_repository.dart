import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/transaction.dart';

class TransactionRepository {
  TransactionRepository() : _client = SupabaseService.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Transaction>> getTransactions({
    List<String>? accountIds,
    DateTime? from,
    DateTime? to,
    int limit = 500,
  }) async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      var query = _client.from('transactions').select().eq('user_id', uid);
      if (accountIds != null && accountIds.isNotEmpty) {
        query = query.inFilter('account_id', accountIds);
      }
      if (from != null)
        query = query.gte('transaction_date', from.toIso8601String());
      if (to != null)
        query = query.lte('transaction_date', to.toIso8601String());
      final res = await query
          .order('transaction_date', ascending: false)
          .limit(limit);
      return (res as List)
          .map((e) => Transaction.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Transaction?> addTransaction({
    required String accountId,
    required String type,
    required double amount,
    required DateTime transactionDate,
    String? toAccountId,
    String? categoryId,
    double feeAmount = 0,
    String? note,
  }) async {
    final uid = _userId;
    if (uid == null || amount <= 0) return null;
    try {
      final map = {
        'user_id': uid,
        'account_id': accountId,
        'type': type,
        'amount': amount,
        'transaction_date': transactionDate.toIso8601String(),
        'fee_amount': feeAmount,
        'note': note,
      };
      if (toAccountId != null) map['to_account_id'] = toAccountId;
      if (categoryId != null) map['category_id'] = categoryId;
      final res = await _client
          .from('transactions')
          .insert(map)
          .select()
          .single();
      return Transaction.fromMap(res);
    } catch (_) {
      return null;
    }
  }
}
