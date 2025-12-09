import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final portRangeTriggeringListProvider = NotifierProvider<
    PortRangeTriggeringListNotifier,
    PortRangeTriggeringListState>(() => PortRangeTriggeringListNotifier());

final preservablePortRangeTriggeringListProvider =
    Provider<PreservableContract>(
  (ref) => ref.watch(portRangeTriggeringListProvider.notifier),
);

class PortRangeTriggeringListNotifier
    extends Notifier<PortRangeTriggeringListState>
    with
        PreservableNotifierMixin<PortRangeTriggeringRuleList,
            PortRangeTriggeringListStatus, PortRangeTriggeringListState> {
  @override
  PortRangeTriggeringListState build() => const PortRangeTriggeringListState(
        settings: Preservable(
            original: PortRangeTriggeringRuleList(rules: []),
            current: PortRangeTriggeringRuleList(rules: [])),
        status: PortRangeTriggeringListStatus(),
      );

  @override
  Future<(PortRangeTriggeringRuleList?, PortRangeTriggeringListStatus?)>
      performFetch(
          {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final repo = ref.read(routerRepositoryProvider);
    final value = await repo.send(
      JNAPAction.getPortRangeTriggeringRules,
      fetchRemote: forceRemote,
      auth: true,
    );
    final rules = List.from(value.output['rules'])
        .map((e) => PortRangeTriggeringRule.fromMap(e))
        .toList();
    final int maxRules = value.output['maxRules'] ?? 50;
    final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
    final status = PortRangeTriggeringListStatus(
        maxRules: maxRules, maxDescriptionLength: maxDesc);
    state = state.copyWith(
        settings: Preservable(
            original: PortRangeTriggeringRuleList(rules: rules),
            current: PortRangeTriggeringRuleList(rules: rules)),
        status: status);
    return (PortRangeTriggeringRuleList(rules: rules), status);
  }

  @override
  Future<void> performSave() async {
    final rules =
        List<PortRangeTriggeringRule>.from(state.settings.current.rules);
    final repo = ref.read(routerRepositoryProvider);
    await repo.send(
      JNAPAction.setPortRangeTriggeringRules,
      data: {'rules': rules.map((e) => e.toMap()).toList()},
      auth: true,
    );
  }

  bool isExceedMax() {
    return state.status.maxRules == state.settings.current.rules.length;
  }

  void addRule(PortRangeTriggeringRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..add(rule))));
  }

  void editRule(int index, PortRangeTriggeringRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)
                  ..replaceRange(index, index + 1, [rule]))));
  }

  void deleteRule(PortRangeTriggeringRule rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..remove(rule))));
  }
}
