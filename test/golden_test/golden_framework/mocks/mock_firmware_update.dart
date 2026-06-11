import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';

class FixedFirmwareUpdateNotifier extends FirmwareUpdateNotifier {
  final FirmwareUpdateState _fixedState;

  FixedFirmwareUpdateNotifier(this._fixedState);

  @override
  FirmwareUpdateState build() => _fixedState;

  @override
  Future<void> loadBanks() async {}

  @override
  Future<bool> pickAndValidateFile() async => true;

  @override
  void cancel() {}

  @override
  Future<void> runUpload({required String commandKey}) async {}

  @override
  Future<void> triggerInstall({required int targetInstance}) async {}

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
}) =>
    [
      firmwareUpdateNotifierProvider
          .overrideWith(() => FixedFirmwareUpdateNotifier(updateState)),
      firmwareBanksDataProvider
          .overrideWith(() => FixedFirmwareBanksDataNotifier(banksData)),
      systemInfoDataProvider
          .overrideWith(() => FixedSystemInfoDataNotifier(systemInfoData)),
    ];

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

  @override
  void enterWaiting({required RecoveryContext context}) {}

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
