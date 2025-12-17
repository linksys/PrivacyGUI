import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:flutter/services.dart';
import 'package:privacy_gui/page/components/composed/input_formatters.dart';

/// A text field that only accepts numbers within a min/max range.
/// Composed component replacing AppTextField.minMaxNumber from privacygui_widgets.
class AppMinMaxNumberTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final int min;
  final int max;
  final bool enable;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextInputType inputType;
  final bool acceptEmpty;

  const AppMinMaxNumberTextField({
    Key? key,
    this.controller,
    this.label,
    this.min = 0,
    required this.max,
    this.enable = true,
    this.onChanged,
    this.errorText,
    this.inputType = TextInputType.number,
    this.acceptEmpty = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          AppText.labelLarge(label!),
          AppGap.xs(),
        ],
        AppTextField(
          controller: controller,
          readOnly: !enable,
          keyboardType: inputType,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            MinMaxNumberFormatter(min: min, max: max, acceptEmpty: acceptEmpty),
          ],
          errorText: errorText,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
