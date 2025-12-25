import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspOperateRequest', () {
    test('should correctly assign properties', () {
      final command = UspPath.parse('Device.Reboot()');
      final args = {'delay': UspValue(10, UspValueType.int)};
      final request = UspOperateRequest(command: command, inputArgs: args);

      expect(request.command, equals(command));
      expect(request.inputArgs, equals(args));
    });

    test('should have empty inputArgs by default', () {
      final command = UspPath.parse('Device.Reboot()');
      final request = UspOperateRequest(command: command);
      expect(request.inputArgs, isEmpty);
    });

    test('should support value equality', () {
      final command1 = UspPath.parse('Device.Reboot()');
      final args1 = {'delay': UspValue(10, UspValueType.int)};
      final request1 = UspOperateRequest(command: command1, inputArgs: args1);

      final command2 = UspPath.parse('Device.Reboot()');
      final args2 = {'delay': UspValue(10, UspValueType.int)};
      final request2 = UspOperateRequest(command: command2, inputArgs: args2);

      final command3 = UspPath.parse('Device.FactoryReset()');
      final request3 = UspOperateRequest(command: command3, inputArgs: args1);

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });
}
