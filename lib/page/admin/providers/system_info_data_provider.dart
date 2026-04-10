import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';

// ── Data Model ──

class SystemInfoData extends Equatable {
  final SystemInfoUIModel model;

  const SystemInfoData({required this.model});

  @override
  List<Object?> get props => [model];
}

// ── Provider ──

/// Layer 1 data provider for System Info + Firmware Images.
///
/// No SSE invalidation domain — system info rarely changes at runtime.
final systemInfoDataProvider =
    AsyncNotifierProvider<SystemInfoDataNotifier, SystemInfoData>(
  SystemInfoDataNotifier.new,
);

// ── Notifier (NOT autoDispose) ──

class SystemInfoDataNotifier extends AsyncNotifier<SystemInfoData> {
  @override
  Future<SystemInfoData> build() async {
    return _fetch();
  }

  Future<SystemInfoData> _fetch() async {
    final usp = ref.read(uspClientProvider);
    if (usp == null) throw StateError('USP service not available');

    // SystemInfo.fetch now includes ActiveFirmwareImage + BootFirmwareImage
    // (merged in YAML v1.1.0), reducing from 3 → 2 USP requests.
    final results = await Future.wait([
      SystemInfo.fetch(usp),
      _fetchFirmwareImages(usp),
    ]);

    final systemInfo = results[0] as SystemInfo;
    final fwImages = results[1] as FirmwareImages;

    final svc = UspDeviceService();
    final fwModels = svc.buildFirmwareImageUIModels(
      data: fwImages,
      activeRef: systemInfo.activeFirmwareImage,
      bootRef: systemInfo.bootFirmwareImage,
    );
    final model = svc.buildSystemInfoUIModel(
      systemInfo,
      firmwareImages: fwModels,
    );

    logger.d('[USP][SystemInfoData] Fetched — '
        'model=${systemInfo.modelName}, '
        'fw=${systemInfo.softwareVersion}');
    return SystemInfoData(model: model);
  }

  /// Fetches firmware image partitions (multi-instance).
  Future<FirmwareImages> _fetchFirmwareImages(UspClient usp) async {
    try {
      return await FirmwareImages.fetch(usp)
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      logger.w('[USP][SystemInfoData] Firmware images fetch failed: $e');
      return FirmwareImages(items: []);
    }
  }
}
