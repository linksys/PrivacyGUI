import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/helpers/firmware_operation_watch.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

/// Dispatches one check and returns the `commandKey` that names it.
typedef OtaCheckDispatcher = Future<String> Function(
    {required int otaInstance});

/// Reads every firmware image row the router publishes.
typedef FirmwareImagesReader = Future<List<FirmwareImageUIModel>> Function();

final firmwareRouterOtaCheckServiceProvider =
    Provider<FirmwareRouterOtaCheckService>((ref) {
  final firmware = ref.read(uspFirmwareUpdateServiceProvider);
  return FirmwareRouterOtaCheckService(
    dispatchCheck: firmware.requestOtaCheck,
    readImages: firmware.fetchAllBanks,
    readAutoUpdate: firmware.fetchAutoUpdate,
    awaiter: ref.read(sseOperationAwaiterProvider),
    lock: ref.read(uspMutationLockProvider),
  );
});

/// Asks the router whether a newer firmware exists.
///
/// **This replaced a direct call to the Linksys cloud OTA API — the app's call, not
/// the cloud.** The router's `fwupd` is the client of that server now, which is why
/// the `Download()` below carries no URL: on the virtual `ota` instance the router
/// ignores it and resolves the OTA server itself. Read "off the cloud" anywhere in
/// this feature as "off *our* call to the cloud"; a new image still arrives from it.
///
/// The router answers in the data model rather than in the response: `Download()`
/// on the virtual `ota` instance returns as soon as it has been accepted, and the
/// answer appears a second or two later as `FirmwareImage.{ota}.Available` /
/// `.Version`. So the shape here is dispatch, then poll the two parameters.
///
/// Three signals exist and each one answers a different question. This service
/// uses two of them and deliberately ignores the third:
///
/// * the operate response's `commandKey` — **was the command dispatched.** The
///   only thing it can tell us, since an Operate on a command that does not exist
///   also answers success. [UspFirmwareUpdateService.requestOtaCheck] throws when
///   it is missing.
/// * `OperationComplete` — **was the command refused.** It arrives in ~49 ms,
///   long before the router has finished looking, so it cannot be read as a
///   result; but `cmd_failure` travels on this channel and no other.
/// * `fwup_state` — **unused.** It goes to `1` for under a second; a 300 ms poll
///   caught that in exactly one sample, and most runs would miss it entirely, so
///   a check that waited for `1` would hang far more often than it worked. The
///   call's own lifecycle is the clock instead.
/// * `FirmwareImage.{ota}.Status` — **the phase, and the completion marker.** Added
///   by `linksys/usp_framework#66`, and it is the second of the three things contract
///   request 6 on #1547 asked for: while `fwupd` is querying the server the ota row
///   reads `Checking`, so a `Checking` that has been *seen* and has then gone is a
///   check that finished. Before it, "nothing new" could only ever be inferred from
///   the deadline expiring.
/// * `fwup_error_code` — **why it failed.** Read at the edges of the run rather than
///   on every poll: it changes when a run starts and when it ends, so a per-poll
///   second `Get` would buy nothing.
///
/// **It is handed two functions, not the service they come off.** The provider
/// above tears `requestOtaCheck` and `fetchAllBanks` off
/// [UspFirmwareUpdateService] and passes only those, and the reason is the one
/// sentence this whole file is arranged around: a check must never install. That
/// same service exposes `requestOtaInstall` — the identical `Download` on the
/// identical virtual instance with `AutoActivate="true"`, which on this router means
/// download, flash and reboot — so holding the object would leave the install verb
/// one dot away from this code,
/// separated from it by nothing but the comments saying not to. Two function
/// fields put the compiler there instead: from inside this class the install verb
/// does not exist, so it cannot be reached by accident, by a merge, or by someone
/// economising on a round trip.
///
/// It settles constitution Article VI §6.2 ("services shall not directly call
/// other services") as a side effect. That is not why it is shaped this way; the
/// unreachable install verb is.
class FirmwareRouterOtaCheckService {
  final OtaCheckDispatcher _dispatchCheck;
  final FirmwareImagesReader _readImages;
  final FirmwareAutoUpdateReader _readAutoUpdate;
  final SseOperationAwaiter? _awaiter;
  final UspMutationLock _lock;
  final Duration _deadline;
  final Duration _pollInterval;
  final Duration _slowPollInterval;
  final Duration _fastPollWindow;

