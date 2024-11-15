import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';

final portRangeTriggeringListProvider = NotifierProvider<
    PortRangeTriggeringListNotifier,
    PortRangeTriggeringListState>(() => PortRangeTriggeringListNotifier());

class PortRangeTriggeringListNotifier
    extends Notifier<PortRangeTriggeringListState> {
  @override
  PortRangeTriggeringListState build() => const PortRangeTriggeringListState();

  Future<PortRangeTriggeringListState> fetch([bool force = false]) async {
    final repo = ref.read(routerRepositoryProvider);
    await repo
        .send(
      JNAPAction.getPortRangeTriggeringRules,
      fetchRemote: force,
      auth: true,
    )
        .then<JNAPSuccess?>((value) {
      final rules = List.from(value.output['rules'])
          .map((e) => PortRangeTriggeringRule.fromMap(e))
          .toList();
      final int maxRules = value.output['maxRules'] ?? 50;
      final int maxDesc = value.output['maxDescriptionLength'] ?? 32;
      state = state.copyWith(
          rules: rules, maxRules: maxRules, maxDescriptionLength: maxDesc);
      return null;
    }).onError(
      (error, stackTrace) {
        return null;
      },
    );
    return state;
  }

  Future<PortRangeTriggeringListState> save() async {
    final rules = List<PortRangeTriggeringRule>.from(state.rules);
    final repo = ref.read(routerRepositoryProvider);
    await repo
        .send(
          JNAPAction.setPortRangeTriggeringRules,
          data: {'rules': rules.map((e) => e.toMap()).toList()},
          auth: true,
        )
        .then((value) => true)
        .onError((error, stackTrace) => false);
    await fetch(true);
    return state;
  }

  bool isExceedMax() {
    return state.maxRules == state.rules.length;
  }

  void addRule(PortRangeTriggeringRule rule) {
    state = state.copyWith(rules: List.from(state.rules)..add(rule));
  }

  void editRule(int index, PortRangeTriggeringRule rule) {
    state = state.copyWith(
        rules: List.from(state.rules)..replaceRange(index, index + 1, [rule]));
  }

  void deleteRule(PortRangeTriggeringRule rule) {
    state = state.copyWith(rules: List.from(state.rules)..remove(rule));
  }
}
