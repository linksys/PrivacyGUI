import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firmware_auto_update.g.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/firmware_operations.g.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';

final uspFirmwareUpdateServiceProvider = Provider<UspFirmwareUpdateService>(
  (ref) => UspFirmwareUpdateService(ref.read(uspClientProvider)!),
);

class UspFirmwareUpdateService {
  final UspClient _usp;

  UspFirmwareUpdateService(this._usp);

  static const String localFirmwarePath = '/tmp/obuspa/firmware.img';

  Future<List<FirmwareImageUIModel>> fetchAllBanks() async {
    try {
      final images = await FirmwareImages.fetch(_usp);
      return images.items.map(_toUIModel).toList();
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<FirmwareImageUIModel> fetchActiveBank() async {
    final all = await fetchAllBanks();
    return all.firstWhere(
      (b) => b.isActive,
      orElse: () => throw UspCompleteFailureError(
        summary: 'No active firmware bank found',
        failures: const [],
      ),
    );
  }

  Future<FirmwareImageUIModel> fetchAvailableBank() async {
    final all = await fetchAllBanks();
    return all.firstWhere(
      (b) => b.available && !b.isActive,
      orElse: () => throw UspCompleteFailureError(
        summary: 'No available firmware bank found',
        failures: const [],
      ),
    );
  }

  Future<void> triggerLocalDownload({
    required int targetInstance,
    String localPath = localFirmwarePath,
    bool autoActivate = true,
  }) async {
    try {
      await FirmwareOperations.download(
        _usp,
        targetInstance,
        url: 'file://$localPath',
        autoActivate: autoActivate ? 'true' : 'false',
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<void> triggerOtaDownload({
    required int targetInstance,
    required String firmwareUrl,
    bool autoActivate = true,
  }) async {
    try {
      await FirmwareOperations.download(
        _usp,
        targetInstance,
        url: firmwareUrl,
        autoActivate: autoActivate ? 'true' : 'false',
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<String> pollStatus(int instance) async {
    try {
      final images = await FirmwareImages.fetch(_usp);
      final match = images.items.firstWhere(
        (i) => _instanceFromPath(i.instancePath) == instance,
        orElse: () => throw UspCompleteFailureError(
          summary: 'Firmware bank instance $instance not found',
          failures: const [],
        ),
      );
      return match.status;
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Verifies a successful firmware activation after a reboot.
  ///
  /// Primary signal: the bank at [expectedActiveInstance] has flipped to
  /// `Active`. Bank flip — not version equality — is the rigorous check,
  /// because dev/QA scenarios legitimately flash the same version onto a
  /// different bank to validate the boot path.
  ///
  /// Returns `true` when the expected bank is Active and reports the
  /// expected version, `false` for version mismatch, and throws a
  /// [ServiceError] for the more serious classes of failure (router did
  /// not boot the new image; inconsistent multi-Active state).
  Future<bool> verifyAfterReboot({
    required String expectedVersion,
    required int expectedActiveInstance,
  }) async {
    try {
      final images = await FirmwareImages.fetch(_usp);
      logger.d(
          '[FirmwareUpdate] service.verifyAfterReboot: banks=${images.items.map((i) => '${i.instancePath}:${i.status}').join(', ')}'
          ', expectedActiveInstance=$expectedActiveInstance, expectedVersion=$expectedVersion');
      final activeBanks =
          images.items.where((i) => i.status == 'Active').toList();
      if (activeBanks.length > 1) {
        throw UspCompleteFailureError(
          summary:
              'Inconsistent firmware state: ${activeBanks.length} banks reported Active',
          failures: const [],
        );
      }
      final match = images.items.firstWhere(
        (i) => _instanceFromPath(i.instancePath) == expectedActiveInstance,
        orElse: () => throw UspCompleteFailureError(
          summary: 'Expected firmware bank instance $expectedActiveInstance '
              'not present after reboot',
          failures: const [],
        ),
      );
      if (match.status != 'Active') {
        throw UspCompleteFailureError(
          summary: 'Router restarted but did not boot the new image (instance '
              '$expectedActiveInstance status=${match.status})',
          failures: const [],
        );
      }
      return match.version == expectedVersion;
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The router's auto-update setting and progress, in one read.
  ///
  /// One `Get` for both because the data plane exposes them side by side, and
  /// because the two questions a caller asks — "may the router update itself" and
  /// "is it updating right now" — are answered by the same three parameters.
  Future<FirmwareAutoUpdateUIModel> fetchAutoUpdate() async {
    try {
      return mapAutoUpdateStatus(await FirmwareAutoUpdate.fetch(_usp));
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Writes the auto-update policy, and **only** the policy.
  ///
  /// `FirmwareAutoUpdate.update()` also takes `fwupPeriodicCheck` and
  /// `updateFirmwareNow`; neither is ever passed. Scheduling is decided against
  /// (REQ-C2) — the data plane can only promise "at the next cron tick", so a UI
  /// that offered a time would be promising something nobody defined — and
  /// `update_firmware_now` is a second flash entry point this app does not use.
  /// Seeing those two parameters unread is the intended state, not an omission.
  ///
  /// [FirmwareAutoUpdatePolicy.unknown] is refused rather than sent: its raw value
  /// is the empty string, which would either clear the parameter or be rejected by
  /// the router, and both are worse than failing at the call site.
  Future<void> setAutoUpdatePolicy(FirmwareAutoUpdatePolicy policy) async {
    if (policy == FirmwareAutoUpdatePolicy.unknown) {
      throw ArgumentError.value(
        policy,
        'policy',
        'has no value to write — read-only, it means the router reported a flag '
            'this build does not define',
      );
    }
    try {
      final result = await FirmwareAutoUpdate.update(
        _usp,
        autoupdateFlags: policy.rawValue,
      );
      switch (UspResultParser.parseSetResult(result)) {
        case UspSuccess():
          break;
        // One parameter, so a "partial" success cannot mean half of the write
        // landed — it means the only write failed while the message did not. Both
        // arms are therefore the same failure to a caller, unlike the
        // multi-parameter writes in `usp_admin_service.dart` where the split
        // carries information.
        case UspPartialSuccess(:final errorSummary, :final failures):
          throw UspCompleteFailureError(
            summary: 'Auto-update policy write failed: $errorSummary',
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'Auto-update policy write failed: $errorSummary',
            failures: errors,
          );
      }
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The one place `fwup_state` becomes an app-layer status.
  ///
  /// Keeping it single-sited is the point: the raw domain is `0/1/3/4/5` (`2` is
  /// a mode of `update_firmware_now`, not a state), only `0` has ever been seen
  /// on real hardware, and a firmware that grows a sixth value must cost one
  /// enum value plus one arm here. Unknown values therefore map to
  /// [FirmwareAutoUpdateStatus.unknown] — never to `idle`, which would report
  /// "nothing is running" during an unrecognised flash — and never throw.
  ///
  /// [FirmwareAutoUpdateUIModel.rawState] carries the value through unparsed so
  /// a failure keeps the number the router sent.
  ///
  /// `autoupdate_flags` is mapped here too rather than in a second method: it
  /// arrives in the same `Get`, so splitting the mapping would mean two reads of
  /// one response.
  static FirmwareAutoUpdateUIModel mapAutoUpdateStatus(FirmwareAutoUpdate raw) {
    final status = switch (raw.fwupState) {
      '0' => FirmwareAutoUpdateStatus.idle,
      '1' => FirmwareAutoUpdateStatus.checking,
      '3' => FirmwareAutoUpdateStatus.downloading,
      '4' => FirmwareAutoUpdateStatus.installing,
      '5' => FirmwareAutoUpdateStatus.failed,
      _ => FirmwareAutoUpdateStatus.unknown,
    };
    if (status == FirmwareAutoUpdateStatus.unknown) {
      logger.w('[FirmwareUpdate] unrecognised fwup_state "${raw.fwupState}"');
    }
    final policy = FirmwareAutoUpdatePolicy.fromRaw(raw.autoupdateFlags);
    if (policy == FirmwareAutoUpdatePolicy.unknown) {
      logger.w('[FirmwareUpdate] unrecognised autoupdate_flags '
          '"${raw.autoupdateFlags}"');
    }
    return FirmwareAutoUpdateUIModel(
      status: status,
      // Carried verbatim. `fwup_progress` rests at both 0 and 100 after a check
      // depending on the mode used, so no value of it means "done" — reading it
      // is only valid within the status above.
      progress: int.tryParse(raw.fwupProgress) ?? 0,
      rawState: raw.fwupState,
      policy: policy,
      rawFlags: raw.autoupdateFlags,
    );
  }

  FirmwareImageUIModel _toUIModel(FirmwareImage image) => FirmwareImageUIModel(
        instance: _instanceFromPath(image.instancePath),
        instancePath: image.instancePath,
        alias: image.alias,
        name: image.name,
        version: image.version,
        status: image.status,
        available: image.available,
      );

  int _instanceFromPath(String path) {
    final trimmed =
        path.endsWith('.') ? path.substring(0, path.length - 1) : path;
    final lastDot = trimmed.lastIndexOf('.');
    if (lastDot < 0) return 0;
    return int.tryParse(trimmed.substring(lastDot + 1)) ?? 0;
  }
}
