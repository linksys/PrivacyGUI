import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/primary_text_field.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';

class CustomTitleInputField extends StatelessWidget {
  const CustomTitleInputField({
    Key? key,
    required this.title,
    required this.controller,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.customPrimaryColor,
    this.isError = false,
    this.errorText = '',
    this.errorColor = Colors.red,
    this.secured = false,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
  }) : super(key: key);

  final Widget? title;
  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final void Function(bool hasFocus)? onFocusChanged;
  final Color? customPrimaryColor;
  final bool isError;
  final String errorText;
  final Color errorColor;
  final bool secured;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final primaryColor = customPrimaryColor ?? Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title ?? const Center(),
        box8(),
        PrimaryTextField(
          controller: controller,
          hintText: hintText,
          inputType: inputType,
          onChanged: onChanged,
          onFocusChanged: onFocusChanged,
          customPrimaryColor: primaryColor,
          isError: isError,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          secured: secured,
          readOnly: readOnly,
        ),
        Visibility(
            visible: isError && errorText.isNotEmpty,
            child: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),
                Text(
                  errorText,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(color: errorColor),
                )
              ],
            )),
      ],
    );
  }
}
