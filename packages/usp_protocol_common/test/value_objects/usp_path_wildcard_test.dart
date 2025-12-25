import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspPath Wildcard', () {
    test('should detect wildcard in path', () {
      // Arrange
      final path = UspPath.parse('Device.WiFi.Radio.*.Status');

      // Assert
      expect(path.hasWildcard, isTrue);
    });

    test('should not detect wildcard in path without it', () {
      // Arrange
      final path = UspPath.parse('Device.WiFi.Radio.1.Status');

      // Assert
      expect(path.hasWildcard, isFalse);
    });
  });
}
