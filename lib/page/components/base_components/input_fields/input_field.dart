import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/input_fields/primary_text_field.dart';

class InputField extends StatelessWidget {
  const InputField({
    Key? key,
    required this.titleText,
    required this.controller,
    this.inputType = TextInputType.text,
    this.hintText = '',
    this.isError = false,
    this.errorColor = Colors.red,
    this.onChanged,
  }) : super(key: key);

  final String titleText;
  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final bool isError;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          child: Text(
            titleText,
            style: Theme.of(context)
                .textTheme
                .headline4
                ?.copyWith(color: isError ? errorColor : Theme.of(context).colorScheme.primary),
          ),
          padding: const EdgeInsets.only(bottom: 8),
        ),
        PrimaryTextField(
          controller: controller,
          hintText: hintText,
          inputType: inputType,
          onChanged: onChanged,
          isError: isError,
        )
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
