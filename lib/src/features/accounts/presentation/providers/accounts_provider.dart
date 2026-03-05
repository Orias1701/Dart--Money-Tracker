import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account_repository.dart';
import '../../domain/account.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

final accountsListProvider = FutureProvider<List<Account>>((ref) async {
  return ref.read(accountRepositoryProvider).getAccounts();
});
