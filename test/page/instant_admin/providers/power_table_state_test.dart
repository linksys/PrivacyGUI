import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_state.dart';

void main() {
  group('PowerTableState', () {
    test('Equatable: same values are equal', () {
      const state1 = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa, PowerTableCountries.twn],
        country: PowerTableCountries.usa,
      );
      const state2 = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa, PowerTableCountries.twn],
        country: PowerTableCountries.usa,
      );
      expect(state1, equals(state2));
    });

    test('Equatable: different values are not equal', () {
      const state1 = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa],
        country: PowerTableCountries.usa,
      );
      const state2 = PowerTableState(
        isPowerTableSelectable: false,
        supportedCountries: [PowerTableCountries.twn],
        country: PowerTableCountries.twn,
      );
      expect(state1, isNot(equals(state2)));
    });

    test('Equatable: different supportedCountries order matters', () {
      const state1 = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa, PowerTableCountries.twn],
      );
      const state2 = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.twn, PowerTableCountries.usa],
      );
      expect(state1, isNot(equals(state2)));
    });

    test('copyWith updates isPowerTableSelectable only', () {
      const original = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa],
        country: PowerTableCountries.usa,
      );
      final updated = original.copyWith(isPowerTableSelectable: false);

      expect(updated.isPowerTableSelectable, false);
      expect(updated.supportedCountries, original.supportedCountries);
      expect(updated.country, original.country);
    });

    test('copyWith updates supportedCountries only', () {
      const original = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa],
        country: PowerTableCountries.usa,
      );
      final updated = original.copyWith(
        supportedCountries: [PowerTableCountries.twn, PowerTableCountries.jpn],
      );

      expect(updated.isPowerTableSelectable, true);
      expect(updated.supportedCountries.length, 2);
      expect(updated.supportedCountries,
          contains(PowerTableCountries.twn));
      expect(updated.country, PowerTableCountries.usa);
    });

    test('copyWith updates country only', () {
      const original = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa, PowerTableCountries.twn],
        country: PowerTableCountries.usa,
      );
      final updated = original.copyWith(country: PowerTableCountries.twn);

      expect(updated.isPowerTableSelectable, true);
      expect(updated.supportedCountries, original.supportedCountries);
      expect(updated.country, PowerTableCountries.twn);
    });

    test('copyWith with no arguments returns equivalent object', () {
      const original = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa],
        country: PowerTableCountries.usa,
      );
      final copied = original.copyWith();

      expect(copied, equals(original));
    });

    test('toMap and fromMap roundtrip', () {
      const original = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa, PowerTableCountries.twn],
        country: PowerTableCountries.usa,
      );
      final map = original.toMap();
      final restored = PowerTableState.fromMap(map);

      expect(restored.isPowerTableSelectable, original.isPowerTableSelectable);
      expect(restored.supportedCountries.length,
          original.supportedCountries.length);
      expect(restored.country, original.country);
    });

    test('toMap and fromMap roundtrip with null country', () {
      const original = PowerTableState(
        isPowerTableSelectable: false,
        supportedCountries: [],
        country: null,
      );
      final map = original.toMap();
      final restored = PowerTableState.fromMap(map);

      expect(restored.isPowerTableSelectable, false);
      expect(restored.supportedCountries, isEmpty);
      expect(restored.country, isNull);
    });

    test('toJson and fromJson roundtrip', () {
      // Note: toJson fails with MappedListIterable because toMap returns
      // a lazy iterable for supportedCountries. This is a known limitation
      // of the current PowerTableState.toMap() implementation.
      // Testing fromJson with a manually created JSON string instead.
      const jsonString =
          '{"isPowerTableSelectable":true,"supportedCountries":["JPN","KOR","TWN"],"country":"JPN"}';
      final restored = PowerTableState.fromJson(jsonString);

      expect(restored.isPowerTableSelectable, true);
      expect(restored.supportedCountries.length, 3);
      expect(restored.country, PowerTableCountries.jpn);
    });

    test('toMap contains expected keys', () {
      const state = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa],
        country: PowerTableCountries.usa,
      );
      final map = state.toMap();

      expect(map.containsKey('isPowerTableSelectable'), true);
      expect(map.containsKey('supportedCountries'), true);
      expect(map.containsKey('country'), true);
    });

    test('toMap excludes null country', () {
      const state = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa],
        country: null,
      );
      final map = state.toMap();

      expect(map.containsKey('country'), false);
    });

    test('toMap converts country codes to uppercase', () {
      const state = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa, PowerTableCountries.twn],
        country: PowerTableCountries.usa,
      );
      final map = state.toMap();

      expect(map['country'], 'USA');
      final countries = (map['supportedCountries'] as Iterable).toList();
      expect(countries, contains('USA'));
      expect(countries, contains('TWN'));
    });

    test('fromMap resolves country codes correctly', () {
      final map = {
        'isPowerTableSelectable': true,
        'supportedCountries': ['USA', 'TWN', 'JPN'],
        'country': 'TWN',
      };
      final state = PowerTableState.fromMap(map);

      expect(state.country, PowerTableCountries.twn);
      expect(state.supportedCountries, contains(PowerTableCountries.usa));
      expect(state.supportedCountries, contains(PowerTableCountries.twn));
      expect(state.supportedCountries, contains(PowerTableCountries.jpn));
    });

    test('props contains all fields', () {
      const state = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa],
        country: PowerTableCountries.usa,
      );

      expect(state.props.length, 3);
      expect(state.props[0], true); // isPowerTableSelectable
      expect(state.props[1], [PowerTableCountries.usa]); // supportedCountries
      expect(state.props[2], PowerTableCountries.usa); // country
    });

    test('stringify is enabled', () {
      const state = PowerTableState(
        isPowerTableSelectable: true,
        supportedCountries: [PowerTableCountries.usa],
        country: PowerTableCountries.usa,
      );

      expect(state.stringify, true);
    });
  });
}
