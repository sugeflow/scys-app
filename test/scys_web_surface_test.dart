import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scys/scys_web_surface.dart';

void main() {
  testWidgets('keeps iOS web content below the status bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: buildScysWebSurface(edgeToEdge: true, child: const Text('网页')),
      ),
    );

    final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
    expect(safeArea.top, isTrue);
    expect(safeArea.bottom, isFalse);
  });
}
