import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspGetResponse', () {
    test('should correctly assign properties', () {
      final results = {
        UspPath.parse('Device.DeviceInfo.SerialNumber'): UspValue(
          '12345',
          UspValueType.string,
        ),
      };
      final response = UspGetResponse(results);

      expect(response.results, equals(results));
    });

    test('should support value equality', () {
      final results1 = {
        UspPath.parse('Device.DeviceInfo.SerialNumber'): UspValue(
          '12345',
          UspValueType.string,
        ),
      };
      final response1 = UspGetResponse(results1);

      final results2 = {
        UspPath.parse('Device.DeviceInfo.SerialNumber'): UspValue(
          '12345',
          UspValueType.string,
        ),
      };
      final response2 = UspGetResponse(results2);

      final results3 = {
        UspPath.parse('Device.DeviceInfo.ModelName'): UspValue(
          'ABC-100',
          UspValueType.string,
        ),
      };
      final response3 = UspGetResponse(results3);

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });
  });
}
