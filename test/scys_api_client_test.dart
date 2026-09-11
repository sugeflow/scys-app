import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scys/auth_token.dart';
import 'package:scys/scys_api_client.dart';

void main() {
  group('ScysUserProfile', () {
    test('maps the website user-center response', () {
      final profile = ScysUserProfile.fromJson({
        'user': {
          'avatar': '/upload/avatar/demo',
          'name': '生财同学',
          'number': '1024',
          'xq_date_expire': '2027-04-18',
        },
        'info': {'自我介绍': '长期主义者'},
        'unread_count': 3,
        'favorite_count': 8,
        'follow_count': 5,
        'follower_count': 13,
      });

      expect(profile.name, '生财同学');
      expect(profile.memberNumber, 1024);
      expect(profile.avatarUrl, '/upload/avatar/demo');
      expect(profile.intro, '长期主义者');
      expect(profile.expiresAt, '2027-04-18');
      expect(profile.unreadCount, 3);
      expect(profile.favoriteCount, 8);
      expect(profile.followCount, 5);
      expect(profile.followerCount, 13);
    });
  });

  group('ScysApiClient', () {
    test('sends the saved token when loading the user profile', () async {
      final tokenStore = _MemoryTokenStore('secret-token');
      final httpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url, Uri.parse('https://scys.com/search/user/center'));
        expect(request.headers['X-TOKEN'], 'secret-token');
        return http.Response(
          jsonEncode({
            'status': 0,
            'data': {
              'user': {'name': '生财同学', 'number': 1024},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final client = ScysApiClient(tokenStore, httpClient: httpClient);

      final profile = await client.fetchUserProfile();

      expect(profile.name, '生财同学');
      expect(profile.memberNumber, 1024);
    });

    test('requires login before making a profile request', () async {
      final client = ScysApiClient(
        _MemoryTokenStore(null),
        httpClient: MockClient((_) async => throw StateError('not called')),
      );

      expect(
        client.fetchUserProfile,
        throwsA(isA<ScysAuthenticationRequired>()),
      );
    });

    test('clears an expired token after an unauthorized response', () async {
      final tokenStore = _MemoryTokenStore('expired-token');
      final client = ScysApiClient(
        tokenStore,
        httpClient: MockClient((_) async => http.Response('', 401)),
      );

      await expectLater(
        client.fetchUserProfile(),
        throwsA(isA<ScysAuthenticationRequired>()),
      );
      expect(tokenStore.value, isNull);
    });
  });
}

class _MemoryTokenStore implements AuthTokenStore {
  _MemoryTokenStore(this.value);

  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;
}
