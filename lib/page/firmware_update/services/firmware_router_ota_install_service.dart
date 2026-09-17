import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/helpers/firmware_operation_watch.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

/// Dispatches one install and returns the `commandKey` that names it.
typedef OtaInstallDispatcher = Future<String> Function(
    {required int otaInstance});

/// Reads `fwup_state` / `fwup_progress` / `autoupdate_flags` in one round trip.
typedef FirmwareAutoUpdateReader = Future<FirmwareAutoUpdateUIModel> Function();

/// Where the update has got to, once per poll.
typedef FirmwareOtaInstallProgressSink = void Function(
    FirmwareOtaInstallProgress progress);

final firmwareRouterOtaInstallServiceProvider =
    Provider<FirmwareRouterOtaInstallService>((ref) {
  final firmware = ref.read(uspFirmwareUpdateServiceProvider);
  return FirmwareRouterOtaInstallService(
    dispatchInstall: firmware.requestOtaInstall,
    readAutoUpdate: firmware.fetchAutoUpdate,
    awaiter: ref.read(sseOperationAwaiterProvider),
    lock: ref.read(uspMutationLockProvider),
  );
});

/// Asks the router to install a newer firmware, and watches it happen.
///
/// The dispatch is [FirmwareRouterOtaCheckService]'s with `AutoActivate` flipped —
/// same `Download`, same virtual `ota` instance, same absent URL. Everything after
/// it is different, because of one property of this flow: **there is no completion
/// signal.** `Download(ota,"true")` is `fwupd -m 2`, which checks, downloads,
/// flashes and then reboots, so the successful end of an install is the router
/// disappearing. Nothing arrives to say it worked.
///
/// That shapes all three of the decisions here:
///
/// * **State is polled, never subscribed.** `fwup_state` lives under
///   `Device.X_LINKSYS_Sysevent.`, and a `ValueChange` subscription on that subtree
///   was measured delivering **zero** notifications while the value went 0→1→0 —
///   these are sysevents behind a dm-reflector, and notification there is itself
///   sampled. So the app samples, and the app owns the clock.
/// * **The disconnect is an expected outcome, not an error.** Once `fwup_state` has
///   reached 3 or 4 a failing read means the reboot has started, and the caller is
///   told [FirmwareOtaInstallVerdict.flashing] rather than being handed a
///   `NetworkError` about an unreachable router (REQ-A6). Before that point the
///   same exception is a real one and is rethrown, because nothing has been
///   observed that would explain it.
/// * **The loop has a termination condition and a ceiling**, both required: a
///   poller with neither outlives the page that started it and keeps reading
///   against a router that is rebooting.
///
/// `OperationComplete` is still used, for the one thing it can say. It arrives in
/// ~49 ms — long before anything has happened — so it cannot report a result; but
/// `cmd_failure` travels on that channel and no other, and on an install a refusal
/// nobody notices reads as a flash in progress for the full ceiling.
///
/// **It is handed two functions, not the service they come off.** Unlike the check,
/// the point is not to hide the install verb — this class is the install. What the
/// two fields exclude is everything else on [UspFirmwareUpdateService], and one
/// member in particular: this flow reads `autoupdate_flags` on every single poll
/// (it arrives in the same `Get`), and `setAutoUpdatePolicy` would let a reading
/// loop turn into a writing one. It settles constitution Article VI §6.2 as a side
/// effect.
class FirmwareRouterOtaInstallService {
  final OtaInstallDispatcher _dispatchInstall;
  final FirmwareAutoUpdateReader _readAutoUpdate;
  final SseOperationAwaiter? _awaiter;
  final UspMutationLock _lock;
  final Duration _checkingPollInterval;
  final Duration _busyPollInterval;
  final Duration _startupGrace;
  final Duration _ceiling;

  /// Gap between reads while `fwup_state` is 1 (or has not moved yet).
  ///
  /// One second because the checking phase is measured at 1–2 s. A slower poll
  /// misses it entirely on a healthy router, and a phase the app never sees is a
  /// phase whose spinner never appears.
  static const Duration defaultCheckingPollInterval = Duration(seconds: 1);

  /// Gap between reads while `fwup_state` is 3 or 4.
  ///
  /// Two seconds because these phases last minutes, and each read is bridge
  /// traffic to a router that is downloading an image and writing NAND.
  static const Duration defaultBusyPollInterval = Duration(seconds: 2);

