class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
    this.userId,
    this.parentId,
    this.orderIndex = 0,
  });

  final String id;
  final String name;
  final String type; // 'income' | 'expense'
  final String iconName;
  final String colorHex;
  final String? userId;
  final String? parentId;
  final int orderIndex;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      iconName: map['icon_name'] as String? ?? 'category',
      colorHex: map['color_hex'] as String? ?? '#A0A0A0',
      userId: map['user_id'] as String?,
      parentId: map['parent_id'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}
