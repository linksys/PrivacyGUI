import 'package:flutter/material.dart';

class PrimaryTextField extends StatefulWidget {
  const PrimaryTextField({
    Key? key,
    required this.controller,
    this.hintText = '',
    this.inputType = TextInputType.text,
    this.onChanged,
  }) : super(key: key);

  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final void Function(String text)? onChanged;

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
      controller: widget.controller,
      style: Theme.of(context).textTheme.bodyText1?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyText1
            ?.copyWith(color: Theme.of(context).colorScheme.surface),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1),
            borderRadius: BorderRadius.zero),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1),
            borderRadius: BorderRadius.zero),
      ),
      onChanged: _onChanged,
      keyboardType: widget.inputType,
    );
  }
}
