import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class WiFiSSIDField extends ConsumerStatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final void Function(bool isValid, String input)? onCheckInput;

  const WiFiSSIDField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onCheckInput,
  });

  @override
  ConsumerState<WiFiSSIDField> createState() => _WiFiSSIDFieldState();
}

class _WiFiSSIDFieldState extends ConsumerState<WiFiSSIDField> {
  final InputValidator wifiSSIDValidator = InputValidator([
    RequiredRule(),
    NoSurroundWhitespaceRule(),
    WiFiSsidRule(),
  ]);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      border: const OutlineInputBorder(),
      headerText: widget.label,
      hintText: widget.hint,
      errorText: () {
        if (widget.controller?.text.isEmpty == true) {
          return null;
        }
        final errorKeys = wifiSSIDValidator
            .validateDetail(widget.controller?.text ?? '', onlyFailed: true);
        if (errorKeys.isEmpty) {
          return null;
        } else if (errorKeys.keys.first ==
            (NoSurroundWhitespaceRule).toString()) {
          return 'Can\'t start and/or end with a space';
        } else if (errorKeys.keys.first == (WiFiSsidRule).toString()) {
          return 'WiFi SSID should not be empty';
        } else {
          return null;
        }
      }(),
      controller: widget.controller,
      onChanged: (value) {
        final errorKeys = wifiSSIDValidator
            .validateDetail(widget.controller?.text ?? '', onlyFailed: true);
        if (value.isEmpty || errorKeys.isNotEmpty) {
          widget.onCheckInput?.call(false, value);
        } else {
          widget.onCheckInput?.call(true, value);
        }
      },
    );
  }
}
