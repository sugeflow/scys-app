import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scys/native_navigation_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps native iOS tab selections to the five website paths', () async {
    final paths = <String>[];
    final bridge = NativeNavigationBridge(paths.add);

    for (var index = 1; index < 5; index++) {
      await bridge.handleMethodCall(MethodCall('selectTab', index));
    }

    expect(paths, [
      '/mobile/money-ideas',
      '/mobile/home/activity',
      '/mobile/home/meeting',
      '/mobile/home/mine',
    ]);
    bridge.dispose();
  });

  test(
    'does not reload when the selected native tab is tapped again',
    () async {
      final paths = <String>[];
      final bridge = NativeNavigationBridge(paths.add);

      await bridge.handleMethodCall(const MethodCall('selectTab', 0));
      await bridge.handleMethodCall(const MethodCall('selectTab', 1));
      await bridge.handleMethodCall(const MethodCall('selectTab', 1));

      expect(paths, ['/mobile/money-ideas']);
      bridge.dispose();
    },
  );

  test('syncs a website-owned page back to the native selection', () async {
    const channel = MethodChannel('test.scys/navigation');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final paths = <String>[];
    final bridge = NativeNavigationBridge(paths.add, channel: channel);

    await bridge.syncLocation(Uri.parse('https://scys.com/mobile/home/mine'));
    await bridge.handleMethodCall(const MethodCall('selectTab', 4));
    await bridge.handleMethodCall(const MethodCall('selectTab', 0));

    expect(calls.map((call) => (call.method, call.arguments)), const [
      ('setTabBarVisible', true),
      ('setSelectedTab', 4),
    ]);
    expect(paths, ['/mobile/home/index']);
    bridge.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('shows the native tab bar only on root tab pages', () async {
    const channel = MethodChannel('test.scys/navigation.visibility');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final bridge = NativeNavigationBridge((_) {}, channel: channel);

    await bridge.syncLocation(Uri.parse('https://scys.com/mobile/home/index'));
    await bridge.syncLocation(
      Uri.parse('https://scys.com/mobile/money-ideas/project/123'),
    );
    await bridge.syncLocation(
      Uri.parse('https://scys.com/mobile/money-ideas/project/456'),
    );
    await bridge.syncLocation(Uri.parse('https://scys.com/mobile/money-ideas'));

    expect(calls.map((call) => (call.method, call.arguments)), const [
      ('setTabBarVisible', true),
      ('setTabBarVisible', false),
      ('setTabBarVisible', true),
      ('setSelectedTab', 1),
    ]);
    bridge.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'keeps the project tab bar on super-tag and opportunity roots',
    () async {
      const channel = MethodChannel('test.scys/navigation.project-roots');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      final bridge = NativeNavigationBridge((_) {}, channel: channel);

      await bridge.syncLocation(Uri.parse('https://scys.com/mobile/super-tag'));
      await bridge.syncLocation(
        Uri.parse('https://scys.com/mobile/super-tag/detail/123'),
      );
      await bridge.syncLocation(
        Uri.parse('https://scys.com/mobile/home/index/opportunity'),
      );

      expect(calls.map((call) => (call.method, call.arguments)), const [
        ('setTabBarVisible', true),
        ('setSelectedTab', 1),
        ('setTabBarVisible', false),
        ('setTabBarVisible', true),
      ]);
      bridge.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  test('ignores unsupported native tab messages', () async {
    final paths = <String>[];
    final bridge = NativeNavigationBridge(paths.add);

    await bridge.handleMethodCall(const MethodCall('other', 2));
    await bridge.handleMethodCall(const MethodCall('selectTab', 99));

    expect(paths, isEmpty);
    bridge.dispose();
  });
}