  /// How long "the router did not find anything" takes to conclude.
  ///
  /// A pure compromise, and the ticket's named one. `Status=NoImage` with
  /// `Available=false` is what the router reports both when it has just checked
  /// and found nothing *and* when it has never checked, so there is no reading
  /// that means "done, nothing new" — only the absence of a reading that means
  /// "yes" for long enough to give up on.
  ///
  /// **Narrowed, not removed, by `linksys/usp_framework#66`.** `Status=Checking` is
  /// now a real completion marker, so a check whose `Checking` phase was *seen* ends
  /// on the router's word instead of on this clock. What still needs the deadline is
  /// the run whose `Checking` was missed: the window is measured at 0.65–0.9 s, so a
  /// poll can fall either side of it, and `Status != Checking` reads the same before
  /// `fwupd` has started as it does after it has finished.
  ///
  /// `linksys.fwup.lastsuccess_checktime` is still the anchor that would remove the
  /// fallback entirely — it *moves* rather than appearing for under a second, so it
  /// cannot be missed. It exists in the sysevent store, it was measured advancing on
  /// every check, and it is still not exposed in the data model.
  ///
  /// Ten seconds because the observed check completes in 1–2 s, leaving room for a
  /// slow OTA server without making a current router feel stuck. Shortening it
  /// reports "nothing new" while the router is still asking — the one wrong answer
  /// this whole file is arranged to avoid.
  static const Duration defaultDeadline = Duration(seconds: 10);

  /// Gap between reads of `FirmwareImage.` while the check could still be running.
  ///
  /// **300 ms, and it used to be 2 s.** The old number was chosen when `Status`
  /// carried no phase worth catching and the loop was only waiting for `Available` to
  /// appear. Now the `Checking` window is what turns a timeout into an answer, and it
  /// was measured at 0.65–0.9 s (three samples of a 220 ms poll on FW
  /// `2.0.1.26091601`) — at 2 s most runs would miss it entirely.
  ///
  /// **But this interval is not the effective read cadence, and `Checking` detection
  /// is therefore opportunistic rather than reliable.** `UspClient.get` routes through
  /// `BridgeRequestThrottler` with a **5 s** result cache keyed on the joined path
  /// list, and `FirmwareImages._paths` is a compile-time constant — so consecutive
  /// polls inside 5 s are served the same map and cannot observe a sub-second
  /// transition. Nothing here can pass a shorter TTL: the generated `_paths` is
  /// private, so the service cannot issue an equivalent uncached `Get`, and the
  /// throttler's only escape hatch is `clearCache()`, which would drop every other
  /// provider's entry too.
  ///
  /// What that costs is the *early* verdict, not correctness: a missed `Checking`
  /// falls through to [defaultDeadline], which is the behaviour this service had
  /// before the marker existed. The cheap polls stay because a cache hit is not
  /// bridge traffic and the loop should react on the first tick after the entry does
  /// expire. Fixing it properly means a `cacheTtl` passthrough on the generated
  /// `fetch` — filed on #1572, and it applies at least as much to the install watch,
  /// whose 1–2 s cadence is bounded by the same 5 s TTL.
  static const Duration defaultPollInterval = Duration(milliseconds: 300);

  /// Gap between reads once the fast window has closed.
  ///
  /// The check completes in about a second; past [defaultFastPollWindow] the loop is
  /// no longer waiting for a phase, it is waiting out the deadline for a router that
  /// is slow — and there a read every 300 ms is bridge traffic for nothing.
  static const Duration defaultSlowPollInterval = Duration(seconds: 1);

  /// How long the loop polls at [defaultPollInterval] before backing off.
  ///
  /// Three seconds against a measured one-second check, so the phase is catchable
  /// with room for a slow OTA server, and the cost is bounded at ten reads.
  static const Duration defaultFastPollWindow = Duration(seconds: 3);

  FirmwareRouterOtaCheckService({
    required OtaCheckDispatcher dispatchCheck,
    required FirmwareImagesReader readImages,
    required FirmwareAutoUpdateReader readAutoUpdate,
    required SseOperationAwaiter? awaiter,
    required UspMutationLock lock,
    Duration deadline = defaultDeadline,
    Duration pollInterval = defaultPollInterval,
    Duration slowPollInterval = defaultSlowPollInterval,
    Duration fastPollWindow = defaultFastPollWindow,
  })  : _dispatchCheck = dispatchCheck,
        _readImages = readImages,
        _readAutoUpdate = readAutoUpdate,
        _awaiter = awaiter,
        _lock = lock,
        _deadline = deadline,
        _pollInterval = pollInterval,
        _slowPollInterval = slowPollInterval,
        _fastPollWindow = fastPollWindow;

  /// The TR-181 subtree whose `OperationComplete` events belong to this check.
  static const String _referencePath = 'Device.DeviceInfo.FirmwareImage.';

