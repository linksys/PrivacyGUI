import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

final nodeLightSettingsProvider =
    NotifierProvider<NodeLightSettingsNotifier, NodeLightSettings>(
        () => NodeLightSettingsNotifier());

class NodeLightSettingsNotifier extends Notifier<NodeLightSettings> {
  @override
  NodeLightSettings build() {
    return NodeLightSettings(isNightModeEnable: false);
  }

  Future<NodeLightSettings> fetch([bool forceRemote = false]) async {
    final routerRepository = ref.read(routerRepositoryProvider);
    final result = await routerRepository.send(
      JNAPAction.getLedNightModeSetting,
      auth: true,
      fetchRemote: forceRemote,
    );
    state = NodeLightSettings.fromMap(result.output);
    logger.d('[State]:[NodeLightSettings]: ${state.toJson()}');
    return state;
  }

  Future<NodeLightSettings> save() async {
    final settings = state;
    final routerRepository = ref.read(routerRepositoryProvider);
    await routerRepository.send(
      JNAPAction.setLedNightModeSetting,
      data: {
        'Enable': settings.isNightModeEnable,
        'StartingTime': settings.startHour,
        'EndingTime': settings.endHour,
      }..removeWhere((key, value) => value == null),
      auth: true,
    );
    await fetch(true);
    return state;
  }

  void setSettings(NodeLightSettings settings) {
    state = settings;
  }

  /// Returns the current node light status based on settings.
  /// This provides a UI-friendly enum value derived from the raw settings.
  NodeLightStatus get currentStatus {
    if ((state.allDayOff ?? false) ||
        (state.startHour == 0 && state.endHour == 24)) {
      return NodeLightStatus.off;
    } else if (!state.isNightModeEnable) {
      return NodeLightStatus.on;
    } else {
      return NodeLightStatus.night;
    }
  }
}
