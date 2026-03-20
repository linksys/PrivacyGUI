import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Firewall Configuration Overview card — 2-tab security overview.
///
/// - Rules: Firewall rule target distribution (donut) + summary stats
/// - Ports: Port forwarding list + protocol distribution bar chart
class UspFirewallOverviewCard extends ConsumerWidget {
  const UspFirewallOverviewCard({super.key});

  static const _cardId = 'firewall_overview';

  static const _tabs = [
    TabItem(label: 'Rules'),
    TabItem(label: 'Ports'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firewall rules + DMZ from domain data provider (Layer 1).
    final firewallData = ref.watch(firewallDataProvider).valueOrNull;
    // Port forwarding from domain data provider (Layer 1).
    final pfData = ref.watch(portForwardingDataProvider).valueOrNull;
    if (firewallData == null) return const CardSkeleton.chart();
    final selectedTab = ref.watch(cardTabIndexProvider(_cardId));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Firewall Overview'),
          AppGap.md(),
          AppTabs(
            tabs: _tabs,
            initialIndex: selectedTab,
            displayMode: TabDisplayMode.segmented,
            showBorder: false,
            onTabChanged: (index) =>
                ref.read(cardTabIndexProvider(_cardId).notifier).state = index,
          ),
          AppGap.md(),
          Expanded(
            child: switch (selectedTab) {
              0 => _RulesTab(
                  ruleSummaries: firewallData.ruleSummaries,
                  portForwardingCount: pfData?.ruleModels.length ?? 0,
                  dmzCount:
                      firewallData.dmzSummaries.where((d) => d.enable).length,
                ),
              1 => _PortsTab(
                  portForwardingRules: pfData?.ruleModels ?? [],
                  dmzSummaries: firewallData.dmzSummaries,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 1: Rules — target distribution donut + summary
// =============================================================================

class _RulesTab extends StatelessWidget {
  final List<FirewallRuleSummary> ruleSummaries;
  final int portForwardingCount;
  final int dmzCount;

  const _RulesTab({
    required this.ruleSummaries,
    required this.portForwardingCount,
    required this.dmzCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (ruleSummaries.isEmpty) {
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
    for (final rule in ruleSummaries) {
      final target = rule.target.isNotEmpty ? rule.target : 'Other';
      targetCounts[target] = (targetCounts[target] ?? 0) + 1;
      if (rule.enabled) activeCount++;
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
                value: '$activeCount/${ruleSummaries.length}'),
            _StatChip(label: 'Port Fwd', value: '$portForwardingCount'),
            _StatChip(label: 'DMZ', value: '$dmzCount'),
          ],
        ),
        AppGap.md(),
        // Donut chart
        Expanded(
          child: Center(
            child: AppPieChart(
              sections: sections,
              donut: true,
              centerWidget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium('${ruleSummaries.length}'),
                  AppText.labelSmall('Rules',
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
              size: 160,
            ),
          ),
        ),
        AppGap.sm(),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < targetCounts.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: seriesColors[i % seriesColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
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

// =============================================================================
// Tab 2: Ports — forwarding list + protocol bar chart
// =============================================================================

class _PortsTab extends StatelessWidget {
  final List portForwardingRules;
  final List<DmzEntrySummary> dmzSummaries;

  const _PortsTab({
    required this.portForwardingRules,
    required this.dmzSummaries,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (portForwardingRules.isEmpty && dmzSummaries.isEmpty) {
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
      final proto = rule.protocol as String;
      protocolCounts[proto] = (protocolCounts[proto] ?? 0) + 1;
    }

    // Active DMZ entries
    final activeDmz = dmzSummaries.where((d) => d.enable).toList();

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
                        '${rule.portSummary} \u2192 ${rule.internalClient}',
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
              showTooltip: false,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

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
