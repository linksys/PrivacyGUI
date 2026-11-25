// How the app waits for the router after a write whose answer names a side
// effect: a restart, a Wi-Fi interruption or anything else that takes the
// router away for a while. It stops polling, probes the router on its own
// schedule until it is back, and polls again; or it gives up with an error the
// save pages turn into their alerts.
//
// The waits are real timers, so every test runs on testWidgets' fake clock and
// reads the outcome after pumping, never awaiting it (#1866 BRIEF rule 11).
// side_effect_boot_check_test.dart pins the "is it back" predicate itself.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';

const _serial = '20J2060A839173';

/// `GetDeviceInfo` output of the router with [serialNumber].
Map<String, dynamic> _deviceInfo(String serialNumber) => {
      'manufacturer': 'Linksys',
      'modelNumber': 'WHW03',
      'hardwareVersion': '2',
      'description': 'Velop',
      'serialNumber': serialNumber,
      'firmwareVersion': '2.1.20.213195',
      'firmwareDate': '2023-07-25T07:27:06Z',
      'services': ['http://linksys.com/jnap/core/Core'],
    };

/// `GetWANStatus` output with [status] as the IPv4 WAN's state.
Map<String, dynamic> _wan(String status) => {
      'supportedWANTypes': ['DHCP', 'Static', 'PPPoE'],
      'detectedWANType': 'DHCP',
      'wanStatus': status,
      'wanIPv6Status': 'Disconnected',
      'macAddress': '30:23:03:2E:AF:EE',
    };

const _gone = JNAPError(result: 'ErrorTimeout');

/// The answer to a write, naming [sideEffects].
JNAPSuccess _written(List<String> sideEffects) =>
    JNAPSuccess(result: 'OK', sideEffects: sideEffects);

/// What a wait ended in, once it has.
class _Outcome {
  Object? value;
  Object? error;
  bool get isDone => value != null || error != null;
}

void main() {
  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;

  SideEffectNotifier notifier() => container.read(sideEffectProvider.notifier);
  JNAPSideEffect sideEffect() => container.read(sideEffectProvider);

  _Outcome watch(Future<Object?> future) {
    final outcome = _Outcome();
    future.then(
      (value) => outcome.value = value ?? 'done',
      onError: (Object error) => outcome.error = error,
    );
    return outcome;
  }

  int probes(JNAPAction action) =>
      router.actions.where((sent) => sent == action).length;

  setUp(() {
    SharedPreferences.setMockInitialValues({pCurrentSN: _serial});
    router = RouterBoundary();
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  testWidgets('passes an answer with no side effect straight through',
      (tester) async {
    const answer = JNAPSuccess(result: 'OK', output: {'mode': 'Master'});

    final outcome = watch(notifier().handleSideEffect(answer));
    await tester.pump();

    expect(outcome.value, answer);
    expect(router.actions, isEmpty);
    expect(polling.stopped, 0);
    expect(sideEffect().hasSideEffect, isFalse);
  });

  group('after a restart', () {
    testWidgets(
        'waits 20 s, then probes every 10 s until the router answers as '
        'itself with its WAN up, then polls again', (tester) async {
      router
        ..holdsInTurn(
            JNAPAction.getDeviceInfo, [_gone, _gone, _deviceInfo(_serial)])
        ..holds(JNAPAction.getWANStatus, _wan('Connected'));
      final answer = _written(['DeviceRestart']);

      final outcome = watch(notifier().handleSideEffect(answer));
      await tester.pump();
      expect(polling.stopped, 1);
      expect(sideEffect().hasSideEffect, isTrue);
      expect(sideEffect().reason, 'DeviceRestart');

      await tester.pump(const Duration(seconds: 19));
      expect(router.actions, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(router.actions, [JNAPAction.getDeviceInfo]);
      await tester.pump(const Duration(seconds: 10));
      expect(probes(JNAPAction.getDeviceInfo), 2);
      expect(outcome.isDone, isFalse);

      await tester.pump(const Duration(seconds: 10));
      expect(router.actions.skip(2),
          [JNAPAction.getDeviceInfo, JNAPAction.getWANStatus]);
      expect(outcome.value, answer);
      expect(polling.started, 1);
    });

    testWidgets('keeps waiting while another router answers in its place',
        (tester) async {
      router.holds(JNAPAction.getDeviceInfo, _deviceInfo('19A10M00000000'));
      final answer = _written(['DeviceRestart']);

      final outcome = watch(notifier().handleSideEffect(answer,
          overrides: const JNAPSideEffectOverrides(maxRetry: 2)));
      await tester.pump(const Duration(seconds: 49));
      expect(outcome.isDone, isFalse);
      await tester.pump(const Duration(seconds: 1));

      // The first probe and one for each of the two retries.
      expect(router.actions, List.filled(3, JNAPAction.getDeviceInfo));
      expect(outcome.error, isA<JNAPSideEffectError>());
      expect((outcome.error as JNAPSideEffectError).attach, answer);
      expect(polling.started, 0);
    });

    testWidgets(
        'knows the router by the serial number setup saved, before a login '
        'has saved one', (tester) async {
      SharedPreferences.setMockInitialValues({pPnpConfiguredSN: _serial});
      router
        ..holds(JNAPAction.getDeviceInfo, _deviceInfo(_serial))
        ..holds(JNAPAction.getWANStatus, _wan('Connected'));
      final answer = _written(['DeviceRestart']);

      final outcome = watch(notifier().handleSideEffect(answer));
      await tester.pump(const Duration(seconds: 20));

      expect(outcome.value, answer);
    });

    testWidgets('stops waiting at once when the caller\'s condition holds',
        (tester) async {
      router.holds(JNAPAction.getDeviceInfo, _deviceInfo('19A10M00000000'));
      final answer = _written(['DeviceRestart']);

      final outcome = watch(notifier().handleSideEffect(answer,
          overrides: JNAPSideEffectOverrides(
              timeDelayStartInSec: 0, condition: () => true)));
      await tester.pump();

      expect(outcome.value, answer);
      expect(router.actions, [JNAPAction.getDeviceInfo]);
      expect(polling.started, 1);
    });
  });

  group('after a Wi-Fi interruption', () {
    testWidgets('waits for the router to answer as itself, then polls again',
        (tester) async {
      router
        ..holdsInTurn(JNAPAction.getDeviceInfo, [_gone, _deviceInfo(_serial)])
        ..holds(JNAPAction.getWANStatus, _wan('Connected'));
      final answer = _written(['WirelessInterruption']);

      final outcome = watch(notifier().handleSideEffect(answer));
      await tester.pump(const Duration(seconds: 20));
      expect(outcome.isDone, isFalse);
      await tester.pump(const Duration(seconds: 10));

      expect(router.actions, [
        JNAPAction.getDeviceInfo,
        JNAPAction.getDeviceInfo,
        JNAPAction.getWANStatus,
      ]);
      expect(outcome.value, answer);
      expect(sideEffect().reason, 'WirelessInterruption');
      expect(polling.started, 1);
    });

    testWidgets('gives up when the retries the caller allows run out',
        (tester) async {
      router.holds(JNAPAction.getDeviceInfo, _deviceInfo('19A10M00000000'));
      final answer = _written(['WirelessInterruption']);

      final outcome = watch(notifier().handleSideEffect(answer,
          overrides: const JNAPSideEffectOverrides(
              maxRetry: 1, timeDelayStartInSec: 5, retryDelayInSec: 5)));
      await tester.pump(const Duration(seconds: 15));

      expect(probes(JNAPAction.getDeviceInfo), 2);
      expect((outcome.error as JNAPSideEffectError).attach, answer);
      expect(polling.started, 0);
    });
  });

  group('after any other side effect', () {
    testWidgets(
        'waits 20 s, then probes the WAN every 15 s until it connects, '
        'without asking who the router is', (tester) async {
      router.holdsInTurn(
          JNAPAction.getWANStatus, [_wan('Disconnected'), _wan('Connected')]);
      final answer = _written(['WANInterruption']);

      final outcome = watch(notifier().handleSideEffect(answer));
      await tester.pump(const Duration(seconds: 20));
      expect(router.actions, [JNAPAction.getWANStatus]);
      await tester.pump(const Duration(seconds: 14));
      expect(outcome.isDone, isFalse);
      await tester.pump(const Duration(seconds: 1));

      expect(
          router.actions, [JNAPAction.getWANStatus, JNAPAction.getWANStatus]);
      expect(outcome.value, answer);
      expect(polling.started, 1);
    });

    testWidgets(
        'gives up after ten retries with the last WAN status attached, so '
        'setup can tell a WAN that will not connect from a router gone',
        (tester) async {
      router.holds(JNAPAction.getWANStatus, _wan('Disconnected'));
      final answer = _written(['WANInterruption']);

      final outcome = watch(notifier().handleSideEffect(answer));
      // The first probe at 20 s, ten retries 15 s apart, and the wait after
      // the last of them.
      await tester.pump(const Duration(seconds: 20 + 10 * 15 + 14));
      expect(outcome.isDone, isFalse);
      await tester.pump(const Duration(seconds: 1));

      expect(probes(JNAPAction.getWANStatus), 11);
      final error = outcome.error as JNAPSideEffectError;
      expect(error.attach, answer);
      final last = error.lastHandledResult as JNAPSuccess;
      expect(last.output['wanStatus'], 'Disconnected');
      expect(last.output['macAddress'], '30:23:03:2E:AF:EE');
      expect(polling.started, 0);
    });

    testWidgets('gives up with nothing attached when the router never answers',
        (tester) async {
      router.refuses(JNAPAction.getWANStatus);
      final answer = _written(['WANInterruption']);

      final outcome = watch(notifier().handleSideEffect(answer,
          overrides: const JNAPSideEffectOverrides(maxRetry: 1)));
      await tester.pump(const Duration(seconds: 20 + 15 + 15));

      expect(probes(JNAPAction.getWANStatus), 2);
      final error = outcome.error as JNAPSideEffectError;
      expect(error.attach, answer);
      expect(error.lastHandledResult, isNull);
    });
  });

  group('a restart the user asks for', () {
    testWidgets('shows a manual restart until the router is back, then clears',
        (tester) async {
      router
        ..holdsInTurn(JNAPAction.getDeviceInfo, [_gone, _deviceInfo(_serial)])
        ..holds(JNAPAction.getWANStatus, _wan('Connected'));

      final outcome = watch(notifier().manualDeviceRestart());
      expect(sideEffect().hasSideEffect, isTrue);
      expect(sideEffect().reason, 'manual');

      // The first probe after 10 s, the next 10 s later.
      await tester.pump(const Duration(seconds: 10));
      expect(router.actions, [JNAPAction.getDeviceInfo]);
      await tester.pump(const Duration(seconds: 10));

      expect(outcome.value, isTrue);
      expect(sideEffect().hasSideEffect, isFalse);
      expect(sideEffect().progress, 0);
      // A restart the user asks for leaves polling to its caller.
      expect((polling.stopped, polling.started), (0, 0));
    });

    testWidgets('fails, and clears, when the router does not come back',
        (tester) async {
      router.refuses(JNAPAction.getDeviceInfo);

      final outcome = watch(notifier().manualDeviceRestart(
          overrides: const JNAPSideEffectOverrides(maxRetry: 1)));
      await tester.pump(const Duration(seconds: 30));

      expect(probes(JNAPAction.getDeviceInfo), 2);
      expect(outcome.error, isA<JNAPSideEffectError>());
      expect(sideEffect().hasSideEffect, isFalse);
    });
  });

  group('a side effect as a value', () {
    test('keeps what copyWith does not name', () {
      const effect = JNAPSideEffect(hasSideEffect: true, reason: 'manual');

      final moved = effect.copyWith(progress: 40);

      expect(
          moved,
          const JNAPSideEffect(
              hasSideEffect: true, reason: 'manual', progress: 40));
      expect(moved, isNot(effect));
      expect(moved.copyWith(), moved);
    });

    test('writes itself out and reads itself back', () {
      final effect = JNAPSideEffect.fromJson(
          jsonDecode('{"hasSideEffect": true, "reason": "DeviceRestart", '
              '"progress": 40}') as Map<String, dynamic>);

      expect(effect.toJson(),
          {'hasSideEffect': true, 'reason': 'DeviceRestart', 'progress': 40});
      expect(JNAPSideEffect.fromJson(effect.toJson()), effect);
      expect(JNAPSideEffect.fromJson(effect.copyWith(progress: 80).toJson()),
          isNot(effect));
    });

    test('writes no reason when it has none', () {
      final idle = JNAPSideEffect.fromJson(
          const {'hasSideEffect': false, 'reason': null, 'progress': 0});

      expect(idle.reason, isNull);
      expect(idle.toJson(),
          {'hasSideEffect': false, 'reason': null, 'progress': 0});
    });
  });

  group('overrides as a value', () {
    test('are equal when they hold the same condition', () {
      bool backAtOnce() => true;
      bool neverBack() => false;

      expect(JNAPSideEffectOverrides(maxRetry: 5, condition: backAtOnce),
          JNAPSideEffectOverrides(maxRetry: 5, condition: backAtOnce));
      expect(JNAPSideEffectOverrides(maxRetry: 5, condition: backAtOnce),
          isNot(JNAPSideEffectOverrides(maxRetry: 5, condition: neverBack)));
      expect(JNAPSideEffectOverrides(condition: backAtOnce).toString(),
          contains('JNAPSideEffectOverrides'));
    });
  });
}
