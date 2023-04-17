import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MACFormField extends ConsumerStatefulWidget {
  const MACFormField({
    super.key,
    this.onChanged,
    this.controller,
    this.hasBorder = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool hasBorder;

  @override
  ConsumerState<MACFormField> createState() => _MACFormFieldState();
}

class _MACFormFieldState extends ConsumerState<MACFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: widget.hasBorder ? InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
      ) : null,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-f]')),
        // allow only  digits
        MacAddressFormatter(),
        // custom class to format entered data from textField
        LengthLimitingTextInputFormatter(17)
        // restrict user to enter max 16 characters
      ],
      onChanged: widget.onChanged,
    );
  }
}

// this class will be called, when their is change in textField
class MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String enteredData = newValue.text; // get data enter by used in textField
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < enteredData.length; i++) {
      // add each character into String buffer
      buffer.write(enteredData[i]);
      int index = i + 1;
      if (index % 2 == 0 && enteredData.length != index) {
        buffer.write(":");
      }
    }

    return TextEditingValue(
        text: buffer.toString(), // final generated credit card number
        selection: TextSelection.collapsed(
            offset: buffer.toString().length) // keep the cursor at end
        );
  }
}
