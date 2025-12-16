import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/views/widgets/validators.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    return AppPasswordInput(
      label: widget.semanticLabel.isNotEmpty ? widget.semanticLabel : loc(context).wifiPassword,
      // autofocus: true, // Not supported/needed in UI Kit usually
      controller: widget.controller,
      // border: const OutlineInputBorder(),
      rules: [
        AppPasswordRule(
          label: loc(context).wifiPasswordLimit,
          validate: ((text) => text.isNotEmpty
              ? (wifiPasswordValidator.getRuleByIndex(0)?.validate(text) ?? false)
              : false),
        ),
        AppPasswordRule(
          label: loc(context).routerPasswordRuleStartEndWithSpace,
          validate: ((text) => text.isNotEmpty
              ? (wifiPasswordValidator.getRuleByIndex(1)?.validate(text) ?? false)
              : false),
        ),
        AppPasswordRule(
          label: loc(context).routerPasswordRuleUnsupportSpecialChar,
          validate: ((text) => text.isNotEmpty
              ? (wifiPasswordValidator.getRuleByIndex(2)?.validate(text) ?? false)
              : false),
        ),
        if (widget.isLength64)
          AppPasswordRule(
            label: loc(context).wifiPasswordRuleHex,
            validate: ((text) => text.isNotEmpty
                ? (wifiPasswordValidator.getRuleByIndex(3)?.validate(text) ?? false)
                : false),
          ),
      ],
      onChanged: widget.onChanged,
      // onValidationChanged: widget.onValidationChanged, // Not supported directly
      onSubmitted: widget.onSubmitted,
    );
  }
}
