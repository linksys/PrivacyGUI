import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'input_field.dart';

class ShortInputField extends ConsumerWidget {
  const ShortInputField({
    super.key,
    required this.titleText,
    required this.controller,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.customPrimaryColor,
    this.width,
  });

  final String titleText;
  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final void Function(bool hasFocus)? onFocusChanged;
  final Color? customPrimaryColor;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: width,
      child: InputField(
        titleText: titleText,
        controller: controller,
        hintText: hintText,
        inputType: inputType,
        onChanged: onChanged,
        onFocusChanged: onFocusChanged,
        customPrimaryColor: customPrimaryColor,
      ),
    );
  }
}
