import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/firmware_operations.g.dart';
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

  FirmwareImageUIModel _toUIModel(FirmwareImage image) => FirmwareImageUIModel(
        instance: _instanceFromPath(image.instancePath),
        instancePath: image.instancePath,
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
