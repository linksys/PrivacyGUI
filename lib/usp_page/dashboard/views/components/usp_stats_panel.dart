import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/usp_page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/usp_page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/usp_page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/usp_page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A row of summary stat cards displayed at the top of the dashboard.
class UspStatsPanel extends ConsumerWidget {
  const UspStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final ethernetData = ref.watch(ethernetDataProvider).valueOrNull;
    if (devicesData == null) return const CardSkeleton.stats();

    final devices = devicesData.deviceModels;
    final onlineCount = devices.where((d) => d.isActive).length;
    final nodeCount = devicesData.nodeModels.length;
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    final radioCount = wifiData?.radioModels.length ?? 0;
    final enabledRadios =
        wifiData?.radioModels.where((r) => r.enable).length ?? 0;
    final lanPorts =
        (ethernetData?.ethernetPortModels ?? []).where((p) => !p.isWan);
    final lanConnected = lanPorts.where((p) => p.isUp).length;
    final lanTotal = lanPorts.length;
    final pfCount =
        ref.watch(portForwardingDataProvider).valueOrNull?.ruleModels.length ??
            0;
    final ptCount =
        ref.watch(portTriggeringDataProvider).valueOrNull?.ruleModels.length ??
            0;
    final forwardCount = pfCount + ptCount;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.router,
            value: '$nodeCount',
            label: 'Router',
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatTile(
            icon: Icons.devices,
            value: '$onlineCount',
            label: 'Devices',
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatTile(
            icon: Icons.lan,
            value: '$lanConnected/$lanTotal',
            label: 'LAN Ports',
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatTile(
            icon: Icons.wifi,
            value: '$enabledRadios/$radioCount',
            label: 'Radios',
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatTile(
            icon: Icons.shortcut,
            value: '$forwardCount',
            label: 'Port Rules',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(icon, size: 24, color: color),
          AppGap.sm(),
          AppText.titleSmall(value, color: color),
          AppGap.xs(),
          AppText.bodySmall(
            label,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
