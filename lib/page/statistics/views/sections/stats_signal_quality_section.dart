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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final entry in [
                (3, loc(context).excellent, colorScheme.primary),
                (2, loc(context).good, Colors.lightGreen),
                (1, loc(context).fair, Colors.orange),
                (0, loc(context).poor, colorScheme.error),
              ]) ...[
                if (distribution.signalLevelDistribution
                    .containsKey(entry.$1)) ...[
                  StatsLegendDot(color: entry.$3),
                  AppGap.xs(),
                  AppText.labelSmall(
                    '${entry.$2}: ${distribution.signalLevelDistribution[entry.$1]}',
                  ),
                  AppGap.md(),
                ],
              ],
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
