import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/app_settings/temperature_unit.dart';
import 'package:privacy_gui/providers/app_settings/temperature_unit_provider.dart';

void main() {
  group('temperatureUnitForRegion', () {
    // CLDR unitPreferenceData, temperature, usage "default": fahrenheit for
    // US only, celsius everywhere else (the "weather" usage adds five more).
    test('the United States reads Fahrenheit', () {
      expect(temperatureUnitForRegion('US'), TemperatureUnit.fahrenheit);
    });

    test('other regions read Celsius', () {
      expect(temperatureUnitForRegion('TW'), TemperatureUnit.celsius);
      expect(temperatureUnitForRegion('GB'), TemperatureUnit.celsius);
    });

    test('a locale with no region reads Celsius', () {
      expect(temperatureUnitForRegion(null), TemperatureUnit.celsius);
    });
  });

  group('fahrenheitOf', () {
    test('converts whole degrees, rounded', () {
      expect(fahrenheitOf(0), 32);
      expect(fahrenheitOf(50), 122);
      expect(fahrenheitOf(-40), -40);
      // 98.6 °F.
      expect(fahrenheitOf(37), 99);
    });
  });

  group('AppSettings.temperatureUnit', () {
    test('survives the round trip through storage', () {
      const settings = AppSettings(temperatureUnit: TemperatureUnit.fahrenheit);

      expect(AppSettings.fromJson(settings.toJson()).temperatureUnit,
          TemperatureUnit.fahrenheit);
    });

    test('is unset in settings saved before it existed', () {
      final saved = AppSettings.fromJson(
          '{"themeMode":"dark","locale":null,"themeColor":null,"showMascot":true}');

      expect(saved.temperatureUnit, isNull);
      expect(saved.themeMode, ThemeMode.dark);
    });
  });

  group('temperatureUnitProvider', () {
    ProviderContainer containerWith({
      required String? region,
      TemperatureUnit? picked,
    }) {
      final container = ProviderContainer(overrides: [
        platformRegionProvider.overrideWithValue(region),
        appSettingsProvider.overrideWith(
            () => _FixedAppSettings(AppSettings(temperatureUnit: picked))),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('follows the region when nothing has been picked', () {
      expect(containerWith(region: 'US').read(temperatureUnitProvider),
          TemperatureUnit.fahrenheit);
      expect(containerWith(region: 'TW').read(temperatureUnitProvider),
          TemperatureUnit.celsius);
    });

    test('a picked unit wins over the region', () {
      expect(
          containerWith(region: 'US', picked: TemperatureUnit.celsius)
              .read(temperatureUnitProvider),
          TemperatureUnit.celsius);
    });
  });
}

class _FixedAppSettings extends AppSettingsNotifier {
  final AppSettings _settings;
  _FixedAppSettings(this._settings);

  @override
  AppSettings build() => _settings;
}
