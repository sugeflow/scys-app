import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const scysWebTokenStorageKey = '__user_token.v3';

String? parseWebStorageToken(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  if (text.isEmpty || text == 'null' || text == 'undefined') {
    return null;
  }

  if (text.startsWith('"')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  return text;
}

abstract interface class AuthTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

class SecureAuthTokenStore implements AuthTokenStore {
  const SecureAuthTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'scys.auth-token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
