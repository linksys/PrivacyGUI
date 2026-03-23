import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/grid_widget_config.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

void main() {
  const config1 = GridWidgetConfig(
    widgetId: 'device_info',
    order: 1,
    visible: true,
    displayMode: DisplayMode.normal,
    columnSpan: 6,
  );

  const config2 = GridWidgetConfig(
    widgetId: 'topology',
    order: 2,
    visible: false,
    displayMode: DisplayMode.compact,
  );

  final prefsWithConfigs = UspLayoutPreferences(
    useCustomLayout: true,
    widgetConfigs: {'device_info': config1, 'topology': config2},
    selectedPreset: UspDashboardPreset.standard,
    hasSeenPresetDialog: true,
  );

  group('Getters', () {
    test('getConfig returns stored config', () {
      final result = prefsWithConfigs.getConfig('device_info');
      expect(result, equals(config1));
    });

    test('getConfig returns default for unknown widget', () {
      final result = prefsWithConfigs.getConfig('unknown_widget');
      expect(result.widgetId, 'unknown_widget');
      expect(result.visible, isTrue);
      expect(result.displayMode, DisplayMode.normal);
    });

    test('getMode extracts displayMode', () {
      expect(prefsWithConfigs.getMode('device_info'), DisplayMode.normal);
      expect(prefsWithConfigs.getMode('topology'), DisplayMode.compact);
    });

    test('isVisible extracts visible', () {
      expect(prefsWithConfigs.isVisible('device_info'), isTrue);
      expect(prefsWithConfigs.isVisible('topology'), isFalse);
    });

    test('orderedVisibleWidgets filters hidden and sorts', () {
      final visible = prefsWithConfigs.orderedVisibleWidgets;
      // Only device_info is visible (topology is hidden)
      // Plus all widgets not in widgetConfigs get default (visible=true)
      expect(visible.every((c) => c.visible), isTrue);
      // Should be sorted by order
      for (int i = 1; i < visible.length; i++) {
        expect(visible[i].order, greaterThanOrEqualTo(visible[i - 1].order));
      }
    });

    test('orderedVisibleWidgets empty when all hidden', () {
      final configs = <String, GridWidgetConfig>{};
      for (final spec in UspWidgetSpecs.all) {
        configs[spec.id] = GridWidgetConfig(
          widgetId: spec.id,
          order: 0,
          visible: false,
        );
      }
      final prefs = UspLayoutPreferences(widgetConfigs: configs);
      expect(prefs.orderedVisibleWidgets, isEmpty);
    });

    test('allWidgetsOrdered includes hidden widgets sorted', () {
      final all = prefsWithConfigs.allWidgetsOrdered;
      expect(all.length, UspWidgetSpecs.all.length);
      for (int i = 1; i < all.length; i++) {
        expect(all[i].order, greaterThanOrEqualTo(all[i - 1].order));
      }
    });
  });

  group('Setters (immutable)', () {
    test('updateConfig replaces config for widgetId', () {
      const newConfig = GridWidgetConfig(
        widgetId: 'device_info',
        order: 10,
        visible: false,
      );
      final result = prefsWithConfigs.updateConfig(newConfig);
      expect(result.getConfig('device_info'), equals(newConfig));
    });

    test('updateConfig preserves other configs', () {
      const newConfig = GridWidgetConfig(widgetId: 'device_info', order: 10);
      final result = prefsWithConfigs.updateConfig(newConfig);
      expect(result.getConfig('topology'), equals(config2));
    });

    test('toggleCustomLayout updates flag', () {
      final result = prefsWithConfigs.toggleCustomLayout(false);
      expect(result.useCustomLayout, isFalse);
    });

    test('toggleCustomLayout preserves configs', () {
      final result = prefsWithConfigs.toggleCustomLayout(false);
      expect(result.widgetConfigs, equals(prefsWithConfigs.widgetConfigs));
    });

    test('setMode updates displayMode', () {
      final result = prefsWithConfigs.setMode('device_info', DisplayMode.expanded);
      expect(result.getMode('device_info'), DisplayMode.expanded);
    });

    test('setVisibility updates visible', () {
      final result = prefsWithConfigs.setVisibility('device_info', false);
      expect(result.isVisible('device_info'), isFalse);
    });

    test('withPreset updates selectedPreset and hasSeenPresetDialog', () {
      const prefs = UspLayoutPreferences();
      final result = prefs.withPreset(UspDashboardPreset.essential);
      expect(result.selectedPreset, UspDashboardPreset.essential);
      expect(result.hasSeenPresetDialog, isTrue);
    });

    test('withPresetDialogSeen only updates flag', () {
      const prefs = UspLayoutPreferences(
        selectedPreset: UspDashboardPreset.monitoring,
      );
      final result = prefs.withPresetDialogSeen();
      expect(result.hasSeenPresetDialog, isTrue);
      expect(result.selectedPreset, UspDashboardPreset.monitoring);
    });
  });

  group('Default config generation', () {
    test('_defaultConfig uses spec index for order', () {
      const prefs = UspLayoutPreferences();
      final config = prefs.getConfig('device_info');
      final expectedIndex = UspWidgetSpecs.all
          .indexWhere((s) => s.id == 'device_info');
      expect(config.order, expectedIndex);
    });

    test('_defaultConfig returns order=0 for unknown ID', () {
      const prefs = UspLayoutPreferences();
      final config = prefs.getConfig('nonexistent_widget');
      expect(config.order, 0);
    });
  });

  group('JSON serialization', () {
    test('toJson includes useCustomLayout', () {
      final json = prefsWithConfigs.toJson();
      expect(json['useCustomLayout'], isTrue);
    });

    test('toJson includes widgetConfigs map', () {
      final json = prefsWithConfigs.toJson();
      expect(json['widgetConfigs'], isA<Map>());
      expect((json['widgetConfigs'] as Map).containsKey('device_info'), isTrue);
    });

    test('toJson includes selectedPreset when not null', () {
      final json = prefsWithConfigs.toJson();
      expect(json['selectedPreset'], 'standard');
    });

    test('toJson excludes selectedPreset when null', () {
      const prefs = UspLayoutPreferences();
      final json = prefs.toJson();
      expect(json.containsKey('selectedPreset'), isFalse);
    });

    test('toJson includes hasSeenPresetDialog', () {
      final json = prefsWithConfigs.toJson();
      expect(json['hasSeenPresetDialog'], isTrue);
    });

    test('fromJson complete object', () {
      final json = prefsWithConfigs.toJson();
      final result = UspLayoutPreferences.fromJson(json);
      expect(result.useCustomLayout, isTrue);
      expect(result.selectedPreset, UspDashboardPreset.standard);
      expect(result.hasSeenPresetDialog, isTrue);
      expect(result.widgetConfigs.containsKey('device_info'), isTrue);
    });

    test('fromJson defaults useCustomLayout=true when missing', () {
      final result = UspLayoutPreferences.fromJson({});
      expect(result.useCustomLayout, isTrue);
    });

    test('fromJson defaults hasSeenPresetDialog=false when missing', () {
      final result = UspLayoutPreferences.fromJson({});
      expect(result.hasSeenPresetDialog, isFalse);
    });

    test('fromJson handles null selectedPreset', () {
      final result = UspLayoutPreferences.fromJson({
        'selectedPreset': null,
      });
      expect(result.selectedPreset, isNull);
    });

    test('fromJson parses valid preset name', () {
      final result = UspLayoutPreferences.fromJson({
        'selectedPreset': 'essential',
      });
      expect(result.selectedPreset, UspDashboardPreset.essential);
    });

    test('fromJson ignores unknown preset name', () {
      final result = UspLayoutPreferences.fromJson({
        'selectedPreset': 'nonexistent_preset',
      });
      expect(result.selectedPreset, isNull);
    });

    test('fromJson builds configs from JSON', () {
      final json = {
        'widgetConfigs': {
          'device_info': config1.toJson(),
        },
      };
      final result = UspLayoutPreferences.fromJson(json);
      expect(result.widgetConfigs.containsKey('device_info'), isTrue);
      expect(result.widgetConfigs['device_info']!.order, 1);
    });

    test('fromJson ignores invalid config entries', () {
      final json = {
        'widgetConfigs': {
          'valid': config1.toJson(),
          'invalid': 'not a map',
        },
      };
      final result = UspLayoutPreferences.fromJson(json);
      // Valid entry parsed, invalid skipped
      expect(result.widgetConfigs.containsKey('valid'), isTrue);
      expect(result.widgetConfigs.containsKey('invalid'), isFalse);
    });

    test('fromJson returns empty configs when configsJson=null', () {
      final result = UspLayoutPreferences.fromJson({
        'useCustomLayout': false,
      });
      expect(result.widgetConfigs, isEmpty);
    });

    test('fromJsonString parses valid JSON', () {
      final jsonStr = jsonEncode(prefsWithConfigs.toJson());
      final result = UspLayoutPreferences.fromJsonString(jsonStr);
      expect(result.useCustomLayout, prefsWithConfigs.useCustomLayout);
      expect(result.selectedPreset, prefsWithConfigs.selectedPreset);
    });

    test('fromJsonString returns default on invalid JSON', () {
      final result = UspLayoutPreferences.fromJsonString('not valid json');
      expect(result, equals(const UspLayoutPreferences()));
    });

    test('toJsonString wraps toJson', () {
      final jsonStr = prefsWithConfigs.toJsonString();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['useCustomLayout'], isTrue);
    });

    test('JSON round-trip preserves all data', () {
      final json = prefsWithConfigs.toJson();
      final restored = UspLayoutPreferences.fromJson(json);
      expect(restored, equals(prefsWithConfigs));
    });
  });

  group('Equatable', () {
    test('equal preferences are equal', () {
      final a = UspLayoutPreferences(
        useCustomLayout: true,
        selectedPreset: UspDashboardPreset.standard,
      );
      final b = UspLayoutPreferences(
        useCustomLayout: true,
        selectedPreset: UspDashboardPreset.standard,
      );
      expect(a, equals(b));
    });

    test('different useCustomLayout not equal', () {
      final a = UspLayoutPreferences(useCustomLayout: true);
      final b = UspLayoutPreferences(useCustomLayout: false);
      expect(a, isNot(equals(b)));
    });

    test('different widgetConfigs not equal', () {
      final a = UspLayoutPreferences(widgetConfigs: {'a': config1});
      final b = UspLayoutPreferences(widgetConfigs: {'b': config2});
      expect(a, isNot(equals(b)));
    });

    test('different selectedPreset not equal', () {
      final a = UspLayoutPreferences(
        selectedPreset: UspDashboardPreset.essential,
      );
      final b = UspLayoutPreferences(
        selectedPreset: UspDashboardPreset.standard,
      );
      expect(a, isNot(equals(b)));
    });

    test('different hasSeenPresetDialog not equal', () {
      final a = UspLayoutPreferences(hasSeenPresetDialog: true);
      final b = UspLayoutPreferences(hasSeenPresetDialog: false);
      expect(a, isNot(equals(b)));
    });

    test('default constructor values', () {
      const prefs = UspLayoutPreferences();
      expect(prefs.useCustomLayout, isTrue);
      expect(prefs.widgetConfigs, isEmpty);
      expect(prefs.selectedPreset, isNull);
      expect(prefs.hasSeenPresetDialog, isFalse);
    });

    test('props list has 4 fields', () {
      expect(prefsWithConfigs.props.length, 4);
    });
  });
}
