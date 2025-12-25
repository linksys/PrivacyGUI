import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspNotify DTOs', () {
    group('UspValueChangeNotify', () {
      test('should correctly assign properties', () {
        final path = UspPath.parse('Device.LocalAgent.Endpoint.1.Status');
        const value = 'Active';
        const subscriptionId = 'sub123';
        const sendResp = true;

        final notify = UspValueChangeNotify(
          paramPath: path,
          paramValue: value,
          subscriptionId: subscriptionId,
          sendResp: sendResp,
        );

        expect(notify.paramPath, equals(path));
        expect(notify.paramValue, equals(value));
        expect(notify.subscriptionId, equals(subscriptionId));
        expect(notify.sendResp, equals(sendResp));
      });

      test('should support value equality', () {
        final path1 = UspPath.parse('Device.LocalAgent.Endpoint.1.Status');
        final notify1 = UspValueChangeNotify(
          paramPath: path1,
          paramValue: 'Active',
        );
        final notify2 = UspValueChangeNotify(
          paramPath: path1,
          paramValue: 'Active',
        );
        final notify3 = UspValueChangeNotify(
          paramPath: path1,
          paramValue: 'Inactive',
        );

        expect(notify1, equals(notify2));
        expect(notify1, isNot(equals(notify3)));
      });
    });

    group('UspObjectCreationNotify', () {
      test('should correctly assign properties', () {
        final path = UspPath.parse('Device.LocalAgent.Endpoint.1');
        const subscriptionId = 'sub123';
        const sendResp = false;
        final uniqueKeys = {'ID': '123', 'Alias': 'MyEndpoint'};

        final notify = UspObjectCreationNotify(
          objPath: path,
          uniqueKeys: uniqueKeys,
          subscriptionId: subscriptionId,
          sendResp: sendResp,
        );

        expect(notify.objPath, equals(path));
        expect(notify.uniqueKeys, equals(uniqueKeys));
        expect(notify.subscriptionId, equals(subscriptionId));
        expect(notify.sendResp, equals(sendResp));
      });

      test('should support value equality', () {
        final path1 = UspPath.parse('Device.LocalAgent.Endpoint.1');
        final notify1 = UspObjectCreationNotify(
          objPath: path1,
          uniqueKeys: {'ID': '1'},
        );
        final notify2 = UspObjectCreationNotify(
          objPath: path1,
          uniqueKeys: {'ID': '1'},
        );
        final notify3 = UspObjectCreationNotify(
          objPath: path1,
          uniqueKeys: {'ID': '2'},
        );

        expect(notify1, equals(notify2));
        expect(notify1, isNot(equals(notify3)));
      });
    });

    group('UspObjectDeletionNotify', () {
      test('should correctly assign properties', () {
        final path = UspPath.parse('Device.LocalAgent.Endpoint.1');
        const subscriptionId = 'sub123';
        const sendResp = true;

        final notify = UspObjectDeletionNotify(
          objPath: path,
          subscriptionId: subscriptionId,
          sendResp: sendResp,
        );

        expect(notify.objPath, equals(path));
        expect(notify.subscriptionId, equals(subscriptionId));
        expect(notify.sendResp, equals(sendResp));
      });

      test('should support value equality', () {
        final path1 = UspPath.parse('Device.LocalAgent.Endpoint.1');
        final notify1 = UspObjectDeletionNotify(objPath: path1);
        final notify2 = UspObjectDeletionNotify(objPath: path1);
        final notify3 = UspObjectDeletionNotify(
          objPath: UspPath.parse('Device.LocalAgent.Endpoint.2'),
        );

        expect(notify1, equals(notify2));
        expect(notify1, isNot(equals(notify3)));
      });
    });

    group('UspOperationCompleteNotify', () {
      test('should correctly assign properties for success', () {
        final path = UspPath.parse('Device.LocalAgent.Endpoint.1');
        const cmdName = 'Reboot';
        const cmdKey = 'cmd123';
        final outputArgs = {'status': 'OK'};
        const subscriptionId = 'sub123';
        const sendResp = true;

        final notify = UspOperationCompleteNotify(
          objPath: path,
          commandName: cmdName,
          commandKey: cmdKey,
          outputArgs: outputArgs,
          subscriptionId: subscriptionId,
          sendResp: sendResp,
        );

        expect(notify.objPath, equals(path));
        expect(notify.commandName, equals(cmdName));
        expect(notify.commandKey, equals(cmdKey));
        expect(notify.outputArgs, equals(outputArgs));
        expect(notify.commandFailure, isNull);
        expect(notify.isSuccess, isTrue);
      });

      test('should correctly assign properties for failure', () {
        final path = UspPath.parse('Device.LocalAgent.Endpoint.1');
        const cmdName = 'Reboot';
        const cmdKey = 'cmd123';
        final failure = UspException(7000, 'Reboot failed');
        const subscriptionId = 'sub123';
        const sendResp = true;

        final notify = UspOperationCompleteNotify(
          objPath: path,
          commandName: cmdName,
          commandKey: cmdKey,
          commandFailure: failure,
          subscriptionId: subscriptionId,
          sendResp: sendResp,
        );

        expect(notify.commandFailure, equals(failure));
        expect(notify.isSuccess, isFalse);
        expect(notify.outputArgs, isEmpty); // Should be empty on failure
      });

      test('should support value equality', () {
        final path1 = UspPath.parse('Device.LocalAgent.Endpoint.1');
        final notify1 = UspOperationCompleteNotify(
          objPath: path1,
          commandName: 'Reboot',
          commandKey: 'cmd1',
        );
        final notify2 = UspOperationCompleteNotify(
          objPath: path1,
          commandName: 'Reboot',
          commandKey: 'cmd1',
        );
        final notify3 = UspOperationCompleteNotify(
          objPath: path1,
          commandName: 'Reboot',
          commandKey: 'cmd2',
        );

        expect(notify1, equals(notify2));
        expect(notify1, isNot(equals(notify3)));
      });
    });

    group('UspOnBoardRequestNotify', () {
      test('should correctly assign properties', () {
        const oui = '123456';
        const productClass = 'MyProduct';
        const serialNumber = 'SN123';
        const agentVersions = '1.0';
        const sendResp = true;

        final notify = UspOnBoardRequestNotify(
          oui: oui,
          productClass: productClass,
          serialNumber: serialNumber,
          agentProtocolVersions: agentVersions,
          sendResp: sendResp,
        );

        expect(notify.oui, equals(oui));
        expect(notify.productClass, equals(productClass));
        expect(notify.serialNumber, equals(serialNumber));
        expect(notify.agentProtocolVersions, equals(agentVersions));
        expect(notify.sendResp, equals(sendResp));
      });

      test('should support value equality', () {
        final notify1 = UspOnBoardRequestNotify(
          oui: '1',
          productClass: 'PC',
          serialNumber: 'SN',
          agentProtocolVersions: 'V1',
        );
        final notify2 = UspOnBoardRequestNotify(
          oui: '1',
          productClass: 'PC',
          serialNumber: 'SN',
          agentProtocolVersions: 'V1',
        );
        final notify3 = UspOnBoardRequestNotify(
          oui: '2',
          productClass: 'PC',
          serialNumber: 'SN',
          agentProtocolVersions: 'V1',
        );

        expect(notify1, equals(notify2));
        expect(notify1, isNot(equals(notify3)));
      });
    });
  });
}
