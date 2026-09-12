import 'package:flutter_test/flutter_test.dart';
import 'package:scys/navigation_policy.dart';

void main() {
  group('NavigationPolicy', () {
    const policy = NavigationPolicy();

    test('keeps scys.com and its subdomains inside the app', () {
      expect(
        policy.decide(Uri.parse('https://scys.com/t/BOA7wWFK')),
        NavigationTarget.inApp,
      );
      expect(
        policy.decide(Uri.parse('https://m.scys.com/topic/1')),
        NavigationTarget.inApp,
      );
    });

    test('keeps official shengcaiyoushu domains inside the app', () {
      expect(
        policy.decide(Uri.parse('https://www.shengcaiyoushu.com/')),
        NavigationTarget.inApp,
      );
      expect(
        policy.decide(Uri.parse('https://search01.shengcaiyoushu.com/test')),
        NavigationTarget.inApp,
      );
    });

    test('keeps the WeChat QR login page inside the app', () {
      expect(
        policy.decide(
          Uri.parse('https://open.weixin.qq.com/connect/qrconnect?appid=demo'),
        ),
        NavigationTarget.inApp,
      );
    });

    test('keeps Feishu links inside the app', () {
      expect(
        policy.decide(Uri.parse('https://www.feishu.cn/hc/zh-CN/')),
        NavigationTarget.inApp,
      );
      expect(
        policy.decide(Uri.parse('https://applink.feishu.cn/client/chat/open')),
        NavigationTarget.inApp,
      );
    });

    test('keeps ZSXQ links inside the app', () {
      expect(
        policy.decide(Uri.parse('https://zsxq.com/group/123456789')),
        NavigationTarget.inApp,
      );
      expect(
        policy.decide(Uri.parse('https://wx.zsxq.com/group/123456789')),
        NavigationTarget.inApp,
      );
    });

    test('opens unrelated web links outside the app', () {
      expect(
        policy.decide(Uri.parse('https://example.com/article')),
        NavigationTarget.external,
      );
      expect(
        policy.decide(Uri.parse('https://scys.com.evil.example/')),
        NavigationTarget.external,
      );
      expect(
        policy.decide(Uri.parse('https://feishu.cn.evil.example/')),
        NavigationTarget.external,
      );
      expect(
        policy.decide(Uri.parse('https://zsxq.com.evil.example/')),
        NavigationTarget.external,
      );
    });

    test('hands custom schemes to an installed app', () {
      expect(
        policy.decide(Uri.parse('weixin://dl/business/?ticket=123')),
        NavigationTarget.external,
      );
      expect(
        policy.decide(Uri.parse('mailto:hello@example.com')),
        NavigationTarget.external,
      );
      expect(policy.decide(Uri.parse('tel:10086')), NavigationTarget.external);
    });

    test('blocks malformed or unsafe navigations', () {
      expect(policy.decide(Uri()), NavigationTarget.blocked);
      expect(
        policy.decide(Uri.parse('javascript:alert(1)')),
        NavigationTarget.blocked,
      );
      expect(
        policy.decide(Uri.parse('data:text/html,hello')),
        NavigationTarget.blocked,
      );
    });
  });
}
