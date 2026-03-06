import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A row of summary stat cards displayed at the top of the dashboard.
class UspStatsPanel extends StatelessWidget {
  final UspDashboardState state;
  final List<DeviceUIModel> devices;

  const UspStatsPanel({super.key, required this.state, required this.devices});

  @override
  Widget build(BuildContext context) {
    final onlineCount = devices.where((d) => d.isActive).length;
    final offlineCount = devices.where((d) => !d.isActive).length;
    final radioCount = state.wifiRadioModels.length;
    final enabledRadios = state.wifiRadioModels.where((r) => r.enable).length;
    final forwardCount = state.portForwardingRuleModels.length +
        state.portTriggeringRuleModels.length;
    final lanPorts = state.ethernetPortModels.where((p) => !p.isWan);
    final lanConnected = lanPorts.where((p) => p.isUp).length;
    final lanTotal = lanPorts.length;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.devices,
            value: '$onlineCount / $offlineCount',
            label: 'Online / Offline',
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
