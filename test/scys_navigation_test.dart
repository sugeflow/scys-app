import 'package:flutter_test/flutter_test.dart';
import 'package:scys/scys_navigation.dart';

void main() {
  test('defines the website navigation contract exactly', () {
    expect(scysTabs.map((tab) => (tab.label, tab.path)), const [
      ('看帖', '/mobile/home/index'),
      ('项目', '/mobile/money-ideas'),
      ('航海', '/mobile/home/activity'),
      ('聚会', '/mobile/home/meeting'),
      ('我的', '/mobile/home/mine'),
    ]);
  });

  test('hide script targets the original five-link bottom navigation', () {
    expect(scysHideWebBottomNavScript, contains("'/mobile/home/index'"));
    expect(scysHideWebBottomNavScript, contains("'/mobile/money-ideas'"));
    expect(scysHideWebBottomNavScript, contains("'/mobile/home/activity'"));
    expect(scysHideWebBottomNavScript, contains("'/mobile/home/meeting'"));
    expect(scysHideWebBottomNavScript, contains("'/mobile/home/mine'"));
    expect(scysHideWebBottomNavScript, contains('MutationObserver'));
    expect(scysHideWebBottomNavScript, contains("display', 'none'"));
  });

  test('native tabs use the website SPA links instead of reloading', () {
    final script = scysTabNavigationScript('/mobile/home/mine');

    expect(script, contains("querySelectorAll('.tabs a[href]')"));
    expect(script, contains('const path = "/mobile/home/mine";'));
    expect(script, contains('anchor.click()'));
    expect(script, isNot(contains('location.assign')));
    expect(script, isNot(contains('location.href =')));
  });

  test('adds one TokenRank menu row immediately after AI passport', () {
    final script = scysTokenRankMenuScript(
      'data:image/png;base64,icon-data',
    );

    expect(script, contains('AI 护照'));
    expect(script, contains('TokenRank'));
    expect(script, contains('/tokenrank/'));
    expect(script, contains('data-scys-tokenrank'));
    expect(script, contains('insertAdjacentElement'));
    expect(script, contains('MutationObserver'));
    expect(script, contains('data:image/png;base64,icon-data'));
  });

  test('measures the rendered passport icon before cloning its menu row', () {
    final script = scysTokenRankMenuScript('data:image/png;base64,icon-data');

    expect(
      script,
      contains("passportItem.querySelector('.menu-icon svg, .menu-icon img')"),
    );
    expect(
      script,
      isNot(contains("iconContainer?.querySelector('svg, img')")),
    );
  });

  test('keeps the cloned menu icon wrapper when swapping the graphic', () {
    final script = scysTokenRankMenuScript('data:image/png;base64,icon-data');

    expect(
      script,
      contains("item.querySelector('.menu-icon svg, .menu-icon img')"),
    );
    expect(script, contains('clonedGraphic.replaceWith(icon)'));
    expect(script, isNot(contains('iconContainer.replaceChildren(icon)')));
  });

  test('recognizes which native tab owns a website location', () {
    expect(
      scysTabIndexForUri(Uri.parse('https://scys.com/mobile/home/index')),
      0,
    );
    expect(
      scysTabIndexForUri(
        Uri.parse('https://scys.com/mobile/money-ideas/project/123'),
      ),
      1,
    );
    expect(
      scysTabIndexForUri(Uri.parse('https://scys.com/mobile/home/mine')),
      4,
    );
    expect(
      scysTabIndexForUri(Uri.parse('https://scys.com/mobile/super-tag')),
      1,
    );
    expect(
      scysTabIndexForUri(
        Uri.parse('https://scys.com/mobile/home/index/opportunity'),
      ),
      1,
    );
    expect(
      scysTabIndexForUri(Uri.parse('https://example.com/mobile/home/mine')),
      isNull,
    );
  });
}
