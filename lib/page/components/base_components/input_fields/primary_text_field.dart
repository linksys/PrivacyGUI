import 'package:flutter/material.dart';

class PrimaryTextField extends StatefulWidget {
  const PrimaryTextField({
    Key? key,
    required this.controller,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.isError = false,
    this.errorColor = Colors.red,
    this.onChanged,
    this.secured = false,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final bool isError;
  final Color errorColor;
  final bool secured;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  _PrimaryTextFieldState createState() => _PrimaryTextFieldState();
}

class _PrimaryTextFieldState extends State<PrimaryTextField> {
  @override
  void dispose() {
    super.dispose();
  }

  void _onChanged(String value) {
    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: widget.secured,
      controller: widget.controller,
      style: Theme.of(context).textTheme.bodyText1?.copyWith(
            color: widget.isError
                ? widget.errorColor
                : Theme.of(context).colorScheme.primary,
          ),
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        hintText: widget.hintText,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyText1
            ?.copyWith(color: Theme.of(context).colorScheme.surface),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: widget.isError
                    ? widget.errorColor
                    : Theme.of(context).colorScheme.primary,
                width: 1),
            borderRadius: BorderRadius.zero),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: widget.isError
                    ? widget.errorColor
                    : Theme.of(context).colorScheme.primary,
                width: 1),
            borderRadius: BorderRadius.zero),
      ),
      onChanged: _onChanged,
      keyboardType: widget.inputType,
    );
  }
}
