import 'package:flutter_test/flutter_test.dart';
import 'package:scys/ios_web_navigation.dart';

void main() {
  test('disables edge swipe on root tabs and enables it elsewhere', () async {
    final values = <bool>[];
    final gestures = IosBackForwardNavigationGestures(
      isIOS: true,
      setEnabled: (enabled) async => values.add(enabled),
    );

    await gestures.syncLocation(
      Uri.parse('https://scys.com/mobile/home/index'),
    );
    await gestures.syncLocation(
      Uri.parse('https://scys.com/mobile/home/index?filter=featured'),
    );
    await gestures.syncLocation(
      Uri.parse('https://scys.com/mobile/money-ideas/project/123'),
    );
    await gestures.syncLocation(
      Uri.parse('https://scys.com/mobile/money-ideas/project/456'),
    );
    await gestures.syncLocation(
      Uri.parse('https://scys.com/mobile/money-ideas'),
    );
    await gestures.syncLocation(Uri.parse('https://scys.com/mobile/super-tag'));
    await gestures.syncLocation(
      Uri.parse('https://scys.com/mobile/super-tag/detail/123'),
    );
    await gestures.syncLocation(
      Uri.parse('https://scys.com/mobile/home/index/opportunity'),
    );

    expect(values, [false, true, false, true, false]);
  });

  test('does not configure WebKit navigation gestures outside iOS', () async {
    final values = <bool>[];
    final gestures = IosBackForwardNavigationGestures(
      isIOS: false,
      setEnabled: (enabled) async => values.add(enabled),
    );

    await gestures.syncLocation(
      Uri.parse('https://scys.com/mobile/home/index'),
    );

    expect(values, isEmpty);
  });
}
