import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

final staticRoutingRuleProvider =
    NotifierProvider<StaticRoutingRuleNotifier, StaticRoutingRuleState>(
        () => StaticRoutingRuleNotifier());

class StaticRoutingRuleNotifier extends Notifier<StaticRoutingRuleState> {
  @override
  StaticRoutingRuleState build() => const StaticRoutingRuleState(
      routerIp: '192.168.1.1', subnetMask: '255.255.255.0');

  void init(
    List<NamedStaticRouteEntry> rules,
    NamedStaticRouteEntry? rule,
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

  void updateRule(NamedStaticRouteEntry? rule) {
    state = state.copyWith(rule: () => rule);
  }

  bool isRuleValid() {
    final rule = state.rule;
    if (rule == null) {
      return false;
    }
    return rule.name.isNotEmpty &&
        isValidSubnetMask(rule.settings.networkPrefixLength) &&
        isValidIpAddress(rule.settings.destinationLAN) &&
        (rule.settings.gateway == null ||
            isValidIpAddress(
                rule.settings.gateway!, rule.settings.interface == 'LAN'));
  }

  bool isValidSubnetMask(int perfixLength) {
    return NetworkUtils.isValidSubnetMask(
        NetworkUtils.prefixLengthToSubnetMask(perfixLength));
  }

  bool isValidIpAddress(String ipAddress, [bool localIPOnly = false]) {
    final validator = localIPOnly
        ? IpAddressAsLocalIpValidator(state.routerIp, state.subnetMask)
        : IpAddressValidator();
    return validator.validate(ipAddress);
  }
}
