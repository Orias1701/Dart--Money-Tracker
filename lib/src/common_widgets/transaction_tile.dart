import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Left: CircleAvatar với icon danh mục, nền color_hex.
/// Middle: Title (tên danh mục/ghi chú), Subtitle (tên ví).
/// Right: Số tiền (đỏ có - nếu expense, trắng/xanh nếu income).
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.accountName,
    required this.amount,
    required this.isExpense,
    this.colorHex,
    this.icon,
    this.paidByLabel,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? accountName;
  final String amount;
  final bool isExpense;
  final String? colorHex;
  final IconData? icon;
  /// Hiển thị khi quản lý nhóm (không phải cá nhân): tên/avatar người thanh toán.
  final String? paidByLabel;
  final VoidCallback? onTap;

  static Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.textSecondary;
    final h = hex.startsWith('#') ? hex : '#$hex';
    if (h.length != 7) return AppColors.textSecondary;
    return Color(int.parse(h.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseHex(colorHex);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: bgColor.withValues(alpha: 0.4),
        child: Icon(
          icon ?? (isExpense ? Icons.arrow_upward : Icons.arrow_downward),
          color: bgColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (subtitle != null || paidByLabel != null)
          ? Text(
              [if (subtitle != null && subtitle!.isNotEmpty) subtitle!, if (paidByLabel != null && paidByLabel!.isNotEmpty) 'Trả bởi: $paidByLabel'].join(' • '),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            isExpense ? '-$amount' : '+$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isExpense ? AppColors.expense : AppColors.income,
            ),
          ),
          if (accountName != null && accountName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              accountName!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
