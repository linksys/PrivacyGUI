import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspAddRequest', () {
    test('should correctly assign properties', () {
      final creation = UspObjectCreation(
        UspPath.parse('Device.WiFi.AccessPoint.'),
        parameters: {
          'SSID': UspValue('MyNewAP', UspValueType.string),
          'Enabled': UspValue(true, UspValueType.boolean),
        },
      );
      final request = UspAddRequest([creation], allowPartial: true);

      expect(request.objects, equals([creation]));
      expect(request.allowPartial, isTrue);
    });

    test('should have allowPartial default to false', () {
      final creation = UspObjectCreation(
        UspPath.parse('Device.WiFi.AccessPoint.'),
      );
      final request = UspAddRequest([creation]);
      expect(request.allowPartial, isFalse);
    });

    test('should support value equality', () {
      final creation1 = UspObjectCreation(
        UspPath.parse('Device.WiFi.AccessPoint.'),
        parameters: {'SSID': UspValue('MyNewAP', UspValueType.string)},
      );
      final request1 = UspAddRequest([creation1], allowPartial: true);

      final creation2 = UspObjectCreation(
        UspPath.parse('Device.WiFi.AccessPoint.'),
        parameters: {'SSID': UspValue('MyNewAP', UspValueType.string)},
      );
      final request2 = UspAddRequest([creation2], allowPartial: true);

      final creation3 = UspObjectCreation(
        UspPath.parse('Device.LocalAgent.'),
        parameters: {'MTP': UspValue('MQTT', UspValueType.string)},
      );
      final request3 = UspAddRequest([creation3], allowPartial: true);

      final request4 = UspAddRequest([creation1], allowPartial: false);

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
      expect(request1, isNot(equals(request4)));
    });
  });
}
