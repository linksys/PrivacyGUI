import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_routing_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/utils.dart';

final staticRoutingProvider =
    NotifierProvider<StaticRoutingNotifier, StaticRoutingState>(
  () => StaticRoutingNotifier(),
);

final preservableStaticRoutingProvider = Provider<PreservableContract>(
  (ref) => ref.watch(staticRoutingProvider.notifier),
);

class StaticRoutingNotifier extends Notifier<StaticRoutingState>
    with
        PreservableNotifierMixin<StaticRoutingSettings, StaticRoutingStatus,
            StaticRoutingState> {
  @override
  StaticRoutingState build() => StaticRoutingState.empty();

  @override
  Future<(StaticRoutingSettings?, StaticRoutingStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          auth: true,
          fetchRemote: forceRemote,
        )
        .then((value) => RouterLANSettings.fromMap(value.output));
    final ipAddress = lanSettings.ipAddress;
    final subnetMask =
        NetworkUtils.prefixLengthToSubnetMask(lanSettings.networkPrefixLength);

    final value = await ref.read(routerRepositoryProvider).send(
        JNAPAction.getRoutingSettings,
        auth: true,
        fetchRemote: forceRemote);
    final getRoutingSettings = GetRoutingSettings.fromMap(value.output);

    final settings = StaticRoutingSettings(
      isNATEnabled: getRoutingSettings.isNATEnabled,
      isDynamicRoutingEnabled: getRoutingSettings.isDynamicRoutingEnabled,
      entries: NamedStaticRouteEntryList(entries: getRoutingSettings.entries),
    );
    final status = StaticRoutingStatus(
      maxStaticRouteEntries: getRoutingSettings.maxStaticRouteEntries,
      routerIp: ipAddress,
      subnetMask: subnetMask,
    );

    return (settings, status);
  }

  void updateSettingNetwork(RoutingSettingNetwork option) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
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
                state.settings.current.isDynamicRoutingEnabled,
            isNATEnabled: state.settings.current.isNATEnabled,
            entries: state.settings.current.entries.entries,
          ).toMap(),
        );
  }

  bool isExceedMax() {
    return state.status.maxStaticRouteEntries ==
        state.settings.current.entries.entries.length;
  }

  void addRule(NamedStaticRouteEntry rule) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          entries: state.settings.current.entries.copyWith(
            entries: List.from(state.settings.current.entries.entries)
              ..add(rule),
          ),
        ),
      ),
    );
  }

  void editRule(int index, NamedStaticRouteEntry rule) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          entries: state.settings.current.entries.copyWith(
            entries: List.from(state.settings.current.entries.entries)
              ..replaceRange(index, index + 1, [rule]),
          ),
        ),
      ),
    );
  }

  void deleteRule(NamedStaticRouteEntry rule) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          entries: state.settings.current.entries.copyWith(
            entries: List.from(state.settings.current.entries.entries)
              ..remove(rule),
          ),
        ),
      ),
    );
  }
}
