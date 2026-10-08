import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

void main() {
  const receipt = '{"accepted":false,"cancelled":true,"requestId":"request-1"}';
  test('shipped WASM direct response exposes synchronous Result', () {
    expect(
        UspClient.extractOperateResult({
          'commandKey': 'command-1',
          'outputArgs': {'Result': receipt}
        }),
        {'commandKey': 'command-1', 'Result': receipt});
  });
  test('unified WASM response retains the same contract', () {
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
        UspClient.extractOperateResult(
            {'commandKey': 'command-1', 'outputArgs': null}),
        {'commandKey': 'command-1'});
  });
  test('already flat output stays compatible', () {
    expect(UspClient.extractOperateResult({'Result': receipt}),
        {'Result': receipt});
  });
  test('absent response data never invents an acknowledgement', () {
    expect(UspClient.extractOperateResult({'result': {}}), isEmpty);
  });
}
