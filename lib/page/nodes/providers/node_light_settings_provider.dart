import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_state.dart';
import 'package:privacy_gui/page/nodes/services/node_light_settings_service.dart';

final nodeLightSettingsProvider =
    NotifierProvider<NodeLightSettingsNotifier, NodeLightState>(
        () => NodeLightSettingsNotifier());

class NodeLightSettingsNotifier extends Notifier<NodeLightState> {
  @override
  NodeLightState build() {
    return NodeLightState.initial();
  }

  /// Fetches the latest settings from the router and updates the state.
  Future<NodeLightState> fetch({bool forceRemote = false}) async {
    final service = ref.read(nodeLightSettingsServiceProvider);
    state = await service.fetchState(forceRemote: forceRemote);
    logger.d('[State]:[NodeLightSettings]: Updated to $state');
    return state;
  }

  /// Saves the current state configurations to the router.
  Future<NodeLightState> save() async {
    final service = ref.read(nodeLightSettingsServiceProvider);
    state = await service.saveState(state);
    return state;
  }

  /// Updates the local state (e.g., from UI interactions) before saving.
  void setSettings(NodeLightState settings) {
    state = settings;
  }

  /// Helper getter for UI consumption, consistent with previous API
  NodeLightStatus get currentStatus => state.status;
}
