import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/primary_text_field.dart';

class InputField extends ConsumerWidget {
  const InputField({
    Key? key,
    required this.titleText,
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

  final String titleText;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor =
        customPrimaryColor ?? Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText.isEmpty
            ? const Center()
            : Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  titleText,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: isError ? errorColor : primaryColor),
                ),
              ),
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
                      .bodyLarge
                      ?.copyWith(color: errorColor),
                )
              ],
            )),
      ],
    );
  }
}
