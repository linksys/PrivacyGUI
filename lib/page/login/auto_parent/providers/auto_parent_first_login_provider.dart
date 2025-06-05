import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_state.dart';

final autoParentFirstLoginProvider = NotifierProvider.autoDispose<
    AutoParentFirstLoginNotifier,
    AutoParentFirstLoginState>(() => AutoParentFirstLoginNotifier());

class AutoParentFirstLoginNotifier
    extends AutoDisposeNotifier<AutoParentFirstLoginState> {
  @override
  AutoParentFirstLoginState build() {
    return AutoParentFirstLoginState();
  }

  // check and auto install the latest firmware, return true if new firmware is available
  Future<bool> checkAndAutoInstallFirmware() async {
    // Pause polling
    ref.read(pollingProvider.notifier).paused = true;
    final fwUpdate = ref.read(firmwareUpdateProvider.notifier);
    logger.i('[FirstTime]: Do FW update check');
    await fwUpdate.fetchAvailableFirmwareUpdates();
    if (fwUpdate.getAvailableUpdateNumber() > 0) {
      logger.i('[FirstTime]: New Firmware available!');
      await fwUpdate.updateFirmware();
      return true;
    } else {
      logger.i('[FirstTime]: No available FW, ready to go');
      return false;
    }
  }

  // set userAcknowledgedAutoConfiguration to true
  Future<void> setUserAcknowledgedAutoConfiguration() async {
    final repo = ref.read(routerRepositoryProvider);
    repo.send(
      JNAPAction.setUserAcknowledgedAutoConfiguration,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      data: {},
      auth: true,
    );
  }

  // set firmware updatePolicy to [FirmwareUpdateSettings.firmwareUpdatePolicyAuto]
  Future<void> setFirmwareUpdatePolicy() async {
    final repo = ref.read(routerRepositoryProvider);
    // Get current firmware update settings
    final firmwareUpdateSettings = await repo
        .send(
          JNAPAction.getFirmwareUpdateSettings,
          fetchRemote: true,
          auth: true,
        )
        .then((value) => value.output)
        .then(
          (output) => FirmwareUpdateSettings.fromMap(output).copyWith(
              updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto),
        )
        .onError((error, stackTrace) {
      return FirmwareUpdateSettings(
          updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
          autoUpdateWindow: FirmwareAutoUpdateWindow(
            startMinute: 0,
            durationMinutes: 240,
          ));
    });

    // enable auto firmware update
    repo.send(
      JNAPAction.setFirmwareUpdateSettings,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      data: firmwareUpdateSettings.toMap(),
      auth: true,
    );
  }

  // Check internet connection via JNAP
  Future<bool> checkInternetConnection() async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(
      JNAPAction.getInternetConnectionStatus,
      fetchRemote: true,
      auth: true,
    );
    logger.i('[FirstTime]: Internet connection status: ${result.output}');
    final connectionStatus = result.output['connectionStatus'];
    final isConnected = connectionStatus == 'InternetConnected';
    return isConnected;
  }

  Future<void> finishFirstTimeLogin() async {
    // Keep userAcknowledgedAutoConfiguration to false if no internet connection
    final isConnected = await checkInternetConnection();
    logger.i('[FirstTime]: Internet connection status: $isConnected');
    if (isConnected) {
      await setUserAcknowledgedAutoConfiguration();
    }
    // Set firmware update policy
    await setFirmwareUpdatePolicy();
  }
}
