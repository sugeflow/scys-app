import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scys/native_profile.dart';
import 'package:scys/scys_api_client.dart';

void main() {
  group('NativeProfileController', () {
    test('publishes loading and ready states', () async {
      final completer = Completer<ScysUserProfile>();
      final controller = NativeProfileController(() => completer.future);

      final refresh = controller.refresh();
      expect(controller.state.status, NativeProfileStatus.loading);

      completer.complete(_profile);
      await refresh;

      expect(controller.state.status, NativeProfileStatus.ready);
      expect(controller.state.profile?.name, '生财同学');
    });

    test('returns to signed out when authentication is required', () async {
      final controller = NativeProfileController(
        () => Future<ScysUserProfile>.error(const ScysAuthenticationRequired()),
      );

      await controller.refresh();

      expect(controller.state.status, NativeProfileStatus.signedOut);
    });
  });

  group('NativeProfileView', () {
    testWidgets('offers web login while signed out', (tester) async {
      var loginRequested = false;

      await tester.pumpWidget(
        MaterialApp(
          home: NativeProfileView(
            state: const NativeProfileState.signedOut(),
            onLogin: () => loginRequested = true,
            onRefresh: () {},
          ),
        ),
      );

      expect(find.text('登录后查看原生个人页'), findsOneWidget);
      await tester.tap(find.text('前往网页登录'));
      expect(loginRequested, isTrue);
    });

    testWidgets('shows profile and membership information', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NativeProfileView(
            state: const NativeProfileState.ready(_profile),
            onLogin: () {},
            onRefresh: () {},
          ),
        ),
      );

      expect(find.text('生财同学'), findsOneWidget);
      expect(find.text('生财号 1024'), findsOneWidget);
      expect(find.text('长期主义者'), findsOneWidget);
      expect(find.text('收藏'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('会员有效期：2027-04-18'), findsOneWidget);
    });
  });
}

const _profile = ScysUserProfile(
  name: '生财同学',
  memberNumber: 1024,
  avatarUrl: '/upload/avatar/demo',
  intro: '长期主义者',
  expiresAt: '2027-04-18',
  unreadCount: 3,
  favoriteCount: 8,
  followCount: 5,
  followerCount: 13,
);
