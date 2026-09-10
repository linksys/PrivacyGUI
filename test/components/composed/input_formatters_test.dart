import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/composed/input_formatters.dart';

/// Feeds [keys] through [formatter] one keystroke at a time, the way a
/// TextField does — each pass sees the *formatted* result of the previous one.
/// That is the property the old implementation got wrong.
String _type(TextInputFormatter formatter, String keys, {String from = ''}) {
  var value = TextEditingValue(
    text: from,
    selection: TextSelection.collapsed(offset: from.length),
  );
  for (final key in keys.split('')) {
    final typed = TextEditingValue(
      text: value.text + key,
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    value = formatter.formatEditUpdate(value, typed);
  }
  return value.text;
}

/// Applies [count] backspaces from the end of [from].
String _backspace(TextInputFormatter formatter, String from, int count) {
  var value = TextEditingValue(
    text: from,
    selection: TextSelection.collapsed(offset: from.length),
  );
  for (int i = 0; i < count; i++) {
    if (value.text.isEmpty) break;
    final chopped = value.text.substring(0, value.text.length - 1);
    value = formatter.formatEditUpdate(
      value,
      TextEditingValue(
        text: chopped,
        selection: TextSelection.collapsed(offset: chopped.length),
      ),
    );
  }
  return value.text;
}

/// Simulates a paste into an empty field.
String _paste(TextInputFormatter formatter, String pasted) => formatter
    .formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(
        text: pasted,
        selection: TextSelection.collapsed(offset: pasted.length),
      ),
    )
    .text;

void main() {
  group('MacAddressFormatter', () {
    late MacAddressFormatter formatter;

    setUp(() => formatter = MacAddressFormatter());

    test('inserts a colon after every pair while typing', () {
      expect(_type(formatter, 'AABBCCDDEEFF'), 'AA:BB:CC:DD:EE:FF');
    });

    test('does not compound the colons it inserted itself', () {
      // The regression that made the field unusable: separators from the
      // previous pass were counted as input, so they multiplied.
      expect(_type(formatter, 'AABB'), 'AA:BB');
      expect(_type(formatter, 'AABBCC'), 'AA:BB:CC');
      expect(_type(formatter, 'AABBCCDD').length, 11);
    });

    test('never leaves a trailing colon mid-entry', () {
      expect(_type(formatter, 'AA'), 'AA');
      expect(_type(formatter, 'AABB'), 'AA:BB');
      expect(_type(formatter, 'AABBCC'), 'AA:BB:CC');
    });

    test('upper-cases hex digits', () {
      expect(_type(formatter, 'aabbccddeeff'), 'AA:BB:CC:DD:EE:FF');
    });

    test('caps growth at 12 hex digits', () {
      expect(_type(formatter, 'AABBCCDDEEFFAA'), 'AA:BB:CC:DD:EE:FF');
    });

    test('a shrinking replacement escapes the cap, as documented', () {
      // The exception the class DartDoc names. The shrink guard cannot tell a
      // backspace from a paste over a full selection, and 16 bare hex digits are
      // shorter than the 17-character address they replace — so they arrive
      // un-capped and un-upper-cased. Pinned rather than fixed: the guard is
      // what makes the separator deletable, and nothing in `lib/` wires this
      // formatter up. Here so the DartDoc cannot quietly become a false claim.
      final replaced = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'AA:BB:CC:DD:EE:FF',
          selection: TextSelection.collapsed(offset: 17),
        ),
        const TextEditingValue(
          text: 'aabbccddeeffaabb',
          selection: TextSelection.collapsed(offset: 16),
        ),
      );
      expect(replaced.text, 'aabbccddeeffaabb');
    });

    test('backspace removes characters instead of re-inserting separators', () {
      expect(
        _backspace(formatter, 'AA:BB:CC:DD:EE:FF', 1),
        'AA:BB:CC:DD:EE:F',
      );
      expect(_backspace(formatter, 'AA:BB:CC:DD:EE:FF', 2), 'AA:BB:CC:DD:EE:');
      expect(_backspace(formatter, 'AA:BB:CC:DD:EE:FF', 3), 'AA:BB:CC:DD:EE');
    });

    test('clears completely when the whole value is deleted', () {
      expect(_backspace(formatter, 'AA:BB:CC:DD:EE:FF', 17), '');
    });

    test('resumes formatting correctly after a backspace', () {
      final afterDelete = _backspace(formatter, 'AA:BB:CC', 1); // 'AA:BB:C'
      expect(_type(formatter, 'C', from: afterDelete), 'AA:BB:CC');
    });

    test('formats a pasted bare hex string', () {
      expect(_paste(formatter, 'aabbccddeeff'), 'AA:BB:CC:DD:EE:FF');
    });

    test('formats a pasted value that already has colons', () {
      expect(_paste(formatter, 'AA:BB:CC:DD:EE:FF'), 'AA:BB:CC:DD:EE:FF');
    });

    test('normalises a pasted hyphen-separated value', () {
      // Hyphens never survive the FilteringTextInputFormatter that runs first,
      // but the formatter must not choke if they reach it.
      expect(_paste(formatter, 'AA-BB-CC-DD-EE-FF'), 'AA:BB:CC:DD:EE:FF');
    });

    test('drops non-hex characters from a pasted value', () {
      expect(_paste(formatter, 'AA:BB:ZZ:CC'), 'AA:BB:CC');
    });

    test('leaves an empty field empty', () {
      expect(_paste(formatter, ''), '');
    });
  });
}
