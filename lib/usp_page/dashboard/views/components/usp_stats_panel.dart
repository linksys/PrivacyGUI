import 'package:flutter/material.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A row of summary stat cards displayed at the top of the dashboard.
class UspStatsPanel extends StatelessWidget {
  final UspDashboardState state;
  final List<ConnectedDevice> devices;

  const UspStatsPanel({super.key, required this.state, required this.devices});

  @override
  Widget build(BuildContext context) {
    final onlineCount = devices.where((d) => d.isActive).length;
    final offlineCount = devices.where((d) => !d.isActive).length;
    final radioCount = state.wifiRadios.items.length;
    final enabledRadios = state.wifiRadios.items.where((r) => r.enable).length;
    final ruleCount =
        state.dhcpReservations.items.length + state.portForwarding.items.length;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.devices,
            value: '$onlineCount',
            label: 'Online',
            color: Theme.of(context).extension<AppColorScheme>()?.semanticSuccess,
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: _StatTile(
            icon: Icons.cloud_off,
            value: '$offlineCount',
            label: 'Offline',
            color: offlineCount > 0
                ? Theme.of(context).extension<AppColorScheme>()?.semanticWarning
                : null,
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
            icon: Icons.rule,
            value: '$ruleCount',
            label: 'Rules',
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
  final Color? color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(icon, size: 24, color: effectiveColor),
          AppGap.sm(),
          AppText.headlineSmall(value, color: effectiveColor),
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
