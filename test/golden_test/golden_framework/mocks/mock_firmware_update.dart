import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';

class FixedFirmwareUpdateNotifier extends FirmwareUpdateNotifier {
  final FirmwareUpdateState _fixedState;

  FixedFirmwareUpdateNotifier(this._fixedState);

  @override
  FirmwareUpdateState build() => _fixedState;

  @override
  Future<void> loadBanks({bool refresh = false}) async {}

  /// Answers with the verdict already in the fixed state instead of asking the
  /// router.
  ///
  /// Every other override here silences a service call; this one also silences a
  /// clock. The real method dispatches `Download()` on the virtual `ota` instance
  /// and then polls `FirmwareImage.` for up to ten seconds, so a golden that taps
  /// the check button would not fail — it would hang until `pumpAndSettle` gave up.
  @override
  Future<FirmwareOtaCheckResult> checkForUpdate() async => _fixedState.otaCheck;

  /// The two router-side OTA seams (#1551), silenced for the same reason as the
  /// check above and one stronger one: [observeRunningOtaInstall] is called from
  /// `FirmwareOtaView.initState`, so **every** pump of that page would start a
  /// twenty-minute poll loop against a router that is not there. Overridden here
  /// rather than in each test file because the page starts it whether or not a
  /// test is about it.
  ///
  /// Both answer `abandoned`, which is the one verdict
  /// `FirmwareUpdateNotifier._applyInstallOutcome` deliberately writes nothing
  /// for — so a fake that has to return something cannot move a fixed state out
  /// from under the test that pinned it.
  @override
  Future<FirmwareOtaInstallResult> triggerRouterOtaInstall({
    required int otaInstance,
  }) async =>
      const FirmwareOtaInstallResult(
          verdict: FirmwareOtaInstallVerdict.abandoned);

  @override
  Future<FirmwareOtaInstallResult> observeRunningOtaInstall() async =>
      const FirmwareOtaInstallResult(
          verdict: FirmwareOtaInstallVerdict.abandoned);

  @override
  Future<bool> pickAndValidateFile() async => true;

  @override
  void cancel() {}

  @override
  Future<void> runUpload({required String commandKey}) async {}

  // `true` = dispatched, which is what a fixture pinning a *phase* wants: the
  // caller's flow continues exactly as it did before the busy refusal existed.
  @override
  Future<bool> triggerInstall({required int targetInstance}) async => true;

  @override
  void enterRecoveryWaiting(
      {Duration cooldown = const Duration(seconds: 60)}) {}

  @override
  void enterRebooting(Duration estimated) {}

  @override
  Future<void> verify({
    required String expectedVersion,
    required int expectedActiveInstance,
  }) async {}

  @override
  void updateUploadProgress(int sent, int total) {}

  @override
  void updateTargetStatus(String status) {}

  @override
  void updateRebootCountdown(Duration remaining) {}
}

class FixedFirmwareBanksDataNotifier extends FirmwareBanksDataNotifier {
  final FirmwareBanksData _fixedData;

  FixedFirmwareBanksDataNotifier(this._fixedData);

  @override
  Future<FirmwareBanksData> build() async => _fixedData;

  @override
  Future<FirmwareBanksData> refresh() async => _fixedData;
}

class FixedSystemInfoDataNotifier extends SystemInfoDataNotifier {
  final SystemInfoData _fixedData;

  FixedSystemInfoDataNotifier(this._fixedData);

  @override
  Future<SystemInfoData> build() async => _fixedData;
}

List<Override> firmwareUpdateOverrides({
  required FirmwareUpdateState updateState,
  required FirmwareBanksData banksData,
  required SystemInfoData systemInfoData,
  FirmwareAutoUpdateUIModel? autoUpdate,
}) =>
    [
      firmwareUpdateNotifierProvider
          .overrideWith(() => FixedFirmwareUpdateNotifier(updateState)),
      firmwareBanksDataProvider
          .overrideWith(() => FixedFirmwareBanksDataNotifier(banksData)),
      systemInfoDataProvider
          .overrideWith(() => FixedSystemInfoDataNotifier(systemInfoData)),
      // The router's own last-check record, which the OTA check card's history line
      // reads (#1572). Defaulted to a router that reports none of the diagnostics
      // leaves, so every existing caller keeps the rendering it had.
      if (autoUpdate != null)
        firmwareAutoUpdateDataProvider
            .overrideWith(() => _FixedAutoUpdateNotifier(autoUpdate)),
    ];

/// Publishes one auto-update reading and never re-reads.
class _FixedAutoUpdateNotifier extends FirmwareAutoUpdateDataNotifier {
  _FixedAutoUpdateNotifier(this._fixed);
  final FirmwareAutoUpdateUIModel _fixed;

  @override
  Future<FirmwareAutoUpdateUIModel> build() async => _fixed;
}

List<Override> firmwareUpdateOverridesWithLoading({
  required FirmwareUpdateState updateState,
  required SystemInfoData systemInfoData,
}) =>
    [
      firmwareUpdateNotifierProvider
          .overrideWith(() => FixedFirmwareUpdateNotifier(updateState)),
      firmwareBanksDataProvider.overrideWith(() => _LoadingBanksNotifier()),
      systemInfoDataProvider
          .overrideWith(() => FixedSystemInfoDataNotifier(systemInfoData)),
    ];

class _LoadingBanksNotifier extends FirmwareBanksDataNotifier {
  @override
  Future<FirmwareBanksData> build() async {
    state = const AsyncLoading();
    return const FirmwareBanksData(banks: []);
  }
}

class FixedAppConnectionStateNotifier extends AppConnectionStateNotifier {
  final AppConnectionState _fixedState;
  final int _consecutiveFailures;
  final ProbeResult? _lastProbeResult;

  FixedAppConnectionStateNotifier({
    required AppConnectionState fixedState,
    int consecutiveFailures = 0,
    ProbeResult? lastProbeResult,
  })  : _fixedState = fixedState,
        _consecutiveFailures = consecutiveFailures,
        _lastProbeResult = lastProbeResult;

  @override
  AppConnectionState build() => _fixedState;

  @override
  int get consecutiveFailures => _consecutiveFailures;

  @override
  ProbeResult? get lastProbeResult => _lastProbeResult;

  /// Always "yes, waiting", because this fake pins the state to
  /// `waitingForRecovery` and the golden's whole subject is the waiting dialog.
  /// Returning false would be this fake claiming the mode has nothing to recover
  /// from, and `showRecoveryDialog` would then never open the dialog under test.
  @override
  bool enterWaiting({required RecoveryContext context}) => true;

  @override
  void exitToLogout() {}

  @override
  Future<void> retryNow() async {}
}

List<Override> recoveryDialogOverrides({
  int consecutiveFailures = 0,
  ProbeResult? lastProbeResult,
}) =>
    [
      appConnectionStateProvider.overrideWith(
        () => FixedAppConnectionStateNotifier(
          fixedState: AppConnectionState.waitingForRecovery,
          consecutiveFailures: consecutiveFailures,
          lastProbeResult: lastProbeResult,
        ),
      ),
    ];
