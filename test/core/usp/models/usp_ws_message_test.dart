import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/usp_ws_message.dart';

void main() {
  group('UspWsMessage', () {
    test('parses successful Operate response', () {
      final js = <String, dynamic>{
        'from_id': 'os::router-001122334455',
        'to_id': 'controller::localui-turbo',
        'version': '1.3',
        'msg_type': 'OperateResp',
        'msg_id': 'op-12345',
        'command': 'Device.LocalAgent.X_LINKSYS_Download()',
        'output_args': <String, dynamic>{
          'Status': 'Success',
          'TransferComplete': 'true',
        },
      };

      final message = UspWsMessage.fromJs(js);

      expect(message.fromId, 'os::router-001122334455');
      expect(message.toId, 'controller::localui-turbo');
      expect(message.version, '1.3');
      expect(message.msgType, 'OperateResp');
      expect(message.msgId, 'op-12345');
      expect(message.command, 'Device.LocalAgent.X_LINKSYS_Download()');
      expect(message.outputArgs, isNotNull);
      expect(message.outputArgs!['Status'], 'Success');
      expect(message.outputArgs!['TransferComplete'], 'true');
      expect(message.error, isNull);
      expect(message.isSuccess, true);
      expect(message.isError, false);
    });

    test('parses Get response', () {
      final js = <String, dynamic>{
        'from_id': 'os::router-001122334455',
        'to_id': 'controller::localui-turbo',
        'version': '1.3',
        'msg_type': 'GetResp',
        'msg_id': 'get-67890',
        'output_args': <String, dynamic>{
          'Device.DeviceInfo.SoftwareVersion': '1.0.17.26050100',
        },
      };

      final message = UspWsMessage.fromJs(js);

      expect(message.msgType, 'GetResp');
      expect(message.msgId, 'get-67890');
      expect(message.command, isNull);
      expect(message.outputArgs!['Device.DeviceInfo.SoftwareVersion'],
          '1.0.17.26050100');
      expect(message.isSuccess, true);
    });

    test('parses error response', () {
      final js = <String, dynamic>{
        'from_id': 'os::router-001122334455',
        'to_id': 'controller::localui-turbo',
        'version': '1.3',
        'msg_type': 'Error',
        'msg_id': 'op-error-001',
        'error': <String, dynamic>{
          'code': '7004',
          'message': 'Invalid command arguments',
        },
      };

      final message = UspWsMessage.fromJs(js);

      expect(message.msgType, 'Error');
      expect(message.error, isNotNull);
      expect(message.error!.code, '7004');
      expect(message.error!.message, 'Invalid command arguments');
      expect(message.isSuccess, false);
      expect(message.isError, true);
    });

    test('handles missing optional fields gracefully', () {
      final js = <String, dynamic>{
        'from_id': 'os::router',
        'to_id': 'controller::test',
        'version': '1.3',
        'msg_type': 'OperateResp',
        'msg_id': 'minimal-001',
      };

      final message = UspWsMessage.fromJs(js);

      expect(message.fromId, 'os::router');
      expect(message.toId, 'controller::test');
      expect(message.command, isNull);
      expect(message.outputArgs, isNull);
      expect(message.error, isNull);
      expect(message.isSuccess, true);
    });

    test('handles null values in map', () {
      final js = <String, dynamic>{
        'from_id': null,
        'to_id': null,
        'version': null,
        'msg_type': null,
        'msg_id': null,
      };

      final message = UspWsMessage.fromJs(js);

      expect(message.fromId, '');
      expect(message.toId, '');
      expect(message.version, '');
      expect(message.msgType, '');
      expect(message.msgId, '');
    });

    test('toString returns readable format', () {
      final js = <String, dynamic>{
        'from_id': 'os::router',
        'to_id': 'controller::test',
        'version': '1.3',
        'msg_type': 'GetResp',
        'msg_id': 'test-001',
      };

      final message = UspWsMessage.fromJs(js);
      final str = message.toString();

      expect(str, contains('GetResp'));
      expect(str, contains('test-001'));
      expect(str, contains('os::router'));
      expect(str, contains('controller::test'));
    });
  });

  group('UspWsError', () {
    test('toString returns readable format', () {
      const error = UspWsError(code: '7004', message: 'Invalid arguments');
      final str = error.toString();

      expect(str, contains('7004'));
      expect(str, contains('Invalid arguments'));
    });
  });
}
