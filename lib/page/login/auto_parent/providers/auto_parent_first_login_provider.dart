import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Check and auto install the latest firmware.
  ///
  /// TODO: Re-implement firmware update check using USP when available.
  /// Returns false (no new firmware) in USP-only mode.
  Future<bool> checkAndAutoInstallFirmware() async {
    logger.i('[FirstTime]: checkAndAutoInstallFirmware — stubbed (USP mode)');
    return false;
  }

  Future<void> finishFirstTimeLogin([bool failCheck = false]) async {
    final service = ref.read(autoParentFirstLoginServiceProvider);

    if (!failCheck) {
      final isConnected = await service.checkInternetConnection();
      logger.i('[FirstTime]: Internet connection status: $isConnected');
      await service.setUserAcknowledgedAutoConfiguration();
    }
    await service.setFirmwareUpdatePolicy();
  }
}
