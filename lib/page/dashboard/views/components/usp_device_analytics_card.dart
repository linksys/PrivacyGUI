import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Device Connection Analytics card — 4 chart views via tab selector.
///
/// - Distribution (Donut): WiFi vs Wired with band breakdown
/// - Trend (Stacked Column): 24h hourly device count
/// - Activity (Heatmap): 24h per-device activity matrix
/// - Signal (Radar): WiFi signal quality per band
class UspDeviceAnalyticsCard extends ConsumerStatefulWidget {
  const UspDeviceAnalyticsCard({super.key});

  @override
  ConsumerState<UspDeviceAnalyticsCard> createState() =>
      _UspDeviceAnalyticsCardState();
}

class _UspDeviceAnalyticsCardState
    extends ConsumerState<UspDeviceAnalyticsCard> {
  static const _cardId = 'device_analytics';

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(uspDeviceAnalyticsProvider);
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));

    return DashboardCardTemplate.tabbed(
      title: 'Device Analytics',
      selectedTabIndex: selectedTab,
      onTabChanged: (index) =>
          ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
      tabs: [
        CardTab(
          label: 'Distribution',
          content: _buildChartView(context, analyticsState, 0),
        ),
        CardTab(
          label: 'Trend',
          content: _buildChartView(context, analyticsState, 1),
        ),
        CardTab(
          label: 'Activity',
          content: _buildChartView(context, analyticsState, 2),
        ),
        CardTab(
          label: 'Signal',
          content: _buildChartView(context, analyticsState, 3),
        ),
      ],
    );
  }

  Widget _buildChartView(
    BuildContext context,
    DeviceAnalyticsState state,
    int selectedTab,
  ) {
    final current = state.current;

    return switch (selectedTab) {
      0 => current != null
          ? _DistributionView(distribution: current)
          : _buildEmptyState(context, 'Waiting for device data...'),
      1 => state.hourlyHistory.isNotEmpty
          ? _TrendView(history: state.hourlyHistory)
          : _buildEmptyState(context, 'Collecting hourly data...'),
      2 => state.hourlyHistory.isNotEmpty
          ? _ActivityView(
              history: state.hourlyHistory,
              allKnownMacs: state.allKnownMacs,
              macDisplayNames: state.macDisplayNames,
            )
          : _buildEmptyState(context, 'Collecting activity data...'),
      3 => current != null && current.bandSignalQuality.isNotEmpty
          ? _SignalView(distribution: current)
          : _buildEmptyState(context, 'No WiFi signal data...'),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: AppText.bodyMedium(
        message,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// =============================================================================
// Tab 1: Distribution (Donut + Band bars)
// =============================================================================

class _DistributionView extends StatelessWidget {
  final DeviceDistribution distribution;
  const _DistributionView({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Flexible(
          child: Center(
            child: AppPieChart(
              sections: [
                AppPieSection(
                    value: distribution.wifiCount.toDouble(),
                    label: 'WiFi',
                    color: colorScheme.primary),
                AppPieSection(
                    value: distribution.wiredCount.toDouble(),
                    label: 'Wired',
                    color: colorScheme.secondary),
              ],
              donut: true,
              centerWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium('${distribution.onlineCount}'),
                  AppText.labelSmall('online',
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
              size: 180,
            ),
          ),
        ),
        AppGap.sm(),
        if (distribution.bandDistribution.isNotEmpty)
          _BandDistributionBars(
            bandDistribution: distribution.bandDistribution,
          ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('WiFi: ${distribution.wifiCount}'),
            AppGap.lg(),
            _LegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Wired: ${distribution.wiredCount}'),
            AppGap.lg(),
            AppText.labelSmall(
              '${distribution.offlineCount} offline',
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }
}

class _BandDistributionBars extends StatelessWidget {
  final Map<String, int> bandDistribution;

  const _BandDistributionBars({required this.bandDistribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = bandDistribution.values.fold(0, (a, b) => a > b ? a : b);
    final seriesColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    return Column(
      children: [
        for (var i = 0; i < bandDistribution.entries.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: AppText.labelSmall(
                    bandDistribution.entries.elementAt(i).key,
                    textAlign: TextAlign.end,
                  ),
                ),
                AppGap.sm(),
                Expanded(
                  child: _HorizontalBar(
                    value: bandDistribution.entries.elementAt(i).value,
                    maxValue: maxCount,
                    color: seriesColors[i % seriesColors.length],
                  ),
                ),
                AppGap.sm(),
                SizedBox(
                  width: 20,
                  child: AppText.labelSmall(
                    '${bandDistribution.entries.elementAt(i).value}',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  final int value;
  final int maxValue;
  final Color color;

  const _HorizontalBar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: constraints.maxWidth * fraction,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Tab 2: Trend (Stacked Column Chart)
// =============================================================================

class _TrendView extends StatelessWidget {
  final List<HourlyAggregate> history;
  const _TrendView({required this.history});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Build 24-hour slot array
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
                  label: 'WiFi', data: wifiData, color: colorScheme.primary),
              AppChartSeries(
                  label: 'Wired',
                  data: wiredData,
                  color: colorScheme.secondary),
            ],
            stacked: true,
            xLabels: xLabels,
            showTooltip: false,
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('WiFi'),
            AppGap.lg(),
            _LegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Wired'),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 3: Activity (Heatmap)
// =============================================================================

class _ActivityView extends StatelessWidget {
  final List<HourlyAggregate> history;
  final Set<String> allKnownMacs;
  final Map<String, String> macDisplayNames;

  const _ActivityView({
    required this.history,
    required this.allKnownMacs,
    required this.macDisplayNames,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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

    // Build 24-hour lookup
    final now = DateTime.now();
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final hourSlots =
        List.generate(24, (i) => currentHour.subtract(Duration(hours: 23 - i)));
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
      final name = macDisplayNames[mac] ?? mac;
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

// =============================================================================
// Tab 4: Signal (Radar / Bar fallback)
// =============================================================================

class _SignalView extends StatelessWidget {
  final DeviceDistribution distribution;
  const _SignalView({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bands = distribution.bandSignalQuality;

    // Radar chart needs >= 3 axes; fallback to bar comparison for fewer
    final useRadar = bands.length >= 3;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: useRadar
                ? AppRadarChart(
                    series: [
                      AppRadarSeries(
                        label: 'Signal Quality',
                        data: bands.values.map((v) => v * 100).toList(),
                        color: colorScheme.primary,
                        filled: true,
                      ),
                    ],
                    axisLabels: bands.keys.toList(),
                    tickCount: 4,
                  )
                : AppBarChart(
                    series: [
                      AppChartSeries(
                        label: 'Signal',
                        data: bands.values.map((v) => v * 100).toList(),
                        color: colorScheme.primary,
                      ),
                    ],
                    xLabels: bands.keys.toList(),
                    yAxis: AppChartAxis(min: 0, max: 100, interval: 25),
                    yLabelFormatter: (v) => '${v.toInt()}%',
                    showValueLabels: true,
                    valueLabelFormatter: (v) => '${v.toInt()}%',
                    showTooltip: false,
                  ),
          ),
        ),
        AppGap.sm(),
        if (distribution.signalLevelDistribution.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final entry in [
                (3, 'Excellent', colorScheme.primary),
                (2, 'Good', Colors.lightGreen),
                (1, 'Fair', Colors.orange),
                (0, 'Poor', colorScheme.error),
              ]) ...[
                if (distribution.signalLevelDistribution
                    .containsKey(entry.$1)) ...[
                  _LegendDot(color: entry.$3),
                  AppGap.xs(),
                  AppText.labelSmall(
                    '${entry.$2}: ${distribution.signalLevelDistribution[entry.$1]}',
                  ),
                  AppGap.md(),
                ],
              ],
            ],
          ),
      ],
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
