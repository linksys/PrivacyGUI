import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/usp_page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Firewall rule target distribution donut + summary stats.
class StatsFirewallRulesSection extends ConsumerWidget {
  const StatsFirewallRulesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fwData = ref.watch(firewallDataProvider).valueOrNull;
    final pfCount =
        ref.watch(portForwardingDataProvider).valueOrNull?.ruleModels.length ?? 0;

    return StatsSectionCard(
      title: 'Firewall Rules',
      subtitle: 'Rule target distribution and security overview',
      chartHeight: 320,
      child: fwData == null
          ? Center(
              child: AppText.bodyMedium(
                'Loading...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, fwData, pfCount),
    );
  }

  Widget _buildChart(BuildContext context, FirewallData fwData, int portForwardingCount) {
    final colorScheme = Theme.of(context).colorScheme;
    final firewallRules = fwData.chainRules.items;
    final dmzCount =
        fwData.dmzEntries.items.where((d) => d.enable).length;

    if (firewallRules.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No firewall rules configured',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Aggregate by target
    final targetCounts = <String, int>{};
    int activeCount = 0;
    for (final rule in firewallRules) {
      final target = rule.target.isNotEmpty ? rule.target : 'Other';
      targetCounts[target] = (targetCounts[target] ?? 0) + 1;
      if (rule.enable) activeCount++;
    }

    final seriesColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
    ];

    final sections = targetCounts.entries.indexed.map((e) {
      final (i, entry) = e;
      return AppPieSection(
        value: entry.value.toDouble(),
        label: entry.key,
        color: seriesColors[i % seriesColors.length],
      );
    }).toList();

    return Column(
      children: [
        // Summary stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatChip(
                label: 'FW Rules',
                value: '$activeCount/${firewallRules.length}'),
            _StatChip(label: 'Port Fwd', value: '$portForwardingCount'),
            _StatChip(label: 'DMZ', value: '$dmzCount'),
          ],
        ),
        AppGap.md(),
        Expanded(
          child: Center(
            child: InteractivePieChart(
              sections: sections,
              defaultCenter: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium('${firewallRules.length}'),
                  AppText.labelSmall('Rules',
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
              touchedCenterLabel: (section, _) => '${section.value.toInt()}',
              size: 160,
            ),
          ),
        ),
        AppGap.sm(),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < targetCounts.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatsLegendDot(color: seriesColors[i % seriesColors.length]),
                  AppGap.xs(),
                  AppText.labelSmall(
                    '${targetCounts.keys.elementAt(i)}: ${targetCounts.values.elementAt(i)}',
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.titleMedium(value),
        AppText.labelSmall(label,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }
}
