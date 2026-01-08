import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_state.dart';
import 'package:privacy_gui/page/login/auto_parent/services/auto_parent_first_login_service.dart';

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
    if (fwUpdate.isFailedCheckFirmwareUpdate()) {
      throw Exception('Failed to check firmware update');
    }
    if (fwUpdate.getAvailableUpdateNumber() > 0) {
      logger.i('[FirstTime]: New Firmware available!');
      await fwUpdate.updateFirmware();
      return true;
    } else {
      logger.i('[FirstTime]: No available FW, ready to go');
      return false;
    }
  }

  Future<void> finishFirstTimeLogin([bool failCheck = false]) async {
    final service = ref.read(autoParentFirstLoginServiceProvider);

    // Keep userAcknowledgedAutoConfiguration to false if check firmware failed
    if (!failCheck) {
      // wait for internet connection
      final isConnected = await service.checkInternetConnection();
      logger.i('[FirstTime]: Internet connection status: $isConnected');
      await service.setUserAcknowledgedAutoConfiguration();
    }
    // Set firmware update policy
    await service.setFirmwareUpdatePolicy();
  }
}