  /// Run one check against [otaInstance] and say what it found.
  ///
  /// Returns [FirmwareOtaCheckVerdict.updateAvailable],
  /// [FirmwareOtaCheckVerdict.noUpdateFound], or
  /// [FirmwareOtaCheckVerdict.checkFailed] when the router named a reason itself;
  /// **throws** for a transport failure or a refusal. Never returns `noUpdateFound`
  /// for a check that did not run — that substitution is what makes a broken check
  /// read as reassurance, and it is the single failure this service is written to
  /// prevent.
  Future<FirmwareOtaCheckResult> check({required int otaInstance}) async {
    // Before the dispatch, not after: the refusal is measured to arrive ~49 ms in
    // and the watch is the only place it appears.
    final watch = await _openWatch();
    // Also before the dispatch, and best-effort. `fwup_error_code` is persistent and
    // undated, so a code standing here is the *previous* run's — and a code that
    // differs from it afterwards can only be this one's. The install service takes
    // the same reading of `fwup_state` for the same reason, after a measured defect
    // where a baseline captured too late suppressed a real phase.
    //
    // A failure to read it costs the diff, not the check: `_readAutoUpdate` is a
    // second `Get` and turning a diagnostic into a hard failure would report a broken
    // check because a diagnostic was unavailable.
    final codeBeforeDispatch = await _errorCodeOrNull();
    try {
      // The lock, and only around the dispatch. Rule 3 exists because the WASM
      // client cannot take concurrent calls, and this is the one call here that
      // is not a read — the poll loop below is `Get`s, which nothing in this
      // codebase locks. Holding it across the loop would block every other
      // mutation for the whole deadline and would sit under the lock's own 30 s
      // timeout.
      final String commandKey;
      try {
        commandKey = await _lock.withLock(
          () => _dispatchCheck(otaInstance: otaInstance),
        );
      } on TimeoutException catch (e) {
        // Mapped here because here is the layer that is allowed to (constitution
        // Article XIII §13.3), and because nothing above can see it coming:
        // `UspMutationLock` throws a bare `TimeoutException`, deliberately not a
        // `ServiceError`, so every `on ServiceError` between this line and the
        // button was blind to it. The check would appear to do nothing for 30 s,
        // leave no failure card, and then escape an unawaited `onTap` as an
        // uncaught async error.
        //
        // The same four lines the install service carries, and deliberately not
        // hoisted into a shared helper: what differs is the sentence, and a
        // helper taking the sentence as a parameter would be a wrapper around
        // `throw` whose only reader is this comment.
        throw TimeoutError(
          detail: 'another router mutation was still running when the firmware '
              'check was dispatched (${e.message ?? '30s'})',
        );
      }

      // Raced, not awaited. A refusal may never come — the ordinary case is that
      // it does not — so this future is allowed to stay pending for the life of
      // the check and is dropped on release.
      OperateResult? refusal;
      final refusalWatch = watch
          ?.firstWhere((r) => r.commandKey == commandKey && r.isFailure)
          .then((r) => refusal = r);
      if (refusalWatch != null) unawaited(refusalWatch);

      final startedAt = DateTime.now();
      final giveUpAt = startedAt.add(_deadline);
      final fastUntil = startedAt.add(_fastPollWindow);

      /// Whether the router was seen querying the OTA server.
      ///
      /// The evidence that a run of *ours* happened, and the licence for two things:
      /// concluding "nothing new" from the router rather than from the clock, and
      /// attributing an error code to this check. `Status != Checking` reads the same
      /// before `fwupd` starts as after it finishes, so only the sighting separates
      /// them.
      var sawChecking = false;

      while (DateTime.now().isBefore(giveUpAt)) {
        // Delay first. An `Available=true` read on the very first tick could be
        // left over from an earlier check, and reporting it would answer this
        // check with a previous one's result — harmless when it agrees, a lie
        // about what just happened when the router has since been flashed.
        await Future<void>.delayed(DateTime.now().isBefore(fastUntil)
            ? _pollInterval
            : _slowPollInterval);

        _throwIfRefused(refusal, otaInstance);

        final ota = _otaRow(await _readImages());
        // `Checking` first, and the order is the correctness. While `fwupd` is
        // querying, **no field on this row is this run's answer** — `Available` and
        // `Version` still hold whatever the last check left, so a router that was
        // flashed to the version it had previously offered would have that version
        // read back as a fresh offer. `fwupd` was measured entering `Checking` about
        // 34 ms after the dispatch, well inside the first poll, so this is the common
        // case rather than a race.
        if (ota != null && ota.status == _checkingStatus) {
          sawChecking = true;
          continue;
        }
        // An offer outranks everything below it, including a failure code: this is
        // the router answering the question, and a code left over from whatever came
        // before does not un-answer it.
        if (ota != null && ota.available) {
          logger.d('[FirmwareUpdate] OTA check found ${ota.version.isEmpty ? //
              'an unnamed image' : ota.version}');
          return FirmwareOtaCheckResult.updateAvailable(version: ota.version);
        }
        if (sawChecking) {
          // Seen checking, and no longer checking: the router has finished, which is
          // the completion marker this service went without until
          // `linksys/usp_framework#66`. So the verdict below is the router's answer
          // rather than an inference from the deadline.
          logger.d('[FirmwareUpdate] the router finished checking');
          return await _concludeAfterRun(codeBeforeDispatch, sawRunStart: true);
        }
      }

      // One last look, for a refusal that landed inside the final gap.
      _throwIfRefused(refusal, otaInstance);

      // The deadline, and still the only answer available for a run whose `Checking`
      // was never caught — the window is under a second. The error code can still
      // rescue it: a code that *moved* since the dispatch was written by this run
      // whether or not the phase was seen.
      logger.d('[FirmwareUpdate] OTA check saw no result within '
          '${_deadline.inSeconds}s');
      // `sawChecking`, not `false`: a check whose `Checking` never cleared inside the
      // deadline — a slow OTA server, which is exactly when the server codes appear —
      // was still observably ours, and passing `false` would fall back to the weaker
      // diff test and answer two identical consecutive failures with "nothing found".
      return await _concludeAfterRun(codeBeforeDispatch,
          sawRunStart: sawChecking);
    } finally {
      await watch?.release();
    }
  }

