import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/ipv6_port_service_list_service.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final ipv6PortServiceListProvider =
    NotifierProvider<Ipv6PortServiceListNotifier, Ipv6PortServiceListState>(
        () => Ipv6PortServiceListNotifier());

final preservableIpv6PortServiceListProvider = Provider<PreservableContract>(
  (ref) => ref.watch(ipv6PortServiceListProvider.notifier),
);

class Ipv6PortServiceListNotifier extends Notifier<Ipv6PortServiceListState>
    with
        PreservableNotifierMixin<IPv6PortServiceRuleUIList,
            Ipv6PortServiceListStatus, Ipv6PortServiceListState> {
  @override
  Ipv6PortServiceListState build() {
    return const Ipv6PortServiceListState(
      settings: Preservable(
        original: IPv6PortServiceRuleUIList(rules: []),
        current: IPv6PortServiceRuleUIList(rules: []),
      ),
      status: Ipv6PortServiceListStatus(),
    );
  }

  @override
  Future<(IPv6PortServiceRuleUIList?, Ipv6PortServiceListStatus?)>
      performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final service = ref.read(ipv6PortServiceListServiceProvider);

      // Delegate to service layer for JNAP communication and transformation
      final (uiRules, _) = await service.fetchRulesFromDevice(
        ref,
        forceRemote: forceRemote,
      );

      if (uiRules == null) {
        return (null, null);
      }

      // Return UI rules with default status
      return (uiRules, const Ipv6PortServiceListStatus());
    } catch (e) {
      throw Exception(
        'Failed to fetch IPv6 port service rules: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> performSave() async {
    try {
      final service = ref.read(ipv6PortServiceListServiceProvider);

      // Delegate to service layer for transformation and JNAP communication
      await service.saveRulesToDevice(ref, state.current.rules);

      // Update original to match current (commit the save)
      state = state.copyWith(
        settings: state.settings.copyWith(
          original: state.settings.current,
        ),
      );
    } catch (e) {
      throw Exception(
          'Failed to save IPv6 port service rules: ${e.toString()}');
    }
  }

  /// Initializes the rules list (for testing and UI initialization)
  void setRules(List<IPv6PortServiceRuleUI> rules) {
    final ruleList = IPv6PortServiceRuleUIList(rules: rules);
    state = state.copyWith(
      settings: state.settings.copyWith(
        original: ruleList,
        current: ruleList,
      ),
    );
  }

  bool isExceedMax() {
    return state.status.maxRules <= state.current.rules.length;
  }

  /// Adds a new rule to the current list
  /// Updates the current state without fetching (local change only)
  void addRule(IPv6PortServiceRuleUI rule) {
    if (isExceedMax()) {
      throw Exception(
          'Maximum number of rules (${state.status.maxRules}) reached');
    }

    final updatedRules = [...state.current.rules, rule];
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(rules: updatedRules),
      ),
    );
  }

  /// Edits an existing rule at the specified index
  /// Updates the current state without fetching (local change only)
  void editRule(int index, IPv6PortServiceRuleUI newRule) {
    if (index < 0 || index >= state.current.rules.length) {
      throw Exception('Invalid rule index: $index');
    }

    final updatedRules = [...state.current.rules];
    updatedRules[index] = newRule;

    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(rules: updatedRules),
      ),
    );
  }

  /// Deletes a rule from the current list
  /// Updates the current state without fetching (local change only)
  void deleteRule(IPv6PortServiceRuleUI rule) {
    final updatedRules = state.current.rules.where((r) => r != rule).toList();

    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(rules: updatedRules),
      ),
    );
  }

  /// Saves the current rules to the device
  /// Called after add/edit/delete operations
  Future<void> saveRules() async {
    await fetch(forceRemote: true);
  }
}
