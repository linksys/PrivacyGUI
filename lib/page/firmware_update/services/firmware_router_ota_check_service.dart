import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_operation_watch.dart';
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
    awaiter: ref.read(sseOperationAwaiterProvider),
    lock: ref.read(uspMutationLockProvider),
  );
});

/// Asks the router whether a newer firmware exists, replacing the cloud OTA API.
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
///
/// **It is handed two functions, not the service they come off.** The provider
/// above tears `requestOtaCheck` and `fetchAllBanks` off
/// [UspFirmwareUpdateService] and passes only those, and the reason is the one
/// sentence this whole file is arranged around: a check must never install. That
/// same service exposes `triggerOtaDownload` — the identical `Download` with
/// `AutoActivate="true"`, which on this router means download, flash and reboot —
/// so holding the object would leave the install verb one dot away from this code,
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
  final SseOperationAwaiter? _awaiter;
  final UspMutationLock _lock;
  final Duration _deadline;
  final Duration _pollInterval;

  /// How long "the router did not find anything" takes to conclude.
  ///
  /// A pure compromise, and the ticket's named one. `Status=NoImage` with
  /// `Available=false` is what the router reports both when it has just checked
  /// and found nothing *and* when it has never checked, so there is no reading
  /// that means "done, nothing new" — only the absence of a reading that means
  /// "yes" for long enough to give up on.
  ///
  /// `linksys.fwup.lastsuccess_checktime` is the anchor that would replace this
  /// with an actual answer: a check whose timestamp moved past the moment we
  /// dispatched has demonstrably finished. It exists in the sysevent store and is
  /// not exposed in the data model; contract request 6 on #1547 asks for it. When
  /// that lands, this constant and the loop below both go away.
  ///
  /// Ten seconds because the observed check completes in 1–2 s, leaving room for a
  /// slow OTA server without making a current router feel stuck. Shortening it
  /// reports "nothing new" while the router is still asking — the one wrong answer
  /// this whole file is arranged to avoid.
  static const Duration defaultDeadline = Duration(seconds: 10);

  /// Gap between reads of `FirmwareImage.`.
  ///
  /// Two seconds is one read per bench-observed check, which is as fine-grained as
  /// the answer is: nothing here is timing anything, it is waiting for a value to
  /// appear. Tighter only adds bridge traffic to a router that is busy.
  static const Duration defaultPollInterval = Duration(seconds: 2);

  FirmwareRouterOtaCheckService({
    required OtaCheckDispatcher dispatchCheck,
    required FirmwareImagesReader readImages,
    required SseOperationAwaiter? awaiter,
    required UspMutationLock lock,
    Duration deadline = defaultDeadline,
    Duration pollInterval = defaultPollInterval,
  })  : _dispatchCheck = dispatchCheck,
        _readImages = readImages,
        _awaiter = awaiter,
        _lock = lock,
        _deadline = deadline,
        _pollInterval = pollInterval;

  /// The TR-181 subtree whose `OperationComplete` events belong to this check.
  static const String _referencePath = 'Device.DeviceInfo.FirmwareImage.';

  /// Run one check against [otaInstance] and say what it found.
  ///
  /// Returns [FirmwareOtaCheckVerdict.updateAvailable] or
  /// [FirmwareOtaCheckVerdict.noUpdateFound]; **throws** for anything else.
  /// Never returns `noUpdateFound` for a check that did not run — that
  /// substitution is what makes a broken check read as reassurance, and it is the
  /// single failure this service is written to prevent.
  Future<FirmwareOtaCheckResult> check({required int otaInstance}) async {
    // Before the dispatch, not after: the refusal is measured to arrive ~49 ms in
    // and the watch is the only place it appears.
    final watch = await _openWatch();
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

      final giveUpAt = DateTime.now().add(_deadline);
      while (DateTime.now().isBefore(giveUpAt)) {
        // Delay first. An `Available=true` read on the very first tick could be
        // left over from an earlier check, and reporting it would answer this
        // check with a previous one's result — harmless when it agrees, a lie
        // about what just happened when the router has since been flashed.
        await Future<void>.delayed(_pollInterval);

        _throwIfRefused(refusal, otaInstance);

        final ota = _otaRow(await _readImages());
        if (ota != null && ota.available) {
          logger.d('[FirmwareUpdate] OTA check found ${ota.version.isEmpty ? //
              'an unnamed image' : ota.version}');
          return FirmwareOtaCheckResult.updateAvailable(version: ota.version);
        }
      }

      // One last look, for a refusal that landed inside the final gap.
      _throwIfRefused(refusal, otaInstance);

      logger.d('[FirmwareUpdate] OTA check found nothing within '
          '${_deadline.inSeconds}s');
      return const FirmwareOtaCheckResult.noUpdateFound();
    } finally {
      await watch?.release();
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
