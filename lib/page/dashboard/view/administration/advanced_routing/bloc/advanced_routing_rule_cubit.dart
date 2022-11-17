import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/advanced_routing_rule.dart';
import 'package:linksys_moab/model/router/lan_settings.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/repository/router/firewall_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

part 'advanced_routing_rule_state.dart';

class AdvancedRoutingRuleCubit extends Cubit<AdvancedRoutingRuleState> {
  late InputValidator _localIpValidator;

  AdvancedRoutingRuleCubit({required RouterRepository repository})
      : _repository = repository,
        super(AdvancedRoutingRuleInitial());

  final RouterRepository _repository;

  goAdd(List<AdvancedRoutingRule> rules) {
    fetch().then((value) => emit(AddAdvancedRoutingRule(rules: rules)));
  }

  goEdit(List<AdvancedRoutingRule> rules, AdvancedRoutingRule rule) {
    fetch().then((value) => emit(EditAdvancedRoutingRule(rules: rules, rule: rule)));
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

  Future<bool> save(AdvancedRoutingRule rule) async {
    final _state = state;
    final rules = List<AdvancedRoutingRule>.from(_state.rules);
    if (_state is AddAdvancedRoutingRule) {
      rules.add(rule);
    } else if (_state is EditAdvancedRoutingRule) {
      int index = _state.rules.indexOf(_state.rule);
      rules.replaceRange(index, index + 1, [rule]);
    }
    // TODO
    // final result = await _repository
    //     .setAdvancedRoutingRules(rules)
    //     .then((value) => true)
    //     .onError((error, stackTrace) => false);
    // return result;
    return true;
  }

  Future<bool> delete() async {
    final _state = state;
    if (_state is EditAdvancedRoutingRule) {
      // TODO
      // final rules = List<AdvancedRoutingRule>.from(_state.rules)
      //   ..removeWhere((element) => element == _state.rule);
      // final result = await _repository
      //     .setAdvancedRoutingRules(rules)
      //     .then((value) => true)
      //     .onError((error, stackTrace) => false);
      // return result;
      return true;
    } else {
      return false;
    }
  }

  bool isDeviceIpValidate(String ipAddress) {
    return _localIpValidator.validate(ipAddress);
  }

  bool isEdit() {
    return state is EditAdvancedRoutingRule;
  }
}
