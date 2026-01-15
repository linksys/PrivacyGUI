import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/grid_widget_config.dart';

void main() {
  group('DashboardLayoutPreferences', () {
    const testWidgetId = 'test_widget';

    test('Initial state is empty and uses standard layout', () {
      const prefs = DashboardLayoutPreferences();
      expect(prefs.useCustomLayout, isFalse);
      expect(prefs.widgetConfigs, isEmpty);
    });

    test('toggleCustomLayout updates state', () {
      const prefs = DashboardLayoutPreferences();
      final updated = prefs.toggleCustomLayout(true);
      expect(updated.useCustomLayout, isTrue);
      // Configs should remain unchanged
      expect(updated.widgetConfigs, isEmpty);
    });

    group('Widget Configuration', () {
      test('getConfig creates default if not exists', () {
        const prefs = DashboardLayoutPreferences();
        // Assume test_widget corresponds to some ID or just verify default creation logic
        // Since test_widget is not in DashboardWidgetSpecs.all, default order is 0.
        final config = prefs.getConfig(testWidgetId);
        expect(config.widgetId, testWidgetId);
        expect(config.order, 0);
        expect(config.visible, isTrue);
        expect(config.displayMode, DisplayMode.normal);
      });

      test('updateConfig stores configuration', () {
        const prefs = DashboardLayoutPreferences();
        final config = GridWidgetConfig(
          widgetId: testWidgetId,
          order: 5,
          displayMode: DisplayMode.expanded,
          visible: false,
        );

        final updated = prefs.updateConfig(config);
        expect(updated.widgetConfigs.length, 1);
        expect(updated.widgetConfigs[testWidgetId], config);
      });

      test('setMode updates display mode', () {
        const prefs = DashboardLayoutPreferences();
        final updated = prefs.setMode(testWidgetId, DisplayMode.compact);
        expect(updated.getMode(testWidgetId), DisplayMode.compact);
      });

      test('setVisibility updates visibility', () {
        const prefs = DashboardLayoutPreferences();
        final updated = prefs.setVisibility(testWidgetId, false);
        expect(updated.isVisible(testWidgetId), isFalse);
      });

      test('setColumnSpan updates and clears span', () {
        const prefs = DashboardLayoutPreferences();
        // Set span
        final s1 = prefs.setColumnSpan(testWidgetId, 4);
        expect(s1.getConfig(testWidgetId).columnSpan, 4);

        // Clear span
        final s2 = s1.setColumnSpan(testWidgetId, null);
        expect(s2.getConfig(testWidgetId).columnSpan, isNull);
      });
    });

    group('Serialization', () {
      test('Json round trip works correctly', () {
        const original =
            DashboardLayoutPreferences(useCustomLayout: true, widgetConfigs: {
          'w1': GridWidgetConfig(
              widgetId: 'w1', order: 1, displayMode: DisplayMode.compact),
          'w2': GridWidgetConfig(
              widgetId: 'w2',
              order: 2,
              displayMode: DisplayMode.expanded,
              visible: false),
        });

        final json = original.toJson();
        final decoded = DashboardLayoutPreferences.fromJson(json);

        expect(decoded, original);
      });

      test('Deserializes legacy format correctly', () {
        // Legacy format: { widgetModes: { w1: "compact", w2: "expanded" } }
        final legacyJson = {
          "widgetModes": {"w1": "compact", "w2": "expanded"}
        };

        final prefs = DashboardLayoutPreferences.fromJson(legacyJson);

        expect(prefs.widgetConfigs.containsKey('w1'), isTrue);
        expect(prefs.widgetConfigs['w1']!.displayMode, DisplayMode.compact);
        // Order should be assigned sequentially starting from 0
        expect(prefs.widgetConfigs['w1']!.order, 0);

        expect(prefs.widgetConfigs.containsKey('w2'), isTrue);
        expect(prefs.widgetConfigs['w2']!.displayMode, DisplayMode.expanded);
        expect(prefs.widgetConfigs['w2']!.order, 1);
      });

      test('Deserializes partial legacy data safely', () {
        // Invalid entries should be ignored
        final legacyJson = {
          "widgetModes": {"w1": "compact", "w2": "INVALID_MODE"}
        };
        final prefs = DashboardLayoutPreferences.fromJson(legacyJson);
        expect(prefs.widgetConfigs.containsKey('w1'), isTrue);
        expect(prefs.widgetConfigs.containsKey('w2'), isFalse);
      });

      test('Handles invalid new format gracefully', () {
        final json = {
          "useCustomLayout": true,
          "widgetConfigs": {
            "w1": {
              "widgetId": "w1",
              "invalid": "data"
            } // Missing required fields might throw
          }
        };
        // GridWidgetConfig.fromJson might throw if required fields are missing, let's see how DashboardLayoutPreferences handles it.
        // Source: try { ... } catch (_) { // Ignore invalid entries }

        // But "widgetId" is required. If missing, it definitely fails.
        // Let's test providing valid minimal JSON
        final validJson = {
          "useCustomLayout": true,
          "widgetConfigs": {
            "w1": {
              "widgetId": "w1",
              "order": 1,
              "visible": true,
              "displayMode": "normal"
            }
          }
        };
        final prefs = DashboardLayoutPreferences.fromJson(validJson);
        expect(prefs.widgetConfigs.length, 1);

        // Now invalid
        final invalidJson = {
          "useCustomLayout": true,
          "widgetConfigs": {
            "w1": {
              "widgetId": "w1"
            } // Missing order? fromJson uses "as int? ?? 0", so it's safe.
            // Missing displayMode? "as String? ?? 'normal'". Safe.
            // All fields seem to have defaults or are nullable except widgetId.
          }
        };
        // Try passing something that causes cast error
        final castErrorJson = {
          "useCustomLayout": true,
          "widgetConfigs": {
            "w1": {"widgetId": "w1", "order": "string_instead_of_int"}
          }
        };
        final prefs2 = DashboardLayoutPreferences.fromJson(castErrorJson);
        expect(prefs2.widgetConfigs, isEmpty,
            reason: "Should ignore entries causing casting errors");
      });
    });
  });
}
