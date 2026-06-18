import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// 24-hour stacked column chart — WiFi vs Wired device count per hour.
class StatsConnectionTrendsSection extends ConsumerWidget {
  const StatsConnectionTrendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspDeviceAnalyticsProvider);

    return StatsSectionCard(
      title: loc(context).connectionTrends,
      subtitle: loc(context).connectionTrendsSubtitle,
      chartHeight: 260,
      child: state.hourlyHistory.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                loc(context).collectingHourlyData,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state.hourlyHistory),
    );
  }

  Widget _buildChart(BuildContext context, List<HourlyAggregate> history) {
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final slots = List.generate(24, (i) {
      final hour = currentHour.subtract(Duration(hours: 23 - i));
      final match = history.where((h) => h.hour == hour).firstOrNull;
      return (
        hour: hour,
        wifi: match?.wifiCount ?? 0,
        wired: match?.wiredCount ?? 0,
      );
    });

    final wifiData = slots.map((s) => s.wifi.toDouble()).toList();
    final wiredData = slots.map((s) => s.wired.toDouble()).toList();
    final xLabels = slots
        .map(
            (s) => s.hour.hour % 3 == 0 ? '${s.hour.hour}'.padLeft(2, '0') : '')
        .toList();

    return Column(
      children: [
        Expanded(
          child: AppBarChart(
            series: [
              AppChartSeries(
                  label: loc(context).wifi,
                  data: wifiData,
                  color: colorScheme.primary),
              AppChartSeries(
                  label: loc(context).wired,
                  data: wiredData,
                  color: colorScheme.secondary),
            ],
            stacked: true,
            xLabels: xLabels,
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall(loc(context).wifi),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall(loc(context).wired),
          ],
        ),
      ],
    );
  }
}
