import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spend_sync/src/common_widgets/transaction_tile.dart';

void main() {
  testWidgets('TransactionTile hiển thị đúng title và số tiền', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TransactionTile(
            title: 'Food',
            subtitle: 'Tiền mặt',
            amount: '150,000',
            isExpense: true,
            colorHex: '#FFD700',
          ),
        ),
      ),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Tiền mặt'), findsOneWidget);
    expect(find.text('-150,000'), findsOneWidget);
  });

  testWidgets('TransactionTile income hiển thị số dương không dấu trừ', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TransactionTile(
            title: 'Lương',
            subtitle: 'Ngân hàng',
            amount: '10,000,000',
            isExpense: false,
          ),
        ),
      ),
    );

    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('10,000,000'), findsOneWidget);
  });
}
