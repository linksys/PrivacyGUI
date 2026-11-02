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

  // #1737 AC6: the add-device search finds a MAC however it is typed.
  group('MacFilterRules — macContains (#1737)', () {
    const mac = 'AA:BB:CC:DD:EE:FF';

    test('ignores separators and case on both sides', () {
      for (final query in [
        'aabb',
        'AABB',
        'aa-bb',
        'aa:bb',
        'AABB.CC',
        'bbccdd',
        'ee:ff',
        'aabbccddeeff',
        'aabb.ccdd.eeff',
      ]) {
        expect(MacFilterRules.macContains(mac, query), isTrue, reason: query);
      }
    });

    test('false for digits the MAC does not contain in that order', () {
      expect(MacFilterRules.macContains(mac, 'aacc'), isFalse);
      expect(MacFilterRules.macContains(mac, 'ffaa'), isFalse);
      expect(MacFilterRules.macContains(mac, 'aabbccddeeff00'), isFalse);
    });

    test('false for a name or an IP, even one that shares hex digits', () {
      // `Pixel` reduces to `e`, which this MAC contains. A name is not part of
      // a MAC: name search is the default matcher's job.
      for (final query in ['Pixel', 'Pixel-7a', '192.168.1.16', 'e f']) {
        expect(MacFilterRules.macContains(mac, query), isFalse, reason: query);
      }
    });

    test('a word made only of hex letters is read as part of a MAC', () {
      // `Cafe` cannot be told apart from a MAC fragment (#1059), so it finds a
      // MAC containing `CA:FE`. Its name still matches through the default.
      expect(MacFilterRules.macContains('02:CA:FE:33:44:55', 'Cafe'), isTrue);
      expect(MacFilterRules.macContains(mac, 'Cafe'), isFalse);
    });

    test('false for separators alone', () {
      for (final query in [':', '-', '.', ':-.']) {
        expect(MacFilterRules.macContains(mac, query), isFalse, reason: query);
      }
    });

    // Round 2 (lens E): an IP query must not be read as MAC digits, even when
    // a MAC happens to contain those digits.
    test('false for an IP-shaped query, even one whose digits the MAC has', () {
      const ipLikeMac = '19:21:68:11:6A:BC';
      for (final query in [
        '192.',
        '192.168',
        '192.168.',
        '192.168.1',
        '192.168.1.16',
        '10.0',
      ]) {
        expect(MacFilterRules.macContains(ipLikeMac, query), isFalse,
            reason: query);
      }
      expect(MacFilterRules.macContains('10:00:BB:CC:DD:EE', '10.0'), isFalse);
    });

    test('a dotted MAC fragment and bare digits are still MAC queries', () {
      const ipLikeMac = '19:21:68:11:6A:BC';
      // Four-digit groups are the dotted MAC spelling, not an IP.
      expect(MacFilterRules.macContains(ipLikeMac, '1921.6811'), isTrue);
      // Digits with no `.` cannot be told apart from a MAC fragment (#1059).
      expect(MacFilterRules.macContains(ipLikeMac, '192168'), isTrue);
      expect(MacFilterRules.macContains(ipLikeMac, '19:21'), isTrue);
      expect(MacFilterRules.macContains(ipLikeMac, '19-21-68'), isTrue);
    });
  });
}
