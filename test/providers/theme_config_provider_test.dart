import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('themeConfigProvider - Normal Mode', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('Returns default theme for empty modelNumber', () async {
      // Arrange
      container = ProviderContainer();

      // Act
      final themeConfig = await container.read(themeConfigProvider.future);

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
      final theme1 = await container.read(themeConfigProvider.future);
      final theme2 = await container.read(themeConfigProvider.future);

      // Assert - Should return same cached instance
      expect(theme1, same(theme2));
    });

    test('Provider does not throw on initial state', () async {
      // Arrange
      container = ProviderContainer();

      // Act & Assert - Should not throw
      expect(
        () async => await container.read(themeConfigProvider.future),
        returnsNormally,
      );
    });
  });

  group('themeConfigProvider - Theme Data Validation', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('Theme config has required light theme properties', () async {
      // Arrange
      container = ProviderContainer();

      // Act
      final themeConfig = await container.read(themeConfigProvider.future);

      // Assert
      expect(themeConfig.lightJson, isA<Map<String, dynamic>>());
      expect(themeConfig.lightJson.containsKey('style'), true);
      expect(themeConfig.lightJson['style'], isNotNull);
    });

    test('Theme config has required dark theme properties', () async {
      // Arrange
      container = ProviderContainer();

      // Act
      final themeConfig = await container.read(themeConfigProvider.future);

      // Assert
      expect(themeConfig.darkJson, isA<Map<String, dynamic>>());
      expect(themeConfig.darkJson.containsKey('style'), true);
      expect(themeConfig.darkJson['style'], isNotNull);
    });

    test('Theme can create ThemeData objects', () async {
      // Arrange
      container = ProviderContainer();

      // Act
      final themeConfig = await container.read(themeConfigProvider.future);

      // Assert - Verify theme config can create ThemeData
      expect(() => themeConfig.createLightTheme(), returnsNormally);
      expect(() => themeConfig.createDarkTheme(), returnsNormally);
    });
  });
}
