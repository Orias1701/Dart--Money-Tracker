import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/debug_tap_logger.dart';

/// Tab bar bo góc: Expense | Income | Transfer.
class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const List<String> _labels = ['Expense', 'Income', 'Transfer'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final selected = selectedIndex == i;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    DebugTapLogger.log('CustomTabBar: tap index=$i "${_labels[i]}"');
                    onChanged(i);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _labels[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.black : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
