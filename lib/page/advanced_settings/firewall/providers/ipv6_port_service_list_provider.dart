import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
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
    // TODO: Implement with IPv6PortServiceListService (US2)
    return (null, null);
  }

  @override
  Future<void> performSave() async {
    // Save is handled individually by add/update/delete operations
    // This implementation is kept for PreservableNotifierMixin compatibility
    throw UnimplementedError(
      'Save is handled by individual add/update/delete operations',
    );
  }

  bool isExceedMax() {
    return state.status.maxRules == state.current.rules.length;
  }

  Future<void> addRule(IPv6PortServiceRuleUI rule) async {
    // TODO: Implement with IPv6PortServiceListService (US2)
    await fetch(forceRemote: true);
  }

  Future<void> editRule(int index, IPv6PortServiceRuleUI newRule) async {
    // TODO: Implement with IPv6PortServiceListService (US2)
    await fetch(forceRemote: true);
  }

  Future<void> deleteRule(IPv6PortServiceRuleUI rule) async {
    // TODO: Implement with IPv6PortServiceListService (US2)
    await fetch(forceRemote: true);
  }
}
