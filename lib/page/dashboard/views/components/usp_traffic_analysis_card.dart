import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Unified traffic monitor card — real-time WAN speed + multi-interface
/// analysis via 4 tab views.
///
/// - Monitor: WAN upload/download speed tiles + dual-line chart
/// - Comparison (Stacked Bar): WAN vs LAN rate over time
/// - Distribution (Donut): Cumulative traffic proportion
/// - Trends (Dual-Axis Line): Bytes/s + Packets/s
class UspTrafficAnalysisCard extends ConsumerStatefulWidget {
  const UspTrafficAnalysisCard({super.key});

  @override
  ConsumerState<UspTrafficAnalysisCard> createState() =>
      _UspTrafficAnalysisCardState();
}

class _UspTrafficAnalysisCardState
    extends ConsumerState<UspTrafficAnalysisCard> {
  static const _cardId = 'traffic_analysis';

  List<(Duration, String)> _intervalOptions(BuildContext context) => [
        (Duration(seconds: 2), '2s'),
        (Duration(seconds: 5), '5s'),
        (Duration(seconds: 10), '10s'),
      ];

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(uspTrafficAnalysisProvider);
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));

    final latest = analysisState.latest;

    return DashboardCardTemplate.tabbed(
      title: loc(context).trafficMonitor,
      // Current WAN throughput, formatted by the same helper the Monitor tab's
      // speed tiles use — the tile is this card in one number, and this card is
      // about rate. Two dashes while the first poll is still in flight, because
      // `0 B/s` would read as a dead link.
      popupValue: latest == null
          ? '--'
          : _formatSpeed(
              latest.interfaces[TrafficInterface.wan]?.totalBytesPerSec ?? 0),
      footer: _buildStatisticsFooter(context, 0),
      titleBadge: analysisState.isFetching
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
              .read(uspTrafficAnalysisProvider.notifier)
              .setRefreshInterval(interval);
        },
      ),
      selectedTabIndex: selectedTab,
      onTabChanged: (index) =>
          ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
      tabs: [
        CardTab(
          label: loc(context).monitor,
          content: _buildChartView(context, analysisState, 0),
        ),
        CardTab(
          label: loc(context).comparison,
          content: _buildChartView(context, analysisState, 1),
        ),
        CardTab(
          label: loc(context).distribution,
          // Opted into the scroll net (#1296): the only tab of this card that
          // shrink-wraps. The other three hold a chart whose height *is* the
          // card's height (229 -> 773px between 4 and 8 rows), and pinning those
          // to a measured minimum would waste 500+px at the sizes users resize to.
          // This one holds a fixed 180px donut with 67px of slack at the narrowest
          // realization, so a measured height loses nothing and the net catches the
          // locale that eats the slack. See the density design §2.10j.
          scrollable: true,
          content: _buildChartView(context, analysisState, 2),
        ),
        CardTab(
          label: loc(context).trends,
          content: _buildChartView(context, analysisState, 3),
        ),
      ],
    );
  }

  String _intervalLabel(BuildContext context, Duration? interval) {
    if (interval == null) return '—';
    return _intervalOptions(context)
            .where((e) => e.$1 == interval)
            .map((e) => e.$2)
            .firstOrNull ??
        '${interval.inSeconds}s';
  }

  Widget _buildChartView(
    BuildContext context,
    TrafficAnalysisState state,
    int selectedTab,
  ) {
    final hasHistory = state.history.isNotEmpty;
    final latest = state.latest;

    return switch (selectedTab) {
      0 => hasHistory
          ? _MonitorView(
              history: state.history,
              intervalLabel: _intervalLabel(context, state.refreshInterval),
            )
          : _buildEmptyState(context, loc(context).waitingForData),
      1 => hasHistory
          ? _ComparisonView(history: state.history)
          : _buildEmptyState(context, loc(context).collectingActivityData),
      2 => latest != null
          ? _DistributionView(snapshot: latest)
          : _buildEmptyState(context, loc(context).waitingForData),
      3 => hasHistory
          ? _TrendsView(history: state.history)
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
            Semantics(
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
                    AppText.labelMedium(
                      label,
                      color: Theme.of(context).colorScheme.primary,
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
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 0: Monitor (WAN speed tiles + dual-line chart)
// =============================================================================

class _MonitorView extends StatelessWidget {
  final List<MultiInterfaceSnapshot> history;
  final String intervalLabel;

  const _MonitorView({required this.history, required this.intervalLabel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest = history.last;
    final wan = latest.interfaces[TrafficInterface.wan];
    final upload = wan?.uploadBytesPerSec ?? 0;
    final download = wan?.downloadBytesPerSec ?? 0;

    return Column(
      children: [
        // Speed tiles
        Row(
          children: [
            Expanded(
              child: _SpeedTile(
                label: loc(context).upload,
                icon: Icons.arrow_upward,
                bytesPerSec: upload,
                color: colorScheme.primary,
              ),
            ),
            AppGap.md(),
            Expanded(
              child: _SpeedTile(
                label: loc(context).download,
                icon: Icons.arrow_downward,
                bytesPerSec: download,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        AppGap.sm(),
        // WAN line chart
        Expanded(
          child: AppLineChart(
            series: [
              AppChartSeries(
                label: loc(context).upload,
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.wan]?.uploadBytesPerSec ??
                        0.0)
                    .toList(),
                filled: true,
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: loc(context).download,
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.wan]
                            ?.downloadBytesPerSec ??
                        0.0)
                    .toList(),
                color: colorScheme.secondary,
              ),
            ],
            yLabelFormatter: _formatSpeed,
            showTooltip: false,
          ),
        ),
        AppGap.sm(),
        // Legend + totals.
        //
        // DEGRADATION SHAPE (#1226) — T03 replicates this in the six other legend
        // rows, so the reasoning matters as much as the code:
        //
        //  1. A `Wrap`, not a `Row` + `Spacer`. At every width where the content
        //     fits it renders exactly as before: one run, `spaceBetween` puts the
        //     legend left and the totals right, which is what the `Spacer` did.
        //     When it does not fit, the totals drop to a second line instead of
        //     overflowing. The chart above is `Expanded`, so it yields the height.
        //  2. The legend yields before anything else — its labels are `Flexible`
        //     with a one-line ellipsis. A legend is a *key* to a chart that is
        //     already colour-coded, so a clipped label still communicates; each
        //     dot+label pair stays glued together so a label never separates from
        //     the colour it explains.
        //  3. The byte totals never shrink: no `Flexible`, no ellipsis, so they
        //     keep their intrinsic width and wrap as a unit. They are the card's
        //     content, not chrome — a truncated byte count is worse than no byte
        //     count, and unlike the legend it cannot be recovered from the chart.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            // The two entries stay inside one `mainAxisSize: min` `Row` so
            // `spaceBetween` has exactly two children to push apart — the legend
            // and the totals — instead of distributing space between three.
            //
            // Each entry needs a `Flexible` here, and this is the only place in
            // the card that does: a `Row` hands non-flex children unbounded
            // width, and `AppChartLegendEntry` contains a `Flexible` of its own,
            // which throws under an unbounded main axis. A `Wrap` child (every
            // other call site) is already bounded, so it needs none.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppChartLegendEntry.seriesName(
                    mark: const ChartMark.lineFilled(dot: true),
                    color: colorScheme.primary,
                    label: loc(context).upload,
                  ),
                ),
                AppGap.lg(),
                Flexible(
                  child: AppChartLegendEntry.seriesName(
                    mark: const ChartMark.line(dot: true),
                    color: colorScheme.secondary,
                    label: loc(context).download,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (wan != null) ...[
                  // Icons, not the U+2191/U+2193 characters these used to be.
                  // The speed tiles above label the same two directions with
                  // Icons.arrow_upward/downward, so the card was drawing one
                  // concept two ways; and neither the primary font nor any
                  // bundled fallback maps those codepoints, which made the
                  // glyph's presence depend on whatever font happened to
                  // resolve it.
                  AppIcon.font(
                    Icons.arrow_upward,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  AppGap.xs(),
                  AppText.labelSmall(
                    UspFormatters.formatBytes(wan.totalBytesSent),
                    color: colorScheme.onSurfaceVariant,
                  ),
                  AppGap.md(),
                  AppIcon.font(
                    Icons.arrow_downward,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  AppGap.xs(),
                  AppText.labelSmall(
                    UspFormatters.formatBytes(wan.totalBytesReceived),
                    color: colorScheme.onSurfaceVariant,
                  ),
                  AppGap.md(),
                ],
                AppIcon.font(
                  Icons.autorenew,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                AppText.labelSmall(
                  intervalLabel,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SpeedTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final double bytesPerSec;
  final Color color;

  const _SpeedTile({
    required this.label,
    required this.icon,
    required this.bytesPerSec,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon.font(icon, size: 16, color: color),
        AppGap.xs(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.labelSmall(label),
              AppText.titleSmall(_formatSpeed(bytesPerSec)),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 1: Comparison (Stacked Bar — WAN vs LAN rates)
// =============================================================================

class _ComparisonView extends StatelessWidget {
  final List<MultiInterfaceSnapshot> history;
  const _ComparisonView({required this.history});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest = history.last;
    final wanRate =
        latest.interfaces[TrafficInterface.wan]?.totalBytesPerSec ?? 0;
    final lanRate =
        latest.interfaces[TrafficInterface.lan]?.totalBytesPerSec ?? 0;

    return Column(
      children: [
        Expanded(
          child: AppBarChart(
            series: [
              AppChartSeries(
                label: 'WAN',
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.wan]?.totalBytesPerSec ??
                        0.0)
                    .toList(),
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: 'LAN',
                data: history
                    .map((s) =>
                        s.interfaces[TrafficInterface.lan]?.totalBytesPerSec ??
                        0.0)
                    .toList(),
                color: colorScheme.secondary,
              ),
            ],
            stacked: true,
            yLabelFormatter: _formatSpeed,
            showTooltip: false,
          ),
        ),
        AppGap.sm(),
        // Still a centred `Row` rather than a `Wrap`: this row was never one of
        // #1226's overflow coordinates, and #1245 is a de-duplication, not a
        // re-layout. `Flexible` bounds each entry so its internal `Flexible` has
        // a width to work with — and, as a side effect, gives the composed
        // 'WAN: 1.2 MB/s' a second line to fall back on rather than overflowing.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: AppChartLegendEntry.statistic(
                mark: const ChartMark.block(),
                color: colorScheme.primary,
                label: loc(context).wanLabel(_formatSpeed(wanRate)),
              ),
            ),
            AppGap.lg(),
            Flexible(
              child: AppChartLegendEntry.statistic(
                mark: const ChartMark.block(),
                color: colorScheme.secondary,
                label: loc(context).lanLabel(_formatSpeed(lanRate)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Tab 2: Distribution (Donut — cumulative traffic proportion)
// =============================================================================

class _DistributionView extends StatelessWidget {
  final MultiInterfaceSnapshot snapshot;
  const _DistributionView({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final wan = snapshot.interfaces[TrafficInterface.wan];
    final lan = snapshot.interfaces[TrafficInterface.lan];
    final wanTotal = wan?.totalBytes ?? 0;
    final lanTotal = lan?.totalBytes ?? 0;
    final grandTotal = wanTotal + lanTotal;

    return Column(
      children: [
        // Not `Flexible`/`Expanded`: this tab scrolls (#1296), so a vertical flex
        // child here would get unbounded height constraints and throw. The donut
        // is a fixed 180px whatever it is given — measured 180 at 4 rows and at
        // 8 rows, where the slot had grown to 793px — so the flex was distributing
        // air, not sizing the picture.
        Center(
          child: AppPieChart(
            sections: [
              AppPieSection(
                  value: wanTotal.toDouble(),
                  label: 'WAN',
                  color: colorScheme.primary),
              AppPieSection(
                  value: lanTotal.toDouble(),
                  label: 'LAN',
                  color: colorScheme.secondary),
            ],
            donut: true,
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.titleSmall(UspFormatters.formatBytes(grandTotal)),
                AppText.labelSmall(loc(context).total,
                    color: colorScheme.onSurfaceVariant),
              ],
            ),
            size: 180,
          ),
        ),
        AppGap.sm(),
        // Per-interface upload/download bars
        if (wan != null || lan != null)
          _InterfaceBreakdownBars(wan: wan, lan: lan),
        AppGap.sm(),
        // `.swatch()`, because these two key donut sections rather than a line or
        // bar series. Same centred `Row` + `Flexible` shape as the Comparison
        // tab; this tab is also in the scroll net (#1296), so the entries must
        // not gain height they cannot pay for — `cardContentScrollShortfall`
        // asserts 0.0 on arrival in `card_scroll_net_test.dart`.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: AppChartLegendEntry.statistic(
                mark: const ChartMark.swatch(),
                color: colorScheme.primary,
                label: loc(context).wanLabel(
                  UspFormatters.formatBytes(wanTotal),
                ),
              ),
            ),
            AppGap.lg(),
            Flexible(
              child: AppChartLegendEntry.statistic(
                mark: const ChartMark.swatch(),
                color: colorScheme.secondary,
                label: loc(context).lanLabel(
                  UspFormatters.formatBytes(lanTotal),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InterfaceBreakdownBars extends StatelessWidget {
  final InterfaceTrafficSnapshot? wan;
  final InterfaceTrafficSnapshot? lan;

  const _InterfaceBreakdownBars({this.wan, this.lan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = <(String, int, int, Color)>[];
    if (wan != null) {
      entries.add((
        'WAN',
        wan!.totalBytesSent,
        wan!.totalBytesReceived,
        colorScheme.primary
      ));
    }
    if (lan != null) {
      entries.add((
        'LAN',
        lan!.totalBytesSent,
        lan!.totalBytesReceived,
        colorScheme.secondary
      ));
    }

    final maxBytes = entries.fold(0, (a, e) => math.max(a, e.$2 + e.$3));

    return Column(
      children: [
        for (final (label, sent, recv, color) in entries)
          Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: AppText.labelSmall(label, textAlign: TextAlign.end),
                ),
                AppGap.sm(),
                Expanded(
                  child: _DualBar(
                    sent: sent,
                    recv: recv,
                    maxValue: maxBytes,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DualBar extends StatelessWidget {
  final int sent;
  final int recv;
  final int maxValue;
  final Color color;

  const _DualBar({
    required this.sent,
    required this.recv,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final total = sent + recv;
    final fraction = maxValue > 0 ? total / maxValue : 0.0;
    final sentFraction = total > 0 ? sent / total : 0.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * fraction;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: barWidth,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(
                  width: barWidth * sentFraction,
                  color: color,
                ),
                Expanded(
                  child: Container(color: color.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Tab 3: Trends (Dual-Axis Line — Bytes/s + Packets/s)
// =============================================================================

class _TrendsView extends StatelessWidget {
  final List<MultiInterfaceSnapshot> history;
  const _TrendsView({required this.history});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _DualAxisLinePainter(
                  context: context,
                  history: history,
                ),
              );
            },
          ),
        ),
        AppGap.sm(),
        // This tab's chart is a hand-written `CustomPaint`, so the marks are read
        // off `_DualAxisLinePainter` rather than off `AppChartSeries`: the bytes
        // series is drawn as a gradient-filled line with a dot per point, the
        // packets series as a dashed line with dots, and the two used to be keyed
        // by a dot and a bare 16×2 `Container` — the closest this card came to
        // drawing its own mark. `.seriesName`, because both labels are bare unit
        // names carrying no digits.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: AppChartLegendEntry.seriesName(
                mark: const ChartMark.lineFilled(dot: true),
                color: colorScheme.primary,
                label: loc(context).bytesPerSec,
              ),
            ),
            AppGap.lg(),
            Flexible(
              child: AppChartLegendEntry.seriesName(
                mark: const ChartMark.line(dashed: true, dot: true),
                color: colorScheme.tertiary,
                label: loc(context).packetsPerSec,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

String _formatSpeed(double bytesPerSec) {
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  var value = bytesPerSec;
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unitIndex]}';
}

// =============================================================================
// CustomPainter: Dual-Axis Line (Bytes/s left, Packets/s right)
// =============================================================================

class _DualAxisLinePainter extends CustomPainter {
  final BuildContext context;
  final List<MultiInterfaceSnapshot> history;

  _DualAxisLinePainter({
    required this.context,
    required this.history,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final colorScheme = Theme.of(context).colorScheme;
    const padding = EdgeInsets.only(left: 52, right: 52, top: 8, bottom: 20);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    // Collect WAN bytes/s and packets/s
    final byteRates = history
        .map((s) => s.interfaces[TrafficInterface.wan]?.totalBytesPerSec ?? 0.0)
        .toList();
    final packetRates = history
        .map((s) =>
            s.interfaces[TrafficInterface.wan]?.totalPacketsPerSec ?? 0.0)
        .toList();

    final bytesMax = _niceMaxBytes(
        byteRates.isEmpty ? 0 : byteRates.reduce((a, b) => math.max(a, b)));
    final packetsMax = _niceMaxPackets(
        packetRates.isEmpty ? 0 : packetRates.reduce((a, b) => math.max(a, b)));

    // Grid
    _drawDualGrid(canvas, chartRect, colorScheme, bytesMax, packetsMax);

    // Bytes/s line (solid, left axis)
    _drawLine(
      canvas,
      chartRect,
      byteRates,
      colorScheme.primary,
      yMax: bytesMax,
      dashed: false,
    );

    // Packets/s line (dashed, right axis)
    _drawLine(
      canvas,
      chartRect,
      packetRates,
      colorScheme.tertiary,
      yMax: packetsMax,
      dashed: true,
    );
  }

  void _drawDualGrid(Canvas canvas, Rect rect, ColorScheme colorScheme,
      double bytesMax, double packetsMax) {
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final labelStyle =
        TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant);

    for (final pct in [0.0, 0.5, 1.0]) {
      final y = rect.bottom - pct * rect.height;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);

      // Left Y-axis: bytes/s
      final bytesVal = bytesMax * pct;
      final byteTp = TextPainter(
        text: TextSpan(text: _formatBytesLabel(bytesVal), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      byteTp.paint(
          canvas, Offset(rect.left - byteTp.width - 4, y - byteTp.height / 2));

      // Right Y-axis: packets/s
      final pktsVal = packetsMax * pct;
      final pktTp = TextPainter(
        text: TextSpan(text: _formatPacketsLabel(pktsVal), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      pktTp.paint(canvas, Offset(rect.right + 4, y - pktTp.height / 2));
    }
  }

  void _drawLine(
    Canvas canvas,
    Rect rect,
    List<double> values,
    Color color, {
    required double yMax,
    required bool dashed,
  }) {
    if (values.isEmpty) return;

    final count = values.length;
    final stepX = count > 1 ? rect.width / (count - 1) : rect.width;
    final path = Path();

    for (int i = 0; i < count; i++) {
      final x = rect.left + i * stepX;
      final ratio = yMax > 0 ? (values[i] / yMax).clamp(0.0, 1.0) : 0.0;
      final y = rect.bottom - ratio * rect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = color);
    }

    if (dashed) {
      _drawDashedPath(canvas, path, color);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      // Gradient fill for solid line
      final fillPath = Path.from(path);
      fillPath.lineTo(rect.left + (count - 1) * stepX, rect.bottom);
      fillPath.lineTo(rect.left, rect.bottom);
      fillPath.close();
      final gradient = ui.Gradient.linear(
        Offset(0, rect.top),
        Offset(0, rect.bottom),
        [color.withValues(alpha: 0.2), color.withValues(alpha: 0.02)],
      );
      canvas.drawPath(fillPath, Paint()..shader = gradient);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Color color) {
    final metrics = path.computeMetrics();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashLength = 6.0;
    const gapLength = 4.0;

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance = end + gapLength;
      }
    }
  }

  static double _niceMaxBytes(double rawMax) {
    if (rawMax <= 0) return 1024;
    const steps = [
      1024.0,
      10240.0,
      102400.0,
      524288.0,
      1048576.0,
      5242880.0,
      10485760.0,
      52428800.0,
      104857600.0,
      1073741824.0,
    ];
    for (final step in steps) {
      if (rawMax <= step) return step;
    }
    return rawMax * 1.1;
  }

  static double _niceMaxPackets(double rawMax) {
    if (rawMax <= 0) return 100;
    const steps = [100.0, 500.0, 1000.0, 5000.0, 10000.0, 50000.0, 100000.0];
    for (final step in steps) {
      if (rawMax <= step) return step;
    }
    return rawMax * 1.1;
  }

  static String _formatBytesLabel(double bytesPerSec) {
    if (bytesPerSec >= 1048576) {
      final mb = bytesPerSec / 1048576;
      return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB/s';
    } else if (bytesPerSec >= 1024) {
      final kb = bytesPerSec / 1024;
      return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB/s';
    }
    return '${bytesPerSec.toStringAsFixed(0)} B/s';
  }

  static String _formatPacketsLabel(double pktsPerSec) {
    if (pktsPerSec >= 1000) {
      return '${(pktsPerSec / 1000).toStringAsFixed(1)}K';
    }
    return pktsPerSec.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _DualAxisLinePainter old) =>
      history.length != old.history.length ||
      (history.isNotEmpty &&
          old.history.isNotEmpty &&
          history.last.timestamp != old.history.last.timestamp);
}
