import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/utils.dart';

final singlePortForwardingListProvider = NotifierProvider<
    SinglePortForwardingListNotifier,
    SinglePortForwardingListState>(() => SinglePortForwardingListNotifier());

class SinglePortForwardingListNotifier
    extends Notifier<SinglePortForwardingListState> {
  @override
  SinglePortForwardingListState build() =>
      const SinglePortForwardingListState();

  Future<SinglePortForwardingListState> fetch([bool force = false]) async {
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
    await repo
        .send(
      JNAPAction.getSinglePortForwardingRules,
      fetchRemote: force,
      auth: true,
    )
        .then<JNAPSuccess?>((value) {
      final rules = List.from(value.output['rules'])
          .map((e) => SinglePortForwardingRule.fromMap(e))
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
    }).onError(
      (error, stackTrace) {
        return null;
      },
    );
    return state;
  }

  Future<SinglePortForwardingListState> save() async {
    final rules = List<SinglePortForwardingRule>.from(state.rules);
    final repo = ref.read(routerRepositoryProvider);
    await repo.send(
      JNAPAction.setSinglePortForwardingRules,
      data: {'rules': rules.map((e) => e.toMap()).toList()},
      auth: true,
    );
    await fetch(true);
    return state;
  }

  bool isExceedMax() {
    return state.maxRules == state.rules.length;
  }

  void addRule(SinglePortForwardingRule rule) {
    state = state.copyWith(rules: List.from(state.rules)..add(rule));
  }

  void editRule(int index, SinglePortForwardingRule rule) {
    state = state.copyWith(
        rules: List.from(state.rules)..replaceRange(index, index + 1, [rule]));
  }

  void deleteRule(SinglePortForwardingRule rule) {
    state = state.copyWith(rules: List.from(state.rules)..remove(rule));
  }
}
