import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/lan_settings.dart';
import 'package:linksys_moab/model/router/port_range_triggering_rule.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/repository/router/firewall_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

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
    fetch().then((value) => emit(EditPortRangeTriggeringRule(rules: rules, rule: rule)));
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
    final _state = state;
    final rules = List<PortRangeTriggeringRule>.from(_state.rules);
    if (_state is AddPortRangeTriggeringRule) {
      rules.add(rule);
    } else if (_state is EditPortRangeTriggeringRule) {
      int index = _state.rules.indexOf(_state.rule);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final result = await _repository
        .setPortRangeTriggeringRules(rules)
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final _state = state;
    if (_state is EditPortRangeTriggeringRule) {
      final rules = List<PortRangeTriggeringRule>.from(_state.rules)
        ..removeWhere((element) => element == _state.rule);
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
