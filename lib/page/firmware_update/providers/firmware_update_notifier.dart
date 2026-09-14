import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/operation_guard.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_router_ota_check_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_validation_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

final firmwareUpdateNotifierProvider =
    AutoDisposeNotifierProvider<FirmwareUpdateNotifier, FirmwareUpdateState>(
  FirmwareUpdateNotifier.new,
);

/// State-machine notifier driving the manual firmware update flow.
///
/// Phases (PR-1 wires the skeleton; later PRs fill in upload / trigger /
/// reboot detect):
///
/// idle → picking → validating → uploading → triggering → installing
///                                                      ↓
///                                              rebooting → verifying → done
///                                                      ↘ failed
class FirmwareUpdateNotifier extends AutoDisposeNotifier<FirmwareUpdateState> {
  UspFirmwareUpdateService get _svc =>
      ref.read(uspFirmwareUpdateServiceProvider);
  FirmwareFilePickerService get _picker =>
      ref.read(firmwareFilePickerServiceProvider);
  FirmwareValidationService get _validator =>
      ref.read(firmwareValidationServiceProvider);
  FirmwareLocalUploadService get _uploader =>
      ref.read(firmwareLocalUploadServiceProvider);
  FirmwareRouterOtaCheckService get _otaChecker =>
      ref.read(firmwareRouterOtaCheckServiceProvider);

  /// Holds the picked image bytes off-state. Kept off [FirmwareUpdateState]
  /// because a 70 MB Uint8List does not belong in an equatable comparison
  /// and would dominate any state-diff cost.
  Uint8List? _pickedBytes;

  Uint8List? get pickedBytes => _pickedBytes;

  bool _cancelRequested = false;

  @override
  FirmwareUpdateState build() {
    ref.onDispose(() => _pickedBytes = null);
    return const FirmwareUpdateState();
  }

  /// Sets state and logs the phase transition.
  void _setState(FirmwareUpdateState newState) {
    final oldPhase = state.phase;
    final newPhase = newState.phase;
    if (oldPhase != newPhase) {
      logger.i('[FirmwareUpdate] phase: $oldPhase → $newPhase');
    }
    state = newState;
  }

