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
    // Deliberately NOT guarded by a `banks` diff, even though `banks` is the
    // only thing _fetch() passes on: this listener is the ONLY refresh trigger
    // systemInfoDataProvider has in the whole app, and _fetch() reads SystemInfo
    // live from USP. A `banks` diff would therefore suppress the app's only
    // systemInfo refresh on a same-version reflash (banks identical,
    // softwareVersion/uptime changed) for the rest of the session. Decoupling
    // the two is a design change, not a guard — see #1505 and
    // doc/riverpod/listen_site_audit.md.
    //
    // No `isLoading` guard either: the double firing on an upstream refetch is
    // absorbed by invalidateSelf(), which coalesces, unlike a direct fetch().
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

    return SystemInfoData(model: model);
  }
}
