import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/validators.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/widgets/input_field/app_password_field.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';

class WifiPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String semanticLabel;
  final bool isLength64;
  final Function(String)? onChanged;
  final Function(bool)? onValidationChanged;
  final Function(String)? onSubmitted;

  const WifiPasswordField({
    super.key,
    required this.controller,
    this.semanticLabel = '',
    this.isLength64 = false,
    this.onChanged,
    this.onValidationChanged,
    this.onSubmitted,
  });

  @override
  State<WifiPasswordField> createState() => _WifiPasswordFieldState();
}

class _WifiPasswordFieldState extends State<WifiPasswordField> {
  final InputValidator wifiPasswordValidator = getWifiPasswordValidator();

  @override
  Widget build(BuildContext context) {
    return AppPasswordField.withValidator(
      semanticLabel: widget.semanticLabel,
      autofocus: true,
      controller: widget.controller,
      border: const OutlineInputBorder(),
      validations: [
        Validation(
          description: loc(context).wifiPasswordLimit,
          validator: ((text) =>
              wifiPasswordValidator.getRuleByIndex(0)?.validate(text) ?? false),
        ),
        Validation(
          description: loc(context).routerPasswordRuleStartEndWithSpace,
          validator: ((text) =>
              wifiPasswordValidator.getRuleByIndex(1)?.validate(text) ?? false),
        ),
        Validation(
          description: loc(context).routerPasswordRuleUnsupportSpecialChar,
          validator: ((text) =>
              wifiPasswordValidator.getRuleByIndex(2)?.validate(text) ?? false),
        ),
        if (widget.isLength64)
          Validation(
            description: loc(context).wifiPasswordRuleHex,
            validator: ((text) =>
                wifiPasswordValidator.getRuleByIndex(3)?.validate(text) ??
                false),
          ),
      ],
      onChanged: widget.onChanged,
      onValidationChanged: widget.onValidationChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
