import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/_providers.dart';

enum PnpIspSettingsStatus {
  initial,
  saving,
  checkSettings,
  checkInternetConnection,
  success,
  error,
}

final pnpIspSettingsProvider =
    NotifierProvider<PnpIspSettingsNotifier, PnpIspSettingsStatus>(
  PnpIspSettingsNotifier.new,
);

class PnpIspSettingsNotifier extends Notifier<PnpIspSettingsStatus> {
  @override
  PnpIspSettingsStatus build() {
    return PnpIspSettingsStatus.initial;
  }

  Future<void> saveAndVerifySettings(
    InternetSettings newSettings,
  ) async {
    try {
      final wanType = WanType.resolve(
        newSettings.ipv4Setting.ipv4ConnectionType,
      )!;

      // 1. Save new settings
      state = PnpIspSettingsStatus.saving;
      logger.i('[PnP]: Troubleshooter - Attempting to save new settings...');
      await ref
          .read(internetSettingsProvider.notifier)
          .savePnpIpv4(newSettings);
      logger.i('[PnP]: Troubleshooter - New settings saved successfully.');

      // 2. Check if the new settings are valid
      state = PnpIspSettingsStatus.checkSettings;
      logger.i('[PnP]: Troubleshooter - Checking new router configuration...');
      final isSettingsValid =
          await ref.read(pnpIspServiceProvider).verifyNewSettings(wanType);
      if (!isSettingsValid) {
        throw Exception(
            '[PnP]: Troubleshooter - Failed to use the new router configuration');
      }
      logger.i('[PnP]: Troubleshooter - The new router configuration is fine.');

      // 3. Check for internet connection
      state = PnpIspSettingsStatus.checkInternetConnection;
      logger.i(
          '[PnP]: Troubleshooter - Checking internet connection with new settings...');
      await ref.read(pnpServiceProvider).checkInternetConnection(30);
      logger.i(
          '[PnP]: Troubleshooter - Check internet connection with new settings - OK');

      // 4. If all successful, update state to success
      state = PnpIspSettingsStatus.success;
    } on Exception catch (e, st) {
      logger.e('[PnP]: Troubleshooter - An error occurred during save/verify',
          error: e, stackTrace: st);
      state = PnpIspSettingsStatus.error;
      // Re-throw the exception so the UI layer can catch it.
      rethrow;
    }
  }
}
