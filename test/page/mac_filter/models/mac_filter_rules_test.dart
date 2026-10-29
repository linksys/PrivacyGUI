import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_rules.dart';

void main() {
  group('MacFilterRules — validateMac', () {
    test('accepts colon and dash forms, rejects garbage', () {
      expect(MacFilterRules.validateMac('AA:BB:CC:DD:EE:01'), isTrue);
      expect(MacFilterRules.validateMac('aa-bb-cc-dd-ee-01'), isTrue);
      expect(MacFilterRules.validateMac('  AA:BB:CC:DD:EE:01  '), isTrue);
      expect(MacFilterRules.validateMac('zz:zz:zz:zz:zz:zz'), isFalse);
      expect(MacFilterRules.validateMac('AA:BB:CC'), isFalse);
      expect(MacFilterRules.validateMac(''), isFalse);
    });

    // #1737 AC1: no separators to type. Each accepted spelling, in both cases
    // and with surrounding whitespace.
    test('accepts the bare 12-digit form (#1737)', () {
      expect(MacFilterRules.validateMac('AABBCCDDEEFF'), isTrue);
      expect(MacFilterRules.validateMac('aabbccddeeff'), isTrue);
      expect(MacFilterRules.validateMac('aAbBcCdDeEfF'), isTrue);
      expect(MacFilterRules.validateMac('  aabbccddee01\t'), isTrue);
    });

    test('accepts dotted groups of four (#1737)', () {
      expect(MacFilterRules.validateMac('aabb.ccdd.eeff'), isTrue);
      expect(MacFilterRules.validateMac('AABB.CCDD.EEFF'), isTrue);
      expect(MacFilterRules.validateMac(' aabb.ccdd.eeff '), isTrue);
    });

    test('still rejects what is not one MAC (#1737)', () {
      for (final bad in [
        'AABBCCDDEEF', // 11 digits
        'AABBCCDDEEFF0', // 13 digits — longer input is not truncated (AC5)
        'AABBCCDDEEFG', // non-hex
        'aabb.ccdd.eef', // short dotted group
        'aab.bccd.deeff', // dotted, wrong grouping
        'aa.bb.cc.dd.ee.ff', // dots between pairs
        'aabb:ccdd:eeff', // colons between groups of four
        'aabb-ccdd-eeff', // dashes between groups of four
        'AA BB CC DD EE FF', // a space is not a separator
        'AA:BB:CC:DD:EE:FF:00', // seven pairs
        'AABBCC:DDEEFF', // partly separated
        '192.168.1.10', // an IP
        'Pixel-7a', // a name
      ]) {
        expect(MacFilterRules.validateMac(bad), isFalse, reason: bad);
      }
    });
  });

  group('MacFilterRules — normalizeMac, accepted spellings (#1737)', () {
    // AC2: every accepted spelling is stored as the same canonical form.
    test('every accepted spelling gives AA:BB:CC:DD:EE:FF', () {
      for (final form in [
        'AA:BB:CC:DD:EE:FF',
        'aa:bb:cc:dd:ee:ff',
        'aa-bb-cc-dd-ee-ff',
        'AABBCCDDEEFF',
        'aabbccddeeff',
        'aabb.ccdd.eeff',
        'AABB.CCDD.EEFF',
        '  aabbccddeeff  ',
      ]) {
        expect(MacFilterRules.normalizeMac(form), 'AA:BB:CC:DD:EE:FF',
            reason: form);
      }
    });

    test('a value that is not one MAC keeps its text, as before', () {
      // The service passes malformed entries through so its error can quote
      // them; the bare-form branch must not split those into pairs.
      expect(MacFilterRules.normalizeMac(' zz-zz '), 'ZZ:ZZ');
      expect(MacFilterRules.normalizeMac('AABBCCDDEEFF0'), 'AABBCCDDEEFF0');
    });
  });

  group('MacFilterRules — normalizeMac', () {
    test('uppercases and colon-separates', () {
      expect(MacFilterRules.normalizeMac('aa-bb-cc-dd-ee-01'),
          'AA:BB:CC:DD:EE:01');
      expect(MacFilterRules.normalizeMac('  aa:bb:cc:dd:ee:01 '),
          'AA:BB:CC:DD:EE:01');
    });
  });
}
