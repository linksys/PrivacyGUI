import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/validation_error.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';

class InternetSettingsFormValidator {
  final InputValidator _macValidator = InputValidator([MACAddressRule()]);
  final InputValidator _ipv6PrefixValidator = InputValidator([IPv6WithReservedRule()]);
  final InputValidator _borderRelayValidator = InputValidator([IpAddressNoReservedRule()]);
  final InputValidator _ipv4Validator = InputValidator([IpAddressNoReservedRule()]);

  ValidationError? validateMacAddress(String? value) {
    if (value == null || value.isEmpty) return ValidationError.invalidMACAddress;
    if (_macValidator.validate(value)) {
      return null;
    } else {
      return ValidationError.invalidMACAddress;
    }
  }

  ValidationError? validateIpv6Prefix(String? value) {
    if (value == null || value.isEmpty) return ValidationError.invalidIpAddress;
    if (_ipv6PrefixValidator.validate(value)) {
      return null;
    } else {
      return ValidationError.invalidIpAddress;
    }
  }

  ValidationError? validateBorderRelay(String? value) {
    if (value == null || value.isEmpty) return ValidationError.invalidIpAddress;
    if (_borderRelayValidator.validate(value)) {
      return null;
    } else {
      return ValidationError.invalidIpAddress;
    }
  }

  ValidationError? validateSubnetMask(String? value) {
    if (value == null || value.isEmpty) return ValidationError.invalidSubnetMask;
    final subnetMaskValidator = SubnetMaskValidator();
    if (subnetMaskValidator.validate(value)) {
      return null;
    } else {
      return ValidationError.invalidSubnetMask;
    }
  }

  ValidationError? validateIpAddress(String? value, [allowEmpty = false]) {
    if (value == null || value.isEmpty) return allowEmpty ? null : ValidationError.invalidIpAddress;
    if (_ipv4Validator.validate(value)) {
      return null;
    } else {
      return ValidationError.invalidIpAddress;
    }
  }

  ValidationError? validateEmpty(String? value) {
    if (value == null || value.isEmpty) return ValidationError.fieldCannotBeEmpty;
    return null;
  }
}
