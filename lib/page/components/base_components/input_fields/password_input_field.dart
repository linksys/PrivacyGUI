import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/customs/_customs.dart';
import 'package:linksys_moab/validator_rules/_validator_rules.dart';

import 'input_field.dart';

// TODO @Peter
class PasswordInputField extends StatefulWidget {
  const PasswordInputField({
    Key? key,
    required this.titleText,
    required this.controller,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.onValidationChanged,
    this.isError = false,
    this.errorText = '',
    this.color,
    this.errorColor = Colors.red,
    this.withValidator = false,
    this.suffixIcon,
  }) : super(key: key);

  const PasswordInputField.withValidator({
    Key? key,
    required this.titleText,
    required this.controller,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.onValidationChanged,
    this.isError = false,
    this.errorText = '',
    this.color,
    this.errorColor = Colors.red,
    this.withValidator = true,
    this.suffixIcon,
  }) : super(key: key);

  final String titleText;
  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final void Function(bool hasFocus)? onFocusChanged;
  final void Function(bool isValid)? onValidationChanged;
  final bool isError;
  final String errorText;
  final Color? color;
  final Color errorColor;
  final bool withValidator;
  final Widget? suffixIcon;

  @override
  _PasswordInputFieldState createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool secured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputField(
          titleText: widget.titleText,
          controller: widget.controller,
          inputType: widget.inputType,
          hintText: widget.hintText,
          isError: widget.isError,
          errorText: widget.errorText,
          errorColor: widget.errorColor,
          onChanged: (value) {
            setState(() {});
            widget.onChanged?.call(value);
            widget.onValidationChanged
                ?.call(ComplexPasswordValidator().validate(value));
          },
          onFocusChanged: widget.onFocusChanged,
          secured: secured,
          customPrimaryColor: widget.color,
          suffixIcon: widget.suffixIcon ?? _suffixIcon(),
        ),
        if (widget.withValidator)
          SizedBox(
            height: widget.errorText.isEmpty ? 23 : 31,
          ),
        if (widget.withValidator)
          PasswordValidityWidget(passwordText: widget.controller.text),
      ],
    );
  }

  Widget _suffixIcon() {
    return SimpleTextButton(
        text: secured ? 'show' : 'hide',
        onPressed: () {
          setState(() {
            secured = !secured;
          });
        });
  }
}
