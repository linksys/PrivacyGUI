import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspAddResponse', () {
    test('should correctly assign properties', () {
      final created = [
        UspCreatedObject(UspPath.parse('Device.WiFi.AccessPoint.1')),
      ];
      final errors = [UspException(1, 'Failed to create another object')];
      final response = UspAddResponse(createdObjects: created, errors: errors);

      expect(response.createdObjects, equals(created));
      expect(response.errors, equals(errors));
    });

    test('should have empty lists by default', () {
      final response = UspAddResponse();
      expect(response.createdObjects, isEmpty);
      expect(response.errors, isEmpty);
    });

    test('should support value equality', () {
      final created1 = [
        UspCreatedObject(UspPath.parse('Device.WiFi.AccessPoint.1')),
      ];
      final errors1 = [UspException(1, 'Error')];
      final response1 = UspAddResponse(
        createdObjects: created1,
        errors: errors1,
      );

      final created2 = [
        UspCreatedObject(UspPath.parse('Device.WiFi.AccessPoint.1')),
      ];
      final errors2 = [UspException(1, 'Error')];
      final response2 = UspAddResponse(
        createdObjects: created2,
        errors: errors2,
      );

      final created3 = [UspCreatedObject(UspPath.parse('Device.LocalAgent.1'))];
      final errors3 = [UspException(2, 'Different Error')];
      final response3 = UspAddResponse(
        createdObjects: created3,
        errors: errors3,
      );

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });
  });
}
