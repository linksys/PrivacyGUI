import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/port_range_triggering_service.dart';
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
        PreservableNotifierMixin<PortRangeTriggeringRuleListUIModel,
            PortRangeTriggeringListStatus, PortRangeTriggeringListState> {
  @override
  PortRangeTriggeringListState build() => const PortRangeTriggeringListState(
        settings: Preservable(
            original: PortRangeTriggeringRuleListUIModel(rules: []),
            current: PortRangeTriggeringRuleListUIModel(rules: [])),
        status: PortRangeTriggeringListStatus(),
      );

  @override
  Future<(PortRangeTriggeringRuleListUIModel?, PortRangeTriggeringListStatus?)>
      performFetch(
          {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(portRangeTriggeringServiceProvider);
    final (rules, status) =
        await service.fetchSettings(forceRemote: forceRemote);

    state = state.copyWith(
        settings: Preservable(original: rules, current: rules), status: status);
    return (rules, status);
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(portRangeTriggeringServiceProvider);
    await service.saveSettings(state.settings.current);
  }

  bool isExceedMax() {
    return state.status.maxRules == state.settings.current.rules.length;
  }

  void addRule(PortRangeTriggeringRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..add(rule))));
  }

  void editRule(int index, PortRangeTriggeringRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)
                  ..replaceRange(index, index + 1, [rule]))));
  }

  void deleteRule(PortRangeTriggeringRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..remove(rule))));
  }
}
