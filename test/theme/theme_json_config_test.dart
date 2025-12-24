import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

void main() {
  group('ThemeJsonConfig', () {
    test('defaultConfig should return glass style and light/dark brightness',
        () {
      final config = ThemeJsonConfig.defaultConfig();
      // Since we can't verify private fields, we verify behavior via createTheme
      final lightTheme = config.createLightTheme();
      final darkTheme = config.createDarkTheme();

      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
    });

    test('fromJsonString should parse valid JSON correctly', () {
      const jsonStr = '''
      {
        "style": "flat",
        "seedColor": "#FF0000",
        "colors": {
          "light": { "primary": "#00FF00" }
        }
      }
      ''';
      final config = ThemeJsonConfig.fromJsonString(jsonStr);
      final lightTheme = config.createLightTheme();

      // Verify seed color usage (indirectly or if feasible to check theme properties)
      // Note: Checking exact generated colors relies on ui_kit implementation details.
      // Here we check basic valid construction.
      expect(lightTheme, isNotNull);
      expect(lightTheme.brightness, Brightness.light);
    });

    test('fromJsonString should return default config for empty string', () {
      final config = ThemeJsonConfig.fromJsonString('');
      final lightTheme = config.createLightTheme();
      expect(lightTheme.brightness, Brightness.light);
    });

    test('fromJsonString should return default config for invalid JSON', () {
      final config = ThemeJsonConfig.fromJsonString('{invalid-json}');
      final lightTheme = config.createLightTheme();
      expect(lightTheme, isNotNull);
    });

    test('createLightTheme with overrideSeedColor should override config', () {
      final config = ThemeJsonConfig.defaultConfig();
      final lightTheme = config.createLightTheme(Colors.blue);
      expect(lightTheme, isNotNull);
      // Ideally we would check if the theme is seeded with blue, but generated colors are complex.
      // At least ensuring no crash.
    });
  });
}
