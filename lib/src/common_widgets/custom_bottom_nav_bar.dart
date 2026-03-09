import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/debug_tap_logger.dart';

/// Bottom nav: nền hình chữ nhật, viền trên uốn cong ôm nút + giữa (kiểu ảnh mẫu).
/// Có shadow nhẹ phía trên. Nút + tròn primary, không label.
/// Đáy nút + = đáy label các nút khác; đỉnh nút + = biên thẳng navbar để thấy phần cong.
/// Các nút khác chia đều; khi chọn chỉ đổi màu chữ/icon (primary), không đổi nền.
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

  static const double _barHeight = 72;
  static const double _navItemContentHeight = 42; // icon 24 + gap 4 + text ~14
  static double get _spaceFromBarBottomToLabelBottom =>
      (_barHeight - _navItemContentHeight) / 2;
  static double get _fabCircleSize =>
      _barHeight - _spaceFromBarBottomToLabelBottom;
  /// Chiều cao phần nhô lên: từ đỉnh vòng cung xuống mặt phẳng thanh (bumpHeight).
  static const double _bumpHeight = 18.0;
  /// Tổng chiều cao navbar = thanh phẳng đúng 72px + phần nhô lên phía trên.
  static double get _totalHeight => _barHeight + _bumpHeight;
  /// Độ rộng vòng cung, vừa với nút + (bumpRadius).
  static double get _bumpRadius => _fabCircleSize / 2 + 6;
  /// Đoạn thẳng thêm trước/sau chân đường cong (độ "lả lướt").
  static const double _flatExtent = 28.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBarShape(context),
          _buildNavRow(context),
          _buildCenterFab(context),
        ],
      ),
    );
  }

  Widget _buildBarShape(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _totalHeight,
      child: CustomPaint(
        size: Size(MediaQuery.sizeOf(context).width, _totalHeight),
        painter: _NavBarShapePainter(
          color: AppColors.surface,
          bumpHeight: _bumpHeight,
          bumpRadius: _bumpRadius,
          flatExtent: _flatExtent,
        ),
      ),
    );
  }

  Widget _buildNavRow(BuildContext context) {
    final centerSlotWidth = _fabCircleSize;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _barHeight,
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.list_alt,
              label: 'Giao dịch',
              selected: currentIndex == 0,
              onTap: () {
                DebugTapLogger.log('BottomNav: _NavItem tap "Records"');
                onTap(0);
              },
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.pie_chart_outline,
              label: 'Biểu đồ',
              selected: currentIndex == 1,
              onTap: () {
                DebugTapLogger.log('BottomNav: _NavItem tap "Charts"');
                onTap(1);
              },
            ),
          ),
          SizedBox(width: centerSlotWidth),
          Expanded(
            child: _NavItem(
              icon: Icons.assessment_outlined,
              label: 'Báo cáo',
              selected: currentIndex == 3,
              onTap: () {
                DebugTapLogger.log('BottomNav: _NavItem tap "Reports"');
                onTap(3);
              },
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_outline,
              label: 'Tôi',
              selected: currentIndex == 4,
              onTap: () {
                DebugTapLogger.log('BottomNav: _NavItem tap "Me"');
                onTap(4);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterFab(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: _barHeight,
      child: Align(
        alignment: Alignment.topCenter,
        child: _FabItem(
          size: _fabCircleSize,
          selected: currentIndex == 2,
          onTap: () {
            DebugTapLogger.log('BottomNav: FAB tap');
            onFabTap();
          },
        ),
      ),
    );
  }
}

/// Vẽ nền navbar + viền cong theo kiểu ConvexBottomBar: Cubic Bezier với bumpHeight, bumpRadius.
class _NavBarShapePainter extends CustomPainter {
  _NavBarShapePainter({
    required this.color,
    required this.bumpHeight,
    required this.bumpRadius,
    required this.flatExtent,
  });

  final Color color;
  final double bumpHeight;
  final double bumpRadius;
  final double flatExtent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = w / 2;

    final path = Path();
    // Bắt đầu từ góc trên trái của thanh ngang (mặt phẳng chung)
    path.moveTo(0, bumpHeight);
    path.lineTo(center - bumpRadius - flatExtent, bumpHeight);

    // Cubic Bezier: nửa trái vòng lồi (chân mượt -> kéo lên đỉnh)
    path.cubicTo(
      center - bumpRadius,
      bumpHeight,
      center - bumpRadius + 5,
      0,
      center,
      0,
    );

    // Cubic Bezier: nửa phải vòng lồi (từ đỉnh xuống chân mượt)
    path.cubicTo(
      center + bumpRadius - 5,
      0,
      center + bumpRadius,
      bumpHeight,
      center + bumpRadius + flatExtent,
      bumpHeight,
    );

    path.lineTo(w, bumpHeight);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawShadow(path, Colors.black38, 8, false);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NavBarShapePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.bumpHeight != bumpHeight ||
        oldDelegate.bumpRadius != bumpRadius ||
        oldDelegate.flatExtent != flatExtent;
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.selected ? AppColors.primary : AppColors.textSecondary;
    final textColor = widget.selected ? AppColors.primary : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: SizedBox.expand(
          child: Center(
            child: Transform.scale(
              scale: _pressed ? 1.1 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 24, color: iconColor),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
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
    );
  }
}

class _FabItem extends StatelessWidget {
  const _FabItem({
    required this.size,
    required this.onTap,
    this.selected = false,
  });

  final double size;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.add, size: 36, color: Colors.black),
        ),
      ),
    );
  }
}
