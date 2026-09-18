import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// WiFi signal quality per band — radar chart (>= 3 bands) or bar fallback.
class StatsSignalQualitySection extends ConsumerStatefulWidget {
  const StatsSignalQualitySection({super.key});

  @override
  ConsumerState<StatsSignalQualitySection> createState() =>
      _StatsSignalQualitySectionState();
}

class _StatsSignalQualitySectionState
    extends ConsumerState<StatsSignalQualitySection> {
  int? _touchedAxisIndex;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uspDeviceAnalyticsProvider);
    final current = state.current;

    return StatsSectionCard(
      title: loc(context).signalQuality,
      subtitle: loc(context).signalQualitySubtitle,
      chartHeight: 280,
      child: current == null || current.bandSignalQuality.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                loc(context).noWifiSignalData,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, current),
    );
  }

  Widget _buildChart(BuildContext context, DeviceDistribution distribution) {
    final colorScheme = Theme.of(context).colorScheme;
    final bands = distribution.bandSignalQuality;
    final useRadar = bands.length >= 3;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: useRadar
                ? AppRadarChart(
                    series: [
                      AppRadarSeries(
                        label: loc(context).signalQuality,
                        data: bands.values.map((v) => v * 100).toList(),
                        color: colorScheme.primary,
                        filled: true,
                      ),
                    ],
                    axisLabels: bands.keys.toList(),
                    tickCount: 4,
                    onTouch: (event) {
                      setState(() {
                        if (event.type == AppChartTouchType.exit ||
                            event.touchedPoints.isEmpty) {
                          _touchedAxisIndex = null;
                        } else {
                          _touchedAxisIndex =
                              event.touchedPoints.first.dataIndex;
                        }
                      });
                    },
                  )
                : AppBarChart(
                    series: [
                      AppChartSeries(
                        label: loc(context).signal,
                        data: bands.values.map((v) => v * 100).toList(),
                        color: colorScheme.primary,
                      ),
                    ],
                    xLabels: bands.keys.toList(),
                    yAxis: AppChartAxis(min: 0, max: 100, interval: 25),
                    yLabelFormatter: (v) => '${v.toInt()}%',
                    showValueLabels: true,
                    valueLabelFormatter: (v) => '${v.toInt()}%',
                  ),
          ),
        ),
        AppGap.sm(),
        if (_touchedAxisIndex != null && _touchedAxisIndex! < bands.length) ...[
          _RadarTooltipRow(
            band: bands.keys.elementAt(_touchedAxisIndex!),
            quality: bands.values.elementAt(_touchedAxisIndex!),
            color: colorScheme.primary,
          ),
        ] else if (distribution.signalLevelDistribution.isNotEmpty)
          // DEGRADATION SHAPE (#1488) — the worst of the four legend rows that
          // ticket measured: 26 of 26 locales overflow at a 320px screen, up to
          // 190px in `ru`, and `ru` at 480px is the coordinate golden CI
          // reported. It is the worst because its child count is data-driven —
          // all four quality levels present means four inflexible groups in one
          // centred `Row`, in 238px.
          //
          // A `Wrap`, for the reason #1252 gives on this page's Traffic Monitor
          // legend: at every width where the groups fit it renders exactly as
          // before (one run, centred), and where they do not, a group drops to a
          // second line instead of overflowing. The chart above is `Expanded`, so
          // it yields the height.
          //
          // The labels themselves are neither `Flexible` nor ellipsized: each one
          // ends in a device count, and an ellipsis lands mid-number
          // (density design §2.10a point 2). Reflowing the row moves the counts;
          // it never shortens them. `spacing` replaces the per-group trailing
          // `AppGap.md`, which also stops the last gap from pushing the centred
          // run off-centre.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry in [
                (3, loc(context).excellent, colorScheme.primary),
                (2, loc(context).good, Colors.lightGreen),
                (1, loc(context).fair, Colors.orange),
                (0, loc(context).poor, colorScheme.error),
              ])
                // One lookup, bound: the previous `containsKey` + `[...]` pair read
                // the map twice and interpolated an `int?`, so a level present with
                // a null count would have rendered "Excellent: null" instead of
                // being left out.
                if (distribution.signalLevelDistribution[entry.$1]
                    case final count?)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatsLegendDot(color: entry.$3),
                      AppGap.xs(),
                      AppText.labelSmall('${entry.$2}: $count'),
                    ],
                  ),
            ],
          ),
      ],
    );
  }
}

class _RadarTooltipRow extends StatelessWidget {
  final String band;
  final double quality;
  final Color color;
  const _RadarTooltipRow({
    required this.band,
    required this.quality,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatsLegendDot(color: color),
        AppGap.xs(),
        AppText.labelSmall('$band: ${(quality * 100).toInt()}%'),
      ],
    );
  }
}
