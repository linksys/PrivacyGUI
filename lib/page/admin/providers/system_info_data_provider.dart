import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/services/usp_system_info_data_service.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';

// ── Data Model ──

class SystemInfoData extends Equatable with DiagnosticLoggable {
  final SystemInfoUIModel model;

  const SystemInfoData({required this.model});

  @override
  String get diagnosticName => 'SystemInfoData';

  @override
  Map<String, Object?> get namedProps => {'model': model};
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
    //
    // NOT THE ONLY WAY THIS PROVIDER REFRESHES. The dashboard orchestrator lists
    // it in `_allDomainProviders`, so login, pull-to-refresh and the startup
    // retry all invalidate it — through a loop over that list, which is why a
    // search for this provider's name finds no `invalidate` call. This listener
    // adds one thing on top: the banks are re-read after a firmware check, an
    // install or a read-failure retry, and the copy embedded in
    // SystemInfoUIModel.firmwareImages has to follow them.
    //
    // UNGUARDED ON PURPOSE, and it costs one extra fetch per banks refresh.
    // `FirmwareBanksDataNotifier.refresh()` publishes a loading frame that keeps
    // the previous banks before it publishes the new ones, so both pass the
    // `hasValue` check below. The two invalidations coalesce only when the
    // second arrives before the rebuild the first one scheduled, which a banks
    // read with real latency does not. Measured with 80 ms of fetch latency: 2
    // fetches per refresh, the first one handed the previous banks, and the
    // value the second publishes is the correct one. Left alone because the
    // second read asks USP for the same paths within the throttler's 5 s cache
    // window, so it is expected to be served without a router round-trip.
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

    // Service fetches SystemInfo; firmwareBanks passed in externally.
    //
    // `physicalBanks`, not `banks`: this is the fan-out point for everything
    // that consumes SystemInfoUIModel.firmwareImages — the support PDF prints
    // one row per entry, and the admin card falls back to `.first.version` as
    // the current version. The virtual OTA instance carries the version the
    // router could update *to*, so letting it through makes both of those lie.
    final model = await svc.fetch(firmwareBanks: banksData?.physicalBanks);

    return SystemInfoData(model: model);
  }
}
