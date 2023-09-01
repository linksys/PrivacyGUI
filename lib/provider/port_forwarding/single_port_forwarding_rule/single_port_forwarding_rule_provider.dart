import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/port_forwarding/single_port_forwarding_rule/single_port_forwarding_rule_state.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_app/validator_rules/validators.dart';

final singlePortForwardingRuleProvider = NotifierProvider<
    SinglePortForwardingRuleNotifier,
    SinglePortForwardingRuleState>(() => SinglePortForwardingRuleNotifier());

class SinglePortForwardingRuleNotifier
    extends Notifier<SinglePortForwardingRuleState> {
  InputValidator? _localIpValidator;

  @override
  SinglePortForwardingRuleState build() =>
      const SinglePortForwardingRuleState();

  goAdd(List<SinglePortForwardingRule> rules) {
    fetch().then((value) => state = state.copyWith(
        mode: SinglePortForwardingRuleMode.adding, rules: rules));
  }

  goEdit(List<SinglePortForwardingRule> rules, SinglePortForwardingRule rule) {
    fetch().then((value) => state.copyWith(
        mode: SinglePortForwardingRuleMode.editing, rules: rules, rule: rule));
  }

  Future fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final lanSettings = await repo
        .send(
          JNAPAction.getLANSettings,
          auth: true,
        )
        .then((value) => RouterLANSettings.fromJson(value.output));
    final ipAddress = lanSettings.ipAddress;
    final subnetMask =
        Utils.prefixLengthToSubnetMask(lanSettings.networkPrefixLength);
    _localIpValidator = IpAddressLocalValidator(ipAddress, subnetMask);
  }

  Future<bool> save(SinglePortForwardingRule rule) async {
    final mode = state.mode;
    final rules = List<SinglePortForwardingRule>.from(state.rules);
    if (mode == SinglePortForwardingRuleMode.adding) {
      rules.add(rule);
    } else if (mode == SinglePortForwardingRuleMode.editing) {
      int index = state.rules.indexOf(state.rule!);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo
        .send(
          JNAPAction.setSinglePortForwardingRules,
          data: {'rules': rules.map((e) => e.toJson()).toList()},
          auth: true,
        )
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final mode = state.mode;
    if (mode == SinglePortForwardingRuleMode.editing) {
      final rules = List<SinglePortForwardingRule>.from(state.rules)
        ..removeWhere((element) => element == state.rule);
      final repo = ref.read(routerRepositoryProvider);
      final result = await repo
          .send(
            JNAPAction.setSinglePortForwardingRules,
            data: {'rules': rules.map((e) => e.toJson()).toList()},
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

  bool isEdit() {
    return state.mode == SinglePortForwardingRuleMode.editing;
  }
}
