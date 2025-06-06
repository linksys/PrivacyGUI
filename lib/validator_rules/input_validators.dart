import 'package:collection/collection.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'rules.dart';

class InputValidator {
  bool? _isValid;
  bool? get isValid => _isValid;
  Map<String, bool> _results = {};
  Map<String, bool> get results => _results;
  final List<ValidationRule> rules;

  InputValidator(this.rules);

  bool validate(String input) {
    _isValid = !rules.any((rule) => !rule.validate(input));
    return _isValid ?? false;
  }

  Map<String, bool> validateDetail(String input, {bool onlyFailed = false}) {
    final results = rules
        .map((rule) => {rule.name: rule.validate(input)})
        .where((pair) => onlyFailed ? !pair.values.first : true);
    _results = results.isEmpty
        ? {}
        : results.reduce((value, element) => value..addAll(element));
    return _results;
  }

  ValidationRule? getRule(String name) {
    return rules.firstWhereOrNull((element) => element.name == name);
  }

  ValidationRule? getRuleByIndex(int index) {
    return index >= rules.length || index < 0 ? null : rules[index];
  }
}

class ComplexPasswordValidator extends InputValidator {
  ComplexPasswordValidator()
      : super([
          RequiredRule(),
          LengthRule(),
          HybridCaseRule(),
          DigitalCheckRule(),
          SpecialCharCheckRule(),
        ]);
}

class EmailValidator extends InputValidator {
  EmailValidator()
      : super([
          RequiredRule(),
          EmailRule(),
        ]);
}

class SubnetMaskValidator extends InputValidator {
  SubnetMaskValidator({int min = 8, int max = 30})
      : super([
          RequiredRule(),
          NoSurroundWhitespaceRule(),
          SubnetMaskRule(
            minNetworkPrefixLength: min,
            maxNetworkPrefixLength: max,
          ),
          IpAddressHasFourOctetsRule(),
        ]);
}

class IpAddressValidator extends InputValidator {
  IpAddressValidator()
      : super([
          NoSurroundWhitespaceRule(),
          IpAddressHasFourOctetsRule(),
          IpAddressNoReservedRule(),
          IpAddressRule(),
        ]);
}

class IpAddressRequiredValidator extends InputValidator {
  IpAddressRequiredValidator()
      : super([
          RequiredRule(),
          NoSurroundWhitespaceRule(),
          IpAddressHasFourOctetsRule(),
          IpAddressNoReservedRule(),
          IpAddressRule(),
        ]);
}

class IpAddressAsNewRouterIpValidator extends InputValidator {
  IpAddressAsNewRouterIpValidator(
    String currentRouterIp,
    String currentSubnetMask,
  ) : super([
          RequiredRule(),
          NoSurroundWhitespaceRule(),
          IpAddressHasFourOctetsRule(),
          IpAddressNoReservedRule(),
          IpAddressRule(),
          HostValidForGivenRouterIPAddressAndSubnetMaskRule(
            currentRouterIp,
            currentSubnetMask,
          ),
        ]);
}

class IpAddressAsLocalIpValidator extends InputValidator {
  IpAddressAsLocalIpValidator(
    String currentRouterIp,
    String currentSubnetMask,
  ) : super([
          RequiredRule(),
          NoSurroundWhitespaceRule(),
          IpAddressHasFourOctetsRule(),
          IpAddressNoReservedRule(),
          IpAddressRule(),
          HostValidForGivenRouterIPAddressAndSubnetMaskRule(
            currentRouterIp,
            currentSubnetMask,
          ),
          NotRouterIpAddressRule(currentRouterIp),
        ]);
}

class MaxUsersValidator extends InputValidator {
  MaxUsersValidator(int max)
      : super([
          RequiredRule(),
          IntegerRule(min: 1, max: max),
        ]);
}

class DhcpClientLeaseTimeValidator extends InputValidator {
  DhcpClientLeaseTimeValidator(int min, int max)
      : super([
          RequiredRule(),
          IntegerRule(min: min, max: max),
        ]);
}

/*
class PPPoEUsernameValidator extends InputValidator {
  PPPoEUsernameValidator()
      : super([
          LengthRule(min: 0, max: 255),
          AsciiRule(),
          NoSurroundWhitespaceRule(),
        ]);
}

class PPPoEPasswordValidator extends InputValidator {
  PPPoEPasswordValidator()
      : super([
          LengthRule(min: 0, max: 255),
          AsciiRule(),
        ]);
}
*/
