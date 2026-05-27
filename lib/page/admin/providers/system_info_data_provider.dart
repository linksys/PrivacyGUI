import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/services/usp_system_info_data_service.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';

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
    // Listen to firmwareBanks changes → auto invalidate (pattern: EthernetDataProvider)
    ref.listen(firmwareBanksDataProvider, (_, next) {
      if (next.hasValue && state.hasValue) {
        ref.invalidateSelf();
      }
    });
    return _fetch();
  }

  Future<SystemInfoData> _fetch() async {
    final svc = ref.read(uspSystemInfoDataServiceProvider);

    // Read from firmwareBanksDataProvider (Single Source of Truth)
    final banksData = ref.read(firmwareBanksDataProvider).valueOrNull;

    // Service fetches SystemInfo; firmwareBanks passed in externally
    final model = await svc.fetch(firmwareBanks: banksData?.banks);

    logger.d('[USP][SystemInfoData]: Fetched — '
        'model=${model.modelName}, '
        'fw=${model.softwareVersion}');

    return SystemInfoData(model: model);
  }
}
