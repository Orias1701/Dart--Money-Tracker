import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ChartsPlaceholderScreen extends StatelessWidget {
  const ChartsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Biểu đồ'),
        backgroundColor: AppColors.background,
      ),
      body: const Center(
        child: Text(
          'Biểu đồ',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
