import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  // ----------------------------------------------------------------------
  // 1. UspInstanceResult (Nested DTO) Test
  // ----------------------------------------------------------------------
  group('UspInstanceResult DTO', () {
    const keysA = {'ID': '1', 'Alias': '2.4G'};
    const keysB = {'ID': '1', 'Alias': '2.4G'};
    const keysC = {'ID': '2'};

    test('should support deep equality checks', () {
      // Arrange
      const result1 = UspInstanceResult('Device.Radio.1', uniqueKeys: keysA);
      const result2 = UspInstanceResult('Device.Radio.1', uniqueKeys: keysB);
      const result3 = UspInstanceResult('Device.Radio.2', uniqueKeys: keysA);
      const result4 = UspInstanceResult('Device.Radio.1', uniqueKeys: keysC);

      // Assert
      expect(
        result1,
        result2,
        reason: 'Must be equal when all properties are the same',
      );

      expect(result1, isNot(result3), reason: 'Path differs');
      expect(result1, isNot(result4), reason: 'Unique keys differ');
    });

    test('should handle empty uniqueKeys correctly', () {
      // Arrange
      const result = UspInstanceResult('Device.Interface.1');

      // Assert
      expect(result.instantiatedPath, 'Device.Interface.1');
      expect(result.uniqueKeys, isEmpty);
      expect(result.props.length, 2);
    });
  });

  // ----------------------------------------------------------------------
  // 2. UspGetInstancesResponse (Main Response DTO) Test
  // ----------------------------------------------------------------------
  group('UspGetInstancesResponse DTO', () {
    // Arrange
    final instanceA1 = const UspInstanceResult('Device.A.1');
    final instanceB1 = const UspInstanceResult(
      'Device.B.1',
      uniqueKeys: {'key': 'val'},
    );
    final instanceB2 = const UspInstanceResult('Device.B.2');

    final dataA = <String, List<UspInstanceResult>>{
      'Device.A.': [instanceA1],
      'Device.B.': [instanceB1, instanceB2],
    };

    final dataB = <String, List<UspInstanceResult>>{
      'Device.A.': [instanceA1],
      'Device.B.': [instanceB1, instanceB2],
    };

    final dataC = <String, List<UspInstanceResult>>{
      'Device.A.': [instanceA1],
    };

    test('should support deep equality checks for nested Map/List', () {
      // Act
      final resp1 = UspGetInstancesResponse(dataA);
      final resp2 = UspGetInstancesResponse(dataB);
      final resp3 = UspGetInstancesResponse(dataC);

      // Assert
      // 1. assert deep equality
      expect(
        resp1,
        resp2,
        reason: 'Response with identical results map should be equal',
      );

      // 2. assert content mismatch
      expect(resp1, isNot(resp3), reason: 'Results map content differs');

      // 3. assert property mismatch
      final resp4Data = Map.of(dataA);
      resp4Data['Device.B.'] = [instanceB1];
      final resp4 = UspGetInstancesResponse(resp4Data);
      expect(
        resp1,
        isNot(resp4),
        reason: 'Change in nested list size should cause inequality',
      );
    });

    test('should handle empty results map correctly', () {
      // Arrange
      final emptyResults = <String, List<UspInstanceResult>>{};
      final response = UspGetInstancesResponse(emptyResults);

      // Assert
      expect(response.results, isEmpty);
      expect(response.props.length, 1);
    });
  });
}
