import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/usp_page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/usp_page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Port forwarding list + protocol distribution bar chart.
class StatsPortMappingSection extends ConsumerWidget {
  const StatsPortMappingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pfData = ref.watch(portForwardingDataProvider).valueOrNull;
    final fwData = ref.watch(firewallDataProvider).valueOrNull;

    return StatsSectionCard(
      title: 'Port Mapping',
      subtitle: 'Port forwarding rules and DMZ configuration',
      chartHeight: 360,
      child: (pfData == null && fwData == null)
          ? Center(
              child: AppText.bodyMedium(
                'Loading...',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, pfData, fwData),
    );
  }

  Widget _buildChart(BuildContext context, PortForwardingData? pfData, FirewallData? fwData) {
    final colorScheme = Theme.of(context).colorScheme;
    final portForwardingRules = pfData?.ruleModels ?? [];
    final dmzEntries = fwData?.dmzEntries.items ?? [];

    if (portForwardingRules.isEmpty && dmzEntries.isEmpty) {
      return Center(
        child: AppText.bodyMedium(
          'No port mappings configured',
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Protocol distribution
    final protocolCounts = <String, int>{};
    for (final rule in portForwardingRules) {
      final proto = rule.protocol;
      protocolCounts[proto] = (protocolCounts[proto] ?? 0) + 1;
    }

    final activeDmz = dmzEntries.where((d) => d.enable).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Port forwarding list (top 5)
        if (portForwardingRules.isNotEmpty) ...[
          AppText.labelLarge('Port Forwarding (${portForwardingRules.length})'),
          AppGap.sm(),
          ...portForwardingRules.take(5).map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    UspStatusDot(isActive: rule.enabled),
                    AppGap.sm(),
                    _ProtocolBadge(protocol: rule.protocol),
                    AppGap.sm(),
                    Expanded(
                      child: AppText.bodySmall(
                        rule.portSummary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
        // DMZ section
        if (activeDmz.isNotEmpty) ...[
          AppGap.md(),
          AppText.labelLarge('DMZ'),
          AppGap.sm(),
          ...activeDmz.map((d) => Row(
                children: [
                  UspStatusDot(isActive: true),
                  AppGap.sm(),
                  AppText.bodySmall('Target: ${d.destIp}'),
                ],
              )),
        ],
        // Protocol distribution bar chart
        if (protocolCounts.isNotEmpty) ...[
          AppGap.md(),
          Expanded(
            child: AppBarChart(
              series: [
                AppChartSeries(
                  label: 'Rules',
                  data: protocolCounts.values.map((v) => v.toDouble()).toList(),
                  color: colorScheme.primary,
                ),
              ],
              xLabels: protocolCounts.keys.toList(),
              showValueLabels: true,
              valueLabelFormatter: (v) => '${v.toInt()}',
            ),
          ),
        ],
      ],
    );
  }
}

class _ProtocolBadge extends StatelessWidget {
  final String protocol;
  const _ProtocolBadge({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: AppText.labelSmall(
        protocol,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
