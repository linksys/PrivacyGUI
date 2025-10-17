import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

InputValidator getWifiSSIDValidator() => InputValidator([
      RequiredRule(),
      NoSurroundWhitespaceRule(),
      LengthRule(min: 1, max: 32),
      WiFiSsidRule(),
    ]);

InputValidator getWifiPasswordValidator() => InputValidator([
      LengthRule(min: 8, max: 64),
      NoSurroundWhitespaceRule(),
      AsciiRule(),
      WiFiPSKRule(),
    ]);
