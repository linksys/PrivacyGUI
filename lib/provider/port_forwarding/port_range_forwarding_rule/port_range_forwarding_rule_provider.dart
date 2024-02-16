import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/port_forwarding/port_range_forwarding_rule/port_range_forwarding_rule_state.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_app/validator_rules/input_validators.dart';

final portRangeForwardingRuleProvider = NotifierProvider<
    PortRangeForwardingRuleNotifier,
    PortRangeForwardingRuleState>(() => PortRangeForwardingRuleNotifier());

class PortRangeForwardingRuleNotifier
    extends Notifier<PortRangeForwardingRuleState> {
  InputValidator? _localIpValidator;
  String _subnetMask = '255.255.0.0';
  String _ipAddress = '192.168.1.1';

  @override
  PortRangeForwardingRuleState build() => const PortRangeForwardingRuleState();

  Future goAdd(List<PortRangeForwardingRule> rules) {
    return fetch().then((value) => state =
        state.copyWith(mode: PortRangeForwardingRuleMode.adding, rules: rules));
  }

  Future goEdit(
      List<PortRangeForwardingRule> rules, PortRangeForwardingRule rule) {
    return fetch().then((value) => state = state.copyWith(
        mode: PortRangeForwardingRuleMode.editing, rules: rules, rule: rule));
  }

  Future fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(JNAPAction.getLANSettings)
        .then((value) => RouterLANSettings.fromJson(value.output));
    _ipAddress = lanSettings.ipAddress;
    _subnetMask =
        Utils.prefixLengthToSubnetMask(lanSettings.networkPrefixLength);
    _localIpValidator = IpAddressAsLocalIpValidator(ipAddress, subnetMask);
  }

  Future<bool> save(PortRangeForwardingRule rule) async {
    final mode = state.mode;
    final rules = List<PortRangeForwardingRule>.from(state.rules);
    if (mode == PortRangeForwardingRuleMode.adding) {
      rules.add(rule);
    } else if (mode == PortRangeForwardingRuleMode.editing) {
      int index = state.rules.indexOf(state.rule!);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo
        .send(
          JNAPAction.setPortRangeForwardingRules,
          auth: true,
          data: {
            'rules': rules.map((e) => e.toJson()).toList(),
          },
        )
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final mode = state.mode;
    if (mode == PortRangeForwardingRuleMode.editing) {
      final rules = List<PortRangeForwardingRule>.from(state.rules)
        ..removeWhere((element) => element == state.rule);
      final repo = ref.read(routerRepositoryProvider);
      final result = await repo
          .send(
            JNAPAction.setPortRangeForwardingRules,
            auth: true,
            data: {
              'rules': rules.map((e) => e.toJson()).toList(),
            },
          )
          .then((value) => true)
          .onError((error, stackTrace) => false);
      return result;
    } else {
      return false;
    }
  }

  bool isDeviceIpValidate(String ipAddress) {
    return _localIpValidator?.validate(ipAddress) ?? false;
  }

  bool isEdit() {
    return state.mode == PortRangeForwardingRuleMode.editing;
  }

  String get subnetMask => _subnetMask;
  String get ipAddress => _ipAddress;
}
