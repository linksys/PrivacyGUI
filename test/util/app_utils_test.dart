import 'package:privacy_gui/util/app_utils.dart';
import 'package:test/test.dart';

void main() {
  group('test string encode/decode', () {
    test('stringBase64Encode: encodes string to Base64 correctly', () {
      const value = 'Hello, world!';
      const expected = 'SGVsbG8sIHdvcmxkIQ==';

      final encoded = Utils.stringBase64Encode(value);
      expect(encoded, expected);
    });

    test('stringBase64Encode: handles empty string', () {
      const value = '';
      const expected = '';

      final encoded = Utils.stringBase64Encode(value);
      expect(encoded, expected);
    });

    test('stringBase64Encode: handles multibyte characters', () {
      const value = '日本語';
      const expected = '5pel5pys6Kqe';

      final encoded = Utils.stringBase64Encode(value);
      expect(encoded, expected);
    });

    test('stringBase64Decode: decodes Base64 string correctly', () {
      const base64String = 'SGVsbG8sIHdvcmxkIQ==';
      const expected = 'Hello, world!';

      final decoded = Utils.stringBase64Decode(base64String);
      expect(decoded, expected);
    });

    test('fullStringDecoded: handles invalid Base64 string', () {
      const invalidEncoded = 'invalid_base64';

      expect(
          () => Utils.fullStringDecoded(invalidEncoded), throwsFormatException);
    });
  });
}
