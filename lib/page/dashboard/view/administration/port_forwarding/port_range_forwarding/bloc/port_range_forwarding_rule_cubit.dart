import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';

part 'port_range_forwarding_rule_state.dart';

class PortRangeForwardingRuleCubit extends Cubit<PortRangeForwardingRuleState> {
  InputValidator? _localIpValidator;

  PortRangeForwardingRuleCubit({required RouterRepository repository})
      : _repository = repository,
        super(PortRangeForwardingRuleInitial());

  final RouterRepository _repository;

  goAdd(List<PortRangeForwardingRule> rules) {
    fetch().then((value) => emit(AddPortRangeForwardingRule(rules: rules)));
  }

  goEdit(List<PortRangeForwardingRule> rules, PortRangeForwardingRule rule) {
    fetch().then(
        (value) => emit(EditPortRangeForwardingRule(rules: rules, rule: rule)));
  }

  Future fetch() async {
    final lanSettings = await _repository
        .getLANSettings()
        .then((value) => RouterLANSettings.fromJson(value.output));
    final ipAddress = lanSettings.ipAddress;
    final subnetMask =
        Utils.prefixLengthToSubnetMask(lanSettings.networkPrefixLength);
    _localIpValidator = IpAddressLocalValidator(ipAddress, subnetMask);
  }

  Future<bool> save(PortRangeForwardingRule rule) async {
    final currentState = state;
    final rules = List<PortRangeForwardingRule>.from(currentState.rules);
    if (currentState is AddPortRangeForwardingRule) {
      rules.add(rule);
    } else if (currentState is EditPortRangeForwardingRule) {
      int index = currentState.rules.indexOf(currentState.rule);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final result = await _repository
        .setPortRangeForwardingRules(rules)
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final currentState = state;
    if (currentState is EditPortRangeForwardingRule) {
      final rules = List<PortRangeForwardingRule>.from(currentState.rules)
        ..removeWhere((element) => element == currentState.rule);
      final result = await _repository
          .setPortRangeForwardingRules(rules)
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
    return state is EditPortRangeForwardingRule;
  }
}
