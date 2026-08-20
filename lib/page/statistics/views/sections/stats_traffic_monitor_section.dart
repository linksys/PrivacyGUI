import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Real-time WAN upload/download speed tiles + dual-line chart.
class StatsTrafficMonitorSection extends ConsumerWidget {
  const StatsTrafficMonitorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspTrafficAnalysisProvider);

    return StatsSectionCard(
      title: loc(context).trafficMonitor,
      subtitle: loc(context).trafficMonitorSubtitle,
      chartHeight: 280,
      child: state.history.isEmpty
          ? _emptyState(context, loc(context).waitingForTrafficData)
          : _buildChart(context, state),
    );
  }

  Widget _buildChart(BuildContext context, TrafficAnalysisState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final history = state.history;
    final wan = history.last.interfaces[TrafficInterface.wan];
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
            tooltipFormatter: statsFormatSpeedTooltip,
            enableZoom: true,
          ),
        ),
        AppGap.sm(),
        // Legend + totals.
        //
        // DEGRADATION SHAPE (#1252, the twin of #1226's dashboard card) — this
        // row is a near-duplicate of the Traffic Analysis Monitor legend, so it
        // takes the identical treatment (design \u00a72.10, \u00a72.10a):
        //
        //  1. A `Wrap`, not a `Row` + `Spacer`. At every width where the content
        //     fits it renders exactly as before: one run, `spaceBetween` puts the
        //     legend left and the totals right, which is what the `Spacer` did.
        //     When it does not fit, the totals drop to a second line instead of
        //     overflowing. The chart above is `Expanded`, so it yields the height
        //     (\u00a72.10a point 3: this is the unstated precondition #1226 relied on;
        //     unlike Network Health's fixed-height gauge, this chart yields).
        //  2. The legend yields before anything else — its labels are `Flexible`
        //     with a one-line ellipsis. A legend keys a chart that is already
        //     colour-coded, so a clipped label still communicates; each dot+label
        //     pair stays glued together so a label never separates from the
        //     colour it explains.
        //  3. The byte totals never shrink: no `Flexible`, no ellipsis, so they
        //     keep their intrinsic width and wrap as a unit. They are the card's
        //     content, not chrome — an ellipsis lands mid-number and a half-shown
        //     statistic misinforms in a way a missing one does not.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatsLegendDot(color: colorScheme.primary),
                AppGap.xs(),
                Flexible(
                  child: AppText.labelSmall(
                    loc(context).upload,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppGap.lg(),
                StatsLegendDot(color: colorScheme.secondary),
                AppGap.xs(),
                Flexible(
                  child: AppText.labelSmall(
                    loc(context).download,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (wan != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icons, not U+2191/U+2193 characters — matches the dashboard's
                  // Traffic Analysis card, which draws the same two directions
                  // with Icons.arrow_upward/downward.
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
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    return Center(
      child: AppText.bodyMedium(
        message,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
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
