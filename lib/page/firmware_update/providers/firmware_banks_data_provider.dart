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

  /// Whether the router is offering an image worth telling the user about.
  ///
  /// [otaInstance] with `available` is not enough on its own, and the missing
  /// comparison was visible on screen (measured from a recording of a full install,
  /// 2026-09-16): seconds after "Update complete — now running 2.0.1.26091516", the
  /// same page still read "Update available — Available: 2.0.1.26091516". The `ota`
  /// row keeps the last offer until `fwupd` next checks, so right after a reboot it
  /// names the build that just went in. The card announced it, and the dashboard
  /// banner would have too.
  ///
  /// So an offer whose version equals the running one is not an offer. Compared
  /// against [activeBank] rather than against anything the install flow remembers,
  /// because this has to be right for a router that updated itself while nobody was
  /// looking as well as for one this app just flashed.
  ///
  /// **An offer with no version stays an offer.** The router does publish
  /// `Available=true` with an empty `Version`, and an unnamed build cannot be
  /// compared to anything — withholding it would turn "we cannot tell" into "there
  /// is nothing", which is the substitution this whole feature is arranged to
  /// avoid. The card already renders that case as a headline with no version line.
  bool get hasOtaOffer {
    final ota = otaInstance;
    if (ota == null || !ota.available) return false;
    final offered = ota.version;
    if (offered.isEmpty) return true;
    return offered != activeBank?.version;
  }

  /// The version [hasOtaOffer] is about, or null when there is no offer — and also
  /// null for an offer the router did not name.
  ///
  /// Two nulls with one meaning for a caller ("nothing to print here") and two
  /// meanings for a reader, which is why [hasOtaOffer] is the predicate: a card that
  /// keyed its headline off this getter would go silent on the unnamed offer.
  String? get otaOfferedVersion {
    if (!hasOtaOffer) return null;
    final offered = otaInstance?.version ?? '';
    return offered.isEmpty ? null : offered;
  }

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