  Future<void> loadBanks() async {
    try {
      // Read from L1 provider (Single Source of Truth)
      final banksData = await ref.read(firmwareBanksDataProvider.future);
      _setState(state.copyWith(
        activeBank: banksData.activeBank,
        targetBank: banksData.availableBank,
      ));
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] loadBanks failed', error: e);
      _fail(e.toString());
      rethrow;
    }
  }

  /// Ask the router whether a newer firmware exists.
  ///
  /// The cloud OTA API used to answer this, which meant assembling a MAC, a model
  /// number and a hardware revision from three other providers and asking a server
  /// about a router it could not see. The router knows, so it is asked directly —
  /// see [FirmwareRouterOtaCheckService]. `firmware_ota_check_service.dart` and its
  /// `FirmwareOtaInfo` are still in the tree with no caller anywhere in `lib`:
  /// #1550 says the cloud path is parked, not deleted, and when it goes is a
  /// separate decision. There is no coexistence — nothing selects between them.
  ///
  /// Returns [FirmwareOtaCheckVerdict.notChecked] — never an error — when the
  /// router has no `ota` row. That is REQ-A1: OEM and rebadged builds never ship
  /// the row, so it is a permanent property of the device rather than a fault, and
  /// it is logged at warning, not error. The caller reads
  /// `FirmwareBanksData.otaInstance` for the same fact to decide whether to offer
  /// the button at all; this arm exists for the race where the row disappears
  /// between the two reads.
  ///
  /// Rethrows [ServiceError] so the view can say the check failed. It must not be
  /// swallowed into `noUpdateFound`: "we could not ask" and "we asked and there is
  /// nothing" are the same sentence to a user and only one of them is true.
  Future<FirmwareOtaCheckResult> checkForUpdate() async {
    final otaInstance =
        (await ref.read(firmwareBanksDataProvider.future)).otaInstance;
    if (otaInstance == null) {
      logger.w('[FirmwareUpdate] no ota instance — this router cannot be asked '
          'for firmware updates');
      return const FirmwareOtaCheckResult.notChecked();
    }

    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.checkingOta,
      otaCheck: const FirmwareOtaCheckResult.notChecked(),
      errorMessage: null,
    ));

    try {
      final result = await _otaChecker.check(otaInstance: otaInstance.instance);
      _setState(state.copyWith(
        phase: FirmwareUpdatePhase.idle,
        otaCheck: result,
      ));
      // The check writes `Available`/`Version` on the router, so the L1 cache the
      // dashboard banner and the mascot read from is now stale. Refreshed after
      // the state is published, and guarded: a failed re-read is a stale banner,
      // not a failed check, and turning it into one would report an error for a
      // check the user just watched succeed.
      try {
        await ref.read(firmwareBanksDataProvider.notifier).refresh();
      } on ServiceError catch (e) {
        logger.w('[FirmwareUpdate] post-check banks refresh failed', error: e);
      }
      return result;
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] OTA check failed', error: e);
      _setState(state.copyWith(phase: FirmwareUpdatePhase.idle));
      rethrow;
    } finally {
      // Belt to the `on ServiceError` braces above, and the only thing standing
      // between an unforeseen throw and a button that spins for the rest of the
      // session. `checkingOta` is what makes `AppButton.isLoading` true, and the
      // ticket's own words are that the checking state is driven by this call's
      // lifecycle — so it must not outlive the call, whatever ends it. A no-op on
      // both paths that get here normally: each has already set `idle`.
      if (state.phase == FirmwareUpdatePhase.checkingOta) {
        logger.w('[FirmwareUpdate] OTA check left the phase set — restoring '
            'idle');
        _setState(state.copyWith(phase: FirmwareUpdatePhase.idle));
      }
    }
  }

  /// Open the OS file picker, then run client-side validation. Updates state
  /// to [FirmwareUpdatePhase.validating] then back to a populated
  /// [FirmwareUpdatePhase.idle] on success (caller drives the next phase via
  /// [triggerInstall]). Returns false if the user cancelled the dialog.
  Future<bool> pickAndValidateFile() async {
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.picking,
      errorMessage: null,
    ));
    final picked = await _picker.pickFirmwareImage();
    if (picked == null) {
      _setState(state.copyWith(phase: FirmwareUpdatePhase.idle));
      return false;
    }
    _setState(state.copyWith(phase: FirmwareUpdatePhase.validating));
    try {
      final result = await _validator.validate(
        filename: picked.name,
        bytes: picked.bytes,
      );
      _pickedBytes = picked.bytes;
      _setState(state.copyWith(
        phase: FirmwareUpdatePhase.idle,
        selectedFileName: result.filename,
        selectedFileSize: result.size,
        selectedFileMd5: result.md5,
        errorMessage: null,
      ));
      return true;
    } on FirmwareValidationFailure catch (e) {
      logger.w('[FirmwareUpdate] validation failed', error: e);
      _fail(e.message);
      return false;
    }
  }

  void cancel() {
    _cancelRequested = true;
    _pickedBytes = null;
    _setState(const FirmwareUpdateState());
  }

  /// Pushes the previously-picked firmware image to the router via Method 1
  /// chunkedPush. Sets uploading phase, drives the progress fields, and
  /// returns once all chunks are accepted. Does NOT trigger the flash —
  /// caller drives [triggerInstall] next so the confirm dialog can sit
  /// between the two stages.
  ///
  /// `transportLoss` — **manual firmware update is a local-only feature**, and
  /// the class doc is worth reading before touching this: the upload is not
  /// broken under Remote Assistance, it is simply not offered there. Cloud OTA is
  /// the remote answer for the same need, and [triggerOtaInstall] below is
  /// allowed in every mode.
  ///
  /// Refused before the state moves, so the view never shows an upload screen for
  /// an upload that will not happen — and refused by throwing, because
  /// `_onConfirmInstall` would otherwise fall straight through to
  /// [triggerInstall] and then to a recovery dialog waiting for a reboot nobody
  /// asked for.
  ///
  /// This is the seam #1496's own analysis could not have used: one line later,
  /// the OTA path and this one converge on the same `enterRecoveryWaiting()` and
  /// the same recovery dialog, so nothing downstream can tell them apart.
  Future<void> runUpload({required String commandKey}) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transportLoss,
        operation: 'local firmware upload');
    final bytes = _pickedBytes;
    final md5 = state.selectedFileMd5;
    if (bytes == null || md5 == null) {
      _fail('No firmware image selected');
      return;
    }
    _cancelRequested = false;
    final total = _uploader.totalFragmentsFor(bytes.length);
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.uploading,
      uploadedChunks: 0,
      totalChunks: total,
      errorMessage: null,
    ));
    try {
      await _uploader.uploadFile(
        bytes: bytes,
        md5: md5,
        commandKey: commandKey,
        isCancelled: () => _cancelRequested,
        onProgress: (sent, t) {
          state = state.copyWith(
            phase: FirmwareUpdatePhase.uploading,
            uploadedChunks: sent,
            totalChunks: t,
            uploadMethod: _uploader.lastUsedMethod,
          );
        },
      );
      // Capture final upload method in state
      _setState(state.copyWith(uploadMethod: _uploader.lastUsedMethod));
    } on FirmwareUploadCancelledException {
      logger.i('[FirmwareUpdate] upload cancelled by user');
      cancel();
      rethrow;
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] upload failed', error: e);
      _fail(e.toString());
      rethrow;
    }
  }

  /// Tells the router to install an image it already holds.
  ///
  /// `transientRestart`, and this is not a loophole in the block above: pushing
  /// the bytes is what needs the router's own host, installing them only restarts
  /// the box. Classifying this by the flow it belongs to rather than by what it
  /// costs is exactly the mistake `DisruptionClass` exists to prevent — and in
  /// Remote Assistance it is unreachable regardless, because
  /// `_onConfirmInstall` returns as soon as [runUpload] throws.
  Future<void> triggerInstall({required int targetInstance}) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transientRestart,
        operation: 'local firmware install');
    _setState(state.copyWith(phase: FirmwareUpdatePhase.triggering));
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.triggerLocalDownload(targetInstance: targetInstance);
      });
      _setState(state.copyWith(phase: FirmwareUpdatePhase.installing));
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] triggerInstall failed', error: e);
      _fail(e.toString());
      rethrow;
    }
  }

  /// Tells the router to fetch and install an image from the cloud.
  ///
  /// `transientRestart`, allowed everywhere — and it is the half of the firmware
  /// pair that is easy to get wrong. An OTA is the *more* alarming of the two to
  /// watch: the router downloads, flashes and reboots. It is also the one that
  /// works remotely, because the router does the fetching over its own uplink and
  /// nothing on the agent's path is destroyed. Together with [runUpload] above,
  /// the two lines are the whole argument for naming consequences instead of
  /// operations.
  Future<void> triggerOtaInstall({
    required int targetInstance,
    required String firmwareUrl,
  }) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transientRestart,
        operation: 'cloud OTA firmware install');
    _setState(state.copyWith(phase: FirmwareUpdatePhase.triggering));
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.triggerOtaDownload(
          targetInstance: targetInstance,
          firmwareUrl: firmwareUrl,
        );
      });
      _setState(state.copyWith(phase: FirmwareUpdatePhase.installing));
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] triggerOtaInstall failed', error: e);
      _fail(e.toString());
      rethrow;
    }
  }

  /// Hands off recovery to the shared [AppConnectionStateNotifier]:
  /// transitions the connection state to `waitingForRecovery` so the
  /// existing probe loop (health → session restore → fingerprint) runs
  /// and the SSE channel is parked. The view is responsible for showing
  /// the firmware-specific recovery dialog around this call.
  void enterRecoveryWaiting({
    Duration cooldown = const Duration(seconds: 60),
  }) {
    _setState(state.copyWith(phase: FirmwareUpdatePhase.rebooting));
    ref.read(appConnectionStateProvider.notifier).enterWaiting(
          context: RecoveryContext(
            trigger: RecoveryTrigger.operationalFirmwareUpgrade,
            cooldown: cooldown,
          ),
        );
  }

  void enterRebooting(Duration estimated) {
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.rebooting,
      rebootRemaining: estimated,
    ));
  }

  Future<void> verify({
    required String expectedVersion,
    required int expectedActiveInstance,
  }) async {
    _setState(state.copyWith(phase: FirmwareUpdatePhase.verifying));

    try {
      // Post-reboot settle: SSE reconnects and dashboard providers refetch
      logger.d('[FirmwareUpdate] verify: post-reboot settle (3s)...');
      await Future<void>.delayed(const Duration(seconds: 3));

      // Wait for throttler to be idle (SSE reconnect may trigger other requests)
      logger.d('[FirmwareUpdate] verify: waiting for throttler idle...');
      await ref.read(bridgeRequestThrottlerProvider).whenIdle();

      // Fetch banks with retry (also retry if banks empty — TR-181 may not be ready)
      FirmwareBanksData? banksData;
      const maxAttempts = 3;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          logger.d(
              '[FirmwareUpdate] verify: calling notifier.refresh() (attempt $attempt/$maxAttempts)...');
          banksData =
              await ref.read(firmwareBanksDataProvider.notifier).refresh();
          logger.d('[FirmwareUpdate] verify: got '
              '${banksData.physicalBanks.length} banks');
          // Counted over physical banks: a table holding only the virtual OTA
          // row is TR-181 still coming up, and treating it as "banks read"
          // would fail the update with "expected bank not present".
          if (banksData.physicalBanks.isNotEmpty) break;
          // Empty banks — TR-181 not ready yet, retry
          logger.w('[FirmwareUpdate] verify: empty banks, retrying...');
          if (attempt == maxAttempts) {
            _fail('Unable to read firmware banks after reboot');
            return;
          }
          await Future<void>.delayed(const Duration(seconds: 3));
        } catch (e) {
          logger.w(
              '[FirmwareUpdate] verify: refresh failed (attempt $attempt/$maxAttempts)',
              error: e);
          if (attempt == maxAttempts) rethrow;
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }
      // Physical banks only. Every check below is about which slot the router
      // booted from, and the virtual OTA instance is not a slot: it would be
      // counted by the multi-Active consistency check and could be matched as
      // the expected instance if the router renumbers.
      final banks = banksData!.physicalBanks;

      logger.d(
          '[FirmwareUpdate] verify: banks=${banks.map((b) => '${b.instancePath}:${b.status}').join(', ')}'
          ', expectedActiveInstance=$expectedActiveInstance, expectedVersion=$expectedVersion');

      // Verify: check for inconsistent multi-Active state
      final activeBanks = banks.where((b) => b.isActive).toList();
      if (activeBanks.length > 1) {
        _fail(
            'Inconsistent firmware state: ${activeBanks.length} banks reported Active');
        return;
      }

      // Find the expected bank
      final match =
          banks.where((b) => b.instance == expectedActiveInstance).firstOrNull;
      if (match == null) {
        _fail(
            'Expected firmware bank instance $expectedActiveInstance not present after reboot');
        return;
      }

      // Verify bank flip: expected instance should now be Active
      if (!match.isActive) {
        _fail(
            'Router restarted but did not boot the new image (instance $expectedActiveInstance status=${match.status})');
        return;
      }

      // Version match check (secondary, optional for manual update)
      // For manual uploads, expectedVersion may be empty (we don't parse the
      // firmware file's embedded version). Bank flip is the primary check.
      if (expectedVersion.isNotEmpty && match.version != expectedVersion) {
        logger.w('[FirmwareUpdate] verify: version mismatch '
            '(expected=$expectedVersion, got=${match.version}), but bank flip succeeded');
      }
      // Bank flip succeeded — mark as done
      _setState(state.copyWith(
        phase: FirmwareUpdatePhase.done,
        activeBank: match,
      ));
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] verify failed', error: e);
      _fail(e.toString());
      rethrow;
    }
  }

  void updateUploadProgress(int sent, int total) {
    state = state.copyWith(
      phase: FirmwareUpdatePhase.uploading,
      uploadedChunks: sent,
      totalChunks: total,
    );
  }

  void updateTargetStatus(String status) {
    state = state.copyWith(targetStatus: status);
  }

  void updateRebootCountdown(Duration remaining) {
    state = state.copyWith(rebootRemaining: remaining);
  }

  void _fail(String message) {
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.failed,
      errorMessage: message,
    ));
  }

  /// Test-only seam: directly seed an active/target bank pair without hitting
  /// the service, useful for snapshot / golden tests in PR-5.
  @visibleForTesting
  void debugSeedBanks({
    FirmwareImageUIModel? active,
    FirmwareImageUIModel? target,
  }) {
    state = state.copyWith(activeBank: active, targetBank: target);
  }
}
