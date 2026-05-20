import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_result.dart';
import '../../models/diagnostic_state.dart';

class StepResultTile extends StatelessWidget {
  final DiagnosticStepUIModel result;
  final bool initiallyExpanded;

  const StepResultTile({
    super.key,
    required this.result,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color) = switch (result.severity) {
      DiagnosticSeverity.ok => (Icons.check_circle, colorScheme.primary),
      DiagnosticSeverity.warning => (Icons.warning, colorScheme.tertiary),
      DiagnosticSeverity.error => (Icons.error, colorScheme.error),
      DiagnosticSeverity.skipped => (
          Icons.skip_next,
          colorScheme.onSurfaceVariant
        ),
    };

    final details = _getResultDetails(result);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppExpansionPanel.single(
        initiallyExpanded: initiallyExpanded,
        headerTitle: _getStepTitle(result.step),
        content: Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.md, bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  AppGap.sm(),
                  AppText.bodySmall(
                    _getSeverityText(result.severity),
                    color: color,
                  ),
                ],
              ),
              AppGap.sm(),
              if (details.isNotEmpty)
                ...details.map((detail) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText.bodySmall(
                            detail.label,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          AppText.labelMedium(detail.value),
                        ],
                      ),
                    ))
              else
                AppText.bodySmall(
                  'No additional details available.',
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSeverityText(DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.ok => 'Passed',
      DiagnosticSeverity.warning => 'Warning',
      DiagnosticSeverity.error => 'Issue Detected',
      DiagnosticSeverity.skipped => 'Skipped',
    };
  }

  String _getStepTitle(DiagnosticStep step) {
    return switch (step) {
      DiagnosticStep.checkingWanStatus => 'WAN Status',
      DiagnosticStep.checkingDhcp => 'DHCP',
      DiagnosticStep.checkingDhcpPool => 'DHCP Pool',
      DiagnosticStep.pingGateway => 'Gateway Ping',
      DiagnosticStep.pingDns => 'DNS Ping',
      DiagnosticStep.pingInternet => 'Internet Connectivity',
      DiagnosticStep.dnsLookup => 'DNS Lookup',
      DiagnosticStep.runningSpeedTest => 'Speed Test',
      DiagnosticStep.checkingWifiSignal => 'WiFi Signal',
      DiagnosticStep.checkingConnectedDevices => 'Connected Devices',
      DiagnosticStep.runningTraceroute => 'Traceroute',
      _ => step.name,
    };
  }

  List<_ResultDetail> _getResultDetails(DiagnosticStepUIModel result) {
    return switch (result) {
      WanStatusCheckUIModel r => [
          _ResultDetail('Status', r.status),
          _ResultDetail(
              'IP Address', r.ipAddress.isNotEmpty ? r.ipAddress : 'None'),
          _ResultDetail('Type', r.addressingType),
        ],
      PingCheckUIModel r => [
          _ResultDetail('Host', r.host),
          _ResultDetail(
              'Latency', r.allFailed ? 'Failed' : '${r.avgResponseTime} ms'),
          _ResultDetail('Success Rate', '${r.successCount}/${r.totalCount}'),
        ],
      WifiSignalCheckUIModel r => [
          _ResultDetail('Band', r.band),
          _ResultDetail('Channel', '${r.channel}'),
          _ResultDetail('Signal',
              r.connectedDevices == 0 ? 'No clients' : '${r.rssi} dBm (avg)'),
          if (r.connectedDevices > 0)
            _ResultDetail('Wireless Clients', '${r.connectedDevices}'),
          for (final radio in r.radios.where((rd) => rd.hasClients))
            _ResultDetail(
              radio.isResolved
                  ? '${radio.band} Ch${radio.channel}'
                  : 'Unresolved',
              '${radio.averageRssi} dBm avg / min ${radio.minRssi} '
              '(${radio.clientCount} clients)',
            ),
        ],
      DhcpPoolCheckUIModel r => [
          if (!r.dhcpEnabled)
            _ResultDetail('Status', 'DHCP disabled')
          else if (r.capacityUnknown)
            _ResultDetail('Status', 'Pool range unavailable')
          else ...[
            _ResultDetail('Range', '${r.minAddress} – ${r.maxAddress}'),
            _ResultDetail('Capacity', '${r.capacity}'),
            _ResultDetail(
                'Used', '${r.usedLeases} (${(r.usageRatio * 100).toInt()}%)'),
          ],
        ],
      ConnectedDevicesCheckUIModel r => [
          _ResultDetail('Total Devices', '${r.totalDevices}'),
          _ResultDetail('Active', '${r.activeDevices}'),
          if (r.highBandwidthDevices.isNotEmpty)
            _ResultDetail('High Bandwidth', r.highBandwidthDevices.join(', ')),
        ],
      DeviceIssuesCheckUIModel r => [
          _ResultDetail('Total Devices', '${r.totalDevices}'),
          _ResultDetail('With Issues', '${r.devicesWithIssues}'),
          if (r.weakSignalDevices.isNotEmpty)
            _ResultDetail(
                'Weak Signal', r.weakSignalDevices.take(3).join(', ')),
          if (r.lowDataRateDevices.isNotEmpty)
            _ResultDetail(
                'Low Data Rate', r.lowDataRateDevices.take(3).join(', ')),
        ],
      WifiCoverageCheckUIModel r => [
          _ResultDetail('Wireless Devices', '${r.totalWirelessDevices}'),
          _ResultDetail('Avg Signal', '${r.averageSignalStrength} dBm'),
          _ResultDetail('Weak Signal Devices', '${r.weakSignalDevices.length}'),
          if (r.weakSignalDevices.isNotEmpty)
            _ResultDetail('Affected', r.weakSignalDevices.take(3).join(', ')),
        ],
      DnsLookupCheckUIModel r => [
          _ResultDetail('Host', r.hostName),
          _ResultDetail(
            'Resolved',
            r.resolvedIps.isEmpty ? 'Failed' : r.resolvedIps.take(2).join(', '),
          ),
          if (r.dnsServerUsed.isNotEmpty)
            _ResultDetail('DNS Server', r.dnsServerUsed),
          if (r.responseTimeMs > 0)
            _ResultDetail('Response Time', '${r.responseTimeMs} ms'),
          if (r.configuredDnsServers.isNotEmpty)
            _ResultDetail(
              'Configured DNS',
              r.configuredDnsServers.take(3).join(', '),
            ),
        ],
      IntermittentCheckUIModel r => [
          _ResultDetail('Uptime', r.uptimeFormatted),
          _ResultDetail(
              'Ping Success', '${(r.pingSuccessRate * 100).toInt()}%'),
          _ResultDetail('Avg Latency', '${r.averageLatencyMs} ms'),
          _ResultDetail('Jitter', '${r.jitterMs} ms'),
          if (r.recentReboot) _ResultDetail('Note', 'Recent reboot detected'),
        ],
      TracerouteCheckUIModel r => [
          _ResultDetail('Target', r.targetHost),
          _ResultDetail('Hops', '${r.hops.length}'),
          if (r.slowHops.isNotEmpty)
            _ResultDetail('Slow Hops', '${r.slowHops.length}'),
        ],
      _ when result.step == DiagnosticStep.runningSpeedTest => [
          if (result.rawData.containsKey('downloadMbps'))
            _ResultDetail('Download',
                '${(result.rawData['downloadMbps'] as double).toStringAsFixed(1)} Mbps'),
          if (result.rawData.containsKey('uploadMbps'))
            _ResultDetail('Upload',
                '${(result.rawData['uploadMbps'] as double).toStringAsFixed(1)} Mbps'),
        ],
      _ when result.step == DiagnosticStep.checkingDhcp => [
          _ResultDetail(
              'Status',
              result.isOk
                  ? 'OK'
                  : result.isSkipped
                      ? 'Static IP'
                      : 'Failed'),
        ],
      _ => [
          if (result.rawData.containsKey('error'))
            _ResultDetail('Error', result.rawData['error'].toString()),
        ],
    };
  }
}

class _ResultDetail {
  final String label;
  final String value;
  const _ResultDetail(this.label, this.value);
}
