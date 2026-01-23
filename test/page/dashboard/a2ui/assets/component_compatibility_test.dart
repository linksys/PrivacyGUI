import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('A2UI Component Compatibility Tests', () {
    late IComponentRegistry registry;

    setUp(() {
      registry = ComponentRegistry();
      UiKitCatalog.standardBuilders.forEach((name, builder) {
        registry.register(name, builder);
      });
    });

    test('checks availability of components used in A2UI widgets', () {
      // Core components that should be available
      final requiredComponents = [
        'AppCard',
        'AppText',
        'AppIcon',
        'AppButton',
        'Column',
        'Row',
        'SizedBox',
        'Stack',
      ];

      // Advanced components that should be available
      final advancedComponents = [
        'AppSwitch',
        'Expanded',
      ];

      print('=== Core Components Check ===');
      for (final component in requiredComponents) {
        final builder = registry.lookup(component);
        if (builder != null) {
          print('✅ $component: Available');
        } else {
          print('❌ $component: NOT AVAILABLE - This will cause rendering errors!');
        }
      }

      print('\n=== Advanced Components Check ===');
      for (final component in advancedComponents) {
        final builder = registry.lookup(component);
        if (builder != null) {
          print('✅ $component: Available');
        } else {
          print('⚠️  $component: Not available - Need to find alternative or remove usage');
        }
      }

      // Get all available components
      final allComponents = <String>[];
      // Note: We can't directly enumerate registry contents, but we can test known components
      final testComponents = [
        'AppCard', 'AppText', 'AppIcon', 'AppButton', 'AppGap',
        'Column', 'Row', 'SizedBox', 'Container', 'Stack', 'Expanded',
        'Positioned', 'AppSwitch', 'AppToggle', 'AppSlider',
        'Padding', 'Center', 'Align', 'Flex', 'Wrap'
      ];

      print('\n=== Available UI Kit Components ===');
      for (final component in testComponents) {
        final builder = registry.lookup(component);
        if (builder != null) {
          allComponents.add(component);
          print('   $component');
        }
      }

      print('\n=== Summary ===');
      print('Total available components tested: ${allComponents.length}');

      // Check core components are available
      for (final required in requiredComponents) {
        expect(registry.lookup(required), isNotNull,
            reason: 'Required component "$required" must be available in UI Kit');
      }
    });

    testWidgets('tests rendering of basic A2UI widget structure', (tester) async {
      // Test a simplified version of our widget structure
      const testWidget = {
        "type": "AppCard",
        "properties": {
          "padding": 16.0,
        },
        "children": [
          {
            "type": "Column",
            "properties": {
              "mainAxisAlignment": "center",
              "crossAxisAlignment": "center"
            },
            "children": [
              {
                "type": "AppIcon",
                "properties": {
                  "icon": "devices",
                  "size": 32.0
                }
              },
              {
                "type": "SizedBox",
                "properties": {
                  "height": 8.0
                }
              },
              {
                "type": "AppText",
                "properties": {
                  "text": "Test Widget",
                  "variant": "headlineMedium"
                }
              }
            ]
          }
        ]
      };

      // This would test if basic structure can be rendered
      // We don't have the full template builder here, but this validates
      // that the component types we're using exist in the registry

      final cardBuilder = registry.lookup('AppCard');
      final columnBuilder = registry.lookup('Column');
      final iconBuilder = registry.lookup('AppIcon');
      final textBuilder = registry.lookup('AppText');
      final sizedBoxBuilder = registry.lookup('SizedBox');

      expect(cardBuilder, isNotNull, reason: 'AppCard must be available');
      expect(columnBuilder, isNotNull, reason: 'Column must be available');
      expect(iconBuilder, isNotNull, reason: 'AppIcon must be available');
      expect(textBuilder, isNotNull, reason: 'AppText must be available');
      expect(sizedBoxBuilder, isNotNull, reason: 'SizedBox must be available');

      print('✅ Basic widget structure components are all available');
    });
  });
}