/// #1550 (W4) — the router answers "is there a new version", not the cloud API.
///
/// Every test here injects a millisecond-scale deadline and poll interval. That is
/// not a shortcut around a slow test: the constants being *injectable* is what the
/// ticket asks for, because the production pair is a placeholder for a parameter
/// the firmware does not expose yet, and the day it does, the number has to be
/// deletable from one place.
///
/// The three failure modes at the bottom are the point of the file. All three end
/// in the same wrong answer if they are not handled — "your firmware is up to
/// date" — and the check has no way to tell that answer from a real one, because
/// the only evidence for it is a timeout.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_router_ota_check_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

class MockUspFirmwareUpdateService extends Mock
    implements UspFirmwareUpdateService {}

class MockSseOperationAwaiter extends Mock implements SseOperationAwaiter {}

/// The virtual ota row, in the two shapes the bench produces.
///
/// `NoImage` with no version is what an M60TB on the latest build reports, and it
/// is the reading that means both "checked, nothing new" and "never checked" — the
/// ambiguity the deadline exists to work around.
FirmwareImageUIModel _otaRow({required bool available, String version = ''}) =>
    FirmwareImageUIModel(
      instance: 3,
      instancePath: 'Device.DeviceInfo.FirmwareImage.3.',
      alias: 'ota',
      name: '',
      version: version,
      status: available ? 'Available' : 'NoImage',
      available: available,
    );

const _bank = FirmwareImageUIModel(
  instance: 1,
  instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
  alias: 'fw1',
  name: 'firmware-bank-1',
  version: '2.0.1.26091009',
  status: 'Active',
  available: true,
);

