import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/account.dart';

class AccountRepository {
  AccountRepository() : _client = SupabaseService.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Account>> getAccounts() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final res = await _client
          .from('accounts')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return (res as List).map((e) => Account.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Account?> addAccount({
    required String name,
    required String accountType,
    double balance = 0,
    String currency = 'VND',
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final res = await _client.from('accounts').insert({
      'user_id': uid,
      'name': name,
      'account_type': accountType,
      'balance': balance,
      'currency': currency,
    }).select().single();
    return Account.fromMap(res);
  }
}
