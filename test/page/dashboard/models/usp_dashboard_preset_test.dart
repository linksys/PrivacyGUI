import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

void main() {
  group('Extension getters', () {
    test('essential displayName', () {
      expect(UspDashboardPreset.essential.displayName, 'Essential');
    });

    test('standard displayName', () {
      expect(UspDashboardPreset.standard.displayName, 'Standard');
    });

    test('professional displayName', () {
      expect(UspDashboardPreset.professional.displayName, 'Professional');
    });

    test('monitoring displayName', () {
      expect(UspDashboardPreset.monitoring.displayName, 'Monitoring');
    });

    test('each preset has non-empty description', () {
      for (final preset in UspDashboardPreset.values) {
        expect(
          preset.description.isNotEmpty,
          isTrue,
          reason: '${preset.name} should have a description',
        );
      }
    });

    test('essential icon', () {
      expect(UspDashboardPreset.essential.icon, Icons.dashboard_outlined);
    });

    test('standard icon', () {
      expect(UspDashboardPreset.standard.icon, Icons.grid_view);
    });

    test('professional icon', () {
      expect(UspDashboardPreset.professional.icon, Icons.tune);
    });

    test('monitoring icon', () {
      expect(UspDashboardPreset.monitoring.icon, Icons.monitor_heart);
    });
  });

  group('cardIds', () {
    test('essential has 6 cards', () {
      expect(UspDashboardPreset.essential.cardIds.length, 6);
    });

    test('standard has 12 cards', () {
      expect(UspDashboardPreset.standard.cardIds.length, 12);
    });

    test('professional has 17 cards (all)', () {
      expect(UspDashboardPreset.professional.cardIds.length, 17);
    });

    test('monitoring has 8 cards', () {
      expect(UspDashboardPreset.monitoring.cardIds.length, 8);
    });

    test('all cardIds exist in UspWidgetSpecs', () {
      for (final preset in UspDashboardPreset.values) {
        for (final id in preset.cardIds) {
          expect(
            UspWidgetSpecs.getById(id),
            isNotNull,
            reason: '$id in ${preset.name} not found in UspWidgetSpecs',
          );
        }
      }
    });

    test('all presets include stats_panel', () {
      for (final preset in UspDashboardPreset.values) {
        expect(
          preset.cardIds.contains('stats_panel'),
          isTrue,
          reason: '${preset.name} should include stats_panel',
        );
      }
    });
  });

  group('createLayout', () {
    test('essential layout length matches cardIds', () {
      final layout = UspDashboardPreset.essential.createLayout();
      expect(layout.length, UspDashboardPreset.essential.cardIds.length);
    });

    test('standard layout length matches cardIds', () {
      final layout = UspDashboardPreset.standard.createLayout();
      expect(layout.length, UspDashboardPreset.standard.cardIds.length);
    });

    test('professional layout length matches cardIds', () {
      final layout = UspDashboardPreset.professional.createLayout();
      expect(layout.length, UspDashboardPreset.professional.cardIds.length);
    });

    test('monitoring layout length matches cardIds', () {
      final layout = UspDashboardPreset.monitoring.createLayout();
      expect(layout.length, UspDashboardPreset.monitoring.cardIds.length);
    });

    test('essential layout IDs match cardIds', () {
      final layout = UspDashboardPreset.essential.createLayout();
      final layoutIds = layout.map((i) => i.id).toSet();
      final cardIds = UspDashboardPreset.essential.cardIds.toSet();
      expect(layoutIds, equals(cardIds));
    });

    test('standard layout IDs match cardIds', () {
      final layout = UspDashboardPreset.standard.createLayout();
      final layoutIds = layout.map((i) => i.id).toSet();
      final cardIds = UspDashboardPreset.standard.cardIds.toSet();
      expect(layoutIds, equals(cardIds));
    });

    test('professional layout IDs match cardIds', () {
      final layout = UspDashboardPreset.professional.createLayout();
      final layoutIds = layout.map((i) => i.id).toSet();
      final cardIds = UspDashboardPreset.professional.cardIds.toSet();
      expect(layoutIds, equals(cardIds));
    });

    test('monitoring layout IDs match cardIds', () {
      final layout = UspDashboardPreset.monitoring.createLayout();
      final layoutIds = layout.map((i) => i.id).toSet();
      final cardIds = UspDashboardPreset.monitoring.cardIds.toSet();
      expect(layoutIds, equals(cardIds));
    });

    test('all presets: stats_panel is w=12 x=0 y=0', () {
      for (final preset in UspDashboardPreset.values) {
        final layout = preset.createLayout();
        final statsPanel = layout.firstWhere((i) => i.id == 'stats_panel');
        expect(statsPanel.w, 12, reason: '${preset.name}');
        expect(statsPanel.x, 0, reason: '${preset.name}');
        expect(statsPanel.y, 0, reason: '${preset.name}');
      }
    });

    test('monitoring: traffic_analysis is prominent', () {
      final layout = UspDashboardPreset.monitoring.createLayout();
      final traffic = layout.firstWhere((i) => i.id == 'traffic_analysis');
      expect(traffic.y, 1);
      expect(traffic.w, 12);
    });

    test('standard: topology is full-width', () {
      final layout = UspDashboardPreset.standard.createLayout();
      final topology = layout.firstWhere((i) => i.id == 'topology');
      expect(topology.w, 12);
    });

    test('no layout item has x < 0 or w > 12', () {
      for (final preset in UspDashboardPreset.values) {
        final layout = preset.createLayout();
        for (final item in layout) {
          expect(item.x, greaterThanOrEqualTo(0),
              reason: '${preset.name}/${item.id} x < 0');
          expect(item.w, lessThanOrEqualTo(12),
              reason: '${preset.name}/${item.id} w > 12');
        }
      }
    });

    test('no item exceeds grid: x + w <= 12', () {
      for (final preset in UspDashboardPreset.values) {
        final layout = preset.createLayout();
        for (final item in layout) {
          expect(
            item.x + item.w,
            lessThanOrEqualTo(12),
            reason: '${preset.name}/${item.id}: x=${item.x} + w=${item.w} > 12',
          );
        }
      }
    });
  });
}
