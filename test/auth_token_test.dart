import 'package:flutter_test/flutter_test.dart';
import 'package:scys/auth_token.dart';

void main() {
  group('parseWebStorageToken', () {
    test('extracts a token returned as a JSON string', () {
      expect(parseWebStorageToken('"token-123"'), 'token-123');
    });

    test('accepts a raw token returned by WebKit', () {
      expect(parseWebStorageToken('token-123'), 'token-123');
    });

    test('rejects missing and blank values', () {
      expect(parseWebStorageToken(null), isNull);
      expect(parseWebStorageToken('null'), isNull);
      expect(parseWebStorageToken('  '), isNull);
    });
  });
}
