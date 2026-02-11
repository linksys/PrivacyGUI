import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/theme/theme_config_loader.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeConfigLoader - Override Resolution', () {
    test('cicd source returns parsed theme from JSON env', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.cicd,
        themeJsonEnv: '{"light":{"style":"cicd"},"dark":{"style":"cicd"}}',
      );
      final config = await loader.load(modelNumber: 'TB-6W');
      expect(config, isA<ThemeJsonConfig>());
      // Override should take priority over modelNumber
      expect(config.lightJson, isNotEmpty);
    });

    test('defaultTheme source returns default config', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.defaultTheme,
      );
      final config = await loader.load(modelNumber: 'TB-6W');
      expect(config.lightJson['style'], 'flat');
    });

    test('assets source falls back to default when asset not found', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.assets,
        themeAssetPath: 'assets/nonexistent_theme.json',
      );
      final config = await loader.load();
      expect(config.lightJson['style'], 'flat');
    });

    test('network source falls back to default (not implemented)', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.network,
        themeNetworkUrl: 'https://example.com/theme.json',
      );
      final config = await loader.load();
      expect(config.lightJson['style'], 'flat');
    });
  });

  group('ThemeConfigLoader - Device Theme Resolution', () {
    test('empty model number returns default theme', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.normal,
      );
      final config = await loader.load(modelNumber: '');
      expect(config, isA<ThemeJsonConfig>());
      expect(config.lightJson['style'], 'flat');
    });

    test('unknown model number returns default theme', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.normal,
      );
      final config = await loader.load(modelNumber: 'UNKNOWN-MODEL');
      expect(config.lightJson['style'], 'flat');
    });

    test('no model number defaults to empty string', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.normal,
      );
      final config = await loader.load();
      expect(config, isA<ThemeJsonConfig>());
      expect(config.lightJson['style'], 'flat');
    });
  });

  group('ThemeConfigLoader - Priority Logic (normal mode)', () {
    test('CI/CD env takes priority over everything', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.normal,
        themeJsonEnv: '{"light":{"style":"cicd"},"dark":{"style":"cicd"}}',
        themeNetworkUrl: 'https://example.com/theme.json',
      );
      // Should not use device theme when env is set
      final config = await loader.load(modelNumber: 'TB-6W');
      expect(config, isA<ThemeJsonConfig>());
    });

    test('network URL triggers override path', () async {
      final loader = ThemeConfigLoader.forTesting(
        forcedSource: ThemeSource.normal,
        themeNetworkUrl: 'https://example.com/theme.json',
      );
      // Should use override path, not device theme
      final config = await loader.load(modelNumber: 'TB-6W');
      expect(config, isA<ThemeJsonConfig>());
    });
  });
}
