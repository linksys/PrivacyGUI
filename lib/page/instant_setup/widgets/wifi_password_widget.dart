import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';

class WiFiPasswordField extends ConsumerStatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final void Function(bool isValid, String input)? onCheckInput;
  final void Function(String value)? onSubmitted;

  const WiFiPasswordField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onCheckInput,
    this.onSubmitted,
  });

  @override
  ConsumerState<WiFiPasswordField> createState() => _WiFiPasswordFieldState();
}

class _WiFiPasswordFieldState extends ConsumerState<WiFiPasswordField> {
  final InputValidator wifiPasswordValidator = InputValidator([
    RequiredRule(),
    NoSurroundWhitespaceRule(),
    WiFiPasswordRule(ignoreLength: true),
    LengthRule(min: 8),
  ]);

  @override
  Widget build(BuildContext context) {
    return AppPasswordField.withValidator(
      border: const OutlineInputBorder(),
      headerText: widget.label,
      hintText: widget.hint,
      // errorText: () {
      //   if (widget.controller?.text.isEmpty == true) {
      //     return null;
      //   }
      //   final errorKeys = wifiPasswordValidator
      //       .validateDetail(widget.controller?.text ?? '', onlyFailed: true)
      //     ..removeWhere((key, value) => key == (LengthRule).toString());
      //   if (errorKeys.isEmpty) {
      //     return null;
      //   } else if (errorKeys.keys.first ==
      //       (NoSurroundWhitespaceRule).toString()) {
      //     return loc(context).routerPasswordRuleStartEndWithSpace;
      //   } else if (errorKeys.keys.first == (WiFiPasswordRule).toString()) {
      //     return loc(context).routerPasswordRuleUnsupportSpecialChar;
      //   }
      // }(),
      validations: [
        Validation(
            description: loc(context).wifiPasswordLimit,
            validator: LengthRule(min: 8, max: 64).validate),
        Validation(
            description: loc(context).routerPasswordRuleStartEndWithSpace,
            validator: NoSurroundWhitespaceRule().validate),
        Validation(
          description: loc(context).routerPasswordRuleUnsupportSpecialChar,
          validator: ((text) => AsciiRule().validate(text)),
        ),
      ],
      controller: widget.controller,
      onChanged: (value) {
        final errorKeys = wifiPasswordValidator
            .validateDetail(widget.controller?.text ?? '', onlyFailed: true);
        if (value.isEmpty || errorKeys.isNotEmpty) {
          widget.onCheckInput?.call(false, value);
        } else {
          widget.onCheckInput?.call(true, value);
        }
      },
      onSubmitted: widget.onSubmitted,
    );
  }
}
