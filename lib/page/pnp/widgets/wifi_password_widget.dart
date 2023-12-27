import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/validator_rules/rules.dart';
import 'package:linksys_app/validator_rules/validators.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class WiFiPasswordField extends ConsumerStatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController controller;
  final void Function(bool isValid, String input)? onCheckInput;

  const WiFiPasswordField({
    super.key,
    this.label,
    this.hint,
    required this.controller,
    this.onCheckInput,
  });

  @override
  ConsumerState<WiFiPasswordField> createState() => _WiFiPasswordFieldState();
}

class _WiFiPasswordFieldState extends ConsumerState<WiFiPasswordField> {
  final InputValidator wifiPasswordValidator = InputValidator([
    NoSurroundWhitespaceRule(),
    WiFiPasswordRule(ignoreLength: true),
    LengthRule(min: 8),
  ], required: true);

  @override
  Widget build(BuildContext context) {
    return AppPasswordField.withValidator(
      headerText: widget.label,
      hintText: widget.hint,
      errorText: () {
        if (widget.controller.text.isEmpty) {
          return null;
        }
        final errorKeys = wifiPasswordValidator
            .validateDetail(widget.controller.text, onlyFailed: true)
          ..removeWhere((key, value) => key == (LengthRule).toString());
        if (errorKeys.isEmpty) {
          return null;
        } else if (errorKeys.keys.first ==
            (NoSurroundWhitespaceRule).toString()) {
          return 'Can\'t start and/or end with a space';
        } else if (errorKeys.keys.first == (WiFiPasswordRule).toString()) {
          return 'Use letters, numbers, and common symbols';
        }
      }(),
      validations: [
        Validation(
            description: '8 characters minimum',
            validator: LengthRule(min: 8).validate)
      ],
      controller: widget.controller,
      onChanged: (value) {
        final errorKeys = wifiPasswordValidator
            .validateDetail(widget.controller.text, onlyFailed: true);
        if (value.isEmpty || errorKeys.isNotEmpty) {
          widget.onCheckInput?.call(false, value);
        } else {
          widget.onCheckInput?.call(true, value);
        }
      },
    );
  }
}
