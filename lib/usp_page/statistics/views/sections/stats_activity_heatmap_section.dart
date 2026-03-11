import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_analytics_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// 24-hour per-device activity heatmap (top 12 devices by activity frequency).
class StatsActivityHeatmapSection extends ConsumerWidget {
  const StatsActivityHeatmapSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspDeviceAnalyticsProvider);

    return StatsSectionCard(
      title: 'Activity Heatmap',
      subtitle: '24-hour per-device activity matrix',
      chartHeight: 360,
      child: state.hourlyHistory.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                'Collecting activity data...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state),
    );
  }

  Widget _buildChart(BuildContext context, DeviceAnalyticsState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = state.hourlyHistory;

    // Sort MACs by activity frequency (most active first), limit to 12
    final macActivity = <String, int>{};
    for (final h in history) {
      for (final mac in h.activeMacs) {
        macActivity[mac] = (macActivity[mac] ?? 0) + 1;
      }
    }
    final sortedMacs = macActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayMacs = sortedMacs.take(12).map((e) => e.key).toList();

    if (displayMacs.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No device activity recorded',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Build 24-hour lookup
    final now = DateTime.now();
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final hourSlots = List.generate(
        24, (i) => currentHour.subtract(Duration(hours: 23 - i)));
    final hourToAggregate = {for (final h in history) h.hour: h};

    // Build heatmap values
    final values = List.generate(displayMacs.length, (row) {
      return List.generate(24, (col) {
        final aggregate = hourToAggregate[hourSlots[col]];
        return (aggregate?.activeMacs.contains(displayMacs[row]) ?? false)
            ? 1.0
            : 0.0;
      });
    });

    final rowLabels = displayMacs.map((mac) {
      final name = state.macDisplayNames[mac] ?? mac;
      return name.length > 10 ? '${name.substring(0, 9)}\u2026' : name;
    }).toList();

    final columnLabels = hourSlots
        .map((h) => h.hour % 6 == 0 ? '${h.hour}'.padLeft(2, '0') : '')
        .toList();

    return AppHeatmapChart(
      data: AppHeatmapData(
        rows: displayMacs.length,
        columns: 24,
        values: values,
        rowLabels: rowLabels,
        columnLabels: columnLabels,
        minValue: 0,
        maxValue: 1,
      ),
      lowColor: colorScheme.surfaceContainerHighest,
      highColor: colorScheme.primary,
    );
  }
}
