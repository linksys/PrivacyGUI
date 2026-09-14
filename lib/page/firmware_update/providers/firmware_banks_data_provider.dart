import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_banks_data_service.dart';

// ── Data Model ──

class FirmwareBanksData extends Equatable with DiagnosticLoggable {
  /// Every `FirmwareImage` row the router reported, as reported. Prefer
  /// [physicalBanks] or [otaInstance]: the raw list mixes the NAND banks with a
  /// virtual instance that is not a bank, and reading it directly is what makes
  /// "an update is available" and "a slot is free to flash into" the same
  /// question when they are not.
  final List<FirmwareImageUIModel> banks;

  const FirmwareBanksData({required this.banks});

  /// The NAND banks — everything except the virtual OTA instance. This is the
  /// inventory of images the router holds, and the only list that may be shown
  /// as slots.
  List<FirmwareImageUIModel> get physicalBanks =>
      banks.where((b) => !b.isOta).toList();

  /// The virtual OTA instance, or null when the router reports none (OEM builds
  /// without the fwup stack). Null means *no update information*, not
  /// "up to date" — and never "an update is available".
  FirmwareImageUIModel? get otaInstance =>
      banks.where((b) => b.isOta).firstOrNull;

  /// Active bank (status == 'Active').
  FirmwareImageUIModel? get activeBank =>
      physicalBanks.where((b) => b.isActive).firstOrNull;

  /// Physical bank free to flash into (available && !isActive). The OTA instance
  /// also reports `Available=1` while not being Active, so this must search the
  /// banks only — otherwise the version the router could download reads as the
  /// version already sitting in the spare slot.
  FirmwareImageUIModel? get availableBank =>
      physicalBanks.where((b) => b.available && !b.isActive).firstOrNull;

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
  ///
  /// Keeps the previous reading while loading and publishes `AsyncError` on
  /// failure, for the reasons spelled out on
  /// `FirmwareAutoUpdateDataNotifier.refresh` — a provider that is not autoDispose
  /// and that nothing else invalidates cannot be left in `AsyncLoading` by a fetch
  /// that threw. Riverpod attaches the previous reading to that error whether or
  /// not it is asked to, which is why this provider's consumers check `hasError`
  /// rather than `valueOrNull`; see there.
  Future<FirmwareBanksData> refresh() async {
    logger.d('[FirmwareUpdate] banks: refresh() called, setting AsyncLoading');
    state = const AsyncLoading<FirmwareBanksData>().copyWithPrevious(state);
    try {
      final data = await _fetch();
      logger.d(
          '[FirmwareUpdate] banks: refresh() fetch complete, setting AsyncData');
      state = AsyncData(data);
      return data;
    } catch (e, stackTrace) {
      logger.e('[FirmwareUpdate] banks: refresh() failed: $e');
      state = AsyncError(e, stackTrace);
      rethrow;
    }
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