  /// How long the value the router *already had* is allowed to mean "not started
  /// yet".
  ///
  /// `fwupd` is spawned in the background, so the first read after a dispatch
  /// routinely still holds whatever the last run left behind; concluding from it
  /// would answer with the previous update's outcome. The other end of the
  /// compromise is the same one the check makes: the checking phase can finish
  /// between two polls, so after this window the value stands on its own.
  ///
  /// **The window covers every unchanged value, not just 0**, and that is the
  /// difference between this working and appearing to. `fwup_state` is a persistent
  /// sysevent scalar — it is not cleared per run, so a router interrupted mid-update
  /// sits at 3 or 4 indefinitely, and gating only 0 meant the first poll of *every*
  /// install on such a router concluded from the previous run's value about a second
  /// in, while `fwupd` went on underneath the card it had already drawn.
  ///
  /// **And the baseline it compares against has to predate the dispatch**, which is
  /// the other half and was missing until 2026-09-16. Taken from the watch's own
  /// first read it does not: the dispatch returned in 34 ms and `fwupd` had already
  /// moved to 1, so the baseline captured this run's own value and the window then
  /// suppressed the whole 6.5 s `checking` phase for being "unchanged". `install()`
  /// therefore reads `fwup_state` before it dispatches and hands the value in.
  ///
  /// Fifteen seconds is the check's own 10 s deadline plus room for a slow OTA
  /// server. `linksys.fwup.lastsuccess_checktime` is the anchor that would replace
  /// this with an actual answer; it exists in the sysevent store and is not exposed
  /// in the data model (contract request 6 on #1547).
  static const Duration defaultStartupGrace = Duration(seconds: 15);

  /// The upper bound on watching one update.
  ///
  /// Twenty minutes covers an OTA image over a slow uplink plus the flash. Hitting
  /// it is not a failure by itself — a router still busy at the ceiling is handed
  /// over as [FirmwareOtaInstallVerdict.flashing] — the bound exists so the loop
  /// cannot run forever.
  static const Duration defaultCeiling = Duration(minutes: 20);

  FirmwareRouterOtaInstallService({
    required OtaInstallDispatcher dispatchInstall,
    required FirmwareAutoUpdateReader readAutoUpdate,
    required SseOperationAwaiter? awaiter,
    required UspMutationLock lock,
    Duration checkingPollInterval = defaultCheckingPollInterval,
    Duration busyPollInterval = defaultBusyPollInterval,
    Duration startupGrace = defaultStartupGrace,
    Duration ceiling = defaultCeiling,
  })  : _dispatchInstall = dispatchInstall,
        _readAutoUpdate = readAutoUpdate,
        _awaiter = awaiter,
        _lock = lock,
        _checkingPollInterval = checkingPollInterval,
        _busyPollInterval = busyPollInterval,
        _startupGrace = startupGrace,
        _ceiling = ceiling;

  /// The TR-181 subtree whose `OperationComplete` events belong to this install.
  static const String _referencePath = 'Device.DeviceInfo.FirmwareImage.';

