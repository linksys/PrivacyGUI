import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

void main() {
  const receipt = '{"accepted":false,"cancelled":true,"requestId":"request-1"}';
  test('shared response exposes synchronous Result without a command key', () {
    expect(
        UspClient.extractOperateResult({
          'success': true,
          'result': {
            'data': {
              'outputArgs': {'Result': receipt}
            }
          }
        }),
        {'Result': receipt});
  });
  test('shared response retains the command key and synchronous Result', () {
    expect(
        UspClient.extractOperateResult({
          'success': true,
          'result': {
            'data': {
              'commandKey': 'command-1',
              'outputArgs': {'Result': receipt}
            }
          }
        }),
        {'commandKey': 'command-1', 'Result': receipt});
  });
  test('asynchronous command without output arguments retains correlation', () {
    expect(
        UspClient.extractOperateResult({
          'success': true,
          'result': {
            'data': {
              'commandKey': 'command-1',
              'requestPath': 'Device.LocalAgent.Request.1.',
            }
          }
        }),
        {
          'commandKey': 'command-1',
          'requestPath': 'Device.LocalAgent.Request.1.',
        });
  });
  test('already flat output stays compatible', () {
    expect(UspClient.extractOperateResult({'Result': receipt}),
        {'Result': receipt});
  });
  test('absent response data never invents an acknowledgement', () {
    expect(UspClient.extractOperateResult({'result': {}}), isEmpty);
  });
}
