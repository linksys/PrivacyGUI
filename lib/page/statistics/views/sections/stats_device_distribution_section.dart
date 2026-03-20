import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// WiFi vs Wired donut + band distribution bars.
class StatsDeviceDistributionSection extends ConsumerWidget {
  const StatsDeviceDistributionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspDeviceAnalyticsProvider);

    return StatsSectionCard(
      title: 'Device Distribution',
      subtitle: 'WiFi vs Wired device breakdown',
      chartHeight: 320,
      child: state.current == null
          ? Center(
              child: AppText.bodyMedium(
                'Waiting for device data...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, state.current!),
    );
  }

  Widget _buildChart(BuildContext context, DeviceDistribution distribution) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Flexible(
          child: Center(
            child: InteractivePieChart(
              sections: [
                AppPieSection(
                    value: distribution.wifiCount.toDouble(),
                    label: 'WiFi',
                    color: colorScheme.primary),
                AppPieSection(
                    value: distribution.wiredCount.toDouble(),
                    label: 'Wired',
                    color: colorScheme.secondary),
              ],
              defaultCenter: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium('${distribution.onlineCount}'),
                  AppText.labelSmall('online',
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
              touchedCenterLabel: (section, _) => '${section.value.toInt()}',
              size: 180,
            ),
          ),
        ),
        AppGap.sm(),
        if (distribution.bandDistribution.isNotEmpty)
          _BandDistributionBars(
              bandDistribution: distribution.bandDistribution),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('WiFi: ${distribution.wifiCount}'),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Wired: ${distribution.wiredCount}'),
            AppGap.lg(),
            AppText.labelSmall(
              '${distribution.offlineCount} offline',
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }
}

class _BandDistributionBars extends StatelessWidget {
  final Map<String, int> bandDistribution;
  const _BandDistributionBars({required this.bandDistribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = bandDistribution.values.fold(0, (a, b) => a > b ? a : b);
    final seriesColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
    ];

    return Column(
      children: [
        for (var i = 0; i < bandDistribution.entries.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: AppText.labelSmall(
                    bandDistribution.entries.elementAt(i).key,
                    textAlign: TextAlign.end,
                  ),
                ),
                AppGap.sm(),
                Expanded(
                  child: _HorizontalBar(
                    value: bandDistribution.entries.elementAt(i).value,
                    maxValue: maxCount,
                    color: seriesColors[i % seriesColors.length],
                  ),
                ),
                AppGap.sm(),
                SizedBox(
                  width: 20,
                  child: AppText.labelSmall(
                    '${bandDistribution.entries.elementAt(i).value}',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HorizontalBar extends StatelessWidget {
  final int value;
  final int maxValue;
  final Color color;
  const _HorizontalBar(
      {required this.value, required this.maxValue, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: constraints.maxWidth * fraction,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
