import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

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
}
