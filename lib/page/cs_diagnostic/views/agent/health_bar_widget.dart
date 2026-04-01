import 'package:flutter/material.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';

enum HealthStatus { green, yellow, red }

class HealthBarWidget extends StatelessWidget {
  final CsDiagnosticState state;

  const HealthBarWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          _indicator(context, 'WiFi', _wifiStatus),
          _indicator(context, 'WAN', _wanStatus),
          _indicator(context, 'DHCP', _dhcpStatus),
          _indicator(context, 'Router', _routerStatus),
        ],
      ),
    );
  }

  HealthStatus get _wifiStatus {
    final wireless = state.clients.where((c) => c.isWireless).toList();
    if (wireless.isEmpty) return HealthStatus.green;
    final flagged = state.flaggedClients.length;
    final ratio = flagged / wireless.length;
    if (ratio >= 0.4) return HealthStatus.red;
    if (ratio >= 0.15 || flagged >= 3) return HealthStatus.yellow;
    return HealthStatus.green;
  }

  HealthStatus get _wanStatus {
    if (state.wanStatus == null) return HealthStatus.red;
    return state.wanConnected ? HealthStatus.green : HealthStatus.red;
  }

  HealthStatus get _dhcpStatus {
    final util = state.dhcpUtilization;
    if (util >= 0.9) return HealthStatus.red;
    if (util >= 0.7) return HealthStatus.yellow;
    return HealthStatus.green;
  }

  HealthStatus get _routerStatus {
    final uptime = state.routerUptimeSeconds;
    if (uptime < 600) return HealthStatus.red;
    if (uptime < 7200) return HealthStatus.yellow;
    return HealthStatus.green;
  }

  Widget _indicator(BuildContext context, String label, HealthStatus status) {
    final color = switch (status) {
      HealthStatus.green => Colors.green,
      HealthStatus.yellow => Colors.amber,
      HealthStatus.red => Colors.red,
    };
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
