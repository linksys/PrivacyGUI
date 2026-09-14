/// #1551 (W5) — the router installs, and the app watches it do so.
///
/// The shape mirrors `firmware_router_ota_check_service_test.dart` because the
/// dispatch is literally the same `Download` with `AutoActivate` flipped. What is
/// new is everything after the dispatch, and it is new for one reason: this flow
/// has **no completion signal**. The router reboots in the middle of it, so the
/// end of a successful install looks exactly like the network going away.
///
/// So the fed sequences below are the specification. Each one is a list of
/// `(fwup_state, fwup_progress)` readings — the two parameters the router
/// publishes — and each asserts either what the caller is told, or what a progress
/// bar is allowed to render, or both. Three of them exist because they were
/// measured on the bench; the ones after `state=3` are the ticket's design
/// assumption, and are marked as such where they appear.
///
/// **Timing is injected, never waited on.** Every service here gets millisecond
/// intervals. The cadence test at the bottom asserts only that the two intervals
/// are different, not what they are — the numbers themselves are pinned as
/// constants, because an assertion that a 1-second gap is 1 second is an assertion
/// about the machine the suite runs on.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_router_ota_install_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

import '../../../mocks/test_data/firmware_update_test_data.dart';

class MockUspFirmwareUpdateService extends Mock
    implements UspFirmwareUpdateService {}

class MockSseOperationAwaiter extends Mock implements SseOperationAwaiter {}

/// One `(fwup_state, fwup_progress)` pair, through the real mapping site.
FirmwareAutoUpdateUIModel _at(String state, [int progress = 0]) =>
    UspFirmwareUpdateService.mapAutoUpdateStatus(
        FirmwareUpdateTestData.autoUpdate(
      fwupState: state,
      fwupProgress: '$progress',
    ));

