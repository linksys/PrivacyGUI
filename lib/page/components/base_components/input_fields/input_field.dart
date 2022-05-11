import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/input_fields/primary_text_field.dart';

class InputField extends StatelessWidget {
  const InputField({
    Key? key,
    required this.titleText,
    required this.controller,
    this.hintText = '',
    this.onChanged,
  }) : super(key: key);

  final String titleText;
  final TextEditingController controller;
  final String hintText;
  final void Function(String text)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          child: Text(
            titleText,
            style: Theme.of(context).textTheme.headline4?.copyWith(
                color: Theme.of(context).colorScheme.primary
            ),
          ),
          padding: const EdgeInsets.only(bottom: 8),
        ),
        PrimaryTextField(
          controller: controller,
          hintText: hintText,
          onChanged: onChanged,
        )
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}