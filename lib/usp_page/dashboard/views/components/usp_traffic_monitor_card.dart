import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/transforms.g.dart';
import 'package:privacy_gui/usp_page/dashboard/models/traffic_monitor_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_traffic_monitor_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Real-time WAN traffic monitor card with dual-line chart (upload/download).
class UspTrafficMonitorCard extends ConsumerWidget {
  const UspTrafficMonitorCard({super.key});

  static final _intervalOptions = <(Duration?, String)>[
    (null, 'Off'),
    (Duration(seconds: 2), '2s'),
    (Duration(seconds: 5), '5s'),
    (Duration(seconds: 10), '10s'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorState = ref.watch(uspTrafficMonitorProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final latest = monitorState.latest;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title + spinner + interval selector
          Row(
            children: [
              AppText.titleMedium('Traffic Monitor'),
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
                      .read(uspTrafficMonitorProvider.notifier)
                      .setRefreshInterval(interval);
                },
              ),
            ],
          ),
          AppGap.md(),

          // Speed tiles
          Row(
            children: [
              Expanded(
                child: _SpeedTile(
                  label: 'Upload',
                  icon: Icons.arrow_upward,
                  bytesPerSec: latest?.uploadBytesPerSec ?? 0,
                  color: colorScheme.primary,
                ),
              ),
              AppGap.md(),
              Expanded(
                child: _SpeedTile(
                  label: 'Download',
                  icon: Icons.arrow_downward,
                  bytesPerSec: latest?.downloadBytesPerSec ?? 0,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          AppGap.lg(),

          // Chart
          if (monitorState.history.isEmpty)
            _buildEmptyState(context)
          else
            _buildChart(context, monitorState),
          AppGap.sm(),

          // Legend + totals
          _buildLegend(context, monitorState),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: AppText.bodyMedium(
          'Waiting for data...',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, TrafficMonitorState monitorState) {
    return SizedBox(
      height: 200,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, 200),
            painter: _TrafficChartPainter(
              context: context,
              history: monitorState.history,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context, TrafficMonitorState monitorState) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest = monitorState.latest;
    final intervalLabel = _intervalOptions
            .where((e) => e.$1 == monitorState.refreshInterval)
            .map((e) => e.$2)
            .firstOrNull ??
        'Off';

    return Column(
      children: [
        Row(
          children: [
            _LegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('Upload'),
            AppGap.lg(),
            _LegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Download'),
            const Spacer(),
            if (monitorState.refreshInterval != null) ...[
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
          ],
        ),
        if (latest != null) ...[
          AppGap.xs(),
          Row(
            children: [
              AppText.labelSmall(
                'Total \u2191 ${Transforms.formatBytes(latest.totalBytesSent)}',
                color: colorScheme.onSurfaceVariant,
              ),
              AppGap.lg(),
              AppText.labelSmall(
                'Total \u2193 ${Transforms.formatBytes(latest.totalBytesReceived)}',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Displays a speed value with auto-scaled units (B/s → KB/s → MB/s → GB/s).
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

  static String _formatSpeed(double bytesPerSec) {
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var value = bytesPerSec;
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unitIndex]}';
  }
}

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

/// CustomPainter for upload & download trend lines with auto-scaled Y axis.
class _TrafficChartPainter extends CustomPainter {
  final BuildContext context;
  final List<TrafficSnapshot> history;

  _TrafficChartPainter({
    required this.context,
    required this.history,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final colorScheme = Theme.of(context).colorScheme;
    const padding = EdgeInsets.only(left: 52, right: 12, top: 8, bottom: 20);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    // Auto-scale Y axis based on max rate
    final allRates = [
      ...history.map((s) => s.uploadBytesPerSec),
      ...history.map((s) => s.downloadBytesPerSec),
    ];
    final rawMax = allRates.reduce((a, b) => a > b ? a : b);
    final yMax = _niceMax(rawMax);

    _drawGrid(canvas, chartRect, colorScheme, yMax);
    _drawYLabels(canvas, chartRect, colorScheme, yMax);

    final uploadValues = history.map((s) => s.uploadBytesPerSec).toList();
    final downloadValues = history.map((s) => s.downloadBytesPerSec).toList();

    // Download line (below, no fill)
    _drawLine(
      canvas,
      chartRect,
      downloadValues,
      colorScheme.secondary,
      yMax: yMax,
      filled: false,
    );
    // Upload line (on top, with gradient fill)
    _drawLine(
      canvas,
      chartRect,
      uploadValues,
      colorScheme.primary,
      yMax: yMax,
      filled: true,
    );
  }

  /// Round up to a "nice" value for the Y axis.
  double _niceMax(double rawMax) {
    if (rawMax <= 0) return 1024; // Minimum 1 KB/s
    // Round up to next power-of-two-ish step
    const steps = [
      1024.0, // 1 KB/s
      10240.0, // 10 KB/s
      102400.0, // 100 KB/s
      524288.0, // 512 KB/s
      1048576.0, // 1 MB/s
      5242880.0, // 5 MB/s
      10485760.0, // 10 MB/s
      52428800.0, // 50 MB/s
      104857600.0, // 100 MB/s
      1073741824.0, // 1 GB/s
    ];
    for (final step in steps) {
      if (rawMax <= step) return step;
    }
    return rawMax * 1.1;
  }

  void _drawGrid(
      Canvas canvas, Rect rect, ColorScheme colorScheme, double yMax) {
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    for (final pct in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = rect.bottom - pct * rect.height;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  void _drawYLabels(
      Canvas canvas, Rect rect, ColorScheme colorScheme, double yMax) {
    final style = TextStyle(
      fontSize: 10,
      color: colorScheme.onSurfaceVariant,
    );

    for (final pct in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final value = yMax * pct;
      final y = rect.bottom - pct * rect.height;
      final tp = TextPainter(
        text: TextSpan(text: _formatAxisLabel(value), style: style),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.left - tp.width - 4, y - tp.height / 2));
    }
  }

  String _formatAxisLabel(double bytesPerSec) {
    if (bytesPerSec >= 1048576) {
      final mb = bytesPerSec / 1048576;
      return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB/s';
    } else if (bytesPerSec >= 1024) {
      final kb = bytesPerSec / 1024;
      return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB/s';
    } else {
      return '${bytesPerSec.toStringAsFixed(0)} B/s';
    }
  }

  void _drawLine(
    Canvas canvas,
    Rect rect,
    List<double> values,
    Color color, {
    required double yMax,
    required bool filled,
  }) {
    if (values.isEmpty) return;

    final path = Path();
    final count = values.length;
    final stepX = count > 1 ? rect.width / (count - 1) : rect.width;

    for (int i = 0; i < count; i++) {
      final x = rect.left + i * stepX;
      final ratio = yMax > 0 ? (values[i] / yMax).clamp(0.0, 1.0) : 0.0;
      final y = rect.bottom - ratio * rect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Point marker
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = color);
    }

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Gradient fill
    if (filled) {
      final fillPath = Path.from(path);
      fillPath.lineTo(rect.left + (count - 1) * stepX, rect.bottom);
      fillPath.lineTo(rect.left, rect.bottom);
      fillPath.close();

      final gradient = ui.Gradient.linear(
        Offset(0, rect.top),
        Offset(0, rect.bottom),
        [color.withValues(alpha: 0.3), color.withValues(alpha: 0.02)],
      );

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrafficChartPainter oldDelegate) {
    return history.length != oldDelegate.history.length ||
        (history.isNotEmpty &&
            oldDelegate.history.isNotEmpty &&
            history.last.timestamp != oldDelegate.history.last.timestamp);
  }
}
