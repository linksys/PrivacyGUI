import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';

enum CallbackRiskLevel { low, medium, high }

/// Predicts whether the customer is likely to call back within 7 days.
class CallbackRiskWidget extends StatelessWidget {
  final CsDiagnosticState state;

  const CallbackRiskWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (level, score, factors) = _assess();

    if (level == CallbackRiskLevel.low) return const SizedBox.shrink();

    final (color, icon, label) = switch (level) {
      CallbackRiskLevel.high => (Colors.red, Icons.priority_high, 'High Call-Back Risk'),
      CallbackRiskLevel.medium => (Colors.orange, Icons.warning_amber, 'Moderate Call-Back Risk'),
      CallbackRiskLevel.low => (Colors.green, Icons.check, 'Low Risk'),
    };

    final crmNote = _generateCrmNote(factors);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$score/10',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...factors.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\u2022 ', style: TextStyle(color: color)),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy CRM Note'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: crmNote));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CRM note copied to clipboard')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  (CallbackRiskLevel, int, List<String>) _assess() {
    int score = 0;
    final factors = <String>[];

    // Router uptime < 48h
    if (state.routerUptimeSeconds > 0 && state.routerUptimeSeconds < 172800) {
      score += 3;
      factors.add('Router uptime under 48h (${_formatUptime(state.routerUptimeSeconds)})');
    }

    // WAN disconnected
    if (!state.wanConnected) {
      score += 3;
      factors.add('WAN currently disconnected');
    }

    // DHCP pool > 80%
    if (state.dhcpUtilization > 0.8) {
      score += 2;
      factors.add('DHCP pool ${(state.dhcpUtilization * 100).toInt()}% full');
    }

    // 2+ flagged devices
    if (state.flaggedClients.length >= 2) {
      score += 2;
      factors.add('${state.flaggedClients.length} devices with poor signal');
    }

    score = score.clamp(0, 10);

    final level = score >= 6
        ? CallbackRiskLevel.high
        : score >= 3
            ? CallbackRiskLevel.medium
            : CallbackRiskLevel.low;

    return (level, score, factors);
  }

  String _generateCrmNote(List<String> factors) {
    final model = state.deviceInfo?['description'] ?? state.deviceInfo?['modelNumber'] ?? 'Unknown';
    final fw = state.deviceInfo?['firmwareVersion'] ?? 'Unknown';

    final buf = StringBuffer();
    buf.writeln('WiFi Diagnostic Summary ($model, FW $fw)');
    buf.writeln('Findings:');
    for (final f in factors) {
      buf.writeln('- $f');
    }
    buf.writeln('Devices: ${state.clients.length} connected, ${state.flaggedClients.length} flagged');
    buf.writeln('DHCP: ${state.dhcpLeasesCount}/${state.dhcpPoolLimit}');
    buf.writeln('Recommend follow-up in 48h if not resolved.');
    return buf.toString();
  }

  String _formatUptime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    if (seconds < 86400) return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
    return '${seconds ~/ 86400}d ${(seconds % 86400) ~/ 3600}h';
  }
}
