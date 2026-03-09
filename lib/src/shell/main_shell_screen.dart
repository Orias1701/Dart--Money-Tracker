import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common_widgets/custom_bottom_nav_bar.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/debug_tap_logger.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/groups/presentation/providers/active_group_provider.dart';
import '../features/shared/presentation/widgets/filter_bottom_sheet.dart';
import 'shell_app_bar_provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeGroupProvider.notifier).ensurePersonalGroup();
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

    final titles = ref.watch(shellAppBarTitleProvider);
    final currentIndex = widget.navigationShell.currentIndex;
    final titleWidget = titles[currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
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
                    icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () => FilterBottomSheet.show(context),
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
                    tooltip: 'Friend',
                  ),
                  IconButton(
                    icon: invitationCount > 0
                        ? Badge(
                            label: Text('$invitationCount'),
                            child: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                          )
                        : const Icon(Icons.notifications_none, color: AppColors.textPrimary),
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () => context.push('/notifications'),
                    tooltip: 'Thông báo',
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: widget.navigationShell),
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
}
