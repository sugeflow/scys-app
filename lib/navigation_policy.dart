enum NavigationTarget { inApp, external, blocked }

class NavigationPolicy {
  const NavigationPolicy();

  static const _inAppDomains = <String>{
    'scys.com',
    'shengcaiyoushu.com',
    'feishu.cn',
    'zsxq.com',
  };

  static const _inAppExactHosts = <String>{'open.weixin.qq.com'};

  static const _externalSchemes = <String>{'mailto', 'tel', 'weixin'};

  NavigationTarget decide(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (_externalSchemes.contains(scheme)) {
      return NavigationTarget.external;
    }

    if (scheme != 'https' || uri.host.isEmpty) {
      return NavigationTarget.blocked;
    }

    final host = uri.host.toLowerCase();
    if (_inAppExactHosts.contains(host) ||
        _inAppDomains.any(
          (domain) => host == domain || host.endsWith('.$domain'),
        )) {
      return NavigationTarget.inApp;
    }

    return NavigationTarget.external;
  }
}
