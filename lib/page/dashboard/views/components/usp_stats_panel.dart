import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/stat_blocks.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A row of summary stat cards displayed at the top of the dashboard.
class UspStatsPanel extends ConsumerWidget {
  const UspStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final ethernetData = ref.watch(ethernetDataProvider).valueOrNull;
    if (devicesData == null) return const CardSkeleton.stats();

    final devices = devicesData.clientDevices;
    final onlineCount = devices.where((d) => d.isActive).length;
    final nodeCount = devicesData.nodes.length;
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
          child: StatTile(
            icon: Icons.router,
            value: '$nodeCount',
            label: loc(context).router,
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: StatTile(
            icon: Icons.devices,
            value: '$onlineCount',
            label: loc(context).devices,
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: StatTile(
            icon: Icons.lan,
            value: '$lanConnected/$lanTotal',
            label: loc(context).lanPorts,
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: StatTile(
            icon: Icons.wifi,
            value: '$enabledRadios/$radioCount',
            label: loc(context).radios,
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: StatTile(
            icon: Icons.shortcut,
            value: '$forwardCount',
            label: loc(context).portRules,
          ),
        ),
      ],
    );
  }
}
