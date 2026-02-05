import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/external_speed_test_links.dart';
import 'package:privacy_gui/page/dashboard/views/components/widgets/parts/internal_speed_test_result.dart';
import 'package:privacy_gui/page/health_check/models/health_check_enum.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_ui_model.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/health_check/shared_widgets/speed_test_widget.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying speed test results.
///
/// For custom layout (Bento Grid) only.
class CustomSpeedTest extends DisplayModeConsumerWidget {
  const CustomSpeedTest({
    super.key,
    super.displayMode,
  });

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 200,
        DisplayMode.expanded => 300,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    // Compact: Minimal view with just download/upload stats + controls
    final healthCheckState = ref.watch(healthCheckProvider);
    final result = healthCheckState.latestSpeedTest ??
        healthCheckState.result ??
        SpeedTestUIModel.empty();
    final isRunning = healthCheckState.status == HealthCheckStatus.running;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        2, // Very tight vertical padding for 1-row
        AppSpacing.md,
        2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCompactStat(
                      context,
                      icon: Icons.arrow_downward,
                      value: result.downloadSpeed,
                      unit: result.downloadUnit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Container(
                      width: 1,
                      height: 20, // Reduced height
                      color: Theme.of(context).dividerColor,
                    ),
                    _buildCompactStat(
                      context,
                      icon: Icons.arrow_upward,
                      value: result.uploadSpeed,
                      unit: result.uploadUnit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              AppGap.xs(), // Reduced gap
              SizedBox(
                width: 28, // Reduced button size
                height: 28,
                child: isRunning
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : IconButton(
                        onPressed: () {
                          ref
                              .read(healthCheckProvider.notifier)
                              .runHealthCheck(Module.speedtest);
                        },
                        icon: const Icon(Icons.play_arrow, size: 20),
                        padding: EdgeInsets.zero,
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: 'Start Speed Test',
                      ),
              ),
            ],
          ),
          // Removed gap for tighter layout
          if (healthCheckState.status != HealthCheckStatus.idle)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _getStatusText(context, healthCheckState),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(BuildContext context, HealthCheckState state) {
    if (state.status == HealthCheckStatus.running) {
      if (state.step == HealthCheckStep.latency) {
        return 'Measuring Latency...';
      }
      if (state.step == HealthCheckStep.downloadBandwidth) {
        return 'Downloading...';
      }
      if (state.step == HealthCheckStep.uploadBandwidth) {
        return 'Uploading...';
      }
      return 'Running...';
    }
    if (state.status == HealthCheckStatus.complete) {
      return 'Completed';
    }
    if (state.status == HealthCheckStatus.idle) {
      if (state.latestSpeedTest != null) {
        return 'Last run: ${state.latestSpeedTest!.timestamp}';
      }
      return 'Ready';
    }
    return '';
  }

