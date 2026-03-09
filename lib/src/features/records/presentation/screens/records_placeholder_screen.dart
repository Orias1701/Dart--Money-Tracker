import 'package:flutter/material.dart';

import '../../../../common_widgets/transaction_tile.dart';
import '../../../../core/constants/app_colors.dart';

/// Placeholder màn Records (Shell cung cấp BottomNav).
class RecordsPlaceholderScreen extends StatelessWidget {
  const RecordsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Giao dịch'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Giai đoạn 1: Nền tảng',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tháng 3/2026',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Chi: 0', style: TextStyle(color: AppColors.textPrimary)),
                        Text('Thu: 0', style: TextStyle(color: AppColors.textPrimary)),
                        Text('Số dư: 0', style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TransactionTile(
              title: 'Ăn uống',
              subtitle: 'Tiền mặt',
              amount: '150,000',
              isExpense: true,
              colorHex: '#FFD700',
            ),
            TransactionTile(
              title: 'Lương',
              subtitle: 'Tài khoản NH',
              amount: '10,000,000',
              isExpense: false,
              colorHex: '#22C55E',
            ),
          ],
        ),
      ),
    );
  }
}
