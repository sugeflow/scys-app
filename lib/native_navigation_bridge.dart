import 'package:flutter/services.dart';

import 'scys_navigation.dart';

class NativeNavigationBridge {
  NativeNavigationBridge(this.onNavigate, {MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName) {
    _channel.setMethodCallHandler(handleMethodCall);
  }

  static const _channelName = 'me.suge.scys/navigation';

  final void Function(String path) onNavigate;
  final MethodChannel _channel;
  int _currentIndex = 0;
  bool? _isTabBarVisible;

  Future<void> handleMethodCall(MethodCall call) async {
    if (call.method != 'selectTab' || call.arguments is! int) {
      return;
    }

    final index = call.arguments as int;
    if (index < 0 || index >= scysTabs.length || index == _currentIndex) {
      return;
    }
    _currentIndex = index;
    onNavigate(scysTabs[index].path);
  }

  Future<void> syncLocation(Uri uri) async {
    final index = scysTabIndexForUri(uri);
    final isTabBarVisible = scysRootTabIndexForUri(uri) != null;
    if (isTabBarVisible != _isTabBarVisible) {
      _isTabBarVisible = isTabBarVisible;
      await _channel.invokeMethod<void>('setTabBarVisible', isTabBarVisible);
    }

    if (!isTabBarVisible || index == null || index == _currentIndex) {
      return;
    }
    _currentIndex = index;
    await _channel.invokeMethod<void>('setSelectedTab', index);
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
