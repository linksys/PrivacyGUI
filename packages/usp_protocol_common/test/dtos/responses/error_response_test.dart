import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspErrorResponse', () {
    test('should correctly assign properties', () {
      final exception = UspException(7000, 'Internal Error');
      final response = UspErrorResponse(exception);

      expect(response.exception, equals(exception));
    });

    test('should support value equality', () {
      final exception1 = UspException(7000, 'Internal Error');
      final response1 = UspErrorResponse(exception1);

      final exception2 = UspException(7000, 'Internal Error');
      final response2 = UspErrorResponse(exception2);

      final exception3 = UspException(7001, 'Another Error');
      final response3 = UspErrorResponse(exception3);

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });
  });
}
