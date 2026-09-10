import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
      title: loc(context).deviceDistribution,
      subtitle: loc(context).deviceDistributionSubtitle,
      chartHeight: 320,
      child: state.current == null
          ? Center(
              child: AppText.bodyMedium(
                loc(context).waitingForDeviceData,
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
                    label: loc(context).wifi,
                    color: colorScheme.primary),
                AppPieSection(
                    value: distribution.wiredCount.toDouble(),
                    label: loc(context).wired,
                    color: colorScheme.secondary),
              ],
              defaultCenter: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium('${distribution.onlineCount}'),
                  AppText.labelSmall(loc(context).online,
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
        // DEGRADATION SHAPE (#1488) — three inflexible groups in a centred `Row`
        // overflowed 238px in 5 of 26 locales (worst `el`, 28px). A `Wrap` for
        // the same reason as this page's other three legend rows: it is identical
        // to the `Row` wherever the groups fit, and drops the offline count to a
        // second line where they do not. The pie chart above is `Flexible`, so it
        // yields the height.
        //
        // Every label ends in a client count, so none of the three is `Flexible`
        // or ellipsized — the row reflows, the numbers stay whole.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatsLegendDot(color: colorScheme.primary),
                AppGap.xs(),
                AppText.labelSmall(
                    loc(context).wifiCount(distribution.wifiCount)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatsLegendDot(color: colorScheme.secondary),
                AppGap.xs(),
                AppText.labelSmall(
                    loc(context).wiredCount(distribution.wiredCount)),
              ],
            ),
            AppText.labelSmall(
              loc(context).nOffline(distribution.offlineCount),
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
