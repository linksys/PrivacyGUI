import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_state.dart';

final nodeLightSettingsServiceProvider =
    Provider<NodeLightSettingsService>((ref) {
  return NodeLightSettingsService(ref.watch(routerRepositoryProvider));
});

/// Service for LED night mode settings operations.
///
/// Handles JNAP communication for retrieving and persisting
/// LED night mode configuration. Handles conversion between
/// core JNAP data ([NodeLightSettings]) and UI state ([NodeLightState]).
class NodeLightSettingsService {
  final RouterRepository _routerRepository;

  NodeLightSettingsService(this._routerRepository);

  /// Retrieves current LED night mode settings from router data.
  ///
  /// [forceRemote] - If true, bypasses cache and fetches from device.
  ///
  /// Returns: [NodeLightState] converted from router response.
  Future<NodeLightState> fetchState({bool forceRemote = false}) async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getLedNightModeSetting,
        auth: true,
        fetchRemote: forceRemote,
      );
      final rawSettings = NodeLightSettings.fromMap(result.output);
      final state = _toState(rawSettings);
      logger.d(
          '[Service]:[NodeLightSettings]: Fetched State $state from $rawSettings');
      return state;
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Persists UI state to router.
  ///
  /// [state] - The UI state to save.
  ///
  /// Returns: [NodeLightState] - Refreshed state after save.
  Future<NodeLightState> saveState(NodeLightState state) async {
    try {
      final settings = _fromState(state);
      await _routerRepository.send(
        JNAPAction.setLedNightModeSetting,
        data: {
          'Enable': settings.isNightModeEnable,
          'StartingTime': settings.startHour,
          'EndingTime': settings.endHour,
        }..removeWhere((key, value) => value == null),
        auth: true,
      );
      logger
          .d('[Service]:[NodeLightSettings]: Saved State $state as $settings');
      // Re-fetch to get confirmed state from device
      return fetchState(forceRemote: true);
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  // --- Adapters ---

  NodeLightState _toState(NodeLightSettings settings) {
    return NodeLightState(
      isNightModeEnabled: settings.isNightModeEnable,
      startHour: settings.startHour ?? 0,
      endHour: settings.endHour ?? 0,
      // allDayOff log derived from start==0 && end==24 or specific logic if JNAP supports it directly,
      // but strictly speaking Model -> UI mapping for allDayOff depends on business rule.
      // node_light_settings.dart L37 in original provider implied:
      // (state.allDayOff ?? false) || (state.startHour == 0 && state.endHour == 24)
      allDayOff: (settings.allDayOff == true) ||
          (settings.startHour == 0 && settings.endHour == 24),
    );
  }

  NodeLightSettings _fromState(NodeLightState state) {
    // If allDayOff is true, JNAP usually expects Start=0, End=24 and Enable=true (Night Mode covers whole day = OFF)
    // Or maybe Enable=false means ON?
    // Let's check original logic:
    // status==off => allDayOff.
    // In Original: NodeLightStatus.off if allDayOff || (0,24).
    // NodeLightStatus.night if isNightModeEnable && !off.
    // NodeLightStatus.on if !isNightModeEnable.

    // If UI state says allDayOff:
    if (state.allDayOff) {
      return NodeLightSettings(
        isNightModeEnable: true,
        startHour: 0,
        endHour: 24,
        allDayOff: true,
      );
    }
    return NodeLightSettings(
      isNightModeEnable: state.isNightModeEnabled,
      startHour: state.startHour,
      endHour: state.endHour,
    );
  }

  /// Maps JNAP errors to ServiceError types.
  ServiceError _mapJnapError(JNAPError error) {
    return switch (error.result) {
      '_ErrorUnauthorized' => const UnauthorizedError(),
      _ => UnexpectedError(originalError: error, message: error.result),
    };
  }
}
