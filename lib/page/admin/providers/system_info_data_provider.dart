import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firmware_images.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
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
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      SystemInfo.fetch(usp),
      _fetchFirmwareImages(usp),
    ]);

    final systemInfo = results[0] as SystemInfo;
    final fwData = results[1] as ({
      FirmwareImages images,
      String activeRef,
      String bootRef
    });

    final svc = UspDeviceService();
    final fwModels = svc.buildFirmwareImageUIModels(
      data: fwData.images,
      activeRef: fwData.activeRef,
      bootRef: fwData.bootRef,
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

  /// Fetches firmware image partitions and the active/boot reference paths.
  Future<({FirmwareImages images, String activeRef, String bootRef})>
      _fetchFirmwareImages(UspService usp) async {
    try {
      final results = await Future.wait([
        FirmwareImages.fetch(usp),
        usp.get([
          'Device.DeviceInfo.ActiveFirmwareImage',
          'Device.DeviceInfo.BootFirmwareImage',
        ]),
      ]).timeout(const Duration(seconds: 10));
      final images = results[0] as FirmwareImages;
      final refs = results[1] as Map<String, dynamic>;
      final activeRef =
          refs['Device.DeviceInfo.ActiveFirmwareImage']?.toString() ?? '';
      final bootRef =
          refs['Device.DeviceInfo.BootFirmwareImage']?.toString() ?? '';
      return (images: images, activeRef: activeRef, bootRef: bootRef);
    } catch (e) {
      logger.w('[USP][SystemInfoData] Firmware images fetch failed: $e');
      return (
        images: FirmwareImages(items: []),
        activeRef: '',
        bootRef: '',
      );
    }
  }
}
