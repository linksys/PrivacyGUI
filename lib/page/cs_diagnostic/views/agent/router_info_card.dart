import 'package:flutter/material.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';

/// Displays router model, firmware, uptime, and WAN details.
class RouterInfoCard extends StatelessWidget {
  final CsDiagnosticState state;

  const RouterInfoCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final model = state.deviceInfo?['description'] ??
        state.deviceInfo?['modelNumber'] ??
        'Unknown';
    final fw = state.deviceInfo?['firmwareVersion'] ?? 'Unknown';
    final serial = state.deviceInfo?['serialNumber'] as String?;
    final wanConn = state.wanStatus?['wanConnection'] as Map<String, dynamic>?;
    final wanIp = wanConn?['ipAddress'] as String? ??
        state.wanStatus?['wanIPAddress'] as String?;
    final wanMac = state.wanStatus?['macAddress'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SelectionArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.router, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Router Info',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(context, 'Model', model.toString()),
              _infoRow(context, 'Firmware', fw.toString()),
              _infoRow(context, 'Uptime', _formatUptime(state.routerUptimeSeconds)),
              _infoRow(context, 'WAN', state.wanConnected ? 'Connected' : 'Disconnected'),
              if (wanIp != null && wanIp.isNotEmpty)
                _infoRow(context, 'WAN IP', wanIp),
              if (wanMac != null && wanMac.isNotEmpty)
                _infoRow(context, 'WAN MAC', wanMac),
              if (serial != null)
                _infoRow(context, 'Serial', serial),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatUptime(int seconds) {
    if (seconds <= 0) return 'Unknown';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    if (seconds < 86400) return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
    return '${seconds ~/ 86400}d ${(seconds % 86400) ~/ 3600}h';
  }
}
