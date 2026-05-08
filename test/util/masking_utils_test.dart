import 'package:privacy_gui/util/masking_utils.dart';
import 'package:privacy_gui/core/utils/fernet_manager.dart';
import 'package:test/test.dart';

void main() {
  group('test mask value', () {
    test('maskJsonValue: masks correctly single key in JSON string', () {
      const rawJson =
          '{"name": "John Doe", "age": 30, "address": "123 Main St."}';
      const keys = ['name'];
      const expected =
          '{"name": "************", "age": 30, "address": "123 Main St."}';

      final maskedJson = MaskingUtils.maskJsonValue(rawJson, keys);
      expect(maskedJson, expected);
    });

    test('maskJsonValue: masks correctly multiple keys in JSON string', () {
      const rawJson =
          '{"name": "John Doe", "age": 30, "address": "123 Main St.", "phone": "555-1212"}';
      const keys = ['name', 'phone'];
      const expected =
          '{"name": "************", "age": 30, "address": "123 Main St.", "phone": "************"}';

      final maskedJson = MaskingUtils.maskJsonValue(rawJson, keys);
      expect(maskedJson, expected);
    });

    test('maskJsonValue: handles empty keys list', () {
      const rawJson = '{"name": "John Doe", "age": 30}';
      const List<String> keys = [];
      const expected = rawJson;

      final maskedJson = MaskingUtils.maskJsonValue(rawJson, keys);
      expect(maskedJson, expected);
    });

    test('maskJsonValue: handles invalid JSON format', () {
      const rawJson = 'invalid json';
      const keys = ['name'];

      final maskedJson = MaskingUtils.maskJsonValue(rawJson, keys);
      expect(maskedJson, rawJson);
    });

    test(
        'maskSensitiveJsonValues: masks specified keys correctly in JSON string',
        () {
      const rawJson =
          '{"username": "john_doe", "password": "123456", "email": "john.doe@example.com"}';
      const expected =
          '{"username": "************", "password": "************", "email": "john.doe@example.com"}';

      final maskedJson = MaskingUtils.maskSensitiveJsonValues(rawJson);
      expect(maskedJson, expected);
    });

    test('maskSensitiveJsonValues: handles empty JSON string', () {
      const rawJson = '';
      final maskedJson = MaskingUtils.maskSensitiveJsonValues(rawJson);
      expect(maskedJson, rawJson);
    });

    test('maskSensitiveJsonValues: handles invalid JSON format', () {
      const rawJson = 'invalid json';
      final maskedJson = MaskingUtils.maskSensitiveJsonValues(rawJson);
      expect(maskedJson, rawJson);
    });
  });

  group('encryptJNAPAuth', () {
    setUp(() {
      FernetManager().resetForTest();
    });

    test('should encrypt the JNAP authorization password when key is available',
        () {
      FernetManager().updateKeyFromSerial('a-test-serial');
      const rawLog =
          'Some log line... X-JNAP-Authorization: Basic YWRtaW46VmVsb3BAMTIzNA== ... some other log';
      const originalPassword = 'YWRtaW46VmVsb3BAMTIzNA==';

      final processedLog = MaskingUtils.encryptJNAPAuth(rawLog);

      expect(processedLog, isNot(contains(originalPassword)));
      expect(processedLog, contains('X-JNAP-Authorization: Basic '));
      expect(processedLog.length, greaterThan(rawLog.length));
    });

    test(
        'should mask the JNAP authorization password when key is NOT available',
        () {
      const rawLog =
          'Another log... X-JNAP-Authorization: Basic YWRtaW46VmVsb3BAMTIzNA== ... end of log';
      const expectedLog =
          'Another log... X-JNAP-Authorization: Basic ************ ... end of log';

      final processedLog = MaskingUtils.encryptJNAPAuth(rawLog);
      expect(processedLog, expectedLog);
    });

    test('should not change the string if the pattern is not found', () {
      const rawLog = 'This is a log line without any authorization header.';
      final processedLog = MaskingUtils.encryptJNAPAuth(rawLog);
      expect(processedLog, rawLog);
    });
  });
}
