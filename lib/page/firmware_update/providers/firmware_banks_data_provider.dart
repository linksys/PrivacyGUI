import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_banks_data_service.dart';

// ── Data Model ──

class FirmwareBanksData extends Equatable with DiagnosticLoggable {
  final List<FirmwareImageUIModel> banks;

  const FirmwareBanksData({required this.banks});

  /// Active bank (status == 'Active').
  FirmwareImageUIModel? get activeBank =>
      banks.where((b) => b.isActive).firstOrNull;

  /// Available bank for flashing (available && !isActive).
  FirmwareImageUIModel? get availableBank =>
      banks.where((b) => b.available && !b.isActive).firstOrNull;

  @override
  String get diagnosticName => 'FirmwareBanksData';

  @override
  Map<String, Object?> get namedProps => {'banks': banks};
}

// ── Provider ──

/// Layer 1 data provider for firmware banks (FirmwareImages).
///
/// This is the **single source of truth** for FirmwareImages data.
/// [systemInfoDataProvider] listens to this provider and uses its data
/// rather than fetching FirmwareImages independently.
final firmwareBanksDataProvider =
    AsyncNotifierProvider<FirmwareBanksDataNotifier, FirmwareBanksData>(
  FirmwareBanksDataNotifier.new,
);

// ── Notifier (NOT autoDispose) ──

class FirmwareBanksDataNotifier extends AsyncNotifier<FirmwareBanksData> {
  @override
  Future<FirmwareBanksData> build() async => _fetch();

  /// Force refetch and update state. Returns fresh data.
  Future<FirmwareBanksData> refresh() async {
    logger.d('[FirmwareUpdate] banks: refresh() called, setting AsyncLoading');
    state = const AsyncLoading();
    final data = await _fetch();
    logger.d(
        '[FirmwareUpdate] banks: refresh() fetch complete, setting AsyncData');
    state = AsyncData(data);
    return data;
  }

  Future<FirmwareBanksData> _fetch() async {
    logger.d('[FirmwareUpdate] banks: _fetch() starting...');
    final service = ref.read(firmwareBanksDataServiceProvider);
    final banks = await service.fetch();
    logger.d('[FirmwareUpdate] banks: fetched ${banks.length} banks, '
        'active=${banks.where((b) => b.isActive).firstOrNull?.version}');
    return FirmwareBanksData(banks: banks);
  }
}
