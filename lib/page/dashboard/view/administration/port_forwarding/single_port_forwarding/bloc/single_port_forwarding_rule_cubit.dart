import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/core/jnap/models/lan_settings.dart';
import 'package:linksys_moab/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:linksys_moab/core/jnap/extensions/_extensions.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

part 'single_port_forwarding_rule_state.dart';

class SinglePortForwardingRuleCubit
    extends Cubit<SinglePortForwardingRuleState> {
  InputValidator? _localIpValidator;

  SinglePortForwardingRuleCubit({required RouterRepository repository})
      : _repository = repository,
        super(SinglePortForwardingRuleInitial());

  final RouterRepository _repository;

  goAdd(List<SinglePortForwardingRule> rules) {
    fetch().then((value) => emit(AddSinglePortForwardingRule(rules: rules)));
  }

  goEdit(List<SinglePortForwardingRule> rules, SinglePortForwardingRule rule) {
    fetch().then((value) =>
        emit(EditSinglePortForwardingRule(rules: rules, rule: rule)));
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

  Future<bool> save(SinglePortForwardingRule rule) async {
    final currentState = state;
    final rules = List<SinglePortForwardingRule>.from(state.rules);
    if (currentState is AddSinglePortForwardingRule) {
      rules.add(rule);
    } else if (currentState is EditSinglePortForwardingRule) {
      int index = currentState.rules.indexOf(currentState.rule);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final result = await _repository
        .setSinglePortForwardingRules(rules)
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final currentState = state;
    if (currentState is EditSinglePortForwardingRule) {
      final rules = List<SinglePortForwardingRule>.from(currentState.rules)
        ..removeWhere((element) => element == currentState.rule);
      final result = await _repository
          .setSinglePortForwardingRules(rules)
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
    return state is EditSinglePortForwardingRule;
  }
}
