import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scys/scys_shell.dart';

void main() {
  testWidgets('keeps the website five-tab order and routes', (tester) async {
    final navigatedPaths = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ScysShell(
          webContent: const Center(child: Text('官网内容')),
          onNavigate: navigatedPaths.add,
        ),
      ),
    );

    expect(find.text('官网内容'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .items
          .map((item) => item.label),
      ['看帖', '项目', '航海', '聚会', '我的'],
    );

    for (final entry in const [
      ('项目', '/mobile/money-ideas'),
      ('航海', '/mobile/home/activity'),
      ('聚会', '/mobile/home/meeting'),
      ('我的', '/mobile/home/mine'),
      ('看帖', '/mobile/home/index'),
    ]) {
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();
      expect(navigatedPaths.last, entry.$2);
      expect(find.text('官网内容'), findsOneWidget);
    }
  });

  testWidgets('lets iOS use its native tab bar instead', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScysShell(
          webContent: const Text('官网内容'),
          onNavigate: (_) {},
          showNavigationBar: false,
        ),
      ),
    );

    expect(find.text('官网内容'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
