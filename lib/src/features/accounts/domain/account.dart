class Account {
  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountType,
    required this.balance,
    this.creditLimit = 0,
    this.currency = 'VND',
    this.includeInTotal = true,
  });

  final String id;
  final String userId;
  final String name;
  final String accountType;
  final double balance;
  final double creditLimit;
  final String currency;
  final bool includeInTotal;

  bool get isAsset => accountType == 'asset';
  bool get isLiability => accountType == 'liability';

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      accountType: map['account_type'] as String,
      balance: (map['balance'] is num) ? (map['balance'] as num).toDouble() : 0,
      creditLimit: (map['credit_limit'] is num) ? (map['credit_limit'] as num).toDouble() : 0,
      currency: map['currency'] as String? ?? 'VND',
      includeInTotal: map['include_in_total'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'account_type': accountType,
      'balance': balance,
      'credit_limit': creditLimit,
      'currency': currency,
      'include_in_total': includeInTotal,
    };
  }
}
