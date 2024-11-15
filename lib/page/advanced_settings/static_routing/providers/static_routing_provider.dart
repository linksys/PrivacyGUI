import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_routing_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/utils.dart';

final staticRoutingProvider =
    NotifierProvider<StaticRoutingNotifier, StaticRoutingState>(
  () => StaticRoutingNotifier(),
);

class StaticRoutingNotifier extends Notifier<StaticRoutingState> {
  @override
  StaticRoutingState build() => StaticRoutingState.empty();

  Future<StaticRoutingState> fetch([bool force = false]) async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          auth: true,
        )
        .then((value) => RouterLANSettings.fromMap(value.output));
    final ipAddress = lanSettings.ipAddress;
    final subnetMask =
        NetworkUtils.prefixLengthToSubnetMask(lanSettings.networkPrefixLength);

    await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getRoutingSettings, auth: true, fetchRemote: true)
        .then((value) {
      final getRoutingSettings = GetRoutingSettings.fromMap(value.output);
      state = state.copyWith(
        setting: getRoutingSettings,
        routerIp: ipAddress,
        subnetMask: subnetMask,
      );
    });

    return state;
  }

  void updateSettingNetwork(RoutingSettingNetwork option) {
    state = state.copyWith(
      setting: state.setting.copyWith(
        isNATEnabled: option == RoutingSettingNetwork.nat,
        isDynamicRoutingEnabled: option == RoutingSettingNetwork.dynamicRouting,
      ),
    );
  }

  Future<StaticRoutingState> save() {
    return ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.setRoutingSettings,
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          data: SetRoutingSettings(
            isDynamicRoutingEnabled: state.setting.isDynamicRoutingEnabled,
            isNATEnabled: state.setting.isNATEnabled,
            entries: state.setting.entries,
          ).toMap(),
        )
        .then((_) => fetch(true));
  }

  bool isExceedMax() {
    return state.setting.maxStaticRouteEntries == state.setting.entries.length;
  }

  void addRule(NamedStaticRouteEntry rule) {
    state = state.copyWith(
      setting: state.setting.copyWith(
        entries: List.from(state.setting.entries)..add(rule),
      ),
    );
  }

  void editRule(int index, NamedStaticRouteEntry rule) {
    state = state.copyWith(
      setting: state.setting.copyWith(
        entries: List.from(state.setting.entries)
          ..replaceRange(index, index + 1, [rule]),
      ),
    );
  }

  void deleteRule(NamedStaticRouteEntry rule) {
    state = state.copyWith(
      setting: state.setting.copyWith(
        entries: List.from(state.setting.entries)..remove(rule),
      ),
    );
  }
}
