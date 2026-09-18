import 'package:flutter_test/flutter_test.dart';
import 'package:sik_app/config/app_config.dart';

void main() {
  group('AppConfig API Key Multi-tier Resolution Tests', () {
    test('Resolves custom saved user key when provided', () {
      const customKey = 'sk-custom-user-provided-key-12345';
      final resolved = AppConfig.resolveApiKey(customKey);
      expect(resolved, equals(customKey));
    });

    test('Trims whitespace from saved key', () {
      const customKeyWithWhitespace = '  sk-custom-user-provided-key-12345  \n';
      final resolved = AppConfig.resolveApiKey(customKeyWithWhitespace);
      expect(resolved, equals('sk-custom-user-provided-key-12345'));
    });

    test('Falls back to environment or empty string when savedKey is null or empty', () {
      final resolvedNull = AppConfig.resolveApiKey(null);
      expect(resolvedNull, isA<String>());

      final resolvedEmpty = AppConfig.resolveApiKey('   ');
      expect(resolvedEmpty, isA<String>());
    });
  });
}
