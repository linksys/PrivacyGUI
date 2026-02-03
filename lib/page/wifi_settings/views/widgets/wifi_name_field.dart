import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/validators.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';

class WifiNameField extends StatefulWidget {
  final TextEditingController controller;
  final String semanticLabel;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const WifiNameField({
    super.key,
    required this.controller,
    this.semanticLabel = '',
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<WifiNameField> createState() => _WifiNameFieldState();
}

class _WifiNameFieldState extends State<WifiNameField> {
  final InputValidator wifiSSIDValidator = getWifiSSIDValidator();

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      semanticLabel: '${widget.semanticLabel} wifi name',
      controller: widget.controller,
      border: const OutlineInputBorder(),
      onChanged: widget.onChanged,
      errorText: () {
        final errorKeys =
            wifiSSIDValidator.validateDetail(widget.controller.text, onlyFailed: true);
        if (errorKeys.isEmpty) {
          return null;
        } else if (errorKeys.keys.first == NoSurroundWhitespaceRule().name) {
          return loc(context).routerPasswordRuleStartEndWithSpace;
        } else if (errorKeys.keys.first == WiFiSsidRule().name ||
            errorKeys.keys.first == RequiredRule().name) {
          return loc(context).theNameMustNotBeEmpty;
        } else if (errorKeys.keys.first == LengthRule().name) {
          return loc(context).wifiSSIDLengthLimit;
        } else {
          return null;
        }
      }(),
      onSubmitted: widget.onSubmitted,
    );
  }
}