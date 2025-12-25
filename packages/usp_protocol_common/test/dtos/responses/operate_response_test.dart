import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspOperateResponse', () {
    test('should correctly assign properties', () {
      final args = {'status': UspValue('OK', UspValueType.string)};
      final response = UspOperateResponse(outputArgs: args);

      expect(response.outputArgs, equals(args));
    });

    test('should have empty outputArgs by default', () {
      final response = UspOperateResponse();
      expect(response.outputArgs, isEmpty);
    });

    test('should support value equality', () {
      final args1 = {'status': UspValue('OK', UspValueType.string)};
      final response1 = UspOperateResponse(outputArgs: args1);

      final args2 = {'status': UspValue('OK', UspValueType.string)};
      final response2 = UspOperateResponse(outputArgs: args2);

      final args3 = {'status': UspValue('FAIL', UspValueType.string)};
      final response3 = UspOperateResponse(outputArgs: args3);

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });
  });
}
