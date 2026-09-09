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

  // #1492: `remote` is Remote Assistance's forced layout, not a style anyone
  // picks, so it must never reach the picker. These assert the list itself; the
  // dialog that consumes it is covered by
  // test/page/dashboard/views/dialogs/preset_selection_dialog_test.dart.
  group('selectable', () {
    test('excludes remote', () {
      expect(
        UspDashboardPreset.selectable,
        isNot(contains(UspDashboardPreset.remote)),
      );
    });

    test('is every other preset, in declaration order', () {
      expect(
        UspDashboardPreset.selectable,
        equals(const [
          UspDashboardPreset.essential,
          UspDashboardPreset.standard,
          UspDashboardPreset.professional,
          UspDashboardPreset.monitoring,
        ]),
      );
    });

    // `selectable` is a *view* of `isUserSelectable`, never a second list to keep
    // in sync — that is what makes the exhaustive `switch` load-bearing. A new
    // preset cannot slip into the picker, because the switch will not compile
    // until somebody decides; and it cannot slip out of it either, because a
    // `true` here has to show up in `selectable`.
    test('is exactly the presets whose isUserSelectable is true', () {
      expect(
        UspDashboardPreset.selectable,
        UspDashboardPreset.values.where((p) => p.isUserSelectable).toList(),
      );
    });

    test('remote is the only preset users may not pick', () {
      expect(UspDashboardPreset.remote.isUserSelectable, isFalse);
      expect(
        UspDashboardPreset.values.where((p) => !p.isUserSelectable),
        [UspDashboardPreset.remote],
      );
    });

    // The excluded preset stays fully functional — RA forces it, and phase 8 of
    // #1474 must not read this exclusion as permission to delete the value.
    test('remote is excluded from the picker, not removed from the enum', () {
      expect(UspDashboardPreset.values, contains(UspDashboardPreset.remote));
      expect(UspDashboardPreset.remote.displayName, 'Remote Support');
      expect(UspDashboardPreset.remote.createLayout().length, 8);
    });
  });

  group('cardIds', () {
    test('essential has 6 cards', () {
      expect(UspDashboardPreset.essential.cardIds.length, 6);
    });

    test('standard has 12 cards', () {
      expect(UspDashboardPreset.standard.cardIds.length, 12);
    });

    test('professional has 18 cards (all)', () {
      expect(UspDashboardPreset.professional.cardIds.length, 18);
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
        expect(statsPanel.w, 12, reason: preset.name);
        expect(statsPanel.x, 0, reason: preset.name);
        expect(statsPanel.y, 0, reason: preset.name);
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
