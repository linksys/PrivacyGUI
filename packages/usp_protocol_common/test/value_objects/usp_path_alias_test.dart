import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspPath Alias Filtering', () {
    test('should parse alias filter from path', () {
      // Arrange
      final path = UspPath.parse('Device.WiFi.SSID.[Alias=="Guest"].Enable');

      // Assert
      expect(path.aliasFilter, isNotEmpty);
      expect(path.aliasFilter['Alias'], 'Guest');
    });

    test('should not have alias filter if not present', () {
      // Arrange
      final path = UspPath.parse('Device.WiFi.SSID.1.Enable');

      // Assert
      expect(path.aliasFilter, isEmpty);
    });
  });
}
