import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('DemoThemeConfig', () {
    test('toJson and fromJson round trip preserves all fields', () {
      final original = DemoThemeConfig(
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
      final restored = DemoThemeConfig.fromJson(json);

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

      final config = DemoThemeConfig.fromJson(json);
      expect(config.style, 'flat');
      expect(config.overrides, isNull);
    });

    test('Notifier updates state correctly', () {
      final notifier = DemoThemeConfigNotifier();

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
}
