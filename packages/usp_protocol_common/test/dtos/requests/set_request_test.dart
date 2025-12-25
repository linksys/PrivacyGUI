import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspSetRequest', () {
    test('should correctly assign properties', () {
      final updates = {
        UspPath.parse('Device.WiFi.SSID'): UspValue(
          'MyWiFi',
          UspValueType.string,
        ),
      };
      final request = UspSetRequest(updates, allowPartial: true);

      expect(request.updates, equals(updates));
      expect(request.allowPartial, isTrue);
    });

    test('should have allowPartial default to false', () {
      final updates = {
        UspPath.parse('Device.WiFi.SSID'): UspValue(
          'MyWiFi',
          UspValueType.string,
        ),
      };
      final request = UspSetRequest(updates);

      expect(request.allowPartial, isFalse);
    });

    test('should support value equality', () {
      final updates1 = {
        UspPath.parse('Device.WiFi.SSID'): UspValue(
          'MyWiFi',
          UspValueType.string,
        ),
      };
      final request1 = UspSetRequest(updates1, allowPartial: true);

      final updates2 = {
        UspPath.parse('Device.WiFi.SSID'): UspValue(
          'MyWiFi',
          UspValueType.string,
        ),
      };
      final request2 = UspSetRequest(updates2, allowPartial: true);

      final updates3 = {
        UspPath.parse('Device.WiFi.Password'): UspValue(
          'secret',
          UspValueType.string,
        ),
      };
      final request3 = UspSetRequest(updates3, allowPartial: true);

      final request4 = UspSetRequest(updates1, allowPartial: false);

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
      expect(request1, isNot(equals(request4)));
    });
  });
}
