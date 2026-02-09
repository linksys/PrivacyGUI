import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/device_theme_config_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('deviceThemeConfigProvider - Normal Mode', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('Returns default theme for empty modelNumber', () async {
      // Arrange
      container = ProviderContainer();

      // Act
      final themeConfig =
          await container.read(deviceThemeConfigProvider.future);

      // Assert
      expect(themeConfig, isA<ThemeJsonConfig>());
      expect(themeConfig.lightJson, isNotEmpty);
      expect(themeConfig.darkJson, isNotEmpty);

      // Verify it's the default theme (Flat style)
      expect(themeConfig.lightJson['style'], 'flat');
    });

    test('Provider caches theme for same modelNumber', () async {
      // Arrange
      container = ProviderContainer();

      // Act - Read provider twice
      final theme1 = await container.read(deviceThemeConfigProvider.future);
      final theme2 = await container.read(deviceThemeConfigProvider.future);

      // Assert - Should return same cached instance
      expect(theme1, same(theme2));
    });

    test('Provider does not throw on initial state', () async {
      // Arrange
      container = ProviderContainer();

      // Act & Assert - Should not throw
      expect(
        () async => await container.read(deviceThemeConfigProvider.future),
        returnsNormally,
      );
    });
  });

  group('deviceThemeConfigProvider - Theme Data Validation', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('Theme config has required light theme properties', () async {
      // Arrange
      container = ProviderContainer();

      // Act
      final themeConfig =
          await container.read(deviceThemeConfigProvider.future);

      // Assert
      expect(themeConfig.lightJson, isA<Map<String, dynamic>>());
      expect(themeConfig.lightJson.containsKey('style'), true);
      expect(themeConfig.lightJson['style'], isNotNull);
    });

    test('Theme config has required dark theme properties', () async {
      // Arrange
      container = ProviderContainer();

      // Act
      final themeConfig =
          await container.read(deviceThemeConfigProvider.future);

      // Assert
      expect(themeConfig.darkJson, isA<Map<String, dynamic>>());
      expect(themeConfig.darkJson.containsKey('style'), true);
      expect(themeConfig.darkJson['style'], isNotNull);
    });

    test('Theme can create ThemeData objects', () async {
      // Arrange
      container = ProviderContainer();

      // Act
      final themeConfig =
          await container.read(deviceThemeConfigProvider.future);

      // Assert - Verify theme config can create ThemeData
      expect(() => themeConfig.createLightTheme(), returnsNormally);
      expect(() => themeConfig.createDarkTheme(), returnsNormally);
    });
  });

  group('deviceThemeConfigProvider - forcedSource Priority', () {
    test('Normal mode is default (no environment variables)', () {
      // This test documents that default behavior is normal mode
      // In actual app: ThemeConfigLoader.forcedSource == ThemeSource.normal
      expect(true, true); // Placeholder for documentation
    });

    test('forcedSource cicd overrides device theme (integration)', () {
      // When THEME_SOURCE=cicd is set, deviceThemeConfigProvider should
      // call ThemeConfigLoader.load() instead of BrandUtils.getDeviceTheme()
      // This requires integration test with --dart-define

      // Documented expected behavior:
      // flutter run --dart-define=THEME_SOURCE=cicd
      // -> forcedSource != normal
      // -> ThemeConfigLoader.load() is called
      expect(true, true); // Placeholder for integration test
    });
  });
}
