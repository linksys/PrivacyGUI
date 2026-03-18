import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/usp_page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/usp_page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/usp_page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/usp_page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/usp_page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/usp_page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/usp_page/_shared/components/usp_info_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// System Performance Dashboard — 4-tab card (F-021).
///
/// - Monitor: CPU/Memory gauges + uptime
/// - Trends: CPU/Memory line chart with area fill + avg/peak stats
/// - Distribution: CPU bucket bar chart + Memory donut
/// - Correlation: CPU % vs WAN traffic rate dual-axis chart
class UspSystemStatusCard extends ConsumerStatefulWidget {
  const UspSystemStatusCard({super.key});

  @override
  ConsumerState<UspSystemStatusCard> createState() =>
      _UspSystemStatusCardState();
}

class _UspSystemStatusCardState extends ConsumerState<UspSystemStatusCard> {
  static const _cardId = 'system_status';

  static const _tabs = [
    TabItem(label: 'Monitor'),
    TabItem(label: 'Trends'),
    TabItem(label: 'Distribution'),
    TabItem(label: 'Correlation'),
  ];

  static final _intervalOptions = <(Duration?, String)>[
    (null, 'Off'),
    (Duration(seconds: 10), '10s'),
    (Duration(seconds: 30), '30s'),
    (Duration(minutes: 1), '60s'),
  ];

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(systemInfoDataProvider).valueOrNull?.model;
    if (info == null) return const CardSkeleton.chart();
    final monitorState = ref.watch(uspSystemMonitorProvider);
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + spinner + interval selector
          Row(
            children: [
              AppText.titleMedium('System Status'),
              if (monitorState.isFetching) ...[
                AppGap.sm(),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
              ],
              const Spacer(),
              AppPopupMenu<Duration?>(
                icon: Icons.timer_outlined,
                iconSize: 20,
                items: _intervalOptions
                    .map((e) => AppPopupMenuItem<Duration?>(
                          value: e.$1,
                          label: e.$2,
                        ))
                    .toList(),
                onSelected: (interval) {
                  ref
                      .read(uspSystemMonitorProvider.notifier)
                      .setRefreshInterval(interval);
                },
              ),
            ],
          ),
          AppGap.sm(),
          AppTabs(
            tabs: _tabs,
            initialIndex: selectedTab,
            displayMode: TabDisplayMode.segmented,
            isScrollable: true,
            showBorder: false,
            onTabChanged: (index) =>
                ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
          ),
          AppGap.md(),
          Expanded(
            child: _buildTabView(context, info, monitorState, selectedTab),
          ),
        ],
      ),
    );
  }

  Widget _buildTabView(
    BuildContext context,
    SystemInfoUIModel info,
    SystemMonitorState monitorState,
    int selectedTab,
  ) {
    return switch (selectedTab) {
      0 => _MonitorView(info: info, monitorState: monitorState),
      1 => monitorState.history.isNotEmpty
          ? _TrendsView(monitorState: monitorState)
          : _buildEmptyState(context, 'Waiting for data...'),
      2 => monitorState.history.isNotEmpty
          ? _DistributionView(monitorState: monitorState)
          : _buildEmptyState(context, 'Waiting for data...'),
      3 => _CorrelationView(monitorState: monitorState, ref: ref),
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
// Tab 1: Monitor (Gauges + Uptime)
// =============================================================================

class _MonitorView extends StatelessWidget {
  final SystemInfoUIModel info;
  final SystemMonitorState monitorState;

  const _MonitorView({required this.info, required this.monitorState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest = monitorState.latest;
    final cpuPercent = latest?.cpuPercent ?? info.cpuPercent;
    final memPercent = latest?.memoryPercent ?? info.memoryPercent;
    final memUsedStr = latest != null
        ? UspFormatters.formatBytes(latest.usedMemoryKb * 1024)
        : info.formattedUsedMemory;
    final memTotalStr = latest != null
        ? UspFormatters.formatBytes(latest.totalMemoryKb * 1024)
        : info.formattedTotalMemory;

    final intervalLabel = _UspSystemStatusCardState._intervalOptions
            .where((e) => e.$1 == monitorState.refreshInterval)
            .map((e) => e.$2)
            .firstOrNull ??
        'Off';

    return Column(
      children: [
        UspInfoRow(label: 'Uptime', value: info.formattedUptime),
        AppGap.md(),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGauge(context,
                  value: cpuPercent.toDouble(),
                  label: 'CPU',
                  display: '$cpuPercent%'),
              _buildGauge(context,
                  value: memPercent.toDouble(),
                  label: 'Memory',
                  display: '$memPercent%'),
            ],
          ),
        ),
        AppGap.sm(),
        Center(
          child: AppText.bodySmall(
            '$memUsedStr / $memTotalStr used',
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppGap.md(),
        Row(
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('CPU: ${latest?.cpuPercent ?? '--'}%'),
            AppGap.lg(),
            _LegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Memory: ${latest?.memoryPercent ?? '--'}%'),
            const Spacer(),
            if (monitorState.refreshInterval != null) ...[
              AppIcon.font(Icons.autorenew,
                  size: 12, color: colorScheme.onSurfaceVariant),
              AppText.labelSmall(intervalLabel,
                  color: colorScheme.onSurfaceVariant),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGauge(
    BuildContext context, {
    required double value,
    required String label,
    required String display,
  }) {
    return AppGauge(
      value: value,
      size: 100,
      centerBuilder: (ctx, v) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleMedium(display),
          AppText.bodySmall(label),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 2: Trends (Line Chart + Stats)
// =============================================================================

class _TrendsView extends StatelessWidget {
  final SystemMonitorState monitorState;
  const _TrendsView({required this.monitorState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = monitorState.history;
    final cpuValues = history.map((s) => s.cpuPercent.toDouble()).toList();
    final memValues = history.map((s) => s.memoryPercent.toDouble()).toList();

    // Compute summary stats
    final avgCpu = cpuValues.isEmpty
        ? 0
        : (cpuValues.reduce((a, b) => a + b) / cpuValues.length).round();
    final peakCpu = cpuValues.isEmpty
        ? 0
        : cpuValues.reduce((a, b) => a > b ? a : b).round();
    final avgMem = memValues.isEmpty
        ? 0
        : (memValues.reduce((a, b) => a + b) / memValues.length).round();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: 'CPU',
                  data: cpuValues,
                  filled: true,
                  color: colorScheme.primary,
                ),
                AppChartSeries(
                  label: 'Memory',
                  data: memValues,
                  color: colorScheme.secondary,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: 100, interval: 25),
              yLabelFormatter: (v) => '${v.toInt()}%',
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('Avg: $avgCpu%  Peak: $peakCpu%'),
            AppGap.lg(),
            _LegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Avg: $avgMem%'),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 3: Distribution (CPU usage histogram)
// =============================================================================

class _DistributionView extends StatelessWidget {
  final SystemMonitorState monitorState;
  const _DistributionView({required this.monitorState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = monitorState.history;

    // CPU distribution: 4 buckets
    final buckets = [0, 0, 0, 0]; // 0-25, 25-50, 50-75, 75-100
    for (final s in history) {
      final idx = (s.cpuPercent / 25).floor().clamp(0, 3);
      buckets[idx]++;
    }
    final maxBucket = buckets.reduce((a, b) => a > b ? a : b);
    // Round up to nice integer ceiling with room for value labels
    final yMax = maxBucket < 1 ? 2.0 : (maxBucket + 2).toDouble();
    final yInterval = yMax <= 4 ? 1.0 : (yMax / 4).ceilToDouble();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: AppBarChart(
              series: [
                AppChartSeries(
                  label: 'CPU',
                  data: buckets.map((b) => b.toDouble()).toList(),
                  color: colorScheme.primary,
                ),
              ],
              xLabels: const ['0-25%', '25-50%', '50-75%', '75-100%'],
              yAxis: AppChartAxis(min: 0, max: yMax, interval: yInterval),
              yLabelFormatter: (v) => v.toInt().toString(),
              showValueLabels: true,
              valueLabelFormatter: (v) => v.toInt().toString(),
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('CPU usage samples: ${history.length}'),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 4: Correlation (CPU vs Traffic dual-axis)
// =============================================================================

class _CorrelationView extends StatelessWidget {
  final SystemMonitorState monitorState;
  final WidgetRef ref;

  const _CorrelationView({required this.monitorState, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trafficState = ref.watch(uspTrafficAnalysisProvider);
    final sysHistory = monitorState.history;

    if (sysHistory.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'Waiting for data...',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final trafficHistory = trafficState.history;
    if (trafficHistory.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'Enable traffic monitor for correlation data',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final cpuData = sysHistory.map((s) => s.cpuPercent.toDouble()).toList();
    final trafficData = _alignTrafficToSystem(sysHistory, trafficHistory);

    // Auto-scale traffic Y-axis
    final maxTraffic =
        trafficData.isEmpty ? 1.0 : trafficData.reduce((a, b) => a > b ? a : b);
    final trafficMax = maxTraffic < 1 ? 1.0 : maxTraffic * 1.2;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: AppLineChart(
              series: [
                AppChartSeries(
                  label: 'CPU',
                  data: cpuData,
                  filled: true,
                  color: colorScheme.primary,
                ),
                AppChartSeries(
                  label: 'Traffic',
                  data: trafficData,
                  dashed: true,
                  color: colorScheme.tertiary,
                  useSecondaryAxis: true,
                ),
              ],
              yAxis: AppChartAxis(min: 0, max: 100, interval: 25),
              yLabelFormatter: (v) => '${v.toInt()}%',
              secondaryYAxis: AppChartAxis(min: 0, max: trafficMax),
              secondaryYLabelFormatter: (v) => _formatRate(v),
              showTooltip: false,
            ),
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('CPU %'),
            AppGap.lg(),
            _LegendDot(color: colorScheme.tertiary),
            AppGap.xs(),
            AppText.labelSmall('Traffic rate'),
          ],
        ),
      ],
    );
  }

  /// Aligns traffic snapshots to system monitor timestamps.
  List<double> _alignTrafficToSystem(
    List<SystemSnapshot> sysHistory,
    List<MultiInterfaceSnapshot> trafficHistory,
  ) {
    return sysHistory.map((sys) {
      final closest = trafficHistory.reduce((a, b) =>
          (a.timestamp.difference(sys.timestamp).abs() <
                  b.timestamp.difference(sys.timestamp).abs())
              ? a
              : b);
      final wan = closest.interfaces[TrafficInterface.wan];
      return (wan?.uploadBytesPerSec ?? 0) + (wan?.downloadBytesPerSec ?? 0);
    }).toList();
  }

  static String _formatRate(double bytesPerSec) {
    if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSec >= 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${bytesPerSec.toStringAsFixed(0)} B/s';
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
