import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/core/jnap/models/port_range_triggering_rule.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_app/validator_rules/_validator_rules.dart';

part 'port_range_triggering_rule_state.dart';

class PortRangeTriggeringRuleCubit extends Cubit<PortRangeTriggeringRuleState> {
  late InputValidator _localIpValidator;

  PortRangeTriggeringRuleCubit({required RouterRepository repository})
      : _repository = repository,
        super(PortRangeTriggeringRuleInitial());

  final RouterRepository _repository;

  goAdd(List<PortRangeTriggeringRule> rules) {
    fetch().then((value) => emit(AddPortRangeTriggeringRule(rules: rules)));
  }

  goEdit(List<PortRangeTriggeringRule> rules, PortRangeTriggeringRule rule) {
    fetch().then(
        (value) => emit(EditPortRangeTriggeringRule(rules: rules, rule: rule)));
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

  Future<bool> save(PortRangeTriggeringRule rule) async {
    final currentState = state;
    final rules = List<PortRangeTriggeringRule>.from(currentState.rules);
    if (currentState is AddPortRangeTriggeringRule) {
      rules.add(rule);
    } else if (currentState is EditPortRangeTriggeringRule) {
      int index = currentState.rules.indexOf(currentState.rule);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final result = await _repository
        .setPortRangeTriggeringRules(rules)
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final currentState = state;
    if (currentState is EditPortRangeTriggeringRule) {
      final rules = List<PortRangeTriggeringRule>.from(currentState.rules)
        ..removeWhere((element) => element == currentState.rule);
      final result = await _repository
          .setPortRangeTriggeringRules(rules)
          .then((value) => true)
          .onError((error, stackTrace) => false);
      return result;
    } else {
      return false;
    }
  }

  bool isDeviceIpValidate(String ipAddress) {
    return _localIpValidator.validate(ipAddress);
  }

  bool isEdit() {
    return state is EditPortRangeTriggeringRule;
  }
}
