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
