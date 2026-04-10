import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspSystemInfoDataServiceProvider = Provider<UspSystemInfoDataService>(
  (ref) {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }
    return UspSystemInfoDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching system info + firmware images.
///
/// Owns all codegen calls and error mapping for [systemInfoDataProvider].
class UspSystemInfoDataService {
  final UspService _usp;

  UspSystemInfoDataService(this._usp);

  /// Fetches system info and firmware images in parallel, returns a
  /// [SystemInfoUIModel] with firmware image data included.
  Future<SystemInfoUIModel> fetch() async {
    final List<Object> results;
    try {
      results = await Future.wait([
        SystemInfo.fetch(_usp),
        _fetchFirmwareImages(),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final systemInfo = results[0] as SystemInfo;
    final fwImages = results[1] as FirmwareImages;

    final fwModels = _buildFirmwareImageUIModels(
      data: fwImages,
      activeRef: systemInfo.activeFirmwareImage,
      bootRef: systemInfo.bootFirmwareImage,
    );

    return SystemInfoUIModel(
      manufacturer: systemInfo.manufacturer,
      modelName: systemInfo.modelName,
      serialNumber: systemInfo.serialNumber,
      hardwareVersion: systemInfo.hardwareVersion,
      softwareVersion: systemInfo.softwareVersion,
      uptime: systemInfo.uptime,
      totalMemory: systemInfo.totalMemory,
      freeMemory: systemInfo.freeMemory,
      cpuUsage: systemInfo.cpuUsage,
      firmwareImages: fwModels,
    );
  }

  // ---------------------------------------------------------------------------
  // Firmware images
  // ---------------------------------------------------------------------------

  Future<FirmwareImages> _fetchFirmwareImages() async {
    try {
      return await FirmwareImages.fetch(_usp)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      logger.w('[USP][SystemInfoData] Firmware images fetch failed: $e');
      return FirmwareImages(items: []);
    }
  }

  List<FirmwareImageUIModel> _buildFirmwareImageUIModels({
    required FirmwareImages data,
    required String activeRef,
    required String bootRef,
  }) {
    final normalizedActive = _stripTrailingDot(activeRef);
    final normalizedBoot = _stripTrailingDot(bootRef);
    return data.items.map((img) {
      final normalizedPath = _stripTrailingDot(img.instancePath);
      return FirmwareImageUIModel(
        instancePath: img.instancePath,
        name: img.name,
        version: img.version,
        status: img.status,
        available: img.available,
        isActive:
            normalizedActive.isNotEmpty && normalizedPath == normalizedActive,
        isBootTarget:
            normalizedBoot.isNotEmpty && normalizedPath == normalizedBoot,
      );
    }).toList();
  }

  static String _stripTrailingDot(String path) =>
      path.endsWith('.') ? path.substring(0, path.length - 1) : path;
}
