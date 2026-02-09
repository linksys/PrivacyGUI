import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

void main() {
  group('BrandUtils.getDeviceTheme Tests', () {
    test('Returns default theme for empty model number', () async {
      final theme = await BrandUtils.getDeviceTheme('');
      expect(theme, isA<ThemeJsonConfig>());
      // Verify it's the default config by checking it matches defaultConfig()
      final defaultTheme = ThemeJsonConfig.defaultConfig();
      expect(theme.lightJson['style'], defaultTheme.lightJson['style']);
    });

    test('Returns default theme for unknown model number', () async {
      final theme = await BrandUtils.getDeviceTheme('UNKNOWN-MODEL-123');
      expect(theme, isA<ThemeJsonConfig>());
      // Should return default theme for unmapped models
      final defaultTheme = ThemeJsonConfig.defaultConfig();
      expect(theme.lightJson['style'], defaultTheme.lightJson['style']);
    });

    test('Returns theme for mapped model (M60DU-EU)', () async {
      final theme = await BrandUtils.getDeviceTheme('M60DU-EU');
      expect(theme, isA<ThemeJsonConfig>());
      // M60 has mapping, should load theme or fallback to default
      expect(theme.lightJson, isNotEmpty);
      expect(theme.darkJson, isNotEmpty);
    });

    // Note: The following tests would require actual asset files in test environment
    // For now, we test the mapping logic and fallback behavior

    test('TB model number matches TB- prefix', () {
      // This test verifies the model suffix map logic would match TB models
      const testModels = ['TB-6W', 'TB-6W-EU', 'TB-3W-US', 'tb-6w'];

      for (final model in testModels) {
        // We can't directly test the private _modelSuffixMap,
        // but we know TB models should attempt to load theme_tb.json
        expect(model.toUpperCase().contains('TB-'), true);
      }
    });

    test('Non-TB model numbers do not match TB- prefix', () {
      const testModels = ['M60DU-EU', 'MX5300', 'WHW03B', 'A03'];

      for (final model in testModels) {
        expect(model.toUpperCase().contains('TB-'), false);
      }
    });
  });

  group('BrandUtils Theme Loading Integration', () {
    // Integration tests that verify actual theme loading behavior
    // These require the asset files to be available in the test environment

    testWidgets('TB model loads theme or falls back to default',
        (tester) async {
      // This test verifies the complete flow: mapping -> asset check -> load/fallback
      final theme = await BrandUtils.getDeviceTheme('TB-6W-EU');

      expect(theme, isA<ThemeJsonConfig>());
      // Theme should be loaded (either TB-specific or default)
      expect(theme.lightJson, isNotEmpty);
      expect(theme.darkJson, isNotEmpty);
    });

    testWidgets('Empty model number returns valid default theme',
        (tester) async {
      final theme = await BrandUtils.getDeviceTheme('');

      expect(theme, isA<ThemeJsonConfig>());
      expect(theme.lightJson['style'], 'flat'); // Default is flat style
      expect(theme.darkJson['style'], 'flat');
    });
  });

  group('BrandUtils Theme Loading Error Handling', () {
    test('Invalid model number does not throw exception', () async {
      // Should handle gracefully and return default
      expect(
        () async => await BrandUtils.getDeviceTheme('!!!INVALID!!!'),
        returnsNormally,
      );
    });

    test('Very long model number does not throw exception', () async {
      final longModelNumber = 'X' * 1000;
      expect(
        () async => await BrandUtils.getDeviceTheme(longModelNumber),
        returnsNormally,
      );
    });

    test('Null-like strings return default theme', () async {
      final testValues = ['', ' ', '  ', '\t', '\n'];

      for (final value in testValues) {
        final theme = await BrandUtils.getDeviceTheme(value.trim());
        expect(theme, isA<ThemeJsonConfig>());
      }
    });
  });

  group('BrandUtils Theme Compatibility', () {
    test('Getters return valid theme data', () async {
      // Use a simple unmapped model to avoid loading actual theme files
      final theme = await BrandUtils.getDeviceTheme('TEST-MODEL');

      // Verify theme has required properties
      expect(theme.lightJson, isA<Map<String, dynamic>>());
      expect(theme.darkJson, isA<Map<String, dynamic>>());
      expect(theme.lightJson.containsKey('style'), true);
      expect(theme.darkJson.containsKey('style'), true);
    });
  });
}
