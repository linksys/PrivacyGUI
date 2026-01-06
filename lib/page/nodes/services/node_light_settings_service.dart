import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';

final nodeLightSettingsServiceProvider =
    Provider<NodeLightSettingsService>((ref) {
  return NodeLightSettingsService(ref.watch(routerRepositoryProvider));
});

/// Service for LED night mode settings operations.
///
/// Handles JNAP communication for retrieving and persisting
/// LED night mode configuration. Stateless - all state management
/// is delegated to NodeLightSettingsNotifier.
class NodeLightSettingsService {
  final RouterRepository _routerRepository;

  NodeLightSettingsService(this._routerRepository);

  /// Retrieves current LED night mode settings from router.
  ///
  /// [forceRemote] - If true, bypasses cache and fetches from device.
  ///                 Default: false (may use cached data).
  ///
  /// Returns: [NodeLightSettings] with current configuration.
  ///
  /// Throws:
  /// - [UnauthorizedError] if authentication fails
  /// - [UnexpectedError] for other JNAP errors
  Future<NodeLightSettings> fetchSettings({bool forceRemote = false}) async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getLedNightModeSetting,
        auth: true,
        fetchRemote: forceRemote,
      );
      final settings = NodeLightSettings.fromMap(result.output);
      logger.d('[Service]:[NodeLightSettings]: Fetched ${settings.toJson()}');
      return settings;
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Persists LED night mode settings to router.
  ///
  /// [settings] - The settings to save. All non-null fields are sent.
  ///
  /// Returns: [NodeLightSettings] - Refreshed settings after save
  ///          (fetches from device to confirm).
  ///
  /// Throws:
  /// - [UnauthorizedError] if authentication fails
  /// - [UnexpectedError] for other JNAP errors
  ///
  /// Behavior:
  /// - Sends Enable, StartingTime, EndingTime to router
  /// - Automatically re-fetches after save to sync state
  /// - Null fields are excluded from request
  Future<NodeLightSettings> saveSettings(NodeLightSettings settings) async {
    try {
      await _routerRepository.send(
        JNAPAction.setLedNightModeSetting,
        data: {
          'Enable': settings.isNightModeEnable,
          'StartingTime': settings.startHour,
          'EndingTime': settings.endHour,
        }..removeWhere((key, value) => value == null),
        auth: true,
      );
      logger.d('[Service]:[NodeLightSettings]: Saved ${settings.toJson()}');
      // Re-fetch to get confirmed state from device
      return fetchSettings(forceRemote: true);
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Maps JNAP errors to ServiceError types.
  ServiceError _mapJnapError(JNAPError error) {
    return switch (error.result) {
      '_ErrorUnauthorized' => const UnauthorizedError(),
      _ => UnexpectedError(originalError: error, message: error.result),
    };
  }
}