  /// The ota row's `Status` while `fwupd` is querying the OTA server.
  ///
  /// One spelling, and it is a TR-181 enum token rather than copy — the same
  /// treatment `FirmwareImageUIModel.isActive` gives `Active`.
  static const String _checkingStatus = 'Checking';

  /// The verdict for a check that produced no offer.
  ///
  /// [sawRunStart] is the whole of the difference between an answer and a guess. With
  /// it, a failure code belongs to this check because the run was observed. Without
  /// it, only a code that *differs from the pre-dispatch reading* does — everything
  /// else may be weeks old, and the definition says it survives until the next
  /// operation or the next reboot.
  Future<FirmwareOtaCheckResult> _concludeAfterRun(
    FirmwareUpdateErrorCode? codeBeforeDispatch, {
    required bool sawRunStart,
  }) async {
    final code = await _errorCodeOrNull();
    if (code != null && code.isFailure) {
      // `codeBeforeDispatch != null` is load-bearing, not defensive: that read is
      // best-effort, and without the guard a *failed* baseline read makes
      // `code != null` trivially true — so a week-old code would be reported as this
      // check's failure, which is the one outcome this rule exists to prevent. The
      // install service carries the identical predicate.
      if (sawRunStart ||
          (codeBeforeDispatch != null && code != codeBeforeDispatch)) {
        logger.w('[FirmwareUpdate] the router reports the check failed '
            '(${code.name})');
        return FirmwareOtaCheckResult.checkFailed(code);
      }
      logger
          .i('[FirmwareUpdate] the router still reports ${code.name}, but this '
              'check was never seen running and the code has not moved — not '
              'reporting it as this check\'s failure');
    }
    return const FirmwareOtaCheckResult.noUpdateFound();
  }

  /// `fwup_error_code`, or null when it could not be read.
  ///
  /// Null for two different reasons on purpose — the parameter absent, or the `Get`
  /// itself failing — because neither licenses a claim and the caller treats them
  /// the same.
  Future<FirmwareUpdateErrorCode?> _errorCodeOrNull() async {
    try {
      return (await _readAutoUpdate()).errorCode;
    } catch (e) {
      logger.d('[FirmwareUpdate] could not read fwup_error_code ($e)');
      return null;
    }
  }

  /// Subscribe to `OperationComplete`, or do without.
  ///
  /// The degrade is [openOperationCompleteWatch]'s, and what it costs *here* is
  /// the reason this file exists: without the refusal channel a refused check
  /// reads as "nothing found". Accepted anyway, because the alternative is
  /// refusing to check at all on a router whose SSE is merely unavailable, and
  /// the check is the feature.
  Future<OperationCompleteWatch?> _openWatch() =>
      openOperationCompleteWatch(_awaiter, referencePath: _referencePath);

  /// The virtual instance, picked by alias rather than by position.
  ///
  /// A spare NAND bank also reports `Available=true` — that is what "there is an
  /// image in this slot" means — so a check that read any available row would
  /// offer the user the version already on the device.
  FirmwareImageUIModel? _otaRow(List<FirmwareImageUIModel> images) {
    for (final image in images) {
      if (image.isOta) return image;
    }
    return null;
  }

  void _throwIfRefused(OperateResult? refusal, int otaInstance) {
    if (refusal == null) return;
    throw UspCompleteFailureError(
      summary: 'The router refused the firmware check on instance $otaInstance '
          '(${refusal.errorCode}${refusal.errorMessage != null ? //
              ': ${refusal.errorMessage}' : ''})',
      failures: const [],
    );
  }
}
