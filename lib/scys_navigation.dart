import 'dart:convert';

import 'package:flutter/material.dart';

@immutable
class ScysTab {
  const ScysTab({required this.label, required this.path});

  final String label;
  final String path;
}

const scysTabs = <ScysTab>[
  ScysTab(label: '看帖', path: '/mobile/home/index'),
  ScysTab(label: '项目', path: '/mobile/money-ideas'),
  ScysTab(label: '航海', path: '/mobile/home/activity'),
  ScysTab(label: '聚会', path: '/mobile/home/meeting'),
  ScysTab(label: '我的', path: '/mobile/home/mine'),
];

int? scysTabIndexForUri(Uri uri) {
  if (uri.host.toLowerCase() != 'scys.com') {
    return null;
  }

  final path = uri.path;
  final rootTabIndex = scysRootTabIndexForUri(uri);
  if (rootTabIndex != null) return rootTabIndex;
  if (path.startsWith('/mobile/money-ideas')) return 1;
  if (path.startsWith('/mobile/home/activity') ||
      path.startsWith('/mobile/activity')) {
    return 2;
  }
  if (path.startsWith('/mobile/home/meeting') ||
      path.startsWith('/mobile/meeting')) {
    return 3;
  }
  if (path.startsWith('/mobile/home/mine') ||
      path.startsWith('/mobile/personal')) {
    return 4;
  }
  return null;
}

int? scysRootTabIndexForUri(Uri uri) {
  if (uri.host.toLowerCase() != 'scys.com') {
    return null;
  }

  return switch (uri.path) {
    '/mobile/home/index' => 0,
    '/mobile/money-ideas' ||
    '/mobile/super-tag' ||
    '/mobile/home/index/opportunity' => 1,
    '/mobile/home/activity' => 2,
    '/mobile/home/meeting' => 3,
    '/mobile/home/mine' => 4,
    _ => null,
  };
}

String scysTabNavigationScript(String path) {
  final encodedPath = jsonEncode(path);
  return '''
(() => {
  const path = $encodedPath;
  const anchor = Array.from(document.querySelectorAll('.tabs a[href]'))
    .find((candidate) =>
      new URL(candidate.href, location.href).pathname === path
    );
  if (!anchor) return false;
  anchor.click();
  return true;
})()
''';
}

const scysHideWebBottomNavScript = r'''
(() => {
  const paths = [
    '/mobile/home/index',
    '/mobile/money-ideas',
    '/mobile/home/activity',
    '/mobile/home/meeting',
    '/mobile/home/mine'
  ];

  const hideOriginalBottomNav = () => {
    document.querySelectorAll('.tabs').forEach((element) => {
      const hrefs = Array.from(element.querySelectorAll('a[href]'))
        .map((anchor) => new URL(anchor.href, location.href).pathname);
      if (paths.every((path) => hrefs.includes(path))) {
        element.style.setProperty('display', 'none', 'important');
        element.setAttribute('data-scys-native-nav-hidden', 'true');
      }
    });
  };

  hideOriginalBottomNav();
  if (window.__scysBottomNavObserver) {
    window.__scysBottomNavObserver.disconnect();
  }
  window.__scysBottomNavObserver = new MutationObserver(
    hideOriginalBottomNav
  );
  window.__scysBottomNavObserver.observe(document.documentElement, {
    childList: true,
    subtree: true
  });
})();
''';