  Widget _buildCompactStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
        AppGap.sm(),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelLarge(value),
            AppText.labelSmall(
              unit,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    return _buildContent(context, ref, isCompact: false);
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    return _buildContent(context, ref, isCompact: false, isExpanded: true);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref, {
    bool isCompact = false,
    bool isExpanded = false,
  }) {
    final state = ref.watch(dashboardHomeProvider);
    final hasLanPort = state.lanPortConnections.isNotEmpty;
    final isRemote = BuildConfig.isRemote();
    final healthCheckState = ref.watch(healthCheckProvider);
    final isHealthCheckSupported = healthCheckState.isSpeedTestModuleSupported;

    if (isHealthCheckSupported) {
      // Internal Speed Test
      if (hasLanPort) {
        if (isExpanded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section: Meter + Key Stats
                // Top Section: Meter + Key Stats
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Meter (Left 60%)
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: SpeedTestWidget(
                          showDetails: false,
                          showInfoPanel:
                              false, // Hide built-in info, we show manual
                          showStepDescriptions: false,
                          showLatestOnIdle: true,
                          layout: SpeedTestLayout.vertical,
                          meterSize:
                              180, // Slightly larger meter since we have space
                          showResultSummary:
                              false, // Hide redundant summary to prevent overflow
                        ),
                      ),
                    ),
                    const VerticalDivider(indent: 10, endIndent: 10),
                    // Big Stats (Right 40%)
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.lg),
                        child: _BigStatsPanel(
                          state: healthCheckState,
                          result: healthCheckState.result ??
                              healthCheckState.latestSpeedTest ??
                              SpeedTestUIModel.empty(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),

                // Middle Section: Details (Date, Server, Ping)
                _DetailsPanel(
                  result: healthCheckState.result ??
                      healthCheckState.latestSpeedTest ??
                      SpeedTestUIModel.empty(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Bottom Section: History Chart (Taller)
                SizedBox(
                  height: 220, // Increased height
                  child: _HistoryChart(
                    history: healthCheckState.historicalSpeedTests,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: SpeedTestWidget(
            showDetails: false,
            showInfoPanel:
                false, // Hide info panel in Normal mode for cleaner look
            showStepDescriptions: false,
            // Show latest results in both Normal and Expanded modes
            showLatestOnIdle: true,
            layout: SpeedTestLayout.vertical,
            // Dynamic meter size: 240 for Normal (Vertical layout in 250px height)
            meterSize: 240,
          ),
        );
      } else {
        return InternalSpeedTestResult(state: state);
      }
    }

    // External Links (Legacy/Remote)
    return Tooltip(
      message: loc(context).featureUnavailableInRemoteMode,
      child: Opacity(
        opacity: isRemote ? 0.5 : 1,
        child: AbsorbPointer(
          absorbing: isRemote,
          child: ExternalSpeedTestLinks(state: state),
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<SpeedTestUIModel> history;

  const _HistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No history available',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Prepare data points (reversed because history is usually new -> old)
    // We want display left (old) -> right (new)
    final data = history.reversed.toList();

    // Max 10 points to keep chart readable
    final displayData =
        data.length > 10 ? data.sublist(data.length - 10) : data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall('Speed History (${displayData.length} runs)'),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _HistoryChartPainter(
                  context: context,
                  data: displayData,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
                color: Theme.of(context).colorScheme.primary,
                label: loc(context).download),
            const SizedBox(width: AppSpacing.lg),
            _LegendItem(
                color: Theme.of(context).colorScheme.secondary,
                label: loc(context).upload),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        AppText.labelSmall(label),
      ],
    );
  }
}

class _HistoryChartPainter extends CustomPainter {
  final BuildContext context;
  final List<SpeedTestUIModel> data;

  _HistoryChartPainter({required this.context, required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 20.0;
    final chartRect = Rect.fromLTWH(
        padding, padding, size.width - padding * 2, size.height - padding * 2);

    // Extract values (parse string if kbps is missing, but simpler to rely on parsing logic or just 0)
    // SpeedTestUIModel has downloadSpeed string "xxx.x" and units.
    // Ideally we use uploadBandwidthKbps if available.
    final downloads = data.map((e) {
      if (e.downloadBandwidthKbps != null && e.downloadBandwidthKbps! > 0) {
        return e.downloadBandwidthKbps! / 1024.0; // Mbps
      }
      // Fallback to parsing string value
      final speed = double.tryParse(e.downloadSpeed) ?? 0;
      if (e.downloadUnit.toUpperCase() == 'KBPS') {
        return speed / 1024.0;
      }
      return speed; // Assume Mbps
    }).toList();

    final uploads = data.map((e) {
      if (e.uploadBandwidthKbps != null && e.uploadBandwidthKbps! > 0) {
        return e.uploadBandwidthKbps! / 1024.0; // Mbps
      }
      // Fallback to parsing string value
      final speed = double.tryParse(e.uploadSpeed) ?? 0;
      if (e.uploadUnit.toUpperCase() == 'KBPS') {
        return speed / 1024.0;
      }
      return speed; // Assume Mbps
    }).toList();

    // If kbps is null/0, try parsing string (fallback)
    for (int i = 0; i < data.length; i++) {
      if (downloads[i] == 0) {
        downloads[i] = double.tryParse(data[i].downloadSpeed) ?? 0;
      }
      if (uploads[i] == 0) {
        uploads[i] = double.tryParse(data[i].uploadSpeed) ?? 0;
      }
    }

    final allValues = [...downloads, ...uploads];
    final maxY = allValues.isEmpty
        ? 100.0
        : allValues.reduce((a, b) => a > b ? a : b) * 1.2; // 20% buffer

    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final gridColor =
        Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5);

    // Draw Grid
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Horizontal lines (0, 50%, 100%)
    canvas.drawLine(Offset(chartRect.left, chartRect.bottom),
        Offset(chartRect.right, chartRect.bottom), paintGrid);
    canvas.drawLine(
        Offset(chartRect.left, chartRect.top + chartRect.height * 0.5),
        Offset(chartRect.right, chartRect.top + chartRect.height * 0.5),
        paintGrid);
    canvas.drawLine(Offset(chartRect.left, chartRect.top),
        Offset(chartRect.right, chartRect.top), paintGrid);

    // Draw Lines
    _drawLine(canvas, chartRect, downloads, maxY, primaryColor, true);
    _drawLine(canvas, chartRect, uploads, maxY, secondaryColor, false);
  }

  void _drawLine(Canvas canvas, Rect rect, List<double> values, double maxY,
      Color color, bool isFilled) {
    if (values.isEmpty) return;

    final path = Path();
    final stepX = rect.width / (values.length - 1 == 0 ? 1 : values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = rect.left + i * stepX;
      final y =
          rect.bottom - (values[i] / (maxY == 0 ? 1 : maxY)) * rect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }

    // Stroke
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // Fill (Optional, maybe gradient?)
    if (isFilled) {
      path.lineTo(rect.right, rect.bottom);
      path.lineTo(rect.left, rect.bottom);
      path.close();
      canvas.drawPath(
          path,
          Paint()
            ..color = color.withOpacity(0.1)
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BigStatsPanel extends StatelessWidget {
  final HealthCheckState state;
  final SpeedTestUIModel result;

  const _BigStatsPanel({required this.state, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.timestamp == '--' && state.status == HealthCheckStatus.idle) {
      return Center(
        child: AppText.bodyMedium(
          'Run a speed test to see details',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Text (e.g. "Running...", "Completed")
        if (state.status == HealthCheckStatus.running)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppText.titleSmall(
              _getStatusText(context, state),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

        // Main Result (Download / Upload) - Using Wrap to prevent overflow
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _buildBigStat(context, 'Download', result.downloadSpeed,
                result.downloadUnit, Theme.of(context).colorScheme.primary),
            _buildBigStat(context, 'Upload', result.uploadSpeed,
                result.uploadUnit, Theme.of(context).colorScheme.secondary),
          ],
        ),
      ],
    );
  }

  String _getStatusText(BuildContext context, HealthCheckState state) {
    if (state.step == HealthCheckStep.latency) return 'Measuring Latency...';
    if (state.step == HealthCheckStep.downloadBandwidth)
      return 'Downloading...';
    if (state.step == HealthCheckStep.uploadBandwidth) return 'Uploading...';
    return 'Running...';
  }

  Widget _buildBigStat(BuildContext context, String label, String value,
      String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelSmall(label,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AppText.headlineSmall(value, color: color),
            const SizedBox(width: 4),
            AppText.labelSmall(unit, color: color),
          ],
        ),
      ],
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  final SpeedTestUIModel result;

  const _DetailsPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    // Detailed Info
    return Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.md,
      children: [
        _buildDetailItem(context, 'Date', result.timestamp),
        _buildDetailItem(context, 'Server', result.serverId),
        _buildDetailItem(context, 'Ping', '${result.latency} ms'),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelSmall(label,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        AppText.titleSmall(value),
      ],
    );
  }
}
