import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/utils.dart';

final singlePortForwardingListProvider = NotifierProvider<
    SinglePortForwardingListNotifier,
    SinglePortForwardingListState>(() => SinglePortForwardingListNotifier());

final preservableSinglePortForwardingListProvider =
    Provider<PreservableContract>(
  (ref) => ref.watch(singlePortForwardingListProvider.notifier),
);

class SinglePortForwardingListNotifier
    extends Notifier<SinglePortForwardingListState>
    with
        PreservableNotifierMixin<SinglePortForwardingRuleList,
            SinglePortForwardingListStatus, SinglePortForwardingListState> {
  @override
  SinglePortForwardingListState build() => const SinglePortForwardingListState(
        settings: Preservable(
            original: SinglePortForwardingRuleList(rules: []),
            current: SinglePortForwardingRuleList(rules: [])),
        status: SinglePortForwardingListStatus(),
      );

  @override
  Future<(SinglePortForwardingRuleList?, SinglePortForwardingListStatus?)>
      performFetch(
          {bool forceRemote = false, bool updateStatusOnly = false}) async {
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
    final value = await repo.send(
      JNAPAction.getSinglePortForwardingRules,
      fetchRemote: forceRemote,
      auth: true,
    );
    final rules = List.from(value.output['rules'])
        .map((e) => SinglePortForwardingRule.fromMap(e))
        .toList();
    final int maxRules = value.output['maxRules'] ?? 50;
    final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
    final status = SinglePortForwardingListStatus(
      maxRules: maxRules,
      maxDescriptionLength: maxDesc,
      routerIp: ipAddress,
      subnetMask: subnetMask,
    );
    state = state.copyWith(
        settings: Preservable(
            original: SinglePortForwardingRuleList(rules: rules),
            current: SinglePortForwardingRuleList(rules: rules)),
        status: status);
    return (SinglePortForwardingRuleList(rules: rules), status);
  }

  @override
  Future<void> performSave() async {
    final rules =
        List<SinglePortForwardingRule>.from(state.settings.current.rules);
    final repo = ref.read(routerRepositoryProvider);
    await repo.send(
      JNAPAction.setSinglePortForwardingRules,
      data: {'rules': rules.map((e) => e.toMap()).toList()},
      auth: true,
    );
  }

  bool isExceedMax() {
    return state.status.maxRules == state.settings.current.rules.length;
  }

  void addRule(SinglePortForwardingRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..add(rule))));
  }

  void editRule(int index, SinglePortForwardingRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)
                  ..replaceRange(index, index + 1, [rule]))));
  }

  void deleteRule(SinglePortForwardingRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..remove(rule))));
  }
}
