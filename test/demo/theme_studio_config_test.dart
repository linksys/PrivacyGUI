import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/demo/providers/theme_studio_config_provider.dart';
import 'package:privacy_gui/demo/theme_studio/studio_theme_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('ThemeStudioConfig', () {
    test('toJson and fromJson round trip preserves all fields', () {
      final original = ThemeStudioConfig(
        style: 'brutal',
        globalOverlay: GlobalOverlayType.hacker,
        visualEffects: AppThemeConfig.effectBlur,
        seedColor: const Color(0xFF123456),
        primary: const Color(0xFFAABBCC),
        surface: const Color(0xFF112233),
        error: const Color(0xFF990000),
        overrides: AppThemeOverrides(
          semantic: SemanticOverrides(
            success: const Color(0xFF00FF00),
            warning: const Color(0xFFFFFF00),
          ),
          component: ComponentOverrides(
            input: InputColorOverride(
              outlineBorderColor: const Color(0xFF333333),
            ),
          ),
        ),
      );

      final json = original.toJson();
      final restored = ThemeStudioConfig.fromJson(json);

      expect(restored.style, original.style);
      expect(restored.globalOverlay, original.globalOverlay);
      expect(restored.visualEffects, original.visualEffects);
      expect(restored.seedColor?.toARGB32(), original.seedColor?.toARGB32());
      expect(restored.primary?.toARGB32(), original.primary?.toARGB32());
      expect(restored.surface?.toARGB32(), original.surface?.toARGB32());
      expect(restored.error?.toARGB32(), original.error?.toARGB32());

      // Check Overrides
      expect(restored.overrides?.semantic?.success?.toARGB32(),
          const Color(0xFF00FF00).toARGB32());
      expect(restored.overrides?.semantic?.warning?.toARGB32(),
          const Color(0xFFFFFF00).toARGB32());
      expect(
          restored.overrides?.component?.input?.outlineBorderColor?.toARGB32(),
          const Color(0xFF333333).toARGB32());
    });

    test('fromJson handles missing overrides gracefully', () {
      final json = {
        'style': 'flat',
        // 'overrides' is missing
      };

      final config = ThemeStudioConfig.fromJson(json);
      expect(config.style, 'flat');
      expect(config.overrides, isNull);
    });

    test('default config inherits (null style/visualEffects)', () {
      // #857-adjacent fix: defaults must inherit from the base theme, not
      // clobber it with glass + all-effects. Null means "use base".
      const config = ThemeStudioConfig();
      expect(config.style, isNull);
      expect(config.visualEffects, isNull);
    });

    test('fromJson keeps null style/visualEffects (inherit) when absent', () {
      final config = ThemeStudioConfig.fromJson({'seedColor': '#FF112233'});
      expect(config.style, isNull);
      expect(config.visualEffects, isNull);
    });

    test('round trip preserves inherit-state (null) for style/effects', () {
      const original = ThemeStudioConfig(seedColor: Color(0xFF112233));
      final restored = ThemeStudioConfig.fromJson(original.toJson());
      expect(restored.style, isNull);
      expect(restored.visualEffects, isNull);
    });

    test('Notifier updates state correctly', () {
      final notifier = ThemeStudioConfigNotifier();

      // Test basic update
      notifier.setStyle('pixel');
      expect(notifier.state.style, 'pixel');

      // Test granular color
      notifier.setPrimary(Colors.red);
      expect(notifier.state.primary, Colors.red);

      // Test semantic override
      notifier.updateSemanticOverrides(success: Colors.green);
      expect(notifier.state.overrides?.semantic?.success, Colors.green);
    });
  });

  group('mergeStudioConfigJson', () {
    // Base theme as an E2E / production build would produce it via THEME_JSON.
    Map<String, dynamic> baseFlat() => {
          'style': 'flat',
          'visualEffects': 0,
          'brightness': 'light',
        };

    test('inherit-default config does NOT clobber base style/visualEffects',
        () {
      // The core regression guard: with the frozen inherit default, the base
      // flat + effects-0 theme must survive untouched. Reverting the builder
      // to an unconditional overwrite would fail here.
      const config = ThemeStudioConfig();
      final merged = mergeStudioConfigJson(baseFlat(), config);
      expect(merged['style'], 'flat');
      expect(merged['visualEffects'], 0);
    });

    test('explicit studio style/visualEffects DO override base', () {
      // Theme Studio must still win when the user sets a value.
      const config = ThemeStudioConfig(style: 'glass', visualEffects: 63);
      final merged = mergeStudioConfigJson(baseFlat(), config);
      expect(merged['style'], 'glass');
      expect(merged['visualEffects'], 63);
    });

    test('null globalOverlay leaves base overlay untouched', () {
      final base = baseFlat()..['globalOverlay'] = 'snow';
      const config = ThemeStudioConfig();
      final merged = mergeStudioConfigJson(base, config);
      expect(merged['globalOverlay'], 'snow');
    });

    test('null color overrides do not inject keys', () {
      const config = ThemeStudioConfig();
      final merged = mergeStudioConfigJson(baseFlat(), config);
      expect(merged.containsKey('primary'), isFalse);
      expect(merged.containsKey('seedColor'), isFalse);
      expect(merged.containsKey('overrides'), isFalse);
    });

    test('userThemeColor is used as seed when config has none', () {
      const config = ThemeStudioConfig();
      final merged = mergeStudioConfigJson(baseFlat(), config,
          userThemeColor: const Color(0xFF00FF00));
      expect(merged['seedColor'], '#00ff00');
    });

    test('config.seedColor takes priority over userThemeColor', () {
      const config = ThemeStudioConfig(seedColor: Color(0xFFFF0000));
      final merged = mergeStudioConfigJson(baseFlat(), config,
          userThemeColor: const Color(0xFF00FF00));
      expect(merged['seedColor'], '#ff0000');
    });
  });
}
