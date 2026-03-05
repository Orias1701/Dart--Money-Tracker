import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ChartsPlaceholderScreen extends StatelessWidget {
  const ChartsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Charts'),
        backgroundColor: AppColors.background,
      ),
      body: const Center(
        child: Text(
          'Charts - Phase 5',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
