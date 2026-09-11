import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_token.dart';

class ScysUserProfile {
  const ScysUserProfile({
    required this.name,
    required this.memberNumber,
    required this.avatarUrl,
    required this.intro,
    required this.expiresAt,
    required this.unreadCount,
    required this.favoriteCount,
    required this.followCount,
    required this.followerCount,
  });

  factory ScysUserProfile.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final info = _asMap(json['info']);

    return ScysUserProfile(
      name: _asString(user['name']) ?? '生财同学',
      memberNumber: _asInt(user['number'] ?? user['group_number']),
      avatarUrl: _asString(user['avatar']) ?? '/images/pic_avatar.png',
      intro: _asString(info['自我介绍']) ?? '',
      expiresAt: _asString(user['xq_date_expire']),
      unreadCount: _asInt(json['unread_count']),
      favoriteCount: _asInt(json['favorite_count']),
      followCount: _asInt(json['follow_count']),
      followerCount: _asInt(json['follower_count']),
    );
  }

  final String name;
  final int memberNumber;
  final String avatarUrl;
  final String intro;
  final String? expiresAt;
  final int unreadCount;
  final int favoriteCount;
  final int followCount;
  final int followerCount;

  Uri get resolvedAvatarUri => Uri.parse(
    avatarUrl.startsWith('http') ? avatarUrl : 'https://scys.com$avatarUrl',
  );
}

class ScysApiClient {
  ScysApiClient(this._tokenStore, {http.Client? httpClient, Uri? baseUri})
    : _httpClient = httpClient ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse('https://scys.com');

  final AuthTokenStore _tokenStore;
  final http.Client _httpClient;
  final Uri _baseUri;

  Future<ScysUserProfile> fetchUserProfile() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const ScysAuthenticationRequired();
    }

    final response = await _httpClient.get(
      _baseUri.resolve('/search/user/center'),
      headers: {'X-TOKEN': token, 'Accept': 'application/json'},
    );

    if (const {401, 402, 409}.contains(response.statusCode)) {
      await _tokenStore.clear();
      throw const ScysAuthenticationRequired();
    }
    if (response.statusCode != 200) {
      throw ScysApiException('服务器返回 ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const ScysApiException('用户资料格式不正确');
    }

    final status = _asInt(decoded['status']);
    if (status != 0) {
      throw ScysApiException(_asString(decoded['message']) ?? '无法读取用户资料');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const ScysApiException('用户资料为空');
    }
    return ScysUserProfile.fromJson(data);
  }

  void close() => _httpClient.close();
}

class ScysAuthenticationRequired implements Exception {
  const ScysAuthenticationRequired();
}

class ScysApiException implements Exception {
  const ScysApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map<String, dynamic> ? value : const {};
}

String? _asString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
