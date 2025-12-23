import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_util_mixin.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

final portRangeForwardingRuleProvider = NotifierProvider<
    PortRangeForwardingRuleNotifier,
    PortRangeForwardingRuleState>(() => PortRangeForwardingRuleNotifier());

class PortRangeForwardingRuleNotifier
    extends Notifier<PortRangeForwardingRuleState> with PortUtilMixin {
  @override
  PortRangeForwardingRuleState build() => const PortRangeForwardingRuleState(
      routerIp: '192.168.1.1', subnetMask: '255.255.255.0');

  void init(
    List<PortRangeForwardingRuleUIModel> rules,
    PortRangeForwardingRuleUIModel? rule,
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

  void updateRule(PortRangeForwardingRuleUIModel? rule) {
    state = state.copyWith(rule: () => rule);
  }

  bool isRuleValid() {
    final rule = state.rule;
    if (rule == null) {
      return false;
    }
    return isNameValid(rule.description) &&
        isDeviceIpValidate(rule.internalServerIPAddress) &&
        isPortRangeValid(rule.firstExternalPort, rule.lastExternalPort) &&
        !isPortConflict(
            rule.firstExternalPort, rule.lastExternalPort, rule.protocol);
  }

  bool isNameValid(String name) {
    return name.isNotEmpty;
  }

  bool isDeviceIpValidate(String ipAddress) {
    final localIpValidator =
        IpAddressAsLocalIpValidator(state.routerIp, state.subnetMask);
    return localIpValidator.validate(ipAddress);
  }

  bool isPortRangeValid(int firstPort, int lastPort) {
    return lastPort - firstPort >= 0;
  }

  bool isPortConflict(int firstPort, int lastPort, String protocol) {
    final singlePortsState = ref.read(singlePortForwardingListProvider).current.rules;
    return singlePortsState.any((rule) =>
            rule.externalPort > firstPort &&
            rule.externalPort < lastPort &&
            (protocol == rule.protocol ||
                protocol == 'Both' ||
                rule.protocol == 'Both')) ||
        state.rules.whereIndexed((index, rule) => index != state.editIndex).any(
            (rule) =>
                doesRangeOverlap(
                  rule.firstExternalPort,
                  rule.lastExternalPort,
                  firstPort,
                  lastPort,
                ) &&
                (protocol == rule.protocol ||
                    protocol == 'Both' ||
                    rule.protocol == 'Both'));
  }
}
