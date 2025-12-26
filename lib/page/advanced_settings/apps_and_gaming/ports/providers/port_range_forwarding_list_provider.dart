import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/port_range_forwarding_service.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final portRangeForwardingListProvider = NotifierProvider<
    PortRangeForwardingListNotifier,
    PortRangeForwardingListState>(() => PortRangeForwardingListNotifier());

final preservablePortRangeForwardingListProvider =
    Provider<PreservableContract>(
  (ref) => ref.watch(portRangeForwardingListProvider.notifier),
);

class PortRangeForwardingListNotifier
    extends Notifier<PortRangeForwardingListState>
    with
        PreservableNotifierMixin<PortRangeForwardingRuleListUIModel,
            PortRangeForwardingListStatus, PortRangeForwardingListState> {
  @override
  PortRangeForwardingListState build() => const PortRangeForwardingListState(
        settings: Preservable(
            original: PortRangeForwardingRuleListUIModel(rules: []),
            current: PortRangeForwardingRuleListUIModel(rules: [])),
        status: PortRangeForwardingListStatus(),
      );

  @override
  Future<(PortRangeForwardingRuleListUIModel?, PortRangeForwardingListStatus?)>
      performFetch(
          {bool forceRemote = false, bool updateStatusOnly = false}) async {
    try {
      final service = ref.read(portRangeForwardingServiceProvider);
      final (rules, status) =
          await service.fetchSettings(forceRemote: forceRemote);

      state = state.copyWith(
        settings: Preservable(original: rules, current: rules),
        status: status,
      );
      return (rules, status);
    } on ServiceError {
      rethrow;
    }
  }

  @override
  Future<void> performSave() async {
    try {
      final service = ref.read(portRangeForwardingServiceProvider);
      await service.saveSettings(state.settings.current);
    } on ServiceError {
      rethrow;
    }
  }

  bool isExceedMax() {
    return state.status.maxRules == state.settings.current.rules.length;
  }

  void addRule(PortRangeForwardingRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..add(rule))));
  }

  void editRule(int index, PortRangeForwardingRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)
                  ..replaceRange(index, index + 1, [rule]))));
  }

  void deleteRule(PortRangeForwardingRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..remove(rule))));
  }
}
