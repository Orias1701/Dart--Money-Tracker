import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Hình tròn chứa icon; màu xám khi chưa chọn, sáng theo color_hex khi chọn.
/// Text tên danh mục ở dưới.
class CategoryGridItem extends StatelessWidget {
  const CategoryGridItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.icon,
    this.colorHex,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final String? colorHex;

  static Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.textSecondary;
    final h = hex.startsWith('#') ? hex : '#$hex';
    if (h.length != 7) return AppColors.textSecondary;
    return Color(int.parse(h.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final color = selected ? _parseHex(colorHex) : AppColors.textSecondary;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: selected ? 0.35 : 0.15),
                child: Icon(
                  icon ?? Icons.category,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
