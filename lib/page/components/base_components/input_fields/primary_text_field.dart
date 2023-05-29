import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrimaryTextField extends ConsumerStatefulWidget {
  const PrimaryTextField({
    Key? key,
    required this.controller,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
    this.onFocusChanged,
    this.customPrimaryColor,
    this.isError = false,
    this.errorColor = Colors.red,
    this.secured = false,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;
  final void Function(bool hasFocus)? onFocusChanged;
  final Color? customPrimaryColor;
  final bool isError;
  final Color errorColor;
  final bool secured;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;

  @override
  _PrimaryTextFieldState createState() => _PrimaryTextFieldState();
}

class _PrimaryTextFieldState extends ConsumerState<PrimaryTextField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();

    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();

    _focus.removeListener(_onFocusChange);
    _focus.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
  }

  void _onFocusChange() {
    widget.onFocusChanged?.call(_focus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.customPrimaryColor ?? Theme.of(context).colorScheme.primary;
    return TextField(
      readOnly: widget.readOnly,
      obscureText: widget.secured,
      controller: widget.controller,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: widget.isError ? widget.errorColor : primaryColor,
          ),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        hintText: widget.hintText,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: Theme.of(context).colorScheme.surface),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: widget.isError ? widget.errorColor : primaryColor,
                width: 1),
            borderRadius: BorderRadius.zero),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: widget.isError ? widget.errorColor : primaryColor,
                width: 1),
            borderRadius: BorderRadius.zero),
      ),
      onChanged: _onChanged,
      keyboardType: widget.inputType,
      focusNode: _focus,
    );
  }
}
