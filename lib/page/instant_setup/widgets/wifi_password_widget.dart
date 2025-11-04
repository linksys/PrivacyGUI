import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';

/// A reusable widget for entering Wi-Fi passwords.
///
/// This widget provides a password input field with optional label, hint,
/// error text, controller, and validation rules.
class WiFiPasswordField extends ConsumerWidget {
  /// The label text for the password input field.
  final String? label;

  /// The hint text displayed inside the password input field.
  final String? hint;

  /// The error text to display below the password input field.
  final String? errorText;

  /// The text editing controller for the password input field.
  final TextEditingController? controller;

  /// Callback function when the text in the password field changes.
  final void Function(String value)? onChanged;

  /// Callback function when the user submits the text in the password field.
  final void Function(String value)? onSubmitted;

  /// A list of validation rules to apply to the password input.
  final List<Validation>? validations;

  const WiFiPasswordField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.validations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPasswordField.withValidator(
      border: const OutlineInputBorder(),
      headerText: label,
      hintText: hint,
      errorText: errorText,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validations: validations,
    );
  }
}