  /// Start an install on [otaInstance] and watch it until it stops being watchable.
  ///
  /// [onProgress] is called once per poll, monotonically within a phase. Returning
  /// [FirmwareOtaInstallVerdict.flashing] means the router is committed and the
  /// caller should wait for it to come back; **it does not mean the update
  /// succeeded** — `verify()` after the reboot is what says that.
  ///
  /// [isCancelled] is asked once per poll — at the top, *before* the wait rather
  /// than after it, so a page that goes away during a two-second sleep costs one
  /// more `Get` and no more — and is how "the user left the page" terminates the
  /// loop. Throws for a refusal, and for a read failure that happens before the
  /// router was ever seen to be busy.
  Future<FirmwareOtaInstallResult> install({
    required int otaInstance,
    FirmwareOtaInstallProgressSink? onProgress,
    bool Function()? isCancelled,
  }) async {
    // Before the dispatch, not after: the refusal is measured ~49 ms in and this
    // is the only channel it appears on.
    final watch = await openOperationCompleteWatch(_awaiter,
        referencePath: _referencePath);
    // Also before the dispatch, and for a reason measured the hard way: the
    // baseline the grace compares against has to predate the thing it is a
    // baseline for. Taking it from the watch's own first read does not — on
    // 2026-09-16 the dispatch returned in **34 ms** and `fwupd` had already moved
    // `fwup_state` to 1, so the first poll a second later captured 1 as "the value
    // before the dispatch" and then suppressed the whole 6.5 s `checking` phase as
    // unchanged. The user saw nothing happen, twice over.
    //
    // Best-effort on purpose. A router that cannot answer this read is about to
    // fail the dispatch or the first poll anyway, and neither is worth turning a
    // diagnostic read into a hard failure over — a null simply restores the old
    // behaviour for that one run.
    String? stateBeforeDispatch;
    try {
      stateBeforeDispatch = (await _readAutoUpdate()).rawState;
    } catch (e) {
      logger.d('[FirmwareUpdate] could not read fwup_state before dispatching '
          'the install, so the startup grace has no baseline ($e)');
    }
    try {
      // The lock, and only around the dispatch. The poll loop below is `Get`s,
      // which nothing in this codebase locks — and holding the lock across a loop
      // that may run for twenty minutes would block every other mutation in the
      // app and sit under the lock's own 30 s timeout.
      final String commandKey;
      try {
        commandKey = await _lock.withLock(
          () => _dispatchInstall(otaInstance: otaInstance),
        );
      } on TimeoutException catch (e) {
        // Mapped here because here is the layer that is allowed to (constitution
        // Article XIII §13.3), and because nothing above can see it coming:
        // `UspMutationLock` throws a bare `TimeoutException`, deliberately not a
        // `ServiceError`, so every `on ServiceError` between this line and the
        // button was blind to it. The dispatch would appear to do nothing for 30 s,
        // leave no failure card, and then escape an unawaited `onTap` as an
        // uncaught async error.
        throw TimeoutError(
          detail: 'another router mutation was still running when the firmware '
              'install was dispatched (${e.message ?? '30s'})',
        );
      }

      // Raced, not awaited. A refusal usually never comes, so this future is
      // allowed to stay pending for the life of the install and is dropped on
      // release.
      OperateResult? refusal;
      final refusalWatch = watch
          ?.firstWhere((r) => r.commandKey == commandKey && r.isFailure)
          .then((r) => refusal = r);
      if (refusalWatch != null) unawaited(refusalWatch);

      return await _watch(
        refusal: () => refusal,
        otaInstance: otaInstance,
        stateBeforeDispatch: stateBeforeDispatch,
        // A state of 0 right after the dispatch means `fwupd` has not started
        // yet, so the first reading cannot be an answer.
        graceFor: _startupGrace,
        // And for the same reason the first read waits: reading before the
        // router can have acted spends a round trip to learn nothing.
        delayBeforeFirstRead: true,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
    } finally {
      await watch?.release();
    }
  }

  /// Watch an update this app did not start (REQ-A6).
  ///
  /// Auto-update can begin a flash on its own, and the OTA page can be opened in
  /// the middle of one, so the progress the page shows must not depend on having
  /// dispatched it. Three things differ from [install]:
  ///
  /// * **nothing is dispatched** — starting a second install on a router already
  ///   flashing is the failure this entry point exists to prevent;
  /// * **no subscription is opened** — there is no `commandKey` to match a refusal
  ///   against, so the channel could say nothing, and opening one would leave a
  ///   subscription on the router for the length of a flash to no purpose;
  /// * **no grace, and the first read is immediate** — the grace covers a dispatch
  ///   the router has not acted on, which cannot apply here; and the page has
  ///   nothing to draw until a reading lands.
  Future<FirmwareOtaInstallResult> observe({
    FirmwareOtaInstallProgressSink? onProgress,
    bool Function()? isCancelled,
  }) =>
      _watch(
        refusal: () => null,
        otaInstance: null,
        graceFor: Duration.zero,
        delayBeforeFirstRead: false,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );

  /// The poll loop both entry points share.
  Future<FirmwareOtaInstallResult> _watch({
    required OperateResult? Function() refusal,
    required int? otaInstance,
    required Duration graceFor,
    required bool delayBeforeFirstRead,
    String? stateBeforeDispatch,
    FirmwareOtaInstallProgressSink? onProgress,
    bool Function()? isCancelled,
  }) async {
    final startedAt = DateTime.now();
    final giveUpAt = startedAt.add(_ceiling);
    final graceEndsAt = startedAt.add(graceFor);

    var sawChecking = false;
    var sawBusy = false;
    var isFirstRead = true;
    var interval = _checkingPollInterval;
    FirmwareOtaInstallProgress? last;

    /// The value `fwup_state` already held before this run could have moved it.
    ///
    /// How a reading is told from an answer. See [defaultStartupGrace] — the
    /// parameter is persistent, so until it *changes* it is still describing the
    /// previous run. Inert on the observe path, where [graceFor] is zero, so the
    /// window is shut before the first read lands.
    ///
    /// Seeded from [stateBeforeDispatch] when the caller has it, and that is the
    /// whole correctness of it: the fallback below captures the *first poll after
    /// the dispatch*, which on a router that starts checking in 34 ms is already
    /// this run's own value. Suppressing that is how a real phase went missing.
    String? stateOnArrival = stateBeforeDispatch;

    FirmwareOtaInstallResult ending(FirmwareOtaInstallVerdict verdict) =>
        FirmwareOtaInstallResult(
          verdict: verdict,
          rawState: last?.rawState ?? '',
          lastProgress: last,
        );

    while (DateTime.now().isBefore(giveUpAt)) {
      if (isCancelled?.call() ?? false) {
        logger
            .d('[FirmwareUpdate] stopped watching the OTA install on request');
        return ending(FirmwareOtaInstallVerdict.abandoned);
      }

      if (delayBeforeFirstRead || !isFirstRead) {
        // Clamped to the ceiling rather than slept blind. The busy interval is
        // two seconds against a twenty-minute bound so it makes no practical
        // difference here — but a loop that can sleep past its own deadline has a
        // real upper bound of `ceiling + interval`, and the next caller to shorten
        // one of the two is the one who finds out.
        final remaining = giveUpAt.difference(DateTime.now());
        if (remaining <= Duration.zero) break;
        await Future<void>.delayed(interval < remaining ? interval : remaining);
      }
      isFirstRead = false;

      _throwIfRefused(refusal(), otaInstance);

      final FirmwareAutoUpdateUIModel reading;
      try {
        reading = await _readAutoUpdate();
      } on ServiceError catch (e) {
        // The update's own reboot, or a router that is genuinely unreachable —
        // and the difference is what we have already seen it doing. Only a router
        // observed downloading or flashing gets the benefit of the doubt.
        if (!sawBusy) rethrow;
        logger.i('[FirmwareUpdate] lost the router while it was flashing — '
            'treating it as the reboot (${e.runtimeType})');
        return ending(FirmwareOtaInstallVerdict.flashing);
      }

      stateOnArrival ??= reading.rawState;

      // Nothing this reading says is about this run yet, so nothing is concluded
      // from it and nothing is published. See [defaultStartupGrace]: `fwup_state`
      // is persistent, so a value that has not moved since the dispatch is still
      // the previous update's, and the previous update's 5 read as this one's
      // failure about a second in. Publishing it would be the same mistake one
      // layer up — a stale 3 promotes the phase to `installing` and draws a
      // download that has not started, at whatever percentage the interrupted run
      // stopped at.
      //
      // `last == null` is what makes this "still" rather than "again": it holds
      // only until the first reading is published, so the *first change* ends the
      // window whatever the clock says. Comparing against the arrival value alone
      // would re-gate a genuine 3→0, and waiting out the full grace would delay a
      // router that answered in 200ms.
      if (last == null &&
          reading.rawState == stateOnArrival &&
          DateTime.now().isBefore(graceEndsAt)) {
        // Recorded even though the reading is not this run's, because of what the
        // flag licenses: only "a disconnect or an idle from here is the reboot".
        // Every use of it keeps the user waiting instead of claiming an outcome,
        // which is the right bias when an install is dispatched onto a router
        // already at 3 or 4 — auto-update beating us to it by a second, or the
        // page opened mid-flash before `observe` had read anything. Getting this
        // wrong the other way tells the user their update failed while the router
        // is writing NAND (REQ-A6).
        //
        // `sawChecking` is deliberately not recorded here, and the asymmetry is
        // the point: that one licenses concluding `idle` *inside* the grace, so a
        // stale 1 would let the next 0 report "no update found" before `fwupd` had
        // started — the original bug with an extra step.
        if (reading.status == FirmwareAutoUpdateStatus.downloading ||
            reading.status == FirmwareAutoUpdateStatus.installing) {
          sawBusy = true;
        }
        logger.d('[FirmwareUpdate] fwup_state is still ${reading.rawState} — '
            'the value it had before the dispatch, so waiting rather than '
            'reporting it');
        continue;
      }

      last = last == null
          ? FirmwareOtaInstallProgress.from(reading)
          : last.advancedTo(reading);
      onProgress?.call(last);

      switch (reading.status) {
        // The router has written the image and is going to reboot. `flashing` is
        // exactly that verdict, so this arm ends the watch on the same path the
        // dropped connection and the post-flash `0` already ended on: wait for the
        // router, then let `verify()` say whether it came back on the new build.
        //
        // Until 2026-09-16 this arm read `failed` and returned
        // `FirmwareOtaInstallVerdict.failed` — see
        // [FirmwareAutoUpdateStatus.rebooting]. It reported every successful
        // install as a failure, and the user saw it on the one run that ever
        // reached this state.
        case FirmwareAutoUpdateStatus.rebooting:
          sawBusy = true;
          logger
              .i('[FirmwareUpdate] the router is rebooting into the new image '
                  '(fwup_state=${reading.rawState})');
          return ending(FirmwareOtaInstallVerdict.flashing);

        case FirmwareAutoUpdateStatus.checking:
          sawChecking = true;
          interval = _checkingPollInterval;

        case FirmwareAutoUpdateStatus.downloading:
        case FirmwareAutoUpdateStatus.installing:
          sawBusy = true;
          interval = _busyPollInterval;

        // Never treated as idle and never thrown on: a firmware that grows a
        // sixth `fwup_state` must keep the progress UI running rather than
        // report that nothing is happening (REQ-A7). It polls on the slower
        // cadence because an unknown state is more likely to be a long phase
        // than a fast one.
        case FirmwareAutoUpdateStatus.unknown:
          interval = _busyPollInterval;

        case FirmwareAutoUpdateStatus.idle:
          // Busy first: a state that has dropped back to 0 after a flash began is
          // reported as the reboot rather than as an install that evaporated.
          //
          // This is **not** because 0 can only mean the reboot — measured
          // 2026-09-16, a failure lands on 0 too, with `fwup_progress` left at 100
          // (see [FirmwareAutoUpdateStatus]). It is because the two are
          // indistinguishable here and only one of them is safe to claim: telling
          // a user their update failed while the router is writing NAND is the
          // worse mistake, and `verify()` separates them a minute later by
          // comparing versions. So this arm buys time rather than an answer, and
          // `FirmwareFailure.bootedOldImage` is where a real flash failure is
          // finally reported.
          if (sawBusy) return ending(FirmwareOtaInstallVerdict.flashing);
          // Mode 2 checks before it downloads, so an accepted dispatch can end
          // here: the router's own check disagreed with the version we offered.
          if (sawChecking || !DateTime.now().isBefore(graceEndsAt)) {
            return ending(FirmwareOtaInstallVerdict.idle);
          }
        // Otherwise still inside the grace — keep looking.
      }
    }

    // The ceiling. A router still busy is handed to the reboot wait; one that
    // never got past checking has concluded nothing, and saying "no update found"
    // for it is the substitution this feature exists to avoid.
    logger.w('[FirmwareUpdate] stopped watching the OTA install after '
        '${_ceiling.inMinutes}min (fwup_state=${last?.rawState ?? 'unread'})');
    return ending(sawBusy
        ? FirmwareOtaInstallVerdict.flashing
        : FirmwareOtaInstallVerdict.timedOut);
  }

  void _throwIfRefused(OperateResult? refusal, int? otaInstance) {
    if (refusal == null) return;
    throw UspCompleteFailureError(
      summary: 'The router refused the firmware install on instance '
          '$otaInstance (${refusal.errorCode}'
          '${refusal.errorMessage != null ? ': ${refusal.errorMessage}' : ''})',
      failures: const [],
    );
  }
}
