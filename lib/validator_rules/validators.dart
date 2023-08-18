import 'package:linksys_app/validator_rules/_validator_rules.dart';

import 'rules.dart';

class InputValidator {
  final List<ValidationRule> rules;
  final bool required;

  InputValidator(this.rules, {this.required = false});

  bool validate(String input) {
    if (required) {
      return input.isNotEmpty && (!rules.any((rule) => !rule.validate(input)));
    } else {
      return input.isEmpty || !rules.any((rule) => !rule.validate(input));
    }
  }

  Map<String, bool> validateDetail(String input, {bool onlyFailed = false}) {
    return rules
        .map((rule) => {rule.name: rule.validate(input)})
        .where((pair) => onlyFailed ? !pair.values.first : true)
        .reduce((value, element) => value..addAll(element));
  }
}

class ComplexPasswordValidator extends InputValidator {
  ComplexPasswordValidator()
      : super([
          LengthRule(),
          HybridCaseRule(),
          DigitalCheckRule(),
          SpecialCharCheckRule()
        ]);
}

class EmailValidator extends InputValidator {
  EmailValidator() : super([EmailRule()]);
}

class SubnetValidator extends InputValidator {
  SubnetValidator({int min = 8, int max = 30})
      : super([
          RequiredRule(),
          NoSurroundWhitespaceRule(),
          SubnetMaskRule(
              minNetworkPrefixLength: min, maxNetworkPrefixLength: max),
          IpAddressHasFourOctetsRule(),
        ], required: true);
}

class IpAddressLocalValidator extends InputValidator {
  IpAddressLocalValidator(String routerIPAddress, String subnetMask)
      : super([
          RequiredRule(),
          NoSurroundWhitespaceRule(),
          IpAddressHasFourOctetsRule(),
          IpAddressNoReservedRule(),
          IpAddressRule(),
          HostValidForGivenRouterIPAddressAndSubnetMaskRule(
              routerIPAddress, subnetMask),
          IpAddressLocalNotRouterIp(routerIPAddress),
        ], required: true);
}

class IpAddressRequiredValidator extends InputValidator {
  IpAddressRequiredValidator()
      : super([
          RequiredRule(),
          NoSurroundWhitespaceRule(),
          IpAddressHasFourOctetsRule(),
          IpAddressNoReservedRule(),
          IpAddressRule(),
        ], required: true);
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

class IpAddressLocalTestSubnetMaskValidator extends InputValidator {
  final String routerIPAddress;
  final String subnetMask;

  IpAddressLocalTestSubnetMaskValidator(this.routerIPAddress, this.subnetMask)
      : super([
          RequiredRule(),
          NoSurroundWhitespaceRule(),
          IpAddressHasFourOctetsRule(),
          IpAddressNoReservedRule(),
          IpAddressRule(),
          HostValidForGivenRouterIPAddressAndSubnetMaskRule(
              routerIPAddress, subnetMask),
        ], required: true);
}

class MaxUsersValidator extends InputValidator {
  MaxUsersValidator(int max)
      : super([
          IntegerRule(min: 1, max: max),
        ], required: true);
}

class LeaseTimeValidator extends InputValidator {
  LeaseTimeValidator(int min, int max)
      : super([IntegerRule(min: min, max: max)], required: true);
}

class PPPoEUsernameValidator extends InputValidator {
  PPPoEUsernameValidator()
      : super([
          LengthRule(min: 0, max: 255),
          AsciiRule(),
          NoSurroundWhitespaceRule()
        ]);
}

class PPPoEPasswordValidator extends InputValidator {
  PPPoEPasswordValidator()
      : super([
          LengthRule(min: 0, max: 255),
          AsciiRule(),
        ]);
}
