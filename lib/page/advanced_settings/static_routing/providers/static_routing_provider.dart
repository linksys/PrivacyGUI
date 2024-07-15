import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_routing_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';

final staticRoutingProvider =
    NotifierProvider<StaticRoutingNotifier, StaticRoutingState>(
  () => StaticRoutingNotifier(),
);

class StaticRoutingNotifier extends Notifier<StaticRoutingState> {
  @override
  StaticRoutingState build() => StaticRoutingState.empty();

  Future<void> fetchSettings() {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getRoutingSettings, auth: true, fetchRemote: true)
        .then((value) {
      final getRoutingSettings = GetRoutingSettings.fromMap(value.output);
      state = state.copyWith(setting: getRoutingSettings);
    });
  }

  Future<void> saveRoutingSettingNetork(RoutingSettingNetwork option) {
    final updatedState = SetRoutingSettings(
      isNATEnabled: option == RoutingSettingNetwork.nat,
      isDynamicRoutingEnabled: option == RoutingSettingNetwork.dynamicRouting,
      entries: state.setting.entries,
    );
    return _saveSettings(updatedState);
  }

  Future<void> saveRoutingSettingList(List<NamedStaticRouteEntry> entries) {
    final updatedState = SetRoutingSettings(
      isNATEnabled: state.setting.isNATEnabled,
      isDynamicRoutingEnabled: state.setting.isDynamicRoutingEnabled,
      entries: entries,
    );
    return _saveSettings(updatedState);
  }

  Future<void> _saveSettings(SetRoutingSettings setting) {
    return ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.setRoutingSettings,
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          data: setting.toMap(),
        )
        .then((_) => fetchSettings());
  }

  // setSettings(FirewallSettings settings) {
  //   state = state.copyWith(settings: settings);
  // }
}
