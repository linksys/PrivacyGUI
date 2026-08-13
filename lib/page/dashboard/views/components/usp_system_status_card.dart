import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The diameter the Monitor tab's CPU/memory gauges are drawn at whenever the
/// card is wide enough to hold two of them side by side. Narrower realizations
/// scale down from here; see `_MonitorView.build`.
const double _kMonitorGaugeSize = 100;

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

  List<(Duration, String)> _intervalOptions(BuildContext context) => [
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

    return DashboardCardTemplate.tabbed(
      title: loc(context).systemStatus,
      footer: _buildStatisticsFooter(context, 2),
      titleBadge: monitorState.isFetching
          ? SizedBox(
              width: 14,
              height: 14,
              child: AppLoader(strokeWidth: 2),
            )
          : null,
      trailing: AppPopupMenu<Duration?>(
        icon: Icons.timer_outlined,
        iconSize: 20,
        items: _intervalOptions(context)
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
      selectedTabIndex: selectedTab,
      onTabChanged: (index) =>
          ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
      tabs: [
        CardTab(
          label: loc(context).monitor,
          content: _MonitorView(info: info, monitorState: monitorState),
        ),
        CardTab(
          label: loc(context).trends,
          content: monitorState.history.isNotEmpty
              ? _TrendsView(monitorState: monitorState)
              : _buildEmptyState(context, loc(context).waitingForData),
        ),
        CardTab(
          label: loc(context).distribution,
          content: monitorState.history.isNotEmpty
              ? _DistributionView(monitorState: monitorState)
              : _buildEmptyState(context, loc(context).waitingForData),
        ),
        CardTab(
          label: loc(context).correlation,
          content: _CorrelationView(monitorState: monitorState, ref: ref),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: AppText.bodyMedium(
        message,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildStatisticsFooter(BuildContext context, int tabIndex) {
    final label = loc(context).viewDetails;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDivider(),
        AppGap.md(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Both `Flexible`s are #1227's detail-footer shape, replicated
            // verbatim from `DashboardCardTemplate._buildDetailFooter`. Safe to
            // flex the link here for the reason given there: the row is
            // end-aligned, so a short link's unused share is stranded at the
            // *start* where it is invisible, and a row that already fits lays
            // out exactly as before.
            Flexible(
              child: Semantics(
                button: true,
                label: label,
                child: InkWell(
                  onTap: () => context.pushNamed(
                    RouteNamed.uspStatistics,
                    queryParameters: {'tab': tabIndex.toString()},
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The arrow keeps its 14px; the label is what shortens.
                      Flexible(
                        child: AppText.labelMedium(
                          label,
                          color: Theme.of(context).colorScheme.primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppGap.xs(),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
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
// Tab 1: Monitor (Gauges + Uptime)
// =============================================================================

class _MonitorView extends StatelessWidget {
  final SystemInfoUIModel info;
  final SystemMonitorState monitorState;

  const _MonitorView({required this.info, required this.monitorState});

  String _formatIntervalLabel(BuildContext context, Duration? interval) {
    if (interval == null) return '—';
    if (interval.inSeconds == 10) return '10s';
    if (interval.inSeconds == 30) return '30s';
    if (interval.inSeconds == 60) return '60s';
    return '${interval.inSeconds}s';
  }

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

    final intervalLabel =
        _formatIntervalLabel(context, monitorState.refreshInterval);

    return Column(
      children: [
        UspInfoRow(
          label: loc(context).uptime,
          value: latest?.formattedUptime ?? info.formattedUptime,
        ),
        AppGap.md(),
        // Two `AppGauge(size: 100)` in a `spaceEvenly` row is the one overflow
        // on this branch that no amount of `Flexible` can fix: the children are
        // not text that can give, they are two circles asking for 200px inside
        // a box measured at **157.4px** at the card's narrowest realization.
        // Hence the constant +43.0px in all 26 locales — this shape is
        // geometry-bound, not translation-bound, and `en` overflows exactly as
        // much as `el`.
        //
        // Stacking them (a `Wrap`) was measured and rejected, and the
        // measurement is worth keeping: two 100px runs plus spacing need ~208px
        // against the 201px (`en`) / 181px (`de`) this `Expanded` offers, and
        // **nothing reports the difference**. `RenderWrap` has no overflow
        // indicator of its own, and the `Expanded` pins its height, so the
        // second circle is simply clipped — 108px between centres inside a
        // 181px box, with all 209 gate cases green. So the circles shrink
        // instead, which is the only option that keeps both readings side by
        // side at every width, and the guard for that lives in
        // `usp_gauge_center_readability_test.dart` rather than in the gate.
        //
        // `math.min` against the natural size makes this an upper bound rather
        // than an allotment (§2.6a point 1's idiom): every width that already
        // fitted two 100px gauges still renders them at exactly 100px, so the
        // wide layouts are untouched and only the narrow one changes. The
        // height term is what protects the fix from #1266's failure mode — the
        // row enumeration can hand this `Expanded` less height than the gauge's
        // own diameter, and a circle taller than its box would overflow the
        // bottom instead. Both `Infinity` cases (unbounded width, unbounded
        // height) degrade to the natural size.
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gaugeSize = math.min(
                _kMonitorGaugeSize,
                math.min(
                  // `AppSpacing.md` is the narrowest gap that still reads as
                  // two separate gauges rather than a figure of eight.
                  (constraints.maxWidth - AppSpacing.md) / 2,
                  constraints.maxHeight,
                ),
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGauge(context,
                      value: cpuPercent.toDouble(),
                      label: loc(context).cpu,
                      display: '$cpuPercent%',
                      size: gaugeSize),
                  _buildGauge(context,
                      value: memPercent.toDouble(),
                      label: loc(context).memory,
                      display: '$memPercent%',
                      size: gaugeSize),
                ],
              );
            },
          ),
        ),
        AppGap.sm(),
        Center(
          child: AppText.bodySmall(
            loc(context).memoryUsed(memUsedStr, memTotalStr),
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppGap.md(),
        // The fourth legend row on this card, and the last to get #1226's shape
        // — #1233 converted the other three (Trends / Distribution /
        // Correlation) and left this one because it also carries the refresh
        // chrome. Labels are composed statistics (`CPU: 47%`), so they
        // soft-wrap rather than ellipsize (§2.10a point 2), which is what
        // `_StatLegendEntry` does by default.
        //
        // §2.10a point 3's precondition holds here, and was measured rather
        // than assumed: the `Expanded` above hands the gauge row **221px**
        // (202px in `ru`) for 100px of gauge, so it can pay for a second and
        // third run out of slack without squeezing the gauges — the opposite of
        // `network_health`, whose `Expanded` holds a gauge of exactly its own
        // fixed height and yields nothing.
        //
        // `SizedBox(width: double.infinity)` is load-bearing, per §2.10c
        // finding 3: a `Wrap` sizes itself to its widest run, and this `Column`
        // is `CrossAxisAlignment.center`, so without a tight width the legend
        // would shrink-wrap and drift to the centre of the card at every width
        // — a pure visual regression that overflows nothing and that the gate
        // would pass either way.
        //
        // What this row does give up: the interval chip's flush-right position.
        // A `Wrap` cannot hold a `Spacer`, and `WrapAlignment.spaceBetween`
        // would distribute space between *all three* children, pulling the two
        // legend entries apart instead — a bigger change to the wide layout
        // than moving a 20px chip. So the chip joins the flow as the last
        // entry, and every width down to the narrowest keeps the same reading
        // order.
        SizedBox(
          width: double.infinity,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _StatLegendEntry(
                color: colorScheme.primary,
                label: loc(context).cpuPercent('${latest?.cpuPercent ?? '--'}'),
              ),
              _StatLegendEntry(
                color: colorScheme.secondary,
                label: loc(context)
                    .memoryPercent('${latest?.memoryPercent ?? '--'}'),
              ),
              // Grouped in a `mainAxisSize: min` `Row` for the same reason a
              // legend entry is: as two bare `Wrap` children the icon and its
              // interval would be separated by `spacing` and could land on
              // different runs.
              if (monitorState.refreshInterval != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon.font(Icons.autorenew,
                        size: 12, color: colorScheme.onSurfaceVariant),
                    AppText.labelSmall(intervalLabel,
                        color: colorScheme.onSurfaceVariant),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGauge(
    BuildContext context, {
    required double value,
    required String label,
    required String display,
    required double size,
  }) {
    return AppGauge(
      value: value,
      size: size,
      // `centerBuilder`'s widget becomes a non-positioned `Stack` child inside
      // `AppGauge`, so it is handed loose `size × size` constraints — this
      // `Column` is the app's own closure and the whole fix lives at this call
      // site, with no ui_kit change to ask for.
      //
      // Since the circle now shrinks with the card, the label has to be told
      // what to do when it no longer fits: `Arbeitsspeicher` is 88.1px of
      // `bodySmall` and the narrowest circle is 70.7px across. Left alone it
      // soft-wraps mid-word inside the arc — a degradation the gate cannot see,
      // because a `Column` reports overflow only in its own axis and this one
      // has 70.7px of height for ~40px of text. Ellipsis, not wrap, per §2.10a
      // point 2: the label is a bare series *name*, and the reading it names is
      // `display` right above it, which keeps its full size and full text. The
      // full label is still on screen unabbreviated — the legend row below
      // spells out `Arbeitsspeicher: 73%` and soft-wraps to do it.
      centerBuilder: (ctx, v) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleMedium(display),
          AppText.bodySmall(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
                  label: loc(context).cpu,
                  data: cpuValues,
                  filled: true,
                  color: colorScheme.primary,
                ),
                AppChartSeries(
                  label: loc(context).memory,
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
        // Legend. Degradation shape per #1226 (see usp_traffic_analysis_card.dart
        // for the full reasoning), adapted: this row has no totals to keep at
        // full size, so every child is a legend entry and the `Wrap` is centred
        // rather than `spaceBetween`. Entries stay glued dot-to-label, and the
        // whole entry wraps to a second run before any label truncates — these
        // labels are `Avg: 42%  Peak: 87%`, statistics rather than a series
        // name, so an ellipsis would cut a number in half.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _StatLegendEntry(
              color: colorScheme.primary,
              label: loc(context).avgPeak(avgCpu, peakCpu),
            ),
            _StatLegendEntry(
              color: colorScheme.secondary,
              label: loc(context).avg(avgMem),
            ),
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
        // A single entry, so there is nothing to wrap between — but the label is
        // the longest of the four tabs ('CPU-Auslastungsstichproben: 37'), and a
        // bare centred `Row` overflows on it. `Wrap` lets the entry keep its
        // intrinsic width and `_StatLegendEntry` lets the label take a second
        // line rather than truncate the sample count.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _StatLegendEntry(
              color: colorScheme.primary,
              label: loc(context).cpuUsageSamples(history.length),
            ),
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
          loc(context).waitingForData,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final trafficHistory = trafficState.history;
    if (trafficHistory.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          loc(context).enableTrafficMonitorForCorrelation,
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
                  label: loc(context).cpu,
                  data: cpuData,
                  filled: true,
                  color: colorScheme.primary,
                ),
                AppChartSeries(
                  label: loc(context).traffic,
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
        // Unlike the other three tabs these labels are bare series names, not
        // statistics — so this is #1226's case exactly, and the entries carry its
        // one-line ellipsis: a clipped 'Traffic rate' still keys the chart,
        // because the colour does the identifying and no digits are lost.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            _StatLegendEntry(
              color: colorScheme.primary,
              label: loc(context).cpu,
              ellipsize: true,
            ),
            _StatLegendEntry(
              color: colorScheme.tertiary,
              label: loc(context).trafficRate,
              ellipsize: true,
            ),
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

/// One legend entry: colour dot, gap, label — the unit that must never split, so
/// a label never separates from the colour it explains (#1226 rule 2).
///
/// File-private on purpose. The same shape exists in `usp_network_health_card`
/// (as `_LegendEntry`) and `usp_traffic_analysis_card`, and extracting one shared
/// widget from the four copies needs Article XIV approval — #1233 deliberately
/// does not block on that conversation, so the shape is replicated in place and
/// the extraction raised separately.
class _StatLegendEntry extends StatelessWidget {
  final Color color;
  final String label;

  /// Whether the label may be clipped to one line to make the entry fit.
  ///
  /// Only safe when the label is a bare **series name** — the chart is already
  /// colour-coded, so a clipped name still keys it (#1226 rule 2). Off by
  /// default because most of this card's legend labels are composed statistics
  /// (`Avg: 42%  Peak: 87%`), where an ellipsis would cut a number in half; those
  /// soft-wrap onto a second line instead, which the `Expanded` chart above pays
  /// for.
  final bool ellipsize;

  const _StatLegendEntry({
    required this.color,
    required this.label,
    this.ellipsize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: color),
        AppGap.xs(),
        // `Flexible`, not a bare `AppText`, and not for the ellipsis alone: a
        // `Row` hands non-flex children *unbounded* width, so a bare label takes
        // its full intrinsic width on one line and overflows regardless of the
        // enclosing `Wrap`. The `Wrap` can move a whole entry to the next run,
        // but only `Flexible` lets the label itself give.
        //
        // Flexible is loose-fit, so the `Row` still hugs a short label and two
        // entries share one run whenever they fit — the wide-layout rendering is
        // unchanged.
        Flexible(
          child: AppText.labelSmall(
            label,
            maxLines: ellipsize ? 1 : null,
            overflow: ellipsize ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }
}
