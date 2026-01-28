import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/retry_strategy/retry.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Riverpod provider for AutoParentFirstLoginService
final autoParentFirstLoginServiceProvider =
    Provider<AutoParentFirstLoginService>((ref) {
  return AutoParentFirstLoginService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for auto-parent first-time login operations.
///
/// Handles JNAP communication for:
/// - Setting user acknowledged auto configuration
/// - Configuring firmware update policy
/// - Checking internet connection status
///
/// Follows constitution.md Article VI Section 6.2:
/// - Handles all JNAP API communication
/// - Returns simple results (void, bool), not raw JNAP responses
/// - Stateless (no internal state)
/// - Dependencies injected via constructor
class AutoParentFirstLoginService {
  AutoParentFirstLoginService(this._routerRepository,
      {RetryStrategy? retryStrategy})
      : _retryStrategy = retryStrategy ??
            ExponentialBackoffRetryStrategy(
              maxRetries: 5,
              initialDelay: const Duration(seconds: 2),
              maxDelay: const Duration(seconds: 2),
            );

  final RouterRepository _routerRepository;
  final RetryStrategy _retryStrategy;

  /// Sets userAcknowledgedAutoConfiguration flag on the router.
  ///
  /// Awaits the JNAP response to ensure the operation completes.
  ///
  /// JNAP Action: [JNAPAction.setUserAcknowledgedAutoConfiguration]
  ///
  /// Returns: [Future<void>] completes when operation succeeds
  ///
  /// Throws: [ServiceError] if operation fails
  Future<void> setUserAcknowledgedAutoConfiguration() async {
    try {
      await _routerRepository.send(
        JNAPAction.setUserAcknowledgedAutoConfiguration,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        data: {},
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Fetches current firmware update settings and enables auto-update policy.
  ///
  /// If fetching current settings fails, uses default settings:
  /// - updatePolicy: firmwareUpdatePolicyAuto
  /// - autoUpdateWindow: startMinute=0, durationMinutes=240
  ///
  /// JNAP Actions:
  /// - GET: [JNAPAction.getFirmwareUpdateSettings]
  /// - SET: [JNAPAction.setFirmwareUpdateSettings]
  ///
  /// Returns: [Future<void>] completes when settings are saved
  ///
  /// Throws: [ServiceError] if save operation fails
  Future<void> setFirmwareUpdatePolicy() async {
    // Get current firmware update settings
    final firmwareUpdateSettings = await _routerRepository
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
      // Use default settings on fetch failure
      return FirmwareUpdateSettings(
        updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
        autoUpdateWindow: FirmwareAutoUpdateWindow(
          startMinute: 0,
          durationMinutes: 240,
        ),
      );
    });

    // Enable auto firmware update
    try {
      await _routerRepository.send(
        JNAPAction.setFirmwareUpdateSettings,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        data: firmwareUpdateSettings.toMap(),
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Checks internet connection status via JNAP with retry logic.
  ///
  /// Uses [ExponentialBackoffRetryStrategy] with:
  /// - maxRetries: 5
  /// - initialDelay: 2 seconds
  /// - maxDelay: 2 seconds
  ///
  /// JNAP Action: [JNAPAction.getInternetConnectionStatus]
  ///
  /// Returns: [Future<bool>]
  /// - `true` if connectionStatus == 'InternetConnected'
  /// - `false` if not connected, retries exhausted, or error occurred
  ///
  /// Throws: Nothing (returns false on all error conditions)
  Future<bool> checkInternetConnection() async {
    // Make up to 5 attempts to check internet connection total 10 seconds
    return _retryStrategy.execute<bool>(() async {
      final result = await _routerRepository.send(
        JNAPAction.getInternetConnectionStatus,
        fetchRemote: true,
        auth: true,
      );
      logger.i('[FirstTime]: Internet connection status: ${result.output}');
      final connectionStatus = result.output['connectionStatus'];
      return connectionStatus == 'InternetConnected';
    }, shouldRetry: (result) => !result).onError((error, stackTrace) {
      logger.e('[FirstTime]: Error checking internet connection: $error');
      return false;
    });
  }
}
