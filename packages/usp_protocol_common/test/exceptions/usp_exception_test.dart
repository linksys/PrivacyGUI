import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspException', () {
    test('should correctly assign properties and format toString', () {
      final exception = UspException(7000, 'Internal Error');

      expect(exception.errorCode, equals(7000));
      expect(exception.message, equals('Internal Error'));
      expect(
        exception.toString(),
        equals('UspException(7000): Internal Error'),
      );
    });

    test('should support value equality', () {
      final exception1 = UspException(7000, 'Internal Error');
      final exception2 = UspException(7000, 'Internal Error');
      final exception3 = UspException(7001, 'Another Error');

      expect(exception1, equals(exception2));
      expect(exception1, isNot(equals(exception3)));
    });
  });
}
