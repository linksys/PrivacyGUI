import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Device Connection Analytics card — 4 chart views via tab selector.
///
/// - Overview (Donut): Online/Offline with WiFi/Wired breakdown
/// - Signal (Bar): WiFi signal quality distribution (Excellent/Good/Fair/Poor)
/// - Trend (Line): 24h total device count
/// - Activity (Heatmap): 24h per-device activity matrix
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
      title: loc(context).deviceAnalytics,
      selectedTabIndex: selectedTab,
      onTabChanged: (index) =>
          ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
      tabs: [
        CardTab(
          label: loc(context).distribution,
          content: _buildChartView(context, analyticsState, 0),
        ),
        CardTab(
          label: loc(context).signal,
          content: _buildChartView(context, analyticsState, 1),
        ),
        CardTab(
          label: loc(context).trend,
          content: _buildChartView(context, analyticsState, 2),
        ),
        CardTab(
          label: loc(context).activity,
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
          ? _OverviewView(distribution: current)
          : _buildEmptyState(context, loc(context).waitingForDeviceData),
      1 => current != null && current.signalLevelDistribution.isNotEmpty
          ? _SignalView(distribution: current)
          : _buildEmptyState(context, loc(context).noWifiSignalData),
      2 => state.hourlyHistory.isNotEmpty
          ? _TrendView(history: state.hourlyHistory)
          : _buildEmptyState(context, loc(context).collectingHourlyData),
      3 => state.hourlyHistory.isNotEmpty
          ? _ActivityView(
              history: state.hourlyHistory,
              allKnownMacs: state.allKnownMacs,
              macDisplayNames: state.macDisplayNames,
            )
          : _buildEmptyState(context, loc(context).collectingActivityData),
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
// Tab 1: Overview (Online/Offline donut + WiFi/Wired breakdown)
// =============================================================================

class _OverviewView extends StatelessWidget {
  final DeviceDistribution distribution;
  const _OverviewView({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final online = distribution.onlineCount;
    final offline = distribution.offlineCount;
    final total = distribution.totalCount;

    return Column(
      children: [
        Flexible(
          child: Center(
            child: AppPieChart(
              sections: [
                AppPieSection(
                  value: online.toDouble(),
                  label: loc(context).online,
                  color: colorScheme.primary,
                ),
                if (offline > 0)
                  AppPieSection(
                    value: offline.toDouble(),
                    label: loc(context).offline,
                    color: colorScheme.outlineVariant,
                  ),
              ],
              donut: true,
              centerWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium('$total'),
                  AppText.labelSmall(loc(context).devices,
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
              size: 180,
            ),
          ),
        ),
        AppGap.md(),
        // WiFi / Wired breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatItem(
              icon: Icons.wifi,
              label: loc(context).wifi,
              value: distribution.wifiCount,
              color: colorScheme.primary,
            ),
            AppGap.xl(),
            _StatItem(
              icon: Icons.cable,
              label: loc(context).wired,
              value: distribution.wiredCount,
              color: colorScheme.secondary,
            ),
          ],
        ),
        AppGap.sm(),
        // Online / Offline legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('${loc(context).online}: $online'),
            if (offline > 0) ...[
              AppGap.lg(),
              _LegendDot(color: colorScheme.outlineVariant),
              AppGap.xs(),
              AppText.labelSmall('${loc(context).offline}: $offline'),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        AppGap.xs(),
        AppText.titleMedium('$value'),
        AppText.labelSmall(label,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }
}

// =============================================================================
// Tab 2: Signal (Signal quality distribution)
// =============================================================================

class _SignalView extends StatelessWidget {
  final DeviceDistribution distribution;
  const _SignalView({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final signalDist = distribution.signalLevelDistribution;

    // Signal levels: 3=Excellent, 2=Good, 1=Fair, 0=Poor
    final levels = [
      (3, loc(context).excellent, colorScheme.primary),
      (2, loc(context).good, Colors.lightGreen),
      (1, loc(context).fair, Colors.orange),
      (0, loc(context).poor, colorScheme.error),
    ];

    final data = levels.map((l) => (signalDist[l.$1] ?? 0).toDouble()).toList();
    final labels = levels.map((l) => l.$2).toList();
    final colors = levels.map((l) => l.$3).toList();
    final total = data.fold(0.0, (a, b) => a + b);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppBarChart(
              series: [
                for (var i = 0; i < levels.length; i++)
                  AppChartSeries(
                    label: labels[i],
                    data: [data[i]],
                    color: colors[i],
                  ),
              ],
              xLabels: [''],
              yAxis: AppChartAxis(
                min: 0,
                max: total > 0 ? total : 1,
                interval: (total / 4).ceilToDouble().clamp(1, double.infinity),
              ),
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        // Legend
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < levels.length; i++)
              if (data[i] > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendDot(color: colors[i]),
                    AppGap.xs(),
                    AppText.labelSmall('${labels[i]}: ${data[i].toInt()}'),
                  ],
                ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 3: Trend (Total device count line chart)
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
      final total = (match?.wifiCount ?? 0) + (match?.wiredCount ?? 0);
      return (hour: hour, total: total);
    });

    final totalData = slots.map((s) => s.total.toDouble()).toList();

    // Calculate Y-axis bounds to avoid duplicate labels with small counts
    final maxCount = slots.map((s) => s.total).reduce((a, b) => a > b ? a : b);
    final yMax = maxCount < 2 ? 2.0 : (maxCount + 1).toDouble();
    final yInterval = yMax <= 4 ? 1.0 : (yMax / 4).ceilToDouble();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: loc(context).devices,
                  data: totalData,
                  color: colorScheme.primary,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: yMax, interval: yInterval),
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        AppText.labelSmall(
          '24h',
          color: colorScheme.onSurfaceVariant,
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
