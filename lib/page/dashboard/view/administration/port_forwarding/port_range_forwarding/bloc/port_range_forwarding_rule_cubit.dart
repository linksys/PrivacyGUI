import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/lan_settings.dart';
import 'package:linksys_moab/model/router/port_range_forwarding_rule.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

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
    final _state = state;
    final rules = List<PortRangeForwardingRule>.from(_state.rules);
    if (_state is AddPortRangeForwardingRule) {
      rules.add(rule);
    } else if (_state is EditPortRangeForwardingRule) {
      int index = _state.rules.indexOf(_state.rule);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final result = await _repository
        .setPortRangeForwardingRules(rules)
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final _state = state;
    if (_state is EditPortRangeForwardingRule) {
      final rules = List<PortRangeForwardingRule>.from(_state.rules)
        ..removeWhere((element) => element == _state.rule);
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
