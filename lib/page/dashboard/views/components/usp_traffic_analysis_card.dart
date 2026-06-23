import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
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

  List<(Duration?, String)> _intervalOptions(BuildContext context) => [
        (null, loc(context).off),
        (Duration(seconds: 2), '2s'),
        (Duration(seconds: 5), '5s'),
        (Duration(seconds: 10), '10s'),
      ];

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(uspTrafficAnalysisProvider);
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));

    return DashboardCardTemplate.tabbed(
      title: loc(context).trafficMonitor,
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
    return _intervalOptions(context)
            .where((e) => e.$1 == interval)
            .map((e) => e.$2)
            .firstOrNull ??
        loc(context).off;
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
        // Legend + totals
        Row(
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall(loc(context).upload),
            AppGap.lg(),
            _LegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall(loc(context).download),
            const Spacer(),
            if (wan != null) ...[
              AppText.labelSmall(
                '\u2191 ${UspFormatters.formatBytes(wan.totalBytesSent)}',
                color: colorScheme.onSurfaceVariant,
              ),
              AppGap.md(),
              AppText.labelSmall(
                '\u2193 ${UspFormatters.formatBytes(wan.totalBytesReceived)}',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall(loc(context).wanLabel(_formatSpeed(wanRate))),
            AppGap.lg(),
            _LegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall(loc(context).lanLabel(_formatSpeed(lanRate))),
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
        Flexible(
          child: Center(
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
        ),
        AppGap.sm(),
        // Per-interface upload/download bars
        if (wan != null || lan != null)
          _InterfaceBreakdownBars(wan: wan, lan: lan),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall(
                loc(context).wanLabel(UspFormatters.formatBytes(wanTotal))),
            AppGap.lg(),
            _LegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall(
                loc(context).lanLabel(UspFormatters.formatBytes(lanTotal))),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall(loc(context).bytesPerSec),
            AppGap.lg(),
            Container(
              width: 16,
              height: 2,
              color: colorScheme.tertiary,
            ),
            AppGap.xs(),
            AppText.labelSmall(loc(context).packetsPerSec),
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
