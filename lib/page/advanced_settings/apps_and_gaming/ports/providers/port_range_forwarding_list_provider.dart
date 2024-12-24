import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/utils.dart';

final portRangeForwardingListProvider = NotifierProvider<
    PortRangeForwardingListNotifier,
    PortRangeForwardingListState>(() => PortRangeForwardingListNotifier());

class PortRangeForwardingListNotifier
    extends Notifier<PortRangeForwardingListState> {
  @override
  PortRangeForwardingListState build() => const PortRangeForwardingListState();

  Future<PortRangeForwardingListState> fetch([bool force = false]) async {
    final repo = ref.read(routerRepositoryProvider);

    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          auth: true,
          fetchRemote: force,
        )
        .then((value) => RouterLANSettings.fromMap(value.output));
    final ipAddress = lanSettings.ipAddress;
    final subnetMask =
        NetworkUtils.prefixLengthToSubnetMask(lanSettings.networkPrefixLength);

    await repo
        .send(JNAPAction.getPortRangeForwardingRules,
            fetchRemote: true, auth: true)
        .then((value) {
      final rules = List.from(value.output['rules'])
          .map((e) => PortRangeForwardingRule.fromMap(e))
          .toList();
      final int maxRules = value.output['maxRules'] ?? 50;
      final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
      state = state.copyWith(
        rules: rules,
        maxRules: maxRules,
        maxDescriptionLength: maxDesc,
        routerIp: ipAddress,
        subnetMask: subnetMask,
      );
    });
    return state;
  }

  Future<PortRangeForwardingListState> save() async {
    final rules = List<PortRangeForwardingRule>.from(state.rules);
    final repo = ref.read(routerRepositoryProvider);
    await repo.send(
      JNAPAction.setPortRangeForwardingRules,
      data: {'rules': rules.map((e) => e.toMap()).toList()},
      auth: true,
    );
  
    await fetch(true);
    return state;
  }

  bool isExceedMax() {
    return state.maxRules == state.rules.length;
  }

  void addRule(PortRangeForwardingRule rule) {
    state = state.copyWith(rules: List.from(state.rules)..add(rule));
  }

  void editRule(int index, PortRangeForwardingRule rule) {
    state = state.copyWith(
        rules: List.from(state.rules)..replaceRange(index, index + 1, [rule]));
  }

  void deleteRule(PortRangeForwardingRule rule) {
    state = state.copyWith(rules: List.from(state.rules)..remove(rule));
  }
}
