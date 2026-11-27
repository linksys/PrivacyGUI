import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

import 'router_boundary.dart';

void main() {
  group('a scheduled poll', () {
    Stream<JNAPResult> poll(RouterBoundary router,
            {int maxRetry = 3,
            bool Function(JNAPResult)? condition,
            Function(bool)? onCompleted}) =>
        router.repo.scheduledCommand(
          action: JNAPAction.getFirmwareUpdateStatus,
          firstDelayInMilliSec: 0,
          retryDelayInMilliSec: 0,
          maxRetry: maxRetry,
          condition: condition,
          onCompleted: onCompleted,
        );

    test('runs the real loop: it stops once the condition holds, and says so',
        () async {
      final router = RouterBoundary()
        ..holdsInTurn(JNAPAction.getFirmwareUpdateStatus, [
          {'step': 1},
          {'step': 2},
        ]);
      bool? exceeded;

      final results = await poll(router,
          condition: (result) =>
              result is JNAPSuccess && result.output['step'] == 2,
          onCompleted: (value) => exceeded = value).toList();

      expect(results.map((r) => (r as JNAPSuccess).output['step']), [1, 2]);
      expect(exceeded, isFalse);
      expect(router.polls, [JNAPAction.getFirmwareUpdateStatus]);
    });

    test('of an action the table does not give fails, and sends nothing',
        () async {
      final router = RouterBoundary();

      await expectLater(
          poll(router).toList(),
          throwsA(isA<StateError>().having((error) => error.message, 'message',
              contains('getFirmwareUpdateStatus'))));
      expect(router.actions, isEmpty);
    });

    test('with no limit fails once it has polled 1000 times', () async {
      final router = RouterBoundary()
        ..holds(JNAPAction.getFirmwareUpdateStatus, const {});

      await expectLater(
          poll(router, maxRetry: -1, condition: (_) => false).toList(),
          throwsA(isA<StateError>()));
      expect(router.actions, hasLength(1000));
    });
  });

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
