import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_info.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_ota_check_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_validation_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

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
  FirmwareOtaCheckService get _otaChecker =>
      ref.read(firmwareOtaCheckServiceProvider);

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

  /// Build OTA check parameters from device data providers.
  ///
  /// Returns `null` if required data is unavailable (e.g., master node not found).
  Future<FirmwareOtaCheckParams?> buildOtaCheckParams() async {
    try {
      final devicesData = await ref.read(devicesDataProvider.future);
      final masterNode = devicesData.nodeModels.master;
      if (masterNode == null) {
        logger.w('[FirmwareUpdate] Master node not found');
        return null;
      }

      final systemInfoData = await ref.read(systemInfoDataProvider.future);
      final hardwareVersion =
          _parseHardwareVersion(systemInfoData.model.hardwareVersion);

      final wanData = await ref.read(wanDataProvider.future);
      final ipAddress = wanData.model.ipAddress;

      return FirmwareOtaCheckParams(
        macAddress: _formatMacAddress(masterNode.deviceId),
        installedVersion: masterNode.softwareVersion,
        modelNumber: masterNode.model,
        hardwareVersion: hardwareVersion,
        ipAddress: ipAddress,
      );
    } catch (e) {
      logger.e('[FirmwareUpdate] Failed to build OTA check params', error: e);
      return null;
    }
  }

  String _formatMacAddress(String mac) {
    return mac.toUpperCase().replaceAll(':', '-');
  }

  String _parseHardwareVersion(String hwVersion) {
    var version = hwVersion;
    if (version.toUpperCase().startsWith('V')) {
      version = version.substring(1);
    }
    final parsed = int.tryParse(version);
    return parsed?.toString() ?? version;
  }

  /// Check for OTA firmware updates from the cloud.
  ///
  /// Returns the [FirmwareOtaInfo] if an update is available, or `null` if
  /// the device is already on the latest version.
  /// Throws [FirmwareOtaCheckException] on API errors.
  Future<FirmwareOtaInfo?> checkForOtaUpdate(
      FirmwareOtaCheckParams params) async {
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.checkingOta,
      clearOtaInfo: true,
      otaUpToDate: false,
      errorMessage: null,
    ));

    try {
      final info = await _otaChecker.checkForUpdate(params);
      if (info != null) {
        _setState(state.copyWith(
          phase: FirmwareUpdatePhase.idle,
          otaInfo: info,
          otaUpToDate: false,
        ));
      } else {
        _setState(state.copyWith(
          phase: FirmwareUpdatePhase.idle,
          clearOtaInfo: true,
          otaUpToDate: true,
        ));
      }
      return info;
    } on FirmwareOtaCheckException catch (e) {
      logger.e('[FirmwareUpdate] OTA check failed', error: e);
      _setState(state.copyWith(phase: FirmwareUpdatePhase.idle));
      rethrow;
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
  Future<void> runUpload({required String commandKey}) async {
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

  Future<void> triggerInstall({required int targetInstance}) async {
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

  Future<void> triggerOtaInstall({
    required int targetInstance,
    required String firmwareUrl,
  }) async {
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
          logger.d(
              '[FirmwareUpdate] verify: got ${banksData.banks.length} banks');
          if (banksData.banks.isNotEmpty) break;
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
      final banks = banksData!.banks;

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
