import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_routing_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/utils.dart';

final staticRoutingProvider =
    NotifierProvider<StaticRoutingNotifier, StaticRoutingState>(
  () => StaticRoutingNotifier(),
);

class StaticRoutingNotifier extends Notifier<StaticRoutingState>
    with
        PreservableNotifierMixin<StaticRoutingSettings, StaticRoutingStatus,
            StaticRoutingState> {
  @override
  StaticRoutingState build() {
    return StaticRoutingState.empty();
  }

  @override
  Future<void> performFetch() async {
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

    final value = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getRoutingSettings, auth: true, fetchRemote: true);

    final getRoutingSettings = GetRoutingSettings.fromMap(value.output);
    state = state.copyWith(
      settings: state.settings.copyWith(setting: getRoutingSettings),
      status: state.status.copyWith(
        routerIp: ipAddress,
        subnetMask: subnetMask,
      ),
    );
  }

  void updateSettingNetwork(RoutingSettingNetwork option) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        setting: state.settings.setting.copyWith(
          isNATEnabled: option == RoutingSettingNetwork.nat,
          isDynamicRoutingEnabled:
              option == RoutingSettingNetwork.dynamicRouting,
        ),
      ),
    );
  }

  @override
  Future<void> performSave() async {
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setRoutingSettings,
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          data: SetRoutingSettings(
            isDynamicRoutingEnabled:
                state.settings.setting.isDynamicRoutingEnabled,
            isNATEnabled: state.settings.setting.isNATEnabled,
            entries: state.settings.setting.entries,
          ).toMap(),
        );
  }

  bool isExceedMax() {
    return state.settings.setting.maxStaticRouteEntries ==
        state.settings.setting.entries.length;
  }

  void addRule(NamedStaticRouteEntry rule) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        setting: state.settings.setting.copyWith(
          entries: List.from(state.settings.setting.entries)..add(rule),
        ),
      ),
    );
  }

  void editRule(int index, NamedStaticRouteEntry rule) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        setting: state.settings.setting.copyWith(
          entries: List.from(state.settings.setting.entries)
            ..replaceRange(index, index + 1, [rule]),
        ),
      ),
    );
  }

  void deleteRule(NamedStaticRouteEntry rule) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        setting: state.settings.setting.copyWith(
          entries: List.from(state.settings.setting.entries)..remove(rule),
        ),
      ),
    );
  }
}

final preservableStaticRoutingProvider = Provider.autoDispose<
    PreservableContract<StaticRoutingSettings, StaticRoutingStatus>>((ref) {
  return ref.watch(staticRoutingProvider.notifier);
});
