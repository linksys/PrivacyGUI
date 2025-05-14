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
    return isNameValid(rule.name) &&
        isValidSubnetMask(rule.settings.networkPrefixLength) &&
        isValidDestinationIpAddress(rule.settings.destinationLAN) &&
        isValidIpAddress(
            rule.settings.gateway ?? '', rule.settings.interface == 'LAN');
  }

  bool isNameValid(String name) {
    return name.isNotEmpty;
  }

  bool isValidSubnetMask(int perfixLength) {
    return NetworkUtils.isValidSubnetMask(
        NetworkUtils.prefixLengthToSubnetMask(perfixLength));
  }

  bool isValidDestinationIpAddress(String ipAddress) {
    return IpAddressValidator().validate(ipAddress);
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
