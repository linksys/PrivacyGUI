import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

import 'router_boundary.dart';

void main() {
  test('holdsInTurn can fail a turn the way an unreachable router does',
      () async {
    final router = RouterBoundary()
      ..holdsInTurn(JNAPAction.getDeviceInfo, [
        ClientException('Connection refused'),
        {'serialNumber': 'S1'},
      ]);
    Future<JNAPResult> send() => router.repo
        .send(JNAPAction.getDeviceInfo, cacheLevel: CacheLevel.noCache);

    await expectLater(send(), throwsA(isA<ClientException>()));
    expect(((await send()) as JNAPSuccess).output, {'serialNumber': 'S1'});
    expect(
        router.actions, [JNAPAction.getDeviceInfo, JNAPAction.getDeviceInfo]);
  });

  test('holdsInTurn needs an answer, and says for which action', () {
    expect(
      () => RouterBoundary().holdsInTurn(JNAPAction.getDevices, []),
      throwsA(isA<ArgumentError>()
          .having((error) => error.message, 'message', contains('getDevices'))),
    );
  });
}
