import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/primary_text_field.dart';

class InputField extends StatelessWidget {
  const InputField({
    Key? key,
    required this.titleText,
    required this.controller,
    this.inputType = TextInputType.text,
    this.hintText = '',
    this.isError = false,
    this.errorText = '',
    this.errorColor = Colors.red,
    this.onChanged,
    this.secured = false,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  final String titleText;
  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final bool isError;
  final String errorText;
  final Color errorColor;
  final bool secured;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          child: Text(
            titleText,
            style: Theme.of(context).textTheme.headline4?.copyWith(
                color: isError
                    ? errorColor
                    : Theme.of(context).colorScheme.primary),
          ),
          padding: const EdgeInsets.only(bottom: 8),
        ),
        PrimaryTextField(
          controller: controller,
          hintText: hintText,
          inputType: inputType,
          onChanged: onChanged,
          isError: isError,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          secured: secured,
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
