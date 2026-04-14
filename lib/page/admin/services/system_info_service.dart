import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';

final systemInfoServiceProvider = Provider<SystemInfoService>(
  (ref) => SystemInfoService(
    ref.read(uspClientProvider)!,
    ref.read(uspDeviceServiceProvider),
  ),
);

/// Service layer for System Information with structured response handling.
///
/// Demonstrates the standard Service layer pattern:
/// - Uses UspClient.getWithResult() for structured API
/// - Handles partial success tolerance for display data
/// - Maps USP errors to ServiceError for unified error handling
/// - Transforms business logic before returning to Provider layer
class SystemInfoService {
  final UspClient _client;
  final UspDeviceService _deviceService;

  SystemInfoService(this._client, this._deviceService);

  /// Fetch system information data with structured error handling.
  ///
  /// Uses codegen SystemInfo.fetch() which now throws structured errors on failure.
  /// SystemInfo represents core device identification - all parameters are important.
  Future<SystemInfoUIModel> fetchSystemInfoData() async {
    try {
      // Parallel fetch: SystemInfo + FirmwareImages
      final results = await Future.wait([
        SystemInfo.fetch(_client),
        _fetchFirmwareImages(),
      ]);

      final systemInfo = results[0] as SystemInfo;
      final fwImages = results[1] as List<FirmwareImageUIModel>;

      // Transform to UI model
      final model = _deviceService.buildSystemInfoUIModel(
        systemInfo,
        firmwareImages: fwImages,
      );

      logger.d('[SystemInfoService] Fetched successfully — '
          'model=${systemInfo.modelName}, fw=${systemInfo.softwareVersion}');

      return model;
    } catch (e) {
      // Handle structured errors from codegen or other failures
      // The error 'e' may be a structured error Map from WASM layer
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Fetch firmware images with timeout and fallback.
  Future<List<FirmwareImageUIModel>> _fetchFirmwareImages() async {
    try {
      final fwImages = await FirmwareImages.fetch(_client)
          .timeout(const Duration(seconds: 20));

      return _deviceService.buildFirmwareImageUIModels(
        data: fwImages,
        activeRef: '', // Will be filled by SystemInfo
        bootRef: '', // Will be filled by SystemInfo
      );
    } catch (e) {
      // Firmware images are optional - don't fail the whole operation
      logger.w('[SystemInfoService] Firmware images fetch failed: $e');
      return [];
    }
  }
}
