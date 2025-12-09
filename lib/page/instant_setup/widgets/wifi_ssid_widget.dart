import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

/// A reusable widget for entering Wi-Fi SSID.
///
/// This widget provides a text input field for SSID with optional label, hint,
/// error text, controller, and callbacks for changes and submission.
class WiFiSSIDField extends ConsumerWidget {
  /// The label text for the SSID input field.
  final String? label;

  /// The hint text displayed inside the SSID input field.
  final String? hint;

  /// The error text to display below the SSID input field.
  final String? errorText;

  /// The text editing controller for the SSID input field.
  final TextEditingController? controller;

  /// Callback function when the text in the SSID field changes.
  final void Function(String value)? onChanged;

  /// Callback function when the user submits the text in the SSID field.
  final void Function(String value)? onSubmitted;

  const WiFiSSIDField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTextField(
      border: const OutlineInputBorder(),
      headerText: label,
      hintText: hint,
      errorText: errorText,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