void main() {
  late MockUspFirmwareUpdateService firmware;
  late MockSseOperationAwaiter awaiter;
  late UspMutationLock lock;
  late OperationCompleteWatch watch;
  late List<FirmwareOtaInstallProgress> emitted;

  /// A service whose loop turns over fast enough to run inside a test.
  FirmwareRouterOtaInstallService buildService({
    Duration checkingPollInterval = const Duration(milliseconds: 2),
    Duration busyPollInterval = const Duration(milliseconds: 2),
    Duration startupGrace = const Duration(milliseconds: 20),
    Duration ceiling = const Duration(milliseconds: 400),
    bool withAwaiter = true,
  }) =>
      FirmwareRouterOtaInstallService(
        // Two functions, not the object. The install verb is one of them here, so
        // the compiler is not being asked to hide it — what it does hide is
        // everything else on that service, in particular `setAutoUpdatePolicy`:
        // this flow reads `autoupdate_flags` on every poll and must never write it.
        dispatchInstall: firmware.requestOtaInstall,
        readAutoUpdate: firmware.fetchAutoUpdate,
        awaiter: withAwaiter ? awaiter : null,
        lock: lock,
        checkingPollInterval: checkingPollInterval,
        busyPollInterval: busyPollInterval,
        startupGrace: startupGrace,
        ceiling: ceiling,
      );

  /// Feeds [sequence] one reading per poll, holding the last one forever.
  void feed(List<FirmwareAutoUpdateUIModel> sequence) {
    var i = 0;
    when(() => firmware.fetchAutoUpdate()).thenAnswer((_) async {
      final reading = sequence[i < sequence.length ? i : sequence.length - 1];
      i++;
      return reading;
    });
  }

  setUp(() {
    firmware = MockUspFirmwareUpdateService();
    awaiter = MockSseOperationAwaiter();
    lock = UspMutationLock();
    watch = OperationCompleteWatch.detached();
    emitted = [];
    when(() => awaiter.watchOperationComplete(
            referencePath: any(named: 'referencePath')))
        .thenAnswer((_) async => watch);
    when(() =>
            firmware.requestOtaInstall(otaInstance: any(named: 'otaInstance')))
        .thenAnswer((_) async => 'install-key-1');
  });

  group('the dispatch', () {
    test('asks the ota instance, and subscribes before it asks', () async {
      feed([_at('0')]);

      await buildService().install(otaInstance: 3);

      // Same ordering as the check, and it matters more: `cmd_failure` arrives
      // ~49ms after the dispatch and is the only channel a refusal appears on.
      // Miss it on an install and a refused flash reads as a flash in progress
      // for the whole ceiling.
      verifyInOrder([
        () => awaiter.watchOperationComplete(
            referencePath: 'Device.DeviceInfo.FirmwareImage.'),
        () => firmware.requestOtaInstall(otaInstance: 3),
      ]);
    });

    test('releases the subscription even when the install throws', () async {
      var released = false;
      watch = OperationCompleteWatch.detached(
          onRelease: () async => released = true);
      when(() => firmware.fetchAutoUpdate()).thenThrow(NetworkError());

      await expectLater(
        buildService().install(otaInstance: 3),
        throwsA(isA<ServiceError>()),
      );
      expect(released, isTrue);
    });

    test('releases the subscription on the ordinary path too', () async {
      // The `Device.LocalAgent.Subscription.` half of the acceptance: created on
      // entry, gone on exit. A flash that leaves its subscription behind leaves it
      // behind across a reboot, when nothing is left to release it.
      var released = false;
      watch = OperationCompleteWatch.detached(
          onRelease: () async => released = true);
      feed([_at('3', 10), _at('4', 0)]);

      await buildService().install(otaInstance: 3);

      expect(released, isTrue);
    });

    test('a subscription that will not open does not sink the install',
        () async {
      when(() => awaiter.watchOperationComplete(
              referencePath: any(named: 'referencePath')))
          .thenThrow(Exception('subscription POST failed'));
      feed([_at('3', 5)]);

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
      verify(() => firmware.requestOtaInstall(otaInstance: 3)).called(1);
    });

    test('an SSE that is down is not a failed install', () async {
      // What `watchOperationComplete` returns when the manager is disconnected:
      // a detached watch nobody can feed. It must read as "no refusal channel",
      // never as a refusal — a false failure here would abandon a flash that is
      // actually running.
      watch = OperationCompleteWatch.detached();
      feed([_at('1'), _at('3', 20), _at('4', 0)]);

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('holds the mutation lock for the operate and not for the poll',
        () async {
      bool? lockedDuringDispatch;
      var lockedDuringPoll = false;
      when(() => firmware.requestOtaInstall(
          otaInstance: any(named: 'otaInstance'))).thenAnswer((_) async {
        lockedDuringDispatch = lock.isLocked;
        return 'install-key-1';
      });
      when(() => firmware.fetchAutoUpdate()).thenAnswer((_) async {
        if (lock.isLocked) lockedDuringPoll = true;
        return _at('0');
      });

      await buildService().install(otaInstance: 3);

      // The width is the point. This loop can run for twenty minutes; a lock held
      // across it would block every other mutation in the app for that long and
      // would sit under the lock's own 30s timeout, which throws a
      // `TimeoutException` rather than a `ServiceError`.
      expect(lockedDuringDispatch, isTrue);
      expect(lockedDuringPoll, isFalse);
      expect(lock.isLocked, isFalse);
    });

    test('runs without an awaiter at all', () async {
      feed([_at('3', 1)]);

      final result =
          await buildService(withAwaiter: false).install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
      verifyNever(() => awaiter.watchOperationComplete(
          referencePath: any(named: 'referencePath')));
    });

    test('a mutation timeout leaves as a ServiceError, not a TimeoutException',
        () async {
      // `UspMutationLock.withLock` throws a bare `TimeoutException` on purpose —
      // it is core, not a feature service, and constitution Article XIII §13.3
      // makes the mapping this layer's job. Nothing above this line could do it:
      // every `on ServiceError` between here and the button was blind to it, so
      // the dispatch appeared to do nothing for 30s, left no failure card, and
      // then escaped an unawaited `onTap` as an uncaught async error.
      //
      // Thrown from the dispatcher rather than by letting the lock time out for
      // real: the lock's timeout is 30s and is not injectable from here, and a
      // suite that waits it out is a suite nobody runs. What is under test is the
      // `catch`, and the exception reaching it is the same object either way.
      when(() => firmware.requestOtaInstall(
              otaInstance: any(named: 'otaInstance')))
          .thenThrow(TimeoutException(
              'USP mutation timed out after 30s', const Duration(seconds: 30)));
      feed([_at('0')]);

      await expectLater(
        buildService().install(otaInstance: 3),
        throwsA(isA<TimeoutError>()),
      );
      verifyNever(() => firmware.fetchAutoUpdate());
    });

    test('a dispatch with no commandKey never reaches the poll loop', () async {
      when(() => firmware.requestOtaInstall(
              otaInstance: any(named: 'otaInstance')))
          .thenThrow(UspCompleteFailureError(
              summary: 'no commandKey', failures: const []));
      feed([_at('0')]);

      await expectLater(
        buildService().install(otaInstance: 3),
        throwsA(isA<ServiceError>()),
      );
      verifyNever(() => firmware.fetchAutoUpdate());
    });
  });

  group('the fed sequences', () {
    test('(0,100) is idle, and 100 renders nowhere', () async {
      // Measured: `fwup_progress` rests at 100 after `fwupd -m 1` and at 0 after
      // `-m 3`. Both are ordinary idle, so no value of it means "finished" — a
      // bar at 100% here would report a completed install that never ran.
      feed([_at('0', 100)]);

      final result =
          await buildService().install(otaInstance: 3, onProgress: emitted.add);

      expect(result.verdict, FirmwareOtaInstallVerdict.idle);
      expect(emitted.map((p) => p.percent), everyElement(isNull));
    });

    test('(1,57) is checking, and 57 appears nowhere', () async {
      // The check phase drives `fwup_progress` in one measured run and holds it at
      // 0 in another. A spinner is the only honest rendering, so `percent` is null
      // even though a number is present.
      //
      // The leading 0 is the pre-dispatch reading, and every install-path sequence
      // here has one for the same reason the router does: `fwupd` is spawned in the
      // background, so the first read back is whatever the last run left. It is
      // held rather than published — see the leftover-5 test below — so a sequence
      // that opened on the reading it wanted to assert would be asserting about a
      // reading this service is required to ignore.
      feed([_at('0'), _at('1', 57), _at('1', 57), _at('0', 57)]);

      await buildService().install(otaInstance: 3, onProgress: emitted.add);

      expect(emitted.first.status, FirmwareAutoUpdateStatus.checking);
      expect(emitted.first.rawProgress, 57);
      expect(emitted.map((p) => p.percent), everyElement(isNull));
    });

    test('1/0 → 1/100 → 3/0 → 3/45 → 4/x never goes backwards from 100%',
        () async {
      // `AutoActivate="true"` is `fwupd -m 2`: check, then download, then flash.
      // So `fwup_progress` runs 0→100 twice for one install, and the check's 100
      // must not be shown at all — otherwise the download's 0 reads as a bar
      // falling off a cliff.
      // The trailing 0 is the reboot arriving as a state change rather than as a
      // dropped connection; it ends the loop so the emitted list is the whole of
      // what a bar would have been asked to draw, not a prefix of it.
      feed([
        _at('0', 0),
        _at('1', 0),
        _at('1', 100),
        _at('3', 0),
        _at('3', 45),
        _at('4', 0),
        _at('0', 100),
      ]);

      final result =
          await buildService().install(otaInstance: 3, onProgress: emitted.add);

      expect(emitted.map((p) => p.percent).toList(),
          [null, null, 0, 45, null, null]);
      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('1/0 → 1/100 → 0/100 says so, instead of getting stuck installing',
        () async {
      // The boundary `AutoActivate="true"` creates: mode 2 checks first, and its
      // check can disagree with the version we showed. The dispatch was accepted,
      // nothing was downloaded, and the caller has to be able to say that rather
      // than sit on a progress bar until the ceiling.
      feed([_at('1', 0), _at('1', 100), _at('0', 100)]);

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.idle);
    });

    test('a state 0 seen before the router has started is not an answer',
        () async {
      // `fwupd` is spawned in the background, so the first read after a dispatch
      // routinely still says 0. Concluding "nothing to install" there would make
      // every install report failure on a fast poll.
      feed([_at('0'), _at('0'), _at('1'), _at('3', 10)]);

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('the 5 left behind by the last update is not this one\'s failure',
        () async {
      // The bug the grace was written for and originally missed. `fwup_state` is a
      // persistent sysevent scalar — it is not cleared per run — so a router whose
      // previous update failed sits at 5 until the next one moves it. A grace that
      // only forgave 0 therefore reported `failed` on the *first poll of every
      // install* on such a router, about a second in, while `fwupd` went on to
      // download, flash and reboot underneath a card reading "Update Failed". And
      // it would have done it again on every retry, because nothing about the
      // router changes to break the loop.
      feed([_at('5'), _at('5'), _at('1'), _at('3', 10)]);

      final result =
          await buildService().install(otaInstance: 3, onProgress: emitted.add);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
      // And the stale value is not merely un-concluded-from, it is unpublished:
      // one `failed` reading reaching the notifier is enough to paint the failure
      // card, whatever the verdict eventually says.
      expect(emitted.map((p) => p.status),
          isNot(contains(FirmwareAutoUpdateStatus.failed)));
    });

    test('the 3 left behind by the last update draws no progress bar',
        () async {
      // The same staleness one layer up. A router interrupted mid-download rests
      // at 3, and publishing that reading would promote the phase to `installing`
      // and draw a download that has not started — with a percentage taken from
      // whatever `fwup_progress` the interrupted run stopped at.
      feed([_at('3', 62), _at('3', 62), _at('1', 0), _at('3', 5)]);

      await buildService().install(otaInstance: 3, onProgress: emitted.add);

      // First published reading is the check, not the leftover 62%.
      expect(emitted.first.status, FirmwareAutoUpdateStatus.checking);
      expect(emitted.map((p) => p.rawProgress), isNot(contains(62)));
    });

    test('a leftover 5 that outlasts the grace is this install\'s failure',
        () async {
      // The other side of it. After the grace an unchanged value stands on its
      // own — a dispatch that never moved `fwup_state` at all has to end
      // somewhere, and reporting the router's own last word beats a twenty-minute
      // spinner.
      feed([_at('5')]);

      final result = await buildService(
        startupGrace: const Duration(milliseconds: 10),
        ceiling: const Duration(seconds: 5),
      ).install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.failed);
    });

    test('a leftover 1 does not let the next 0 mean "no update found"',
        () async {
      // The asymmetry in what a held-back reading is allowed to record. A stale 1
      // is auto-update running its own check when we dispatched; if that reading
      // set `sawChecking`, the 0 that follows it would satisfy the idle arm's
      // "checked and found nothing" condition *inside* the grace, and the install
      // would report "no update found" before `fwupd` had started — the leftover-5
      // bug with one more step in it.
      feed([_at('1'), _at('0'), _at('1'), _at('3', 10)]);

      final result = await buildService(
        startupGrace: const Duration(seconds: 5),
        ceiling: const Duration(milliseconds: 400),
      ).install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('a leftover 4 still buys the disconnect the benefit of the doubt',
        () async {
      // The other half of the asymmetry. The dispatch can land on a router already
      // flashing — auto-update beating us by a second, or the page opened mid-flash
      // before `observe` had read anything — and the reading that says so is held
      // back as stale. It must still record `sawBusy`, because the very next event
      // on a flashing router is the reboot taking the connection with it, and REQ-A6
      // is that this reads as the reboot rather than as "your router is
      // unreachable" at the moment it is doing what was asked.
      var reads = 0;
      when(() => firmware.fetchAutoUpdate()).thenAnswer((_) async {
        reads++;
        if (reads == 1) return _at('4', 0);
        throw NetworkError();
      });

      final result = await buildService(
        startupGrace: const Duration(seconds: 5),
      ).install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('a state that moves inside the grace is acted on at once', () async {
      // The grace is keyed on the value being *unchanged*, not on the clock: a
      // router that answers the dispatch in 200ms must not have its first real
      // reading held back for the remaining 14.8s.
      feed([_at('0'), _at('5')]);

      final result = await buildService(
        startupGrace: const Duration(seconds: 30),
        ceiling: const Duration(seconds: 5),
      ).install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.failed);
    });

    test('a state 0 that outlasts the grace is an answer', () async {
      // The other side of the same compromise, and the same one the check makes:
      // the checking window is under a second, so a check that finds nothing is
      // routinely invisible between two polls. After the grace, an idle router is
      // an idle router.
      feed([_at('0')]);

      final result = await buildService(
        startupGrace: const Duration(milliseconds: 10),
        ceiling: const Duration(seconds: 5),
      ).install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.idle);
    });

    test('progress within one state never falls', () async {
      feed([
        _at('0'),
        _at('3', 40),
        _at('3', 10),
        _at('3', 60),
        _at('4'),
        _at('0')
      ]);

      await buildService().install(otaInstance: 3, onProgress: emitted.add);

      expect(emitted.map((p) => p.percent).toList(), [40, 40, 60, null, null]);
    });
  });

  group('the ways it ends', () {
    test('fwup_state 5 is a failure that keeps the number', () async {
      feed([_at('3', 30), _at('5', 30)]);

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.failed);
      // REQ-A7: the raw value is retrievable from the result, so a failure can
      // report what the router said rather than a rounded-off app word.
      expect(result.rawState, '5');
      expect(result.lastProgress?.rawProgress, 30);
    });

    test('a read that fails after the router got busy is the reboot', () async {
      // REQ-A6. The flash takes the connection with it, so the disconnect *is*
      // the expected next event — surfacing it as a connection error would tell
      // the user their router is unreachable at the exact moment it is doing what
      // they asked.
      var reads = 0;
      when(() => firmware.fetchAutoUpdate()).thenAnswer((_) async {
        reads++;
        if (reads <= 2) return _at('4', 0);
        throw NetworkError();
      });

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('a read that fails before it got busy is a real error', () async {
      // The same exception, and the opposite verdict, because nothing has been
      // observed that would explain it. Swallowing this one would turn an
      // unreachable router into a firmware update the user is told to wait for.
      when(() => firmware.fetchAutoUpdate()).thenThrow(NetworkError());

      await expectLater(
        buildService().install(otaInstance: 3),
        throwsA(isA<NetworkError>()),
      );
    });

    test('a read that fails while only checking is also a real error',
        () async {
      var reads = 0;
      when(() => firmware.fetchAutoUpdate()).thenAnswer((_) async {
        reads++;
        if (reads == 1) return _at('1');
        throw NetworkError();
      });

      await expectLater(
        buildService().install(otaInstance: 3),
        throwsA(isA<NetworkError>()),
      );
    });

    test('cmd_failure is a refusal, not an install in progress', () async {
      feed([_at('0')]);
      watch.emit(const OperateResult(
        commandName: 'Download()',
        commandKey: 'install-key-1',
        status: 'Error',
        outputArgs: {},
        errorCode: '7022',
        errorMessage: 'Command failure',
      ));

      await expectLater(
        buildService().install(otaInstance: 3),
        throwsA(isA<ServiceError>()),
      );
    });

    test('another command\'s cmd_failure is not this install\'s', () async {
      feed([_at('3', 10)]);
      watch.emit(const OperateResult(
        commandName: 'Download()',
        commandKey: 'some-other-key',
        status: 'Error',
        outputArgs: {},
        errorCode: '7022',
      ));

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('an ordinary OperationComplete is not a refusal', () async {
      feed([_at('3', 10)]);
      // What the bench produces 49ms in: acceptance. Reading it as a result would
      // end the watch before the router had started.
      watch.emit(const OperateResult(
        commandName: 'Download()',
        commandKey: 'install-key-1',
        status: 'Requested',
        outputArgs: {'Status': 'Requested'},
      ));

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('the ceiling ends a router that never got past checking', () async {
      feed([_at('1')]);

      final result = await buildService(
        ceiling: const Duration(milliseconds: 30),
      ).install(otaInstance: 3);

      // Not `idle`. Nothing concluded, and saying "no update found" on a timeout
      // is the substitution this whole feature is written to avoid.
      expect(result.verdict, FirmwareOtaInstallVerdict.timedOut);
      expect(result.rawState, '1');
    });

    test('the ceiling on a busy router hands over to the reboot wait',
        () async {
      feed([_at('4')]);

      final result = await buildService(
        ceiling: const Duration(milliseconds: 30),
      ).install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('an unrecognised state keeps polling and never reads as idle',
        () async {
      // REQ-A7's extension room. A sixth `fwup_state` must not stop the loop and
      // must not be reported as "nothing is happening".
      feed([_at('7'), _at('7'), _at('3', 5)]);

      final result = await buildService().install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
    });

    test('an unrecognised state that outlasts the ceiling times out', () async {
      feed([_at('7')]);

      final result = await buildService(
        ceiling: const Duration(milliseconds: 30),
      ).install(otaInstance: 3);

      expect(result.verdict, FirmwareOtaInstallVerdict.timedOut);
      expect(result.rawState, '7');
    });

    test('the caller can stop it, and it stops reading', () async {
      // The termination condition for "the user left the page". The notifier owns
      // the flag; what is asserted here is that the loop asks before every read,
      // so leaving does not leave a poller running against a rebooting router.
      var reads = 0;
      var cancelled = false;
      when(() => firmware.fetchAutoUpdate()).thenAnswer((_) async {
        reads++;
        if (reads >= 2) cancelled = true;
        return _at('3', reads);
      });

      final result = await buildService(ceiling: const Duration(seconds: 5))
          .install(otaInstance: 3, isCancelled: () => cancelled);

      expect(result.verdict, FirmwareOtaInstallVerdict.abandoned);
      expect(reads, 2);
    });
  });

  group('observing an update nobody in this app started', () {
    test('reads the state without dispatching anything', () async {
      // REQ-A6. Auto-update can start a flash on its own, and the page may be
      // opened in the middle of one. Dispatching here would start a *second*
      // install on a router already flashing.
      feed([_at('3', 20), _at('4', 0)]);

      final result = await buildService().observe(onProgress: emitted.add);

      expect(result.verdict, FirmwareOtaInstallVerdict.flashing);
      verifyNever(() =>
          firmware.requestOtaInstall(otaInstance: any(named: 'otaInstance')));
      expect(emitted.first.percent, 20);
    });

    test('takes its first reading immediately', () async {
      // Unlike the install, which waits for `fwupd` to be spawned. Here the
      // router is already busy and the page has nothing to draw until the first
      // read lands, so a poll interval spent waiting is a poll interval of blank
      // screen.
      feed([_at('3', 20)]);

      await buildService(
        busyPollInterval: const Duration(seconds: 30),
        ceiling: const Duration(milliseconds: 200),
      ).observe(onProgress: emitted.add);

      expect(emitted, isNotEmpty);
    });

    test('an idle router is idle, with no grace period', () async {
      // The grace exists to cover a dispatch the router has not acted on yet.
      // Nothing was dispatched here, so a state of 0 means the update ended
      // between the page opening and the first read — and the page needs to stop
      // showing progress at once.
      feed([_at('0')]);

      final result = await buildService(
        startupGrace: const Duration(seconds: 30),
        ceiling: const Duration(seconds: 5),
      ).observe();

      expect(result.verdict, FirmwareOtaInstallVerdict.idle);
    });

    test('subscribes to nothing, because it dispatched nothing', () async {
      // No `commandKey` exists to match a refusal against, so there is nothing
      // this flow could do with the channel. Opening one would leave a
      // subscription on the router for the length of a flash to no purpose.
      feed([_at('0')]);

      await buildService().observe();

      verifyNever(() => awaiter.watchOperationComplete(
          referencePath: any(named: 'referencePath')));
    });

    test('a failed update is reported, not swallowed', () async {
      feed([_at('5')]);

      final result = await buildService().observe();

      expect(result.verdict, FirmwareOtaInstallVerdict.failed);
      expect(result.rawState, '5');
    });
  });

  group('the polling cadence', () {
    test('is slower once the router is busy than while it is checking',
        () async {
      // Asserted as an inequality on purpose. The requirement is 1s while
      // checking and 2s while downloading — pinned as constants below — but
      // measuring a wall-clock gap in a unit test measures the machine. What is
      // worth proving here is that the two intervals are used for the states they
      // belong to, i.e. that the loop switches at all.
      Future<int> readsIn(String state) async {
        var reads = 0;
        when(() => firmware.fetchAutoUpdate()).thenAnswer((_) async {
          reads++;
          return _at(state, 1);
        });
        await buildService(
          checkingPollInterval: const Duration(milliseconds: 1),
          busyPollInterval: const Duration(milliseconds: 40),
          ceiling: const Duration(milliseconds: 200),
        ).install(otaInstance: 3);
        return reads;
      }

      expect(await readsIn('1'), greaterThan(await readsIn('3')));
    });

    test('the production numbers are pinned', () {
      // 1s while checking: the phase is measured to last 1–2 seconds, so a slower
      // poll would routinely miss it entirely and the check would look like a
      // router doing nothing.
      expect(FirmwareRouterOtaInstallService.defaultCheckingPollInterval,
          const Duration(seconds: 1));
      // 2s while downloading or flashing: the phase lasts minutes, and every read
      // is bridge traffic to a router that is busy writing NAND.
      expect(FirmwareRouterOtaInstallService.defaultBusyPollInterval,
          const Duration(seconds: 2));
      // 15s of grace: covers a check that takes longer than the bench's 1–2s on a
      // slow WAN. Too short reports "nothing to install" while the router is
      // still asking.
      expect(FirmwareRouterOtaInstallService.defaultStartupGrace,
          const Duration(seconds: 15));
      // 20 minutes of ceiling: an OTA image over a slow uplink plus the flash.
      // The loop must have an upper bound — a poller with none outlives the page
      // that started it.
      expect(FirmwareRouterOtaInstallService.defaultCeiling,
          const Duration(minutes: 20));
    });
  });
}
