import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
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

  Future<void> loadBanks() async {
    try {
      final active = await _svc.fetchActiveBank();
      final available = await _svc.fetchAvailableBank();
      state = state.copyWith(activeBank: active, targetBank: available);
    } on ServiceError catch (e) {
      logger.e('[USP][FirmwareUpdate]: loadBanks failed', error: e);
      _fail(e.toString());
      rethrow;
    }
  }

  /// Open the OS file picker, then run client-side validation. Updates state
  /// to [FirmwareUpdatePhase.validating] then back to a populated
  /// [FirmwareUpdatePhase.idle] on success (caller drives the next phase via
  /// [triggerInstall]). Returns false if the user cancelled the dialog.
  Future<bool> pickAndValidateFile() async {
    state = state.copyWith(
      phase: FirmwareUpdatePhase.picking,
      errorMessage: null,
    );
    final picked = await _picker.pickFirmwareImage();
    if (picked == null) {
      state = state.copyWith(phase: FirmwareUpdatePhase.idle);
      return false;
    }
    state = state.copyWith(phase: FirmwareUpdatePhase.validating);
    try {
      final result = await _validator.validate(
        filename: picked.name,
        bytes: picked.bytes,
      );
      _pickedBytes = picked.bytes;
      state = state.copyWith(
        phase: FirmwareUpdatePhase.idle,
        selectedFileName: result.filename,
        selectedFileSize: result.size,
        selectedFileMd5: result.md5,
        errorMessage: null,
      );
      return true;
    } on FirmwareValidationFailure catch (e) {
      logger.w('[USP][FirmwareUpdate]: validation failed', error: e);
      _fail(e.message);
      return false;
    }
  }

  void cancel() {
    _cancelRequested = true;
    _pickedBytes = null;
    state = const FirmwareUpdateState();
  }

  /// Pushes the previously-picked firmware image to the router via Method 1
  /// chunkedPush. Sets uploading phase, drives the progress fields, and
  /// returns once all chunks are accepted. Does NOT trigger the flash —
  /// caller drives [triggerInstall] next so the confirm dialog can sit
  /// between the two stages.
  Future<void> runUpload({required String commandKey}) async {
    final bytes = _pickedBytes;
    final md5 = state.selectedFileMd5;
    if (bytes == null || md5 == null) {
      _fail('No firmware image selected');
      return;
    }
    _cancelRequested = false;
    final total = _uploader.totalFragmentsFor(bytes.length);
    state = state.copyWith(
      phase: FirmwareUpdatePhase.uploading,
      uploadedChunks: 0,
      totalChunks: total,
      errorMessage: null,
    );
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
      state = state.copyWith(uploadMethod: _uploader.lastUsedMethod);
    } on FirmwareUploadCancelledException {
      logger.i('[USP][FirmwareUpdate]: upload cancelled by user');
      cancel();
      rethrow;
    } on ServiceError catch (e) {
      logger.e('[USP][FirmwareUpdate]: upload failed', error: e);
      _fail(e.toString());
      rethrow;
    }
  }

  Future<void> triggerInstall({required int targetInstance}) async {
    state = state.copyWith(phase: FirmwareUpdatePhase.triggering);
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.triggerLocalDownload(targetInstance: targetInstance);
      });
      state = state.copyWith(phase: FirmwareUpdatePhase.installing);
    } on ServiceError catch (e) {
      logger.e('[USP][FirmwareUpdate]: triggerInstall failed', error: e);
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
    state = state.copyWith(phase: FirmwareUpdatePhase.rebooting);
    ref.read(appConnectionStateProvider.notifier).enterWaiting(
          context: RecoveryContext(
            trigger: RecoveryTrigger.operationalFirmwareUpgrade,
            cooldown: cooldown,
          ),
        );
  }

  void enterRebooting(Duration estimated) {
    state = state.copyWith(
      phase: FirmwareUpdatePhase.rebooting,
      rebootRemaining: estimated,
    );
  }

  Future<void> verify({
    required String expectedVersion,
    required int expectedActiveInstance,
  }) async {
    state = state.copyWith(phase: FirmwareUpdatePhase.verifying);
    // Clear throttler cache to ensure fresh data after reboot
    ref.read(bridgeRequestThrottlerProvider).clearCache();
    try {
      final ok = await _svc.verifyAfterReboot(
        expectedVersion: expectedVersion,
        expectedActiveInstance: expectedActiveInstance,
      );
      if (ok) {
        state = state.copyWith(phase: FirmwareUpdatePhase.done);
      } else {
        _fail('Verification failed: version mismatch after reboot');
      }
    } on ServiceError catch (e) {
      logger.e('[USP][FirmwareUpdate]: verify failed', error: e);
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
    state = state.copyWith(
      phase: FirmwareUpdatePhase.failed,
      errorMessage: message,
    );
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
