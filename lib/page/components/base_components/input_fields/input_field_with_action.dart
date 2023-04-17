import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

class InputFieldWithAction extends ConsumerWidget {
  const InputFieldWithAction({
    Key? key,
    required this.controller,
    required this.titleText,
    required this.rightTitleText,
    required this.rightAction,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.customPrimaryColor,
    this.isError = false,
    this.errorColor = Colors.red,
    this.errorText = '',
    this.secured = false,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
  }) : super(key: key);

  final TextEditingController controller;
  final String titleText;
  final String rightTitleText;
  final void Function()? rightAction;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final void Function(bool hasFocus)? onFocusChanged;
  final Color? customPrimaryColor;
  final bool isError;
  final Color errorColor;
  final String errorText;
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
        Row(
          children: [
            Expanded(
              child: Text(
                titleText,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(color: isError ? errorColor : primaryColor),
              ),
            ),
            SimpleTextButton(
              text: rightTitleText,
              onPressed: rightAction,
              padding: EdgeInsets.zero,
            )
          ],
        ),
        PrimaryTextField(
          controller: controller,
          hintText: hintText,
          inputType: inputType,
          onChanged: onChanged,
          onFocusChanged: onFocusChanged,
          customPrimaryColor: primaryColor,
          isError: isError,
          errorColor: errorColor,
          secured: secured,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
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
