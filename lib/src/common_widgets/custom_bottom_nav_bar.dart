import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/debug_tap_logger.dart';

/// Bottom nav: nền hình chữ nhật, nút tròn (bằng nhau), nút + lớn hơn 20%.
/// Selected: vàng chữ đen, hiệu ứng nổi (vòng tròn màu nền app phía sau). Unselected: nền trùng navbar, chữ trắng. Hover: đổi nhẹ màu nền.
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  static const double _buttonSize = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kBottomNavigationBarHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.list_alt,
              label: 'Records',
              selected: currentIndex == 0,
              onTap: () {
                DebugTapLogger.log('BottomNav: _NavItem tap "Records"');
                onTap(0);
              },
              size: _buttonSize,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.pie_chart_outline,
              label: 'Charts',
              selected: currentIndex == 1,
              onTap: () {
                DebugTapLogger.log('BottomNav: _NavItem tap "Charts"');
                onTap(1);
              },
              size: _buttonSize,
            ),
          ),
          _FabItem(
            size: _buttonSize,
            selected: currentIndex == 2,
            onTap: () {
              DebugTapLogger.log('BottomNav: FAB tap');
              onFabTap();
            },
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.assessment_outlined,
              label: 'Reports',
              selected: currentIndex == 3,
              onTap: () {
                DebugTapLogger.log('BottomNav: _NavItem tap "Reports"');
                onTap(3);
              },
              size: _buttonSize,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline,
              label: 'Me',
              selected: currentIndex == 4,
              onTap: () {
                DebugTapLogger.log('BottomNav: _NavItem tap "Me"');
                onTap(4);
              },
              size: _buttonSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected;
    final double baseSize = widget.size;
    final double borderWidth = isSelected ? baseSize * 0.2 : 0.0;
    final double lift = isSelected ? baseSize * 0.25 : 0.0;
    final bgColor = isSelected
        ? AppColors.primary
        : (_hover ? AppColors.surface.withValues(alpha: 0.85) : AppColors.surface);
    final textColor = isSelected ? Colors.black : AppColors.textPrimary;
    final iconColor = isSelected ? Colors.black : AppColors.textPrimary;

    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hover = v),
          hoverColor: Colors.transparent,
          splashColor: AppColors.primary.withValues(alpha: 0.3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(bottom: lift),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: baseSize,
                height: baseSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: borderWidth,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 22, color: iconColor),
                    const SizedBox(height: 2),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FabItem extends StatefulWidget {
  const _FabItem({required this.size, required this.onTap, this.selected = false});

  final double size;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_FabItem> createState() => _FabItemState();
}

class _FabItemState extends State<_FabItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selected;
    final baseSize = widget.size;
    final borderWidth = baseSize * 0.2;
    final lift = baseSize * 0.25;
    final bgColor = isSelected ? AppColors.primary : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hover = v),
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: lift),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: baseSize * 1.2,
            height: baseSize * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover ? bgColor.withValues(alpha: 0.95) : bgColor,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 28, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
