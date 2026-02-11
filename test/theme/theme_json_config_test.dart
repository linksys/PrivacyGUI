import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

void main() {
  group('ThemeJsonConfig', () {
    test('parses visualEffects correctly', () {
      final json = {
        'style': 'glass',
        'visualEffects': 123,
      };

      final config = ThemeJsonConfig.fromJson(json);

      expect(config.lightJson['visualEffects'], 123);
      expect(config.darkJson['visualEffects'], 123);
    });

    test('parses globalOverlay correctly when present', () {
      final json = {
        'style': 'glass',
        'globalOverlay': 'none',
      };

      final config = ThemeJsonConfig.fromJson(json);

      expect(config.lightJson['globalOverlay'], 'none');
      expect(config.darkJson['globalOverlay'], 'none');
    });

    test('omits globalOverlay when absent', () {
      final json = {
        'style': 'glass',
      };

      final config = ThemeJsonConfig.fromJson(json);

      expect(config.lightJson.containsKey('globalOverlay'), isFalse);
      expect(config.darkJson.containsKey('globalOverlay'), isFalse);
    });

    test('parses all fields correctly in full json', () {
      final json = {
        'style': 'glass',
        'visualEffects': 42,
        'globalOverlay': 'liquid',
        'seedColor': '#FF0000',
        'colors': {
          'light': {'primary': '#00FF00'},
          'dark': {'primary': '#0000FF'}
        }
      };

      final config = ThemeJsonConfig.fromJson(json);

      // Verify light theme json
      expect(config.lightJson['style'], 'glass');
      expect(config.lightJson['visualEffects'], 42);
      expect(config.lightJson['globalOverlay'], 'liquid');
      expect(config.lightJson['seedColor'], '#FF0000');
      expect(config.lightJson['primary'], '#00FF00');

      // Verify dark theme json
      expect(config.darkJson['style'], 'glass');
      expect(config.darkJson['visualEffects'], 42);
      expect(config.darkJson['globalOverlay'], 'liquid');
      // seedColor should be propagated if present in root
      expect(config.darkJson['seedColor'], '#FF0000');
      expect(config.darkJson['primary'], '#0000FF');
    });
  });
}
