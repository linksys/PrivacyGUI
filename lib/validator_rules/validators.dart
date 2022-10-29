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
  SubnetValidator()
      : super([
    RequiredRule(),
    NoSurroundWhitespaceRule(),
    SubnetMaskRule(),
    IpAddressHasFourOctetsRule(),
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