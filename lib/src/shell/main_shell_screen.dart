import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common_widgets/custom_bottom_nav_bar.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/debug_tap_logger.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) {
          DebugTapLogger.log('MainShell: BottomNav onTap index=$i');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            DebugTapLogger.log('MainShell: PostFrame goBranch($i)');
            if (context.mounted) navigationShell.goBranch(i);
          });
        },
        onFabTap: () {
          DebugTapLogger.log('MainShell: FAB onPressed -> goBranch(2) Add tab');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) navigationShell.goBranch(2);
          });
        },
      ),
    );
  }
}
