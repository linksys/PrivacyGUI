import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspGetInstancesRequest DTO', () {
    test('should construct with default values and support const', () {
      // Arrange
      final paths = [
        UspPath.parse('Device.WiFi.SSID.'),
        UspPath.parse('Device.IP.Interface.'),
      ];

      // Act
      final request = UspGetInstancesRequest(paths);

      // Assert
      expect(request.objPaths, paths);
      expect(
        request.firstLevelOnly,
        isFalse,
        reason: 'Default should be false',
      );
    });

    test('should support deep equality checks via Equatable', () {
      // Arrange
      final pathsA = [UspPath.parse('Device.A')];
      final pathsB = [UspPath.parse('Device.A')];
      final pathsC = [UspPath.parse('Device.B')];

      // Act
      final req1 = UspGetInstancesRequest(pathsA, firstLevelOnly: true);
      final req2 = UspGetInstancesRequest(pathsB, firstLevelOnly: true);
      final req3 = UspGetInstancesRequest(pathsC, firstLevelOnly: true);
      final req4 = UspGetInstancesRequest(pathsA, firstLevelOnly: false);

      // Assert
      // 1. assert deep equality
      expect(req1, req2, reason: 'Equal objects must be equal');

      // 2. assert content mismatch
      expect(req1, isNot(req3), reason: 'Paths content differs');

      // 3. assert property mismatch
      expect(req1, isNot(req4), reason: 'Flag differs');
    });

    test('should handle empty paths list correctly', () {
      // Arrange
      final paths = <UspPath>[];
      final request = UspGetInstancesRequest(paths);

      // Assert
      expect(request.objPaths, isEmpty);
      expect(
        request.props.length,
        2,
        reason: 'Should only contain paths and flag',
      );
    });
  });
}
