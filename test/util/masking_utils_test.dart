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

  group('maskSerialNumber', () {
    test('masks JSON format with double quotes', () {
      const raw = '{"serialNumber": "ABC123456XYZ"}';
      const expected = '{"serialNumber": "****6XYZ"}';
      expect(MaskingUtils.maskSerialNumber(raw), expected);
    });

    test('masks JSON format without value quotes', () {
      const raw = '"serialNumber": ABC123456XYZ';
      const expected = '"serialNumber": ****6XYZ';
      expect(MaskingUtils.maskSerialNumber(raw), expected);
    });

    test('masks format without any quotes', () {
      const raw = 'serialNumber: ABC123456XYZ';
      const expected = 'serialNumber: ****6XYZ';
      expect(MaskingUtils.maskSerialNumber(raw), expected);
    });

    test('masks short serial number (<=4 chars) completely', () {
      const raw = '{"serialNumber": "AB12"}';
      const expected = '{"serialNumber": "****"}';
      expect(MaskingUtils.maskSerialNumber(raw), expected);
    });

    test('masks multiple serial numbers', () {
      const raw =
          '{"serialNumber": "SERIAL001"}, {"serialNumber": "SERIAL002"}';
      const expected =
          '{"serialNumber": "****L001"}, {"serialNumber": "****L002"}';
      expect(MaskingUtils.maskSerialNumber(raw), expected);
    });

    test('is case insensitive for key', () {
      const raw = '{"SERIALNUMBER": "ABC123456XYZ"}';
      const expected = '{"SERIALNUMBER": "****6XYZ"}';
      expect(MaskingUtils.maskSerialNumber(raw), expected);
    });

    test('returns unchanged if no serial number found', () {
      const raw = '{"deviceName": "MyRouter"}';
      expect(MaskingUtils.maskSerialNumber(raw), raw);
    });

    test('handles empty string', () {
      expect(MaskingUtils.maskSerialNumber(''), '');
    });
  });

  group('maskMacAddress', () {
    test('masks MAC with colon separator', () {
      const raw = 'MAC: AA:BB:CC:DD:EE:FF';
      const expected = 'MAC: XX:XX:XX:XX:EE:FF';
      expect(MaskingUtils.maskMacAddress(raw), expected);
    });

    test('masks MAC with hyphen separator', () {
      const raw = 'MAC: AA-BB-CC-DD-EE-FF';
      const expected = 'MAC: XX-XX-XX-XX-EE-FF';
      expect(MaskingUtils.maskMacAddress(raw), expected);
    });

    test('masks multiple MAC addresses', () {
      const raw = 'src=AA:BB:CC:DD:EE:FF dst=11:22:33:44:55:66';
      const expected = 'src=XX:XX:XX:XX:EE:FF dst=XX:XX:XX:XX:55:66';
      expect(MaskingUtils.maskMacAddress(raw), expected);
    });

    test('handles mixed case', () {
      const raw = 'aA:bB:cC:dD:eE:fF';
      const expected = 'XX:XX:XX:XX:eE:fF';
      expect(MaskingUtils.maskMacAddress(raw), expected);
    });

    test('returns unchanged if no MAC address found', () {
      const raw = 'No MAC here, just IP 192.168.1.1';
      expect(MaskingUtils.maskMacAddress(raw), raw);
    });

    test('handles empty string', () {
      expect(MaskingUtils.maskMacAddress(''), '');
    });

    test('does not match invalid MAC formats', () {
      const raw = 'Invalid: GG:HH:II:JJ:KK:LL';
      expect(MaskingUtils.maskMacAddress(raw), raw);
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
