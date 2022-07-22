abstract class ValidationRule {
  String get name;

  bool validate(String input);
}

abstract class RegExValidationRule extends ValidationRule {
  RegExp get _rule;

  @override
  bool validate(String input) => _rule.hasMatch(input);
}

class EmailRule extends RegExValidationRule {
  @override
  String get name => 'Email';

  @override
  RegExp get _rule => RegExp(
      r"^[a-zA-Z0-9.!#$%&‘*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
}

class LengthRule extends ValidationRule {
  final int min;
  final int max;

  LengthRule({this.min = 10, this.max = 0});

  @override
  String get name => 'Length';

  @override
  bool validate(String input) {
    return max > 0
        ? input.length >= min && input.length <= max
        : input.length >= min;
  }
}

class HybridCaseRule extends ValidationRule {
  @override
  String get name => 'HybridCase';

  @override
  bool validate(String input) {
    return input != input.toUpperCase() && input != input.toLowerCase();
  }
}

class DigitalCheckRule extends RegExValidationRule {
  @override
  String get name => 'Digital';

  @override
  RegExp get _rule => RegExp(r".*\d+.*");
}

class SpecialCharCheckRule extends RegExValidationRule {
  @override
  String get name => 'SpecialChar';

  @override
  RegExp get _rule => RegExp(r".*[^a-zA-Z0-9 ]+.*");
// From current linksys app
// RegExp regEx = RegExp(
//     r"(?=.*?[\x20-\x29\x2A-\x2F\x3A-\x3F\x40\x5B-\x5F\x60\x7D-\x7E])\w+");
}

class WiFiPasswordRule extends RegExValidationRule {
  @override
  String get name => 'WiFiPassword';

  @override
  RegExp get _rule => RegExp(r"^(?! )[\x20-\x7e]{8,64}(?<! )$");
}

class WiFiSsidRule extends RegExValidationRule {
  @override
  String get name => 'WiFiSsid';

  @override
  RegExp get _rule => RegExp(r"^(?! ).{1,32}(?<! )$");
}

class IpAddressRule extends RegExValidationRule {
  @override
  String get name => 'IpAddress';

  @override
  RegExp get _rule => RegExp(
    r"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
  );
}

class InputValidator {
  final List<ValidationRule> rules;

  InputValidator(this.rules);

  bool validate(String input) {
    return !rules.any((rule) => !rule.validate(input));
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
