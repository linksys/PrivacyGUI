import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A row of summary stat cards displayed at the top of the dashboard.
class UspStatsPanel extends ConsumerWidget {
  const UspStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspDashboardProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();

    final devices = state.deviceModels;
    final onlineCount = devices.where((d) => d.isActive).length;
    final nodeCount = state.nodeModels.length;
    final radioCount = state.wifiRadioModels.length;
    final enabledRadios = state.wifiRadioModels.where((r) => r.enable).length;
    final lanPorts = state.ethernetPortModels.where((p) => !p.isWan);
    final lanConnected = lanPorts.where((p) => p.isUp).length;
    final lanTotal = lanPorts.length;
    final forwardCount = state.portForwardingRuleModels.length +
        state.portTriggeringRuleModels.length;

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
