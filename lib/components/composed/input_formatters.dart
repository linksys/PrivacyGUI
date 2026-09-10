import 'package:flutter/services.dart';

/// Formats MAC address input with colons between each pair (AA:BB:CC:DD:EE:FF)
/// and upper-cases the hex digits.
///
/// The colons are re-derived from the hex digits on every keystroke rather than
/// appended to whatever is already in the field. That distinction is the whole
/// point: `formatEditUpdate` receives the *result* of the previous pass, so a
/// formatter that counts characters without first stripping the separators it
/// inserted itself feeds on its own output — one pair of colons becomes two,
/// then four, and twelve keystrokes produce a 200-character string.
///
/// No length limiter is needed — a MAC is 6 bytes and this caps *growth* at 12
/// hex digits. Only growth: a net-shrinking edit is passed through untouched by
/// the guard below, which cannot tell a backspace from a paste over a full
/// selection, so replacing a complete address with a longer bare string leaves
/// it un-capped and un-upper-cased. That is the price of a deletable separator,
/// and a test pins it.
///
/// **Nothing in `lib/` wires this up.** It is kept rather than deleted so the
/// paragraph above does not have to be rediscovered by the next MAC-only field,
/// and its tests pin that behaviour. The Instant Privacy add-device field is not
/// that caller: it doubles as an `AppSelectAutoComplete` query box matching a
/// device on name and IP as well as MAC, so formatting keystrokes into hex pairs
/// there disables the search half of the control (#1059).
class MacAddressFormatter extends TextInputFormatter {
  /// Hex digits in a 6-byte MAC address.
  static const _hexDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Deletion is passed through untouched. Reformatting a shrinking string
    // re-inserts the separator the user just backspaced over, which makes the
    // colons impossible to delete and strands the caret.
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    var hex =
        newValue.text.replaceAll(RegExp(r'[^a-fA-F0-9]'), '').toUpperCase();
    if (hex.length > _hexDigits) {
      hex = hex.substring(0, _hexDigits);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < hex.length; i++) {
      buffer.write(hex[i]);
      // Separator after every pair, but never trailing — otherwise the field
      // shows "AA:" before the user has typed anything to put after it.
      if ((i + 1) % 2 == 0 && i != hex.length - 1) {
        buffer.write(':');
      }
    }
    final text = buffer.toString();

    return TextEditingValue(
      text: text,
      // The caret parks at the end. A MAC is a fixed-width value typed
      // left-to-right, so mapping the old offset across inserted separators
      // buys nothing and mid-string editing is not a use case here.
      selection: TextSelection.collapsed(offset: text.length),
    );
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
