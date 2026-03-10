import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/transforms.g.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_monitor_state.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_info_row.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Combined System Status + Monitor card.
/// Shows gauges (CPU/Memory), uptime, trend chart, and auto-refresh controls.
class UspSystemStatusCard extends ConsumerWidget {
  final SystemInfoUIModel? info;

  const UspSystemStatusCard({super.key, this.info});

  static final _intervalOptions = <(Duration?, String)>[
    (null, 'Off'),
    (Duration(seconds: 10), '10s'),
    (Duration(seconds: 30), '30s'),
    (Duration(minutes: 1), '60s'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = this.info ??
        ref.watch(uspDashboardProvider).valueOrNull?.systemInfoModel;
    if (info == null) return const SizedBox.shrink();
    final monitorState = ref.watch(uspSystemMonitorProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final latest = monitorState.latest;

    // Use live monitor data when available, fallback to dashboard info
    final cpuPercent = latest?.cpuPercent ?? info.cpuPercent;
    final memPercent = latest?.memoryPercent ?? info.memoryPercent;
    final memUsedStr = latest != null
        ? Transforms.formatBytes(latest.usedMemoryKb * 1024)
        : info.formattedUsedMemory;
    final memTotalStr = latest != null
        ? Transforms.formatBytes(latest.totalMemoryKb * 1024)
        : info.formattedTotalMemory;

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
          AppGap.md(),

          // Uptime
          UspInfoRow(label: 'Uptime', value: info.formattedUptime),
          AppGap.md(),

          // Gauges — synced with monitor's latest snapshot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGauge(
                context,
                value: cpuPercent.toDouble(),
                label: 'CPU',
                display: '$cpuPercent%',
              ),
              _buildGauge(
                context,
                value: memPercent.toDouble(),
                label: 'Memory',
                display: '$memPercent%',
              ),
            ],
          ),
          AppGap.sm(),
          Center(
            child: AppText.bodySmall(
              '$memUsedStr / $memTotalStr used',
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppGap.lg(),

          // Chart
          if (monitorState.history.isEmpty)
            _buildEmptyState(context)
          else
            _buildChart(context, monitorState),
          AppGap.sm(),

          // Legend (no sample count)
          _buildLegend(context, monitorState),
        ],
      ),
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

  Widget _buildChart(BuildContext context, SystemMonitorState monitorState) {
    return SizedBox(
      height: 200,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, 200),
            painter: _SystemMonitorChartPainter(
              context: context,
              history: monitorState.history,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(BuildContext context, SystemMonitorState monitorState) {
    final colorScheme = Theme.of(context).colorScheme;
    final latest = monitorState.latest;
    final intervalLabel = _intervalOptions
            .where((e) => e.$1 == monitorState.refreshInterval)
            .map((e) => e.$2)
            .firstOrNull ??
        'Off';

    return Row(
      children: [
        _LegendDot(color: colorScheme.primary),
        AppGap.xs(),
        AppText.labelSmall(
          'CPU: ${latest?.cpuPercent ?? '--'}%',
        ),
        AppGap.lg(),
        _LegendDot(color: colorScheme.secondary),
        AppGap.xs(),
        AppText.labelSmall(
          'Memory: ${latest?.memoryPercent ?? '--'}%',
        ),
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
    );
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

/// CustomPainter for CPU & Memory trend lines (0-100% fixed Y axis).
class _SystemMonitorChartPainter extends CustomPainter {
  final BuildContext context;
  final List<SystemSnapshot> history;

  _SystemMonitorChartPainter({
    required this.context,
    required this.history,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final colorScheme = Theme.of(context).colorScheme;
    const padding = EdgeInsets.only(left: 36, right: 12, top: 8, bottom: 20);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    _drawGrid(canvas, chartRect, colorScheme);
    _drawYLabels(canvas, chartRect, colorScheme);

    final cpuValues = history.map((s) => s.cpuPercent.toDouble()).toList();
    final memValues = history.map((s) => s.memoryPercent.toDouble()).toList();

    // Memory line (below CPU, no fill)
    _drawLine(
      canvas,
      chartRect,
      memValues,
      colorScheme.secondary,
      filled: false,
    );
    // CPU line (on top, with gradient fill)
    _drawLine(
      canvas,
      chartRect,
      cpuValues,
      colorScheme.primary,
      filled: true,
    );
  }

  void _drawGrid(Canvas canvas, Rect rect, ColorScheme colorScheme) {
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    // Horizontal grid lines at 0%, 25%, 50%, 75%, 100%
    for (final pct in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = rect.bottom - pct * rect.height;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }
  }

  void _drawYLabels(Canvas canvas, Rect rect, ColorScheme colorScheme) {
    final style = TextStyle(
      fontSize: 10,
      color: colorScheme.onSurfaceVariant,
    );

    for (final pct in [0, 25, 50, 75, 100]) {
      final y = rect.bottom - (pct / 100) * rect.height;
      final tp = TextPainter(
        text: TextSpan(text: '$pct%', style: style),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rect.left - tp.width - 4, y - tp.height / 2));
    }
  }

  void _drawLine(
    Canvas canvas,
    Rect rect,
    List<double> values,
    Color color, {
    required bool filled,
  }) {
    if (values.isEmpty) return;

    final path = Path();
    final count = values.length;
    final stepX = count > 1 ? rect.width / (count - 1) : rect.width;

    for (int i = 0; i < count; i++) {
      final x = rect.left + i * stepX;
      final y = rect.bottom - (values[i] / 100) * rect.height;
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
  bool shouldRepaint(covariant _SystemMonitorChartPainter oldDelegate) {
    return history.length != oldDelegate.history.length ||
        (history.isNotEmpty &&
            oldDelegate.history.isNotEmpty &&
            history.last.timestamp != oldDelegate.history.last.timestamp);
  }
}
