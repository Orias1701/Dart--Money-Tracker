import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common_widgets/custom_bottom_nav_bar.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/debug_tap_logger.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/groups/presentation/providers/active_group_provider.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/shared/presentation/widgets/filter_bottom_sheet.dart';
import '../features/transactions/presentation/providers/add_screen_bar_provider.dart';
import 'shell_app_bar_provider.dart';

const double _kNotifButtonRadius = 24;
const double _kNotifButtonDiameter = _kNotifButtonRadius * 2;

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  bool _notificationPanelOpen = false;
  Offset _notificationButtonOffset = Offset.zero;
  bool _notificationPositionInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeGroupProvider.notifier).ensurePersonalGroup();
    });
  }

  void _initNotificationButtonPosition(Size size) {
    if (_notificationPositionInitialized || size.width < _kNotifButtonDiameter) return;
    _notificationPositionInitialized = true;
    final maxX = size.width - _kNotifButtonRadius - _kNotifButtonDiameter;
    final maxY = size.height - _kNotifButtonRadius - _kNotifButtonDiameter;
    setState(() {
      _notificationButtonOffset = Offset(
        maxX,
        100.0.clamp(_kNotifButtonRadius, maxY),
      );
    });
  }

  void _onNotificationPanUpdate(Size size, DragUpdateDetails details) {
    setState(() {
      _notificationButtonOffset = Offset(
        (_notificationButtonOffset.dx + details.delta.dx)
            .clamp(_kNotifButtonRadius, size.width - _kNotifButtonRadius - _kNotifButtonDiameter),
        (_notificationButtonOffset.dy + details.delta.dy)
            .clamp(_kNotifButtonRadius, size.height - _kNotifButtonRadius - _kNotifButtonDiameter),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final activeGroup = ref.watch(activeGroupProvider);
    if (user != null && activeGroup == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeGroupProvider.notifier).ensurePersonalGroup();
      });
    }
    final invitationsAsync = ref.watch(myInvitationsProvider);
    final invitationCount = invitationsAsync.valueOrNull?.length ?? 0;
    final size = MediaQuery.sizeOf(context);
    if (!_notificationPositionInitialized && size.width > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initNotificationButtonPosition(size));
    }

    final titles = ref.watch(shellAppBarTitleProvider);
    final currentIndex = widget.navigationShell.currentIndex;
    final titleWidget = titles[currentIndex];
    final isAddScreen = currentIndex == 2;
    final addBar = isAddScreen ? ref.watch(addScreenBarProvider) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: isAddScreen && addBar != null
                      ? _buildAddBar(addBar)
                      : _buildNormalBar(titleWidget, invitationCount, currentIndex),
                ),
              ),
              Expanded(child: widget.navigationShell),
            ],
          ),
          _buildFloatingNotificationButton(size, invitationCount),
          if (_notificationPanelOpen) _buildNotificationOverlay(size),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (i) {
          DebugTapLogger.log('MainShell: BottomNav onTap index=$i');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            DebugTapLogger.log('MainShell: PostFrame goBranch($i)');
            if (context.mounted) widget.navigationShell.goBranch(i);
          });
        },
        onFabTap: () {
          DebugTapLogger.log('MainShell: FAB onPressed -> go /add');
          context.go('/add');
        },
      ),
    );
  }

  Widget _buildNormalBar(Widget? titleWidget, int invitationCount, int currentIndex) {
    final filterApplicable = currentIndex == 0 || currentIndex == 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: titleWidget ?? const SizedBox.shrink(),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: AppColors.textPrimary.withValues(alpha: filterApplicable ? 1.0 : 0.25),
          ),
          iconSize: 28,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.all(12),
          ),
          onPressed: filterApplicable ? () => FilterBottomSheet.show(context) : null,
          tooltip: 'Bộ lọc',
        ),
        IconButton(
          icon: const Icon(Icons.people_outline, color: AppColors.textPrimary),
          iconSize: 28,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.all(12),
          ),
          onPressed: () => context.push('/friend'),
          tooltip: 'Bạn bè',
        ),
      ],
    );
  }

  Widget _buildAddBar(AddScreenBarState addBar) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: addBar.onCancel,
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              tooltip: 'Hủy',
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: AppColors.textPrimary.withValues(alpha: 0.25),
              ),
              iconSize: 28,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: null,
              tooltip: 'Bộ lọc',
            ),
            IconButton(
              icon: const Icon(Icons.people_outline, color: AppColors.textPrimary),
              iconSize: 28,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: () => context.push('/friend'),
              tooltip: 'Bạn bè',
            ),
          ],
        ),
        Positioned.fill(
          child: Center(
            child: addBar.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: addBar.onSave,
                    child: const Text(
                      'Lưu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingNotificationButton(Size size, int invitationCount) {
    final isActive = _notificationPanelOpen;
    return Positioned(
      left: _notificationButtonOffset.dx,
      top: _notificationButtonOffset.dy,
      child: GestureDetector(
        onTap: () => setState(() => _notificationPanelOpen = !_notificationPanelOpen),
        onPanUpdate: (details) => _onNotificationPanUpdate(size, details),
        child: Material(
          color: isActive ? AppColors.primary : AppColors.surface,
          elevation: 4,
          shadowColor: Colors.black45,
          shape: const CircleBorder(),
          child: SizedBox(
            width: _kNotifButtonDiameter,
            height: _kNotifButtonDiameter,
            child: Center(
              child: invitationCount > 0
                  ? Badge(
                      label: Text(
                        '$invitationCount',
                        style: TextStyle(
                          color: isActive ? AppColors.primary : AppColors.surface,
                          fontSize: 12,
                        ),
                      ),
                      child: Icon(
                        Icons.notifications_none,
                        color: isActive ? Colors.white : AppColors.primary,
                        size: 26,
                      ),
                    )
                  : Icon(
                      Icons.notifications_none,
                      color: isActive ? Colors.white : AppColors.primary,
                      size: 26,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationOverlay(Size size) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _notificationPanelOpen = false),
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black54,
            width: size.width,
            height: size.height,
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.9,
                  maxHeight: size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Thông báo',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textPrimary),
                            onPressed: () => setState(() => _notificationPanelOpen = false),
                            tooltip: 'Đóng',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.6,
                      child: NotificationsPanelContent(
                        onClose: () => setState(() => _notificationPanelOpen = false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
