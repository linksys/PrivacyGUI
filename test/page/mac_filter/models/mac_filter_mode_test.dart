import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';

void main() {
  group('MacFilterMode — wire values', () {
    test('each mode reads back from the string the firmware accepts', () {
      expect(MacFilterMode.fromWire('Allow'), MacFilterMode.allow);
      expect(MacFilterMode.fromWire('Deny'), MacFilterMode.deny);
      expect(MacFilterMode.fromWire('Disabled'), MacFilterMode.disabled);
      expect(MacFilterMode.allow.wire, 'Allow');
      expect(MacFilterMode.deny.wire, 'Deny');
      expect(MacFilterMode.disabled.wire, 'Disabled');
    });

    test('an unknown value reads as off, the safe default for a filter', () {
      expect(MacFilterMode.fromWire(''), MacFilterMode.disabled);
      expect(MacFilterMode.fromWire('allow'), MacFilterMode.disabled);
    });
  });
}
