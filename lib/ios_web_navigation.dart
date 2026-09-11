import 'scys_navigation.dart';

typedef BackForwardNavigationGestureSetter = Future<void> Function(
  bool enabled,
);

class IosBackForwardNavigationGestures {
  IosBackForwardNavigationGestures({
    required this.isIOS,
    required this.setEnabled,
  });

  final bool isIOS;
  final BackForwardNavigationGestureSetter setEnabled;
  bool? _isEnabled;

  Future<void> syncLocation(Uri uri) async {
    if (!isIOS) return;
    final isRootTab = scysRootTabIndexForUri(uri) != null;
    final shouldEnable = !isRootTab;
    if (shouldEnable == _isEnabled) return;
    _isEnabled = shouldEnable;
    await setEnabled(shouldEnable);
  }
}
