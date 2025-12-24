import 'package:flutter/services.dart';

/// Formats MAC address input with colons between each pair (AA:BB:CC:DD:EE:FF)
class MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String enteredData = newValue.text;
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < enteredData.length; i++) {
      buffer.write(enteredData[i]);
      int index = i + 1;
      if (index % 2 == 0 && enteredData.length != index) {
        buffer.write(":");
      }
    }

    return TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.toString().length));
  }
}

/// Converts text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Formats IP octets (0-255)
class IPOctetsFormatter extends TextInputFormatter {
  final bool acceptEmpty;

  IPOctetsFormatter({this.acceptEmpty = true});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      final initValue = acceptEmpty ? '' : '0';
      return TextEditingValue(
          text: initValue,
          selection: TextSelection.collapsed(offset: initValue.length));
    }
    String enteredData = newValue.text;
    StringBuffer buffer = StringBuffer();

    final intValue = int.tryParse(enteredData);
    if ((intValue ?? 256) > 255) {
      buffer.clear();
      buffer.write(0);
    } else {
      buffer.write(intValue);
    }
    return TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.toString().length));
  }
}

/// Formats numbers within min-max range
class MinMaxNumberFormatter extends TextInputFormatter {
  final int min;
  final int max;
  final bool acceptEmpty;

  MinMaxNumberFormatter({
    this.min = 0,
    required this.max,
    this.acceptEmpty = false,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      final initValue = acceptEmpty ? '' : '$min';
      return TextEditingValue(
          text: initValue,
          selection:
              TextSelection(baseOffset: 0, extentOffset: initValue.length));
    }
    String enteredData = newValue.text;
    StringBuffer buffer = StringBuffer();

    final intValue = int.tryParse(enteredData);
    final exceedMax = (intValue ?? (max + 1)) > max;
    if (exceedMax) {
      buffer.clear();
      buffer.write(max);
    } else {
      buffer.write(intValue);
    }
    return TextEditingValue(
        text: buffer.toString(),
        selection: exceedMax
            ? TextSelection(
                baseOffset: 0, extentOffset: buffer.toString().length)
            : TextSelection.collapsed(offset: buffer.toString().length));
  }
}