void main() {
  late MockUspFirmwareUpdateService firmware;
  late MockSseOperationAwaiter awaiter;
  late UspMutationLock lock;
  late OperationCompleteWatch watch;

  /// A service whose poll loop turns over fast enough to run inside a test.
  FirmwareRouterOtaCheckService buildService({
    Duration deadline = const Duration(milliseconds: 60),
    Duration pollInterval = const Duration(milliseconds: 5),
    bool withAwaiter = true,
  }) =>
      FirmwareRouterOtaCheckService(
        // Two methods, not the object — the service under test cannot reach
        // `triggerOtaDownload`, and neither can this test hand it one.
        dispatchCheck: firmware.requestOtaCheck,
        readImages: firmware.fetchAllBanks,
        awaiter: withAwaiter ? awaiter : null,
        lock: lock,
        deadline: deadline,
        pollInterval: pollInterval,
      );

  setUp(() {
    firmware = MockUspFirmwareUpdateService();
    awaiter = MockSseOperationAwaiter();
    lock = UspMutationLock();
    watch = OperationCompleteWatch.detached();
    when(() => awaiter.watchOperationComplete(
            referencePath: any(named: 'referencePath')))
        .thenAnswer((_) async => watch);
    when(() => firmware.requestOtaCheck(otaInstance: any(named: 'otaInstance')))
        .thenAnswer((_) async => 'cmd-key-1');
  });

  group('the dispatch', () {
    test('asks the ota instance, and subscribes before it asks', () async {
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: false)]);

      await buildService().check(otaInstance: 3);

      // Order matters and is asserted rather than assumed: `cmd_failure` is
      // measured to arrive ~49ms after the dispatch, so a subscription opened
      // afterwards can miss the only refusal channel there is.
      verifyInOrder([
        () => awaiter.watchOperationComplete(
            referencePath: 'Device.DeviceInfo.FirmwareImage.'),
        () => firmware.requestOtaCheck(otaInstance: 3),
      ]);
    });

    test('releases the subscription even when the check throws', () async {
      var released = false;
      watch = OperationCompleteWatch.detached(
          onRelease: () async => released = true);
      when(() => firmware.fetchAllBanks()).thenThrow(NetworkError());

      await expectLater(
        buildService().check(otaInstance: 3),
        throwsA(isA<ServiceError>()),
      );
      expect(released, isTrue);
    });

    test('a subscription that will not open does not sink the check', () async {
      // Opening the watch is an HTTP POST and can fail on its own. Before this
      // was handled it threw straight out of `check()` past the phase the caller
      // had already set — and as a bridge exception, not a `ServiceError`, so the
      // notifier's `on ServiceError` did not catch it either, so the button spun
      // for the rest of the session. Degrading matches what the awaiter itself
      // does when SSE is down.
      when(() => awaiter.watchOperationComplete(
              referencePath: any(named: 'referencePath')))
          .thenThrow(Exception('subscription POST failed'));
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: true)]);

      final result = await buildService().check(otaInstance: 3);

      expect(result.verdict, FirmwareOtaCheckVerdict.updateAvailable);
      verify(() => firmware.requestOtaCheck(otaInstance: 3)).called(1);
    });

    test('holds the mutation lock for the operate and not for the poll',
        () async {
      // Constitution Article IV Rule 3, at the width the WASM client's
      // no-concurrent-calls limit actually needs: the operate is a write and takes
      // the lock, the reads that follow are `Get`s and nothing in this codebase
      // locks those. The width matters — the loop runs for the whole deadline, and
      // a lock held across it would block every other mutation in the app for ten
      // seconds and sit under the lock's own 30s timeout, which throws a
      // `TimeoutException` rather than a `ServiceError`.
      bool? lockedDuringDispatch;
      var lockedDuringPoll = false;
      when(() =>
              firmware.requestOtaCheck(otaInstance: any(named: 'otaInstance')))
          .thenAnswer((_) async {
        lockedDuringDispatch = lock.isLocked;
        return 'cmd-key-1';
      });
      when(() => firmware.fetchAllBanks()).thenAnswer((_) async {
        if (lock.isLocked) lockedDuringPoll = true;
        return [_bank, _otaRow(available: false)];
      });

      await buildService().check(otaInstance: 3);

      expect(lockedDuringDispatch, isTrue);
      expect(lockedDuringPoll, isFalse);
      expect(lock.isLocked, isFalse);
    });

    test('a mutation timeout leaves as a ServiceError, not a TimeoutException',
        () async {
      // The half of this the install service fixed at its own dispatch and this
      // one did not. `UspMutationLock.withLock` throws a bare `TimeoutException`
      // on purpose — it is core, not a feature service, and constitution Article
      // XIII §13.3 makes the mapping this layer's job. Nothing above this line
      // could do it: every `on ServiceError` between here and the button was blind
      // to it, so the check appeared to do nothing for 30s, left no failure card,
      // and then escaped an unawaited `onTap` as an uncaught async error.
      //
      // Thrown from the dispatcher rather than by letting the lock time out for
      // real: the lock's timeout is 30s and is not injectable from here, and a
      // suite that waits it out is a suite nobody runs. What is under test is the
      // `catch`, and the exception reaching it is the same object either way.
      when(() =>
              firmware.requestOtaCheck(otaInstance: any(named: 'otaInstance')))
          .thenThrow(TimeoutException(
              'USP mutation timed out after 30s', const Duration(seconds: 30)));

      await expectLater(
        buildService().check(otaInstance: 3),
        throwsA(isA<TimeoutError>()),
      );
      // And it aborts before the poll loop. This is the assertion that separates
      // the fix from the bug it replaces: an unmapped throw also leaves the
      // method, but a check that reached the loop would spend its whole deadline
      // reading banks and could still return `noUpdateFound` — the one answer
      // this service exists never to invent.
      verifyNever(() => firmware.fetchAllBanks());
    });

    test('runs without an awaiter at all', () async {
      // `sseOperationAwaiterProvider` is nullable, and a check is offered on
      // every surface. Losing the refusal channel degrades the answer; it must
      // not remove the feature.
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: true)]);

      final result =
          await buildService(withAwaiter: false).check(otaInstance: 3);

      expect(result.verdict, FirmwareOtaCheckVerdict.updateAvailable);
      verifyNever(() => awaiter.watchOperationComplete(
          referencePath: any(named: 'referencePath')));
    });
  });

  group('reading the answer out of the data model', () {
    test('an available ota row is an update, with its version', () async {
      when(() => firmware.fetchAllBanks()).thenAnswer(
          (_) async => [_bank, _otaRow(available: true, version: '2.0.2.1')]);

      final result = await buildService().check(otaInstance: 3);

      expect(result,
          const FirmwareOtaCheckResult.updateAvailable(version: '2.0.2.1'));
    });

    test('keeps polling until the router publishes the row', () async {
      var reads = 0;
      when(() => firmware.fetchAllBanks()).thenAnswer((_) async {
        reads++;
        return [_bank, _otaRow(available: reads >= 3, version: '2.0.2.1')];
      });

      final result = await buildService().check(otaInstance: 3);

      expect(result.isUpdateAvailable, isTrue);
      expect(reads, 3);
    });

    test('an available row with no version is still an offer', () async {
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: true)]);

      final result = await buildService().check(otaInstance: 3);

      expect(result.verdict, FirmwareOtaCheckVerdict.updateAvailable);
      expect(result.version, isEmpty);
    });

    test('reads the ota row, never the spare NAND bank', () async {
      // `_bank` is available-and-not-active exactly as a spare slot is, so a
      // check that read the banks would report the version already sitting in
      // NAND as one the router is offering to fetch.
      when(() => firmware.fetchAllBanks()).thenAnswer((_) async => [
            _bank,
            const FirmwareImageUIModel(
              instance: 2,
              instancePath: 'Device.DeviceInfo.FirmwareImage.2.',
              alias: 'fw2',
              name: 'firmware-bank-2',
              version: '1.0.15.211003',
              status: 'Standby',
              available: true,
            ),
            _otaRow(available: false),
          ]);

      final result = await buildService().check(otaInstance: 3);

      expect(result.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
    });

    test('a vanished ota row is not an update', () async {
      when(() => firmware.fetchAllBanks()).thenAnswer((_) async => [_bank]);

      final result = await buildService().check(otaInstance: 3);

      expect(result.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
    });
  });

  group('the three measured failure modes', () {
    test('fwup_state never leaves 0 and the check still finishes cleanly',
        () async {
      // The ticket's first failure mode, and the reason this service reads no
      // `fwup_state` at all: the checking window is under a second, a 300ms poll
      // caught it once in one sample, and a check driven off "state became 1"
      // would hang on every run that finished between two samples. Nothing here
      // waits for that transition — the call's own lifecycle is the clock.
      //
      // There is no `verifyNever(fetchAutoUpdate)` here on purpose: the service is
      // handed two functions and `fetchAutoUpdate` is not one of them, so it is
      // not reachable rather than merely unused, and an assertion that cannot
      // fail is worse than the structure that made it redundant.
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: false)]);

      final result = await buildService().check(otaInstance: 3);

      expect(result.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
    });

    test('no commandKey is an error, not "you are up to date"', () async {
      when(() =>
              firmware.requestOtaCheck(otaInstance: any(named: 'otaInstance')))
          .thenThrow(UspCompleteFailureError(
              summary: 'no commandKey', failures: const []));
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: false)]);

      await expectLater(
        buildService().check(otaInstance: 3),
        throwsA(isA<ServiceError>()),
      );
      // And it does not quietly fall through to the poll loop, which would
      // report the *previous* check's reading as this one's answer.
      verifyNever(() => firmware.fetchAllBanks());
    });

    test('cmd_failure is an error, not "you are up to date"', () async {
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: false)]);
      // Arrives on its own clock, as the real one does — after the dispatch and
      // while the poll loop is already running.
      Future<void>.delayed(const Duration(milliseconds: 8), () {
        watch.emit(const OperateResult(
          commandName: 'Download()',
          commandKey: 'cmd-key-1',
          status: 'Error',
          outputArgs: {},
          errorCode: '7022',
          errorMessage: 'Command failure',
        ));
      });

      await expectLater(
        buildService(deadline: const Duration(milliseconds: 200))
            .check(otaInstance: 3),
        throwsA(isA<ServiceError>()),
      );
    });

    test('a cmd_failure that beats the poll loop is still an error', () async {
      // The race the other way round: the refusal is buffered by the watch
      // before anything asks for it, because the notification is measured to
      // arrive before the operate's own HTTP response does.
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: false)]);
      when(() =>
              firmware.requestOtaCheck(otaInstance: any(named: 'otaInstance')))
          .thenAnswer((_) async {
        watch.emit(const OperateResult(
          commandName: 'Download()',
          commandKey: 'cmd-key-1',
          status: 'Error',
          outputArgs: {},
          errorCode: '7022',
        ));
        return 'cmd-key-1';
      });

      await expectLater(
        buildService().check(otaInstance: 3),
        throwsA(isA<ServiceError>()),
      );
    });

    test('another command\'s cmd_failure is not this check\'s', () async {
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: false)]);
      watch.emit(const OperateResult(
        commandName: 'Download()',
        commandKey: 'some-other-key',
        status: 'Error',
        outputArgs: {},
        errorCode: '7022',
      ));

      final result = await buildService().check(otaInstance: 3);

      expect(result.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
    });

    test('an ordinary OperationComplete is not a refusal', () async {
      when(() => firmware.fetchAllBanks())
          .thenAnswer((_) async => [_bank, _otaRow(available: false)]);
      // What the bench actually produces 49ms in: acceptance. Reading this as a
      // result would report a check as finished before it had looked.
      watch.emit(const OperateResult(
        commandName: 'Download()',
        commandKey: 'cmd-key-1',
        status: 'Requested',
        outputArgs: {'Status': 'Requested'},
      ));

      final result = await buildService().check(otaInstance: 3);

      expect(result.verdict, FirmwareOtaCheckVerdict.noUpdateFound);
    });
  });

  group('the deadline', () {
    test('a read that keeps failing surfaces as an error', () async {
      when(() => firmware.fetchAllBanks()).thenThrow(NetworkError());

      await expectLater(
        buildService().check(otaInstance: 3),
        throwsA(isA<NetworkError>()),
      );
    });

    test('is tunable, and the production default is documented', () {
      // Pinned so that "replace this once contract request 6 is answered" has a
      // named thing to delete. Values are a compromise both ends of which are
      // wrong: shorter reports "nothing new" while the router is still asking,
      // longer spends the whole window on the common case, which is a router
      // that is already current.
      expect(FirmwareRouterOtaCheckService.defaultDeadline,
          const Duration(seconds: 10));
      expect(FirmwareRouterOtaCheckService.defaultPollInterval,
          const Duration(seconds: 2));
    });
  });
}
