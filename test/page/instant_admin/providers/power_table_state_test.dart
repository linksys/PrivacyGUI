import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_state.dart';

const _state = <String, dynamic>{
  'isPowerTableSelectable': true,
  'supportedCountries': ['CHN', 'TWN', 'EEE'],
  'country': 'TWN',
};

void main() {
  group('PowerTableState', () {
    test('reads the regions by their router names', () {
      final state = PowerTableState.fromMap(_state);

      expect(state.isPowerTableSelectable, isTrue);
      expect(state.supportedCountries, [
        PowerTableCountries.chn,
        PowerTableCountries.twn,
        PowerTableCountries.eee,
      ]);
      expect(state.country, PowerTableCountries.twn);
    });

    test('writes the regions back by their router names', () {
      expect(PowerTableState.fromMap(_state).toMap(), _state);
    });

    test('survives a JSON round trip', () {
      final state = PowerTableState.fromMap(_state);

      expect(PowerTableState.fromJson(state.toJson()), state);
    });

    test('leaves the region out when there is none', () {
      final state = PowerTableState.fromMap(
          const {'isPowerTableSelectable': false, 'supportedCountries': []});

      expect(state.country, isNull);
      expect(state.toMap(), isNot(contains('country')));
    });

    test('copyWith changes the region and keeps the choices', () {
      final state = PowerTableState.fromMap(_state)
          .copyWith(country: PowerTableCountries.eee);

      expect(state.country, PowerTableCountries.eee);
      expect(state.supportedCountries,
          PowerTableState.fromMap(_state).supportedCountries);
      expect(state, isNot(PowerTableState.fromMap(_state)));
      expect(state.copyWith(country: PowerTableCountries.twn),
          PowerTableState.fromMap(_state));
    });
  });
}
