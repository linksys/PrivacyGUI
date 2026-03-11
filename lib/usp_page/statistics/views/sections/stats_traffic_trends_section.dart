import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/traffic_analysis_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dual-axis line chart: Bytes/s (left) + Packets/s (right).
class StatsTrafficTrendsSection extends ConsumerWidget {
  const StatsTrafficTrendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: 'Traffic Trends',
      subtitle: 'Bytes/s and Packets/s dual-axis view',
      chartHeight: 280,
      child: state.history.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                'Collecting data...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state.history),
    );
  }

  Widget _buildChart(
      BuildContext context, List<MultiInterfaceSnapshot> history) {
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
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('Bytes/s'),
            AppGap.lg(),
            Container(width: 16, height: 2, color: colorScheme.tertiary),
            AppGap.xs(),
            AppText.labelSmall('Pkts/s'),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// CustomPainter: Dual-Axis Line (Bytes/s left, Packets/s right)
// =============================================================================

class _DualAxisLinePainter extends CustomPainter {
  final BuildContext context;
  final List<MultiInterfaceSnapshot> history;

  _DualAxisLinePainter({required this.context, required this.history});

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

    final byteRates = history
        .map(
            (s) => s.interfaces[TrafficInterface.wan]?.totalBytesPerSec ?? 0.0)
        .toList();
    final packetRates = history
        .map((s) =>
            s.interfaces[TrafficInterface.wan]?.totalPacketsPerSec ?? 0.0)
        .toList();

    final bytesMax = _niceMaxBytes(
        byteRates.isEmpty ? 0 : byteRates.reduce((a, b) => math.max(a, b)));
    final packetsMax = _niceMaxPackets(packetRates.isEmpty
        ? 0
        : packetRates.reduce((a, b) => math.max(a, b)));

    _drawDualGrid(canvas, chartRect, colorScheme, bytesMax, packetsMax);
    _drawLine(canvas, chartRect, byteRates, colorScheme.primary,
        yMax: bytesMax, dashed: false);
    _drawLine(canvas, chartRect, packetRates, colorScheme.tertiary,
        yMax: packetsMax, dashed: true);
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
      canvas.drawLine(
          Offset(rect.left, y), Offset(rect.right, y), gridPaint);

      final bytesVal = bytesMax * pct;
      final byteTp = TextPainter(
        text: TextSpan(text: _formatBytesLabel(bytesVal), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      byteTp.paint(canvas,
          Offset(rect.left - byteTp.width - 4, y - byteTp.height / 2));

      final pktsVal = packetsMax * pct;
      final pktTp = TextPainter(
        text: TextSpan(text: _formatPacketsLabel(pktsVal), style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      pktTp.paint(canvas, Offset(rect.right + 4, y - pktTp.height / 2));
    }
  }

  void _drawLine(Canvas canvas, Rect rect, List<double> values, Color color,
      {required double yMax, required bool dashed}) {
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
            ..style = PaintingStyle.stroke);
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
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  static double _niceMaxBytes(double rawMax) {
    if (rawMax <= 0) return 1024;
    const steps = [
      1024.0, 10240.0, 102400.0, 524288.0, 1048576.0,
      5242880.0, 10485760.0, 52428800.0, 104857600.0, 1073741824.0,
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
    if (pktsPerSec >= 1000) return '${(pktsPerSec / 1000).toStringAsFixed(1)}K';
    return pktsPerSec.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _DualAxisLinePainter old) =>
      history.length != old.history.length ||
      (history.isNotEmpty &&
          old.history.isNotEmpty &&
          history.last.timestamp != old.history.last.timestamp);
}
