class Transaction {
  const Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.feeAmount = 0,
    required this.transactionDate,
    this.note,
  });

  final String id;
  final String userId;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final String type;
  final double amount;
  final double feeAmount;
  final DateTime transactionDate;
  final String? note;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isTransfer => type == 'transfer';

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final d = map['transaction_date'];
    return Transaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String,
      toAccountId: map['to_account_id'] as String?,
      categoryId: map['category_id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0,
      feeAmount: (map['fee_amount'] is num) ? (map['fee_amount'] as num).toDouble() : 0,
      transactionDate: d != null ? (d is DateTime ? d : DateTime.parse(d.toString())) : DateTime.now(),
      note: map['note'] as String?,
    );
  }
}
