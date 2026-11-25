import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/power_table_settings.dart';

/// `GetPowerTableSettings` output, as the router answers it.
const _routerAnswer = <String, dynamic>{
  'isPowerTableSelectable': true,
  'supportedCountries': ['CHN', 'TWN', 'EEE', 'USA'],
  'country': 'TWN',
};

void main() {
  group('PowerTableSettings', () {
    test('reads whether the region can be chosen, the choices and the region',
        () {
      final settings = PowerTableSettings.fromMap(_routerAnswer);

      expect(settings.isPowerTableSelectable, isTrue);
      expect(settings.supportedCountries, ['CHN', 'TWN', 'EEE', 'USA']);
      expect(settings.country, 'TWN');
    });

    test('reads no region when the router names none', () {
      final settings = PowerTableSettings.fromMap(const {
        'isPowerTableSelectable': false,
        'supportedCountries': <String>[],
      });

      expect(settings.isPowerTableSelectable, isFalse);
      expect(settings.supportedCountries, isEmpty);
      expect(settings.country, isNull);
    });

    test('writes back the shape it read', () {
      expect(PowerTableSettings.fromMap(_routerAnswer).toMap(), _routerAnswer);
    });

    test('survives a JSON round trip', () {
      final settings = PowerTableSettings.fromMap(_routerAnswer);

      expect(PowerTableSettings.fromJson(settings.toJson()), settings);
    });

    test('copyWith changes the region and keeps the rest', () {
      final settings =
          PowerTableSettings.fromMap(_routerAnswer).copyWith(country: 'EEE');

      expect(settings.country, 'EEE');
      expect(settings.isPowerTableSelectable, isTrue);
      expect(settings.supportedCountries, ['CHN', 'TWN', 'EEE', 'USA']);
      expect(settings, isNot(PowerTableSettings.fromMap(_routerAnswer)));
    });
  });
}
