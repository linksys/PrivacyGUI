import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';

/// Generates and displays a plain-text diagnostic report for support agents.
class ReportSummaryView extends StatelessWidget {
  final CsDiagnosticState state;

  const ReportSummaryView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final report = _generateReport();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Copy this report and paste it into the support ticket. '
                          'It contains no customer PII — only device names and signal data.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: SelectableText(
                  report,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Report'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: report));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report copied to clipboard')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _generateReport() {
    final buf = StringBuffer();
    final now = DateTime.now();

    buf.writeln('=== Instant-Help Diagnostic Report ===');
    buf.writeln('Generated: ${now.toIso8601String().substring(0, 19)}');
    buf.writeln();

    // Router Info
    buf.writeln('--- Router ---');
    final model = state.deviceInfo?['modelNumber'] ?? state.deviceInfo?['description'] ?? 'Unknown';
    final fw = state.deviceInfo?['firmwareVersion'] ?? 'Unknown';
    final serial = state.deviceInfo?['serialNumber'] ?? '';
    buf.writeln('Model: $model');
    if (serial.isNotEmpty) buf.writeln('Serial: $serial');
    buf.writeln('Firmware: $fw');
    buf.writeln('Uptime: ${_formatUptime(state.routerUptimeSeconds)}');
    buf.writeln();

    // WAN
    buf.writeln('--- WAN ---');
    buf.writeln('Status: ${state.wanConnected ? "Connected" : "DISCONNECTED"}');
    final wanIp = state.wanStatus?['wanIPAddress'] as String?;
    if (wanIp != null && wanIp.isNotEmpty) {
      buf.writeln('WAN IP: $wanIp');
    }
    buf.writeln();

    // DHCP
    buf.writeln('--- DHCP ---');
    buf.writeln('Leases: ${state.dhcpLeasesCount} / ${state.dhcpPoolLimit} (${(state.dhcpUtilization * 100).toInt()}%)');
    buf.writeln();

    // Health Summary
    buf.writeln('--- Health Summary ---');
    buf.writeln('Complexity Score: ${state.complexityScore}/10');
    buf.writeln('Total Devices: ${state.clients.length}');
    buf.writeln('Flagged Devices: ${state.flaggedClients.length}');

    final wireless = state.clients.where((c) => c.isWireless).toList();
    final on5 = wireless.where((c) => c.band == '5GHz').length;
    final on24 = wireless.where((c) => c.band == '2.4GHz').length;
    final on6 = wireless.where((c) => c.band == '6GHz').length;
    final wired = state.clients.where((c) => !c.isWireless).length;
    buf.writeln('Band Split: 5GHz=$on5, 2.4GHz=$on24${on6 > 0 ? ', 6GHz=$on6' : ''}, Wired=$wired');
    buf.writeln();

    // Radio Config
    if (state.radioInfo != null) {
      buf.writeln('--- Radio Configuration ---');
      buf.writeln('Band Steering: ${state.bandSteeringEnabled ? "Enabled" : "Disabled"}');
      final radios = state.radioInfo!['radios'] as List? ?? [];
      for (final radio in radios) {
        final band = radio['band'] as String? ?? radio['radioID'] as String? ?? radio['physicalRadioID'] as String? ?? '?';
        final chRaw = radio['settings']?['channel'] ?? '?';
        final ch = (chRaw == 0 || chRaw == '0') ? 'Auto' : '$chRaw';
        final width = radio['settings']?['channelWidth'] ?? '?';
        final mode = radio['settings']?['mode'] ?? '?';
        buf.writeln('$band: Ch $ch ($width) — $mode');
      }
      buf.writeln();
    }

    // Speed Test Results
    if (state.speedTestStep == 'complete') {
      buf.writeln('--- Speed Test (WAN) ---');
      if (state.speedTestLatencyMs != null) {
        buf.writeln('Latency: ${state.speedTestLatencyMs} ms');
      }
      if (state.speedTestDownloadMbps != null) {
        buf.writeln('Download: ${state.speedTestDownloadMbps!.toStringAsFixed(1)} Mbps');
      }
      if (state.speedTestUploadMbps != null) {
        buf.writeln('Upload: ${state.speedTestUploadMbps!.toStringAsFixed(1)} Mbps');
      }
      buf.writeln();
    }

    // Guest Network
    buf.writeln('Guest Network: ${state.guestNetworkEnabled ? "Enabled" : "Disabled"}');

    // Security & Access Controls
    buf.writeln('--- Security & Access ---');
    if (state.securityMode != null) {
      buf.writeln('Security Mode: ${state.securityMode}');
    }
    if (state.macFilterMode != null) {
      buf.writeln('MAC Filter: ${state.macFilterMode} mode (active)');
    } else {
      buf.writeln('MAC Filter: Disabled');
    }
    buf.writeln('Parental Controls: ${state.parentalControlsEnabled ? "Enabled" : "Disabled"}');
    buf.writeln('Wireless Scheduler: ${state.wirelessScheduleEnabled ? "Enabled" : "Disabled"}');
    buf.writeln();

    // Firmware Update
    if (state.firmwareUpdateAvailable) {
      buf.writeln('FIRMWARE UPDATE AVAILABLE: ${state.availableFirmwareVersion ?? "unknown version"}');
    }

    // Backhaul (mesh nodes)
    if (state.backhaulInfo != null) {
      final devices = state.backhaulInfo!['backhaulDevices'] as List? ?? [];
      if (devices.isNotEmpty) {
        buf.writeln();
        buf.writeln('--- Mesh Backhaul ---');
        for (final node in devices) {
          final id = node['deviceID'] as String? ?? 'Unknown';
          final connType = node['connectionType'] as String? ?? '?';
          final speed = node['speedMbps'] as int? ?? 0;
          buf.writeln('$id: $connType backhaul, $speed Mbps');
        }
      }
    }
    buf.writeln();

    // Alerts
    final alerts = <String>[];
    if (!state.wanConnected) alerts.add('WAN DISCONNECTED');
    if (state.routerUptimeSeconds > 0 && state.routerUptimeSeconds < 7200) {
      alerts.add('RECENT REBOOT (${_formatUptime(state.routerUptimeSeconds)})');
    }
    if (state.dhcpUtilization >= 0.8) {
      alerts.add('DHCP POOL ${(state.dhcpUtilization * 100).toInt()}% FULL');
    }
    if (state.flaggedClients.length >= 3) {
      alerts.add('${state.flaggedClients.length} DEVICES WITH POOR SIGNAL');
    }
    if (state.firmwareUpdateAvailable) {
      alerts.add('FIRMWARE UPDATE AVAILABLE');
    }
    if (state.macFilterMode != null) {
      alerts.add('MAC FILTER ACTIVE (${state.macFilterMode} mode)');
    }
    if (state.wirelessScheduleEnabled) {
      alerts.add('WIRELESS SCHEDULER ACTIVE');
    }
    if (alerts.isNotEmpty) {
      buf.writeln('--- ALERTS ---');
      for (final a in alerts) {
        buf.writeln('! $a');
      }
      buf.writeln();
    }

    // Device Table
    buf.writeln('--- Connected Devices ---');
    buf.writeln('${_padRight('Device', 22)}${_padRight('Type', 12)}${_padRight('IP', 16)}${_padRight('Band', 8)}${_padRight('Signal', 10)}${_padRight('TX', 8)}${_padRight('RX', 8)}Flag');
    buf.writeln('-' * 92);

    for (final c in state.clients) {
      final signal = c.isWireless && c.signalDecibels != null
          ? '${c.signalDecibels} dBm'
          : '-';
      final tx = c.txRateMbps != null ? '${c.txRateMbps}' : '-';
      final rx = c.rxRateMbps != null ? '${c.rxRateMbps}' : '-';
      final flag = c.isFlagged ? '*' : '';
      final mfr = c.manufacturer ?? '-';

      buf.writeln('${_padRight(c.displayName, 22)}${_padRight(mfr, 12)}${_padRight(c.ipAddress ?? '-', 16)}${_padRight(c.band, 8)}${_padRight(signal, 10)}${_padRight(tx, 8)}${_padRight(rx, 8)}$flag');
    }
    buf.writeln();
    buf.writeln('* = flagged (signal < -75 dBm or rate < 10 Mbps)');
    buf.writeln();
    buf.writeln('=== End Report ===');

    return buf.toString();
  }

  String _padRight(String s, int width) {
    if (s.length >= width) return '${s.substring(0, width - 1)} ';
    return s.padRight(width);
  }

  String _formatUptime(int seconds) {
    if (seconds <= 0) return 'Unknown';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m';
    if (seconds < 86400) return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
    return '${seconds ~/ 86400}d ${(seconds % 86400) ~/ 3600}h';
  }
}
