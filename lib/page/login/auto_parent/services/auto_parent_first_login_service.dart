import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Riverpod provider for AutoParentFirstLoginService
final autoParentFirstLoginServiceProvider =
    Provider<AutoParentFirstLoginService>((ref) {
  return AutoParentFirstLoginService();
});

/// Service for auto-parent first-time login operations.
///
/// TODO: Re-implement using USP when auto-parent configuration is available.
/// Previously used JNAP for setUserAcknowledgedAutoConfiguration,
/// firmware update settings, and internet connection checks.
class AutoParentFirstLoginService {
  AutoParentFirstLoginService();

  Future<void> setUserAcknowledgedAutoConfiguration() async {
    logger.d(
        '[AutoParentFirstLogin]: setUserAcknowledgedAutoConfiguration — stubbed (USP mode)');
  }

  Future<void> setFirmwareUpdatePolicy() async {
    logger.d(
        '[AutoParentFirstLogin]: setFirmwareUpdatePolicy — stubbed (USP mode)');
  }

  Future<bool> checkInternetConnection() async {
    logger.d(
        '[AutoParentFirstLogin]: checkInternetConnection — returning true (USP mode)');
    return true;
  }
}
