import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspDeleteResponse', () {
    test('should correctly assign properties', () {
      final deleted = [UspPath.parse('Device.WiFi.AccessPoint.1')];
      final errors = [UspException(1, 'Object is read-only')];
      final response = UspDeleteResponse(deletedPaths: deleted, errors: errors);

      expect(response.deletedPaths, equals(deleted));
      expect(response.errors, equals(errors));
    });

    test('should have empty lists by default', () {
      final response = UspDeleteResponse();
      expect(response.deletedPaths, isEmpty);
      expect(response.errors, isEmpty);
    });

    test('should support value equality', () {
      final deleted1 = [UspPath.parse('Device.WiFi.AccessPoint.1')];
      final errors1 = [UspException(1, 'Error')];
      final response1 = UspDeleteResponse(
        deletedPaths: deleted1,
        errors: errors1,
      );

      final deleted2 = [UspPath.parse('Device.WiFi.AccessPoint.1')];
      final errors2 = [UspException(1, 'Error')];
      final response2 = UspDeleteResponse(
        deletedPaths: deleted2,
        errors: errors2,
      );

      final deleted3 = [UspPath.parse('Device.LocalAgent.1')];
      final errors3 = [UspException(2, 'Different Error')];
      final response3 = UspDeleteResponse(
        deletedPaths: deleted3,
        errors: errors3,
      );

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });
  });
}
