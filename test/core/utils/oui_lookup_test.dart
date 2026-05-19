import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';

void main() {
  // ---------------------------------------------------------------------------
  // getVendor
  // ---------------------------------------------------------------------------

  group('OuiLookup - getVendor', () {
    test('returns vendor for known Apple OUI (colon format)', () {
      expect(OuiLookup.getVendor('00:03:93:AA:BB:CC'), 'Apple, Inc.');
    });

    test('returns vendor for known Apple OUI (dash format)', () {
      expect(OuiLookup.getVendor('00-03-93-AA-BB-CC'), 'Apple, Inc.');
    });

    test('returns vendor for known Apple OUI (no separator)', () {
      expect(OuiLookup.getVendor('000393AABBCC'), 'Apple, Inc.');
    });

    test('returns vendor case-insensitively', () {
      expect(OuiLookup.getVendor('00:03:93:aa:bb:cc'), 'Apple, Inc.');
    });

    test('returns null for unknown OUI', () {
      expect(OuiLookup.getVendor('FF:FF:FF:AA:BB:CC'), isNull);
    });

    test('returns null for invalid MAC (too short)', () {
      expect(OuiLookup.getVendor('00:03'), isNull);
    });

    test('returns vendor for Samsung OUI', () {
      expect(
          OuiLookup.getVendor('00:07:AB:11:22:33'), 'Samsung Electronics Co.,Ltd');
    });

    test('returns vendor for Google OUI', () {
      expect(OuiLookup.getVendor('3C:5A:B4:11:22:33'), 'Google, Inc.');
    });

    test('returns vendor for Samsung A0:7D:9C OUI', () {
      expect(
          OuiLookup.getVendor('A0:7D:9C:67:CD:4C'), 'Samsung Electronics Co.,Ltd');
    });
  });

  // ---------------------------------------------------------------------------
  // hasVendor
  // ---------------------------------------------------------------------------

  group('OuiLookup - hasVendor', () {
    test('returns true for known OUI', () {
      expect(OuiLookup.hasVendor('00:03:93:AA:BB:CC'), isTrue);
    });

    test('returns false for unknown OUI', () {
      expect(OuiLookup.hasVendor('FF:FF:FF:AA:BB:CC'), isFalse);
    });

    test('returns false for invalid MAC', () {
      expect(OuiLookup.hasVendor('invalid'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // isRandomizedMac
  // ---------------------------------------------------------------------------

  group('OuiLookup - isRandomizedMac', () {
    test('returns true for second digit 2 (locally administered)', () {
      expect(OuiLookup.isRandomizedMac('02:AA:BB:CC:DD:EE'), isTrue);
      expect(OuiLookup.isRandomizedMac('A2:AA:BB:CC:DD:EE'), isTrue);
    });

    test('returns true for second digit 6 (locally administered)', () {
      expect(OuiLookup.isRandomizedMac('06:AA:BB:CC:DD:EE'), isTrue);
      expect(OuiLookup.isRandomizedMac('B6:AA:BB:CC:DD:EE'), isTrue);
    });

    test('returns true for second digit A (locally administered)', () {
      expect(OuiLookup.isRandomizedMac('0A:AA:BB:CC:DD:EE'), isTrue);
      expect(OuiLookup.isRandomizedMac('CA:AA:BB:CC:DD:EE'), isTrue);
    });

    test('returns true for second digit E (locally administered)', () {
      expect(OuiLookup.isRandomizedMac('0E:AA:BB:CC:DD:EE'), isTrue);
      expect(OuiLookup.isRandomizedMac('DE:AA:BB:CC:DD:EE'), isTrue);
    });

    test('returns false for universally administered MAC', () {
      expect(OuiLookup.isRandomizedMac('00:03:93:AA:BB:CC'), isFalse);
      expect(OuiLookup.isRandomizedMac('04:AA:BB:CC:DD:EE'), isFalse);
      expect(OuiLookup.isRandomizedMac('08:AA:BB:CC:DD:EE'), isFalse);
      expect(OuiLookup.isRandomizedMac('0C:AA:BB:CC:DD:EE'), isFalse);
    });

    test('returns false for invalid MAC (too short)', () {
      expect(OuiLookup.isRandomizedMac('0'), isFalse);
    });

    test('handles lowercase input', () {
      expect(OuiLookup.isRandomizedMac('0e:aa:bb:cc:dd:ee'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // getVendorOrPrivate
  // ---------------------------------------------------------------------------

  group('OuiLookup - getVendorOrPrivate', () {
    test('returns "Private/Random" for randomized MAC', () {
      expect(
          OuiLookup.getVendorOrPrivate('02:AA:BB:CC:DD:EE'), 'Private/Random');
      expect(
          OuiLookup.getVendorOrPrivate('DE:AD:BE:EF:12:34'), 'Private/Random');
    });

    test('returns vendor for known non-randomized MAC', () {
      expect(OuiLookup.getVendorOrPrivate('00:03:93:AA:BB:CC'), 'Apple, Inc.');
    });

    test('returns null for unknown non-randomized MAC', () {
      expect(OuiLookup.getVendorOrPrivate('00:FF:FF:AA:BB:CC'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // MAC format normalization
  // ---------------------------------------------------------------------------

  group('OuiLookup - MAC format handling', () {
    test('normalizes colon-separated MAC', () {
      expect(OuiLookup.getVendor('00:03:93:AA:BB:CC'), 'Apple, Inc.');
    });

    test('normalizes dash-separated MAC', () {
      expect(OuiLookup.getVendor('00-03-93-AA-BB-CC'), 'Apple, Inc.');
    });

    test('normalizes contiguous MAC', () {
      expect(OuiLookup.getVendor('000393AABBCC'), 'Apple, Inc.');
    });

    test('normalizes mixed case MAC', () {
      expect(OuiLookup.getVendor('00:03:93:aa:Bb:cC'), 'Apple, Inc.');
    });

    test('handles MAC with only 6 hex chars (OUI only)', () {
      expect(OuiLookup.getVendor('000393'), 'Apple, Inc.');
    });
  });
}
