import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/device_score.dart';
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
    final scoredDevices = _getScoredDevicesForDisplay(result);
    final isSpeedTest = result.step == DiagnosticStep.runningSpeedTest;

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
              if (isSpeedTest) ...[
                _SpeedTestVisualization(rawData: result.rawData),
                AppGap.md(),
              ],
              if (details.isNotEmpty)
                ...details.map((detail) => Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodySmall(
                            detail.label,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          AppGap.md(),
                          Expanded(
                            child: AppText.labelMedium(
                              detail.value,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ))
              else if (!isSpeedTest)
                AppText.bodySmall(
                  'No additional details available.',
                  color: colorScheme.onSurfaceVariant,
                ),
              if (scoredDevices.isNotEmpty) ...[
                AppGap.md(),
                AppText.labelMedium(
                  'Affected Devices',
                  color: colorScheme.onSurfaceVariant,
                ),
                AppGap.xs(),
                ...scoredDevices.map(
                  (device) => _DeviceScoreRow(
                    key: ValueKey(device.macAddress),
                    device: device,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<DeviceScoreUIModel> _getScoredDevicesForDisplay(
      DiagnosticStepUIModel result) {
    if (result is! DeviceIssuesCheckUIModel) return const [];
    final issues =
        result.deviceScores.where((d) => d.hasIssue).toList(growable: false);
    issues.sort((a, b) => a.overallScore.compareTo(b.overallScore));
    return issues.take(5).toList(growable: false);
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
      DiagnosticStep.checkingMeshBackhaul => 'Mesh Backhaul',
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
      MeshBackhaulCheckUIModel r => r.nodes.isEmpty
          ? const [
              _ResultDetail('Mesh', 'Single-router setup — no backhaul'),
            ]
          : [
              _ResultDetail('Nodes', '${r.nodes.length}'),
              if (r.poorCount > 0)
                _ResultDetail('Poor backhaul', '${r.poorCount}'),
              if (r.weakCount > 0)
                _ResultDetail('Weak backhaul', '${r.weakCount}'),
              ..._buildMeshNodeDetails(r.nodes),
            ],
      _ when result.step == DiagnosticStep.runningSpeedTest => [
          if (result.rawData['serverHost'] is String &&
              (result.rawData['serverHost'] as String).isNotEmpty)
            _ResultDetail('Server', result.rawData['serverHost'] as String),
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

  List<_ResultDetail> _buildMeshNodeDetails(
      List<MeshNodeBackhaulUIModel> nodes) {
    final details = <_ResultDetail>[];
    for (final n in nodes) {
      final severityText = switch (n.severity) {
        MeshBackhaulSeverity.healthy => 'Healthy',
        MeshBackhaulSeverity.weak => 'Weak',
        MeshBackhaulSeverity.poor => 'Poor',
      };
      final staleMarker = n.isStale ? ' ⚠️ Stale' : '';
      details.add(_ResultDetail(
        n.label,
        '${n.linkType} • $severityText$staleMarker',
      ));
      if (n.parentLabel != null && n.parentLabel!.isNotEmpty) {
        details.add(_ResultDetail('  Connected to', n.parentLabel!));
      }
      if (!n.isWired && n.signalStrengthDbm != 0) {
        final signalLevel = getWifiSignalLevel(n.signalStrengthDbm);
        details.add(_ResultDetail('  Signal',
            '${n.signalStrengthDbm} dBm (${signalLevel.displayTitle})'));
      }
      if (n.lastUplinkRateKbps > 0 || n.lastDownlinkRateKbps > 0) {
        final up = n.lastUplinkRateKbps > 0
            ? '↑${formatSpeed(n.lastUplinkRateKbps)}'
            : '--';
        final down = n.lastDownlinkRateKbps > 0
            ? '↓${formatSpeed(n.lastDownlinkRateKbps)}'
            : '--';
        details.add(_ResultDetail('  Speed', '$down / $up'));
      }
    }
    return details;
  }
}

class _ResultDetail {
  final String label;
  final String value;
  const _ResultDetail(this.label, this.value);
}

/// Inline gauge + latency badge for the speed test step. Replaces the
/// previous standalone SpeedTestResultCard so the result UI stays uniform.
class _SpeedTestVisualization extends StatelessWidget {
  final Map<String, dynamic> rawData;

  const _SpeedTestVisualization({required this.rawData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final downloadMbps = (rawData['downloadMbps'] as num?)?.toDouble() ?? 0;
    final uploadMbps = (rawData['uploadMbps'] as num?)?.toDouble() ?? 0;
    final hasUpload = rawData['hasUpload'] as bool? ?? true;
    final latencyMs = rawData['latencyMs'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latencyMs != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.network_ping,
                  size: 14, color: colorScheme.onSurfaceVariant),
              AppGap.xs(),
              AppText.bodySmall(
                '$latencyMs ms latency',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          AppGap.md(),
        ],
        Row(
          children: [
            Expanded(
              child: SpeedGauge(
                label: 'Download',
                value: downloadMbps,
                icon: Icons.download,
                color: colorScheme.primary,
              ),
            ),
            AppGap.lg(),
            Expanded(
              child: hasUpload
                  ? SpeedGauge(
                      label: 'Upload',
                      value: uploadMbps,
                      icon: Icons.upload,
                      color: colorScheme.tertiary,
                    )
                  : Column(
                      children: [
                        Icon(Icons.upload,
                            color: colorScheme.onSurfaceVariant, size: 32),
                        AppGap.sm(),
                        AppText.bodySmall(
                          'N/A',
                          color: colorScheme.onSurfaceVariant,
                        ),
                        AppGap.xs(),
                        AppText.labelSmall('Upload'),
                      ],
                    ),
            ),
          ],
        ),
        if (!hasUpload) ...[
          AppGap.sm(),
          AppText.bodySmall(
            'Upload test not supported on this firmware.',
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}

class SpeedGauge extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const SpeedGauge({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        AppGap.sm(),
        AppText.headlineSmall(value.toStringAsFixed(1), color: color),
        AppText.bodySmall('Mbps'),
        AppGap.xs(),
        AppText.labelSmall(label),
      ],
    );
  }
}

class _DeviceScoreRow extends StatelessWidget {
  final DeviceScoreUIModel device;

  const _DeviceScoreRow({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoreColor = device.overallScore < 50
        ? colorScheme.error
        : device.overallScore < 70
            ? colorScheme.tertiary
            : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.labelMedium(
                  device.name.isEmpty ? device.macAddress : device.name,
                ),
              ),
              AppText.labelMedium(
                'Score ${device.overallScore}',
                color: scoreColor,
              ),
            ],
          ),
          AppText.bodySmall(
            _formatSubtitle(device),
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _formatSubtitle(DeviceScoreUIModel d) {
    final parts = <String>[];
    if (!d.isWireless) {
      parts.add('Wired');
    } else if (d.rssiDbm != null) {
      parts.add('${d.signalLabel} (${d.rssiDbm} dBm)');
    } else {
      parts.add(d.signalLabel);
    }
    if (d.downlinkKbps != null) {
      final mbps = (d.downlinkKbps! / 1000).toStringAsFixed(1);
      parts.add('$mbps Mbps');
    }
    return parts.join(' · ');
  }
}
