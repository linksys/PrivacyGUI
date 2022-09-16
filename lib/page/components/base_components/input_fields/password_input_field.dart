import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/customs/customs.dart';


// TODO @Peter
class PasswordInputField extends StatefulWidget {
  const PasswordInputField({
    Key? key,
    required this.titleText,
    required this.controller,
    this.inputType = TextInputType.text,
    this.hintText = '',
    this.isError = false,
    this.errorText = '',
    this.errorColor = Colors.red,
    this.onChanged,
    this.color,
    this.withValidator = false,
  }) : super(key: key);

  const PasswordInputField.withValidator(
      {Key? key,
      required this.titleText,
      required this.controller,
      this.hintText = '',
      this.inputType = TextInputType.text,
      this.onChanged,
      this.isError = false,
      this.errorText = '',
      this.color,
      this.errorColor = Colors.red,
      this.withValidator = true})
      : super(key: key);

  final String titleText;
  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final bool isError;
  final String errorText;
  final Color errorColor;
  final bool withValidator;
  final Color? color;

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
          },
          secured: secured,
          customPrimaryColor: widget.color,
          suffixIcon: _suffixIcon(),
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
