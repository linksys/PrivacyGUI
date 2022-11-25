import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/lan_settings.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

part 'single_port_forwarding_rule_state.dart';

class SinglePortForwardingRuleCubit extends Cubit<SinglePortForwardingRuleState> {
  late InputValidator _localIpValidator;

  SinglePortForwardingRuleCubit({required RouterRepository repository})
      : _repository = repository,
        super(SinglePortForwardingRuleInitial());

  final RouterRepository _repository;

  goAdd(List<SinglePortForwardingRule> rules) {
    fetch().then((value) => emit(AddSinglePortForwardingRule(rules: rules)));
  }

  goEdit(List<SinglePortForwardingRule> rules, SinglePortForwardingRule rule) {
    fetch().then((value) => emit(EditSinglePortForwardingRule(rules: rules, rule: rule)));
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
    final _state = state;
    final rules = List<SinglePortForwardingRule>.from(_state.rules);
    if (_state is AddSinglePortForwardingRule) {
      rules.add(rule);
    } else if (_state is EditSinglePortForwardingRule) {
      int index = _state.rules.indexOf(_state.rule);
      rules.replaceRange(index, index + 1, [rule]);
    }
    final result = await _repository
        .setSinglePortForwardingRules(rules)
        .then((value) => true)
        .onError((error, stackTrace) => false);
    return result;
  }

  Future<bool> delete() async {
    final _state = state;
    if (_state is EditSinglePortForwardingRule) {
      final rules = List<SinglePortForwardingRule>.from(_state.rules)
        ..removeWhere((element) => element == _state.rule);
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
    return _localIpValidator.validate(ipAddress);
  }

  bool isEdit() {
    return state is EditSinglePortForwardingRule;
  }
}
