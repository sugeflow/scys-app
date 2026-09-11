import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'ios_web_navigation.dart';
import 'load_error_view.dart';
import 'native_navigation_bridge.dart';
import 'navigation_policy.dart';
import 'page_load_state.dart';
import 'scys_navigation.dart';
import 'scys_shell.dart';
import 'scys_web_surface.dart';

const _homeUrl = 'https://scys.com/mobile/home/index';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScysApp());
}

class ScysApp extends StatelessWidget {
  const ScysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '生财有术',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const ScysWebViewPage(),
    );
  }
}

class ScysWebViewPage extends StatefulWidget {
  const ScysWebViewPage({super.key});

  @override
  State<ScysWebViewPage> createState() => _ScysWebViewPageState();
}

class _ScysWebViewPageState extends State<ScysWebViewPage> {
  static const _navigationPolicy = NavigationPolicy();

  final PageLoadState _loadState = PageLoadState();
  late final WebViewController _controller;
  NativeNavigationBridge? _nativeNavigationBridge;
  IosBackForwardNavigationGestures? _iosBackForwardGestures;

  @override
  void initState() {
    super.initState();
    _loadState.addListener(_refresh);
    if (Platform.isIOS) {
      _nativeNavigationBridge = NativeNavigationBridge(_openTab);
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _handlePageStarted,
          onUrlChange: _handleUrlChange,
          onProgress: _loadState.updateProgress,
          onPageFinished: _handlePageFinished,
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _loadState.showError('当前无法连接到生财有术，请检查网络后重试');
            }
          },
          onNavigationRequest: _handleNavigation,
        ),
      );
    final platformController = _controller.platform;
    if (platformController is WebKitWebViewController) {
      _iosBackForwardGestures = IosBackForwardNavigationGestures(
        isIOS: Platform.isIOS,
        setEnabled: platformController.setAllowsBackForwardNavigationGestures,
      );
      unawaited(_iosBackForwardGestures!.syncLocation(Uri.parse(_homeUrl)));
    }
    unawaited(_controller.loadRequest(Uri.parse(_homeUrl)));
  }

  Future<void> _handlePageFinished(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.toLowerCase() != 'scys.com') {
      return;
    }

    try {
      await _controller.runJavaScript(scysHideWebBottomNavScript);
    } catch (_) {
      // Navigation remains usable if the page temporarily rejects injection.
    }
  }

  void _handlePageStarted(String url) {
    _loadState.startLoading();
    _syncNativeLocation(url);
  }

  void _handleUrlChange(UrlChange change) {
    _syncNativeLocation(change.url);
  }

  void _syncNativeLocation(String? url) {
    if (!Platform.isIOS || url == null) return;
    final uri = Uri.tryParse(url);
    final bridge = _nativeNavigationBridge;
    if (uri != null && bridge != null) {
      unawaited(bridge.syncLocation(uri));
      final gestures = _iosBackForwardGestures;
      if (gestures != null) {
        unawaited(gestures.syncLocation(uri));
      }
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<NavigationDecision> _handleNavigation(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) {
      return NavigationDecision.prevent;
    }

    switch (_navigationPolicy.decide(uri)) {
      case NavigationTarget.inApp:
        return NavigationDecision.navigate;
      case NavigationTarget.external:
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('无法打开这个链接')));
        }
        return NavigationDecision.prevent;
      case NavigationTarget.blocked:
        return NavigationDecision.prevent;
    }
  }

  Future<void> _retry() async {
    _loadState.startLoading();
    await _controller.reload();
  }

  void _openTab(String path) {
    unawaited(_openTabWithoutReload(path));
  }

  Future<void> _openTabWithoutReload(String path) async {
    try {
      final usedWebsiteRouter = await _controller.runJavaScriptReturningResult(
        scysTabNavigationScript(path),
      );
      if (usedWebsiteRouter == true) return;
    } catch (_) {
      // Fall back to a full navigation if the page is not ready for scripting.
    }
    await _controller.loadRequest(Uri.parse('https://scys.com$path'));
  }

  Future<void> _handleSystemBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) {
      await SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _loadState
      ..removeListener(_refresh)
      ..dispose();
    _nativeNavigationBridge?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleSystemBack();
        }
      },
      child: ScysShell(
        onNavigate: _openTab,
        showNavigationBar: !Platform.isIOS,
        webContent: buildScysWebSurface(
          edgeToEdge: Platform.isIOS,
          child: Stack(
            children: [
              Positioned.fill(child: WebViewWidget(controller: _controller)),
              if (_loadState.errorMessage case final message?)
                Positioned.fill(
                  child: LoadErrorView(message: message, onRetry: _retry),
                ),
              if (_loadState.isLoading)
                Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    value: _loadState.progress == 0
                        ? null
                        : _loadState.progress / 100,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
