import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_performance_helpers.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Per-client RSSI bar chart with tier coloring.
class StatsWifiSignalSection extends ConsumerWidget {
  const StatsWifiSignalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    if (wifiData == null) {
      return StatsSectionCard(
        title: 'WiFi Signal Strength',
        subtitle: 'Per-client signal strength (RSSI)',
        chartHeight: 300,
        child: Center(
          child: AppText.bodyMedium(
            'Loading...',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final activeClients = _buildClientList(wifiData, devicesData);

    return StatsSectionCard(
      title: 'WiFi Signal Strength',
      subtitle: '${activeClients.length} active WiFi clients',
      chartHeight: 300,
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

  List<_ClientInfo> _buildClientList(
      WifiData wifiData, DevicesData? devicesData) {
    final clients = <_ClientInfo>[];
    for (final entry in wifiData.wifiClientMap.entries) {
      final client = entry.value;
      if (!client.active) continue;
      final device = devicesData?.deviceModels
          .where((d) => d.mac.toUpperCase() == entry.key.toUpperCase())
          .firstOrNull;
      final name = device?.hostName ?? entry.key;
      final displayName =
          name.length > 10 ? '${name.substring(0, 9)}\u2026' : name;
      clients.add(_ClientInfo(
          mac: entry.key, displayName: displayName, client: client));
    }
    return clients;
  }

  Widget _buildChart(BuildContext context, List<_ClientInfo> clients) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: clients.length,
            separatorBuilder: (_, __) => AppGap.xs(),
            itemBuilder: (context, index) {
              final c = clients[index];
              final rssi = c.client.signalStrength;
              final tier = WifiPerformanceHelpers.signalTier(rssi);
              final color = WifiPerformanceHelpers.tierColor(tier, colorScheme);
              final norm = ((rssi + 100) / 70).clamp(0.0, 1.0);

              return Row(
                children: [
                  SizedBox(width: 80, child: AppText.labelSmall(c.displayName)),
                  AppGap.sm(),
                  Expanded(child: _ColoredLinearBar(value: norm, color: color)),
                  AppGap.sm(),
                  SizedBox(
                    width: 60,
                    child: AppText.bodySmall('$rssi dBm',
                        textAlign: TextAlign.end),
                  ),
                ],
              );
            },
          ),
        ),
        AppGap.sm(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final entry in [
              (SignalTier.excellent, 'Excellent'),
              (SignalTier.good, 'Good'),
              (SignalTier.fair, 'Fair'),
              (SignalTier.weak, 'Weak'),
            ]) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      WifiPerformanceHelpers.tierColor(entry.$1, colorScheme),
                  shape: BoxShape.circle,
                ),
              ),
              AppGap.xs(),
              AppText.labelSmall(entry.$2),
              AppGap.md(),
            ],
          ],
        ),
      ],
    );
  }
}

class _ClientInfo {
  final String mac;
  final String displayName;
  final WifiClientUIModel client;
  const _ClientInfo(
      {required this.mac, required this.displayName, required this.client});
}

class _ColoredLinearBar extends StatelessWidget {
  final double value;
  final Color color;
  const _ColoredLinearBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * value,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      },
    );
  }
}
