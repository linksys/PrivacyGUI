import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/providers/consts.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';

final singlePortForwardingRuleProvider = NotifierProvider<
    SinglePortForwardingRuleNotifier,
    SinglePortForwardingRuleState>(() => SinglePortForwardingRuleNotifier());

class SinglePortForwardingRuleNotifier
    extends Notifier<SinglePortForwardingRuleState> {
  InputValidator? _localIpValidator;
  String _subnetMask = '255.255.0.0';
  String _ipAddress = '192.168.1.1';

  @override
  SinglePortForwardingRuleState build() =>
      const SinglePortForwardingRuleState();

  Future goAdd(List<SinglePortForwardingRule> rules) {
    return fetch().then(
        (value) => state = state.copyWith(mode: RuleMode.adding, rules: rules));
  }

  Future goEdit(
      List<SinglePortForwardingRule> rules, SinglePortForwardingRule rule) {
    return fetch().then((value) => state =
        state.copyWith(mode: RuleMode.editing, rules: rules, rule: rule));
  }

  Future fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          auth: true,
        )
        .then((value) => RouterLANSettings.fromMap(value.output));
    _ipAddress = lanSettings.ipAddress;
    _subnetMask =
        NetworkUtils.prefixLengthToSubnetMask(lanSettings.networkPrefixLength);
    _localIpValidator = IpAddressAsLocalIpValidator(ipAddress, subnetMask);
  }

  Future<bool> save(SinglePortForwardingRule rule) async {
    final mode = state.mode;
    final rules = List<SinglePortForwardingRule>.from(state.rules);
    if (mode == RuleMode.adding) {
      rules.add(rule);
    } else if (mode == RuleMode.editing) {
      int index = state.rules.indexOf(state.rule!);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo
        .send(
          JNAPAction.setSinglePortForwardingRules,
          data: {'rules': rules.map((e) => e.toMap()).toList()},
          auth: true,
        )
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final mode = state.mode;
    if (mode == RuleMode.editing) {
      final rules = List<SinglePortForwardingRule>.from(state.rules)
        ..removeWhere((element) => element == state.rule);
      final repo = ref.read(routerRepositoryProvider);
      final result = await repo
          .send(
            JNAPAction.setSinglePortForwardingRules,
            data: {'rules': rules.map((e) => e.toMap()).toList()},
            auth: true,
          )
          .then((value) => true)
          .onError((error, stackTrace) => false);
      return result;
    } else {
      return false;
    }
  }

  bool isDeviceIpValidate(String ipAddress) {
    final localIpValidator = _localIpValidator;
    return localIpValidator != null
        ? localIpValidator.validate(ipAddress)
        : false;
  }

  bool isPortConflict(int externalPort, String protocol) {
    return state.rules.any((rule) =>
        rule.externalPort == externalPort &&
        (protocol == rule.protocol || protocol == 'Both'));
  }

  bool isEdit() {
    return state.mode == RuleMode.editing;
  }

  String get subnetMask => _subnetMask;
  String get ipAddress => _ipAddress;
}
