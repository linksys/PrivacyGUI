import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/services/system_info_service.dart';

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
    // Use SystemInfoService instead of direct codegen + manual logic
    final systemInfoService = ref.read(systemInfoServiceProvider);

    try {
      // SystemInfoService handles:
      // - Multi-model aggregation (SystemInfo + FirmwareImages)
      // - Structured error handling from WASM layer
      // - Business logic transformation via UspDeviceService
      // - Unified error mapping
      final model = await systemInfoService.fetchSystemInfoData();

      logger.d('[USP][SystemInfoData] Service layer fetch completed — '
          'model=${model.modelName}, fw=${model.softwareVersion}');

      return SystemInfoData(model: model);
    } catch (e) {
      // SystemInfoService already converts USP/WASM errors to ServiceError
      // Provider layer just needs to handle ServiceError types
      logger.e('[USP][SystemInfoData] Service layer error: $e');
      rethrow;
    }
  }
}
