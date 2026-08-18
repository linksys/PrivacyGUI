import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
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
          // Opted into the scroll net (#1296). This is the one tab of this card
          // whose content shrink-wraps: the donut is a fixed 180px at every card
          // size (measured 180 at 4 rows and at 8 rows, while its slot grew
          // 245 -> 789px), so the vertical `Flexible` that used to hold it was
          // only centring air. The four breakdown rows below it are what varies —
          // 71px in `ar` and 133px in `el` at the 260.5px card — and with the
          // donut fixed, `el` sat 3px from painting over them with the gate
          // reporting nothing (a `Center` spills in both directions and a
          // `RenderFlex` only reports the part that falls past the bottom edge).
          // See the density design §2.10j.
          scrollable: true,
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
        // Not `Flexible`/`Expanded`: this tab scrolls (#1296), so a vertical flex
        // child here would be a child with unbounded height constraints and throw.
        // Nothing is lost by dropping it — `AppPieChart` derives its geometry from
        // `size:`, not from the box it is given, so the flex never sized the donut;
        // it only distributed leftover height around it.
        Center(
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
        AppGap.md(),
        // Connection type + status breakdown
        Row(
          children: [
            Expanded(
              child: LayoutBlock(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.wifi, color: colorScheme.primary, size: 20),
                    AppGap.sm(),
                    Expanded(
                      child: AppText.bodyMedium(loc(context).wifi),
                    ),
                    AppText.titleSmall('${distribution.wifiCount}'),
                  ],
                ),
              ),
            ),
            AppGap.sm(),
            Expanded(
              child: LayoutBlock(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.settings_ethernet,
                        color: colorScheme.secondary, size: 20),
                    AppGap.sm(),
                    Expanded(
                      child: AppText.bodyMedium(loc(context).wired),
                    ),
                    AppText.titleSmall('${distribution.wiredCount}'),
                  ],
                ),
              ),
            ),
          ],
        ),
        AppGap.sm(),
        Row(
          children: [
            Expanded(
              child: LayoutBlock(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppGap.sm(),
                    Expanded(
                      child: AppText.bodyMedium(loc(context).online),
                    ),
                    AppText.titleSmall('$online'),
                  ],
                ),
              ),
            ),
            AppGap.sm(),
            Expanded(
              child: LayoutBlock(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppGap.sm(),
                    Expanded(
                      child: AppText.bodyMedium(loc(context).offline),
                    ),
                    AppText.titleSmall('$offline'),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                // `.statistic`, so the label soft-wraps instead of ellipsizing:
                // it composes a count into the text and an ellipsis could cut
                // the number in half (§2.10a point 2). `.block()` mirrors the
                // `AppBarChart` series above.
                AppChartLegendEntry.statistic(
                  mark: const ChartMark.block(),
                  color: colors[i],
                  label: '${labels[i]}: ${data[i].toInt()}',
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
