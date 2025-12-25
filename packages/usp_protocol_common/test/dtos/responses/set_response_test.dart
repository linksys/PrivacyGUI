import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspSetResponse', () {
    test('should correctly assign properties', () {
      final success = [UspPath.parse('Device.WiFi.SSID')];
      final failures = {
        UspPath.parse('Device.WiFi.Password'): UspException(
          1,
          'Invalid password',
        ),
      };
      final response = UspSetResponse(
        successPaths: success,
        failurePaths: failures,
      );

      expect(response.successPaths, equals(success));
      expect(response.failurePaths, equals(failures));
      expect(response.hasErrors, isTrue);
    });

    test('should have empty lists and maps by default', () {
      final response = UspSetResponse();
      expect(response.successPaths, isEmpty);
      expect(response.failurePaths, isEmpty);
      expect(response.hasErrors, isFalse);
    });

    test('should support value equality', () {
      final success1 = [UspPath.parse('Device.WiFi.SSID')];
      final failures1 = {
        UspPath.parse('Device.WiFi.Password'): UspException(
          1,
          'Invalid password',
        ),
      };
      final response1 = UspSetResponse(
        successPaths: success1,
        failurePaths: failures1,
      );

      final success2 = [UspPath.parse('Device.WiFi.SSID')];
      final failures2 = {
        UspPath.parse('Device.WiFi.Password'): UspException(
          1,
          'Invalid password',
        ),
      };
      final response2 = UspSetResponse(
        successPaths: success2,
        failurePaths: failures2,
      );

      final success3 = [UspPath.parse('Device.WiFi.Alias')];
      final failures3 = {
        UspPath.parse('Device.WiFi.SomethingElse'): UspException(2, 'Error'),
      };
      final response3 = UspSetResponse(
        successPaths: success3,
        failurePaths: failures3,
      );

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });
  });
}
