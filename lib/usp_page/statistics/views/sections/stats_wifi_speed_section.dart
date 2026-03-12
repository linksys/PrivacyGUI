import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/statistics/views/components/stats_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Grouped DL/UL bar chart per WiFi client.
class StatsWifiSpeedSection extends ConsumerWidget {
  const StatsWifiSpeedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspDashboardProvider).valueOrNull;
    if (state == null) {
      return StatsSectionCard(
        title: 'WiFi Client Speed',
        subtitle: 'Downlink/Uplink rates per client',
        chartHeight: 260,
        child: Center(
          child: AppText.bodyMedium(
            'Loading...',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final activeClients = _buildClientList(state);

    return StatsSectionCard(
      title: 'WiFi Client Speed',
      subtitle: 'Downlink/Uplink rates per client',
      chartHeight: 260,
      child: activeClients.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                'No WiFi clients connected',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, activeClients),
    );
  }

  List<_ClientInfo> _buildClientList(dynamic state) {
    final clients = <_ClientInfo>[];
    for (final entry in (state.wifiClientMap as Map<String, WifiClient>).entries) {
      final client = entry.value;
      if (!client.active) continue;
      final device = (state.deviceModels as List)
          .where((d) => d.mac.toUpperCase() == entry.key.toUpperCase())
          .firstOrNull;
      final name = device?.hostName ?? entry.key;
      final displayName =
          name.length > 10 ? '${name.substring(0, 9)}\u2026' : name;
      clients
          .add(_ClientInfo(displayName: displayName, client: client));
    }
    return clients;
  }

  Widget _buildChart(BuildContext context, List<_ClientInfo> clients) {
    final colorScheme = Theme.of(context).colorScheme;

    final dlData =
        clients.map((c) => c.client.lastDataDownlinkRate / 1000).toList();
    final ulData =
        clients.map((c) => c.client.lastDataUplinkRate / 1000).toList();
    final xLabels = clients.map((c) => c.displayName).toList();

    return Column(
      children: [
        Expanded(
          child: AppBarChart(
            series: [
              AppChartSeries(
                label: 'Downlink',
                data: dlData,
                color: colorScheme.primary,
              ),
              AppChartSeries(
                label: 'Uplink',
                data: ulData,
                color: colorScheme.secondary,
              ),
            ],
            xLabels: xLabels,
            yLabelFormatter: (v) => '${v.toInt()} Mbps',
            showValueLabels: clients.length <= 4,
            valueLabelFormatter: (v) => '${v.toInt()}',
            tooltipFormatter: (label, v) =>
                '$label: ${v.toInt()} Mbps',
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatsLegendDot(color: colorScheme.primary),
            AppGap.xs(),
            AppText.labelSmall('Downlink'),
            AppGap.lg(),
            StatsLegendDot(color: colorScheme.secondary),
            AppGap.xs(),
            AppText.labelSmall('Uplink'),
          ],
        ),
      ],
    );
  }
}

class _ClientInfo {
  final String displayName;
  final WifiClient client;
  const _ClientInfo({required this.displayName, required this.client});
}
