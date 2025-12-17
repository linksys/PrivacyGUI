import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_routing_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

final staticRoutingRuleProvider =
    NotifierProvider<StaticRoutingRuleNotifier, StaticRoutingRuleState>(
        () => StaticRoutingRuleNotifier());

/// Notifier for managing a single static routing rule being edited
///
/// This notifier manages the state for editing one routing rule in the detail view.
/// It validates rule properties and provides methods to update the rule.
class StaticRoutingRuleNotifier extends Notifier<StaticRoutingRuleState> {
  @override
  StaticRoutingRuleState build() => const StaticRoutingRuleState(
      routerIp: '192.168.1.1', subnetMask: '255.255.255.0');

  /// Initialize the rule editor with a list of rules and the rule being edited
  ///
  /// Parameters:
  /// - [rules]: List of existing rules for duplicate detection
  /// - [rule]: The rule being edited (null if creating new)
  /// - [index]: The index of the rule (null if creating new)
  /// - [routerIp]: Device router IP for validation context
  /// - [subnetMask]: Device subnet mask for validation context
  void init(
    List<StaticRoutingRuleUIModel> rules,
    StaticRoutingRuleUIModel? rule,
    int? index,
    String routerIp,
    String subnetMask,
  ) {
    state = state.copyWith(
      rules: rules,
      rule: () => rule,
      routerIp: routerIp,
      subnetMask: subnetMask,
      editIndex: () => index,
    );
  }

  /// Update the current rule being edited
  void updateRule(StaticRoutingRuleUIModel? rule) {
    state = state.copyWith(rule: () => rule);
  }

  bool isRuleValid() {
    final rule = state.rule;
    if (rule == null) {
      return false;
    }
    return isNameValid(rule.name) &&
        isValidSubnetMask(rule.networkPrefixLength) &&
        IpAddressValidator().validate(rule.destinationIP) &&
        isValidIpAddress(rule.gateway ?? '', rule.interface == 'LAN');
  }

  bool isNameValid(String name) {
    return name.isNotEmpty;
  }

  bool isValidSubnetMask(int perfixLength) {
    return NetworkUtils.isValidSubnetMask(
        NetworkUtils.prefixLengthToSubnetMask(perfixLength));
  }

  bool isValidIpAddress(String ipAddress, [bool localIPOnly = false]) {
    if (localIPOnly) {
      return IpAddressAsLocalIpValidator(state.routerIp, state.subnetMask)
          .validate(ipAddress);
    } else {
      return IpAddressValidator().validate(ipAddress) &&
          !IpAddressAsLocalIpValidator(state.routerIp, state.subnetMask)
              .validate(ipAddress);
    }
  }
}
