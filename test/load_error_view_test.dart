import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scys/load_error_view.dart';

void main() {
  testWidgets('shows a retry action when the page cannot load', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoadErrorView(
          message: '当前无法连接到生财有术',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('当前无法连接到生财有术'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);

    await tester.tap(find.text('重新加载'));
    expect(retried, isTrue);
  });
}
