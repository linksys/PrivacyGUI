import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_data.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';

void main() {
  group('MacFilterData — fromWire', () {
    test('reads the mode and splits the comma-joined list', () {
      final data =
          MacFilterData.fromWire('Deny', 'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:02');

      expect(data.mode, MacFilterMode.deny);
      expect(data.macs, ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']);
    });

    test('an empty list string is no MACs, not one empty MAC', () {
      expect(MacFilterData.fromWire('Disabled', '').macs, isEmpty);
      expect(MacFilterData.fromWire('Disabled', '  ').macs, isEmpty);
    });

    test('drops blanks around and between entries', () {
      expect(MacFilterData.fromWire('Allow', ' AA:BB:CC:DD:EE:01 ,,').macs,
          ['AA:BB:CC:DD:EE:01']);
    });
  });

  group('MacFilterData — Instant Privacy', () {
    // One device mode feeds both pages: Allow is Instant Privacy's, Deny is MAC
    // Filter's, so MAC Filter's Deny must not read as Instant Privacy on.
    test('is on only in Allow', () {
      expect(
          const MacFilterData(mode: MacFilterMode.allow, macs: [])
              .isInstantPrivacyOn,
          isTrue);
      expect(
          const MacFilterData(mode: MacFilterMode.deny, macs: [])
              .isInstantPrivacyOn,
          isFalse);
      expect(
          const MacFilterData(mode: MacFilterMode.disabled, macs: [])
              .isInstantPrivacyOn,
          isFalse);
    });
  });

  group('MacFilterData — equality', () {
    test('compares the mode and the list', () {
      const a = MacFilterData(mode: MacFilterMode.allow, macs: ['AA']);

      expect(a, const MacFilterData(mode: MacFilterMode.allow, macs: ['AA']));
      expect(a,
          isNot(const MacFilterData(mode: MacFilterMode.deny, macs: ['AA'])));
      expect(a,
          isNot(const MacFilterData(mode: MacFilterMode.allow, macs: ['BB'])));
    });
  });
}
