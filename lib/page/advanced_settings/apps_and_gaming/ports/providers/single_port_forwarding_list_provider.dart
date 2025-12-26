import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/single_port_forwarding_service.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

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
        PreservableNotifierMixin<SinglePortForwardingRuleListUIModel,
            SinglePortForwardingListStatus, SinglePortForwardingListState> {
  @override
  SinglePortForwardingListState build() => const SinglePortForwardingListState(
        settings: Preservable(
            original: SinglePortForwardingRuleListUIModel(rules: []),
            current: SinglePortForwardingRuleListUIModel(rules: [])),
        status: SinglePortForwardingListStatus(),
      );

  @override
  Future<
          (
            SinglePortForwardingRuleListUIModel?,
            SinglePortForwardingListStatus?
          )>
      performFetch(
          {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(singlePortForwardingServiceProvider);
    final (settings, status) =
        await service.fetchSettings(forceRemote: forceRemote);

    state = state.copyWith(
        settings: Preservable(original: settings, current: settings),
        status: status);
    return (settings, status);
  }

  @override
  Future<void> performSave() async {
    final service = ref.read(singlePortForwardingServiceProvider);
    await service.saveSettings(state.settings.current);
  }

  bool isExceedMax() {
    return state.status.maxRules == state.settings.current.rules.length;
  }

  void addRule(SinglePortForwardingRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..add(rule))));
  }

  void editRule(int index, SinglePortForwardingRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)
                  ..replaceRange(index, index + 1, [rule]))));
  }

  void deleteRule(SinglePortForwardingRuleUIModel rule) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(
                rules: List.from(state.settings.current.rules)..remove(rule))));
  }
}
