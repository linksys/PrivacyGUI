import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

final singlePortForwardingRuleProvider = NotifierProvider<
    SinglePortForwardingRuleNotifier,
    SinglePortForwardingRuleState>(() => SinglePortForwardingRuleNotifier());

class SinglePortForwardingRuleNotifier
    extends Notifier<SinglePortForwardingRuleState> {
  @override
  SinglePortForwardingRuleState build() => const SinglePortForwardingRuleState(
      routerIp: '192.168.1.1', subnetMask: '255.255.255.0');

  void init(
    List<SinglePortForwardingRule> rules,
    SinglePortForwardingRule? rule,
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

  void updateRule(SinglePortForwardingRule? rule) {
    state = state.copyWith(rule: () => rule);
  }

  bool isRuleValid() {
    final rule = state.rule;
    if (rule == null) {
      return false;
    }
    return rule.description.isNotEmpty &&
        isDeviceIpValidate(rule.internalServerIPAddress) &&
        !isPortConflict(rule.externalPort, rule.protocol);
  }

  bool isDeviceIpValidate(String ipAddress) {
    final localIpValidator =
        IpAddressAsLocalIpValidator(state.routerIp, state.subnetMask);
    return localIpValidator.validate(ipAddress);
  }

  bool isPortConflict(int externalPort, String protocol) {
    final portRangeState = ref.read(portRangeForwardingListProvider).rules;
    return portRangeState.any((rule) =>
            externalPort > rule.firstExternalPort &&
            externalPort < rule.lastExternalPort &&
            (protocol == rule.protocol ||
                protocol == 'Both' ||
                rule.protocol == 'Both')) ||
        state.rules.whereIndexed((index, rule) => index != state.editIndex).any(
            (rule) =>
                rule.externalPort == externalPort &&
                (protocol == rule.protocol ||
                    protocol == 'Both' ||
                    rule.protocol == 'Both'));
  }
}
