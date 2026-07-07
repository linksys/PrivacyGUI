import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/util/network_utils.dart';
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

    final details = _getResultDetails(context, result);
    final scoredDevices = _getScoredDevicesForDisplay(result);
    final isSpeedTest = result.step == DiagnosticStep.runningSpeedTest;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppExpansionPanel.single(
        initiallyExpanded: initiallyExpanded,
        headerTitle: _getStepTitle(context, result.step),
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
                    _getSeverityText(context, result.severity),
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
                  loc(context).noAdditionalDetailsAvailable,
                  color: colorScheme.onSurfaceVariant,
                ),
              if (scoredDevices.isNotEmpty) ...[
                AppGap.md(),
                AppText.labelMedium(
                  loc(context).affectedDevices,
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

  String _getSeverityText(BuildContext context, DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.ok => loc(context).passed,
      DiagnosticSeverity.warning => loc(context).warning,
      DiagnosticSeverity.error => loc(context).issueDetected,
      DiagnosticSeverity.skipped => loc(context).skipped,
    };
  }

  String _getStepTitle(BuildContext context, DiagnosticStep step) {
    return switch (step) {
      DiagnosticStep.checkingWanStatus => loc(context).wanStatus,
      DiagnosticStep.checkingDhcp => loc(context).dhcp,
      DiagnosticStep.checkingDhcpPool => loc(context).dhcpPool,
      DiagnosticStep.pingGateway => loc(context).gatewayPing,
      DiagnosticStep.pingDns => loc(context).dnsPing,
      DiagnosticStep.pingInternet => loc(context).internetConnectivity,
      DiagnosticStep.dnsLookup => loc(context).dnsLookupStep,
      DiagnosticStep.runningSpeedTest => loc(context).speedTest,
      DiagnosticStep.checkingWifiSignal => loc(context).wifiSignal,
      DiagnosticStep.checkingConnectedDevices => loc(context).connectedDevices,
      DiagnosticStep.runningTraceroute => loc(context).traceroute,
      DiagnosticStep.checkingMeshBackhaul => loc(context).meshBackhaul,
      _ => step.name,
    };
  }

  List<_ResultDetail> _getResultDetails(
      BuildContext context, DiagnosticStepUIModel result) {
    return switch (result) {
      WanStatusCheckUIModel r => [
          _ResultDetail(loc(context).status, r.status),
          _ResultDetail(loc(context).ipAddress,
              r.ipAddress.isNotEmpty ? r.ipAddress : loc(context).none),
          _ResultDetail(loc(context).type, r.addressingType),
        ],
      PingCheckUIModel r => [
          _ResultDetail(loc(context).host, r.host),
          _ResultDetail(loc(context).latency,
              r.allFailed ? loc(context).failed : '${r.avgResponseTime} ms'),
          _ResultDetail(
              loc(context).successRate, '${r.successCount}/${r.totalCount}'),
        ],
      WifiSignalCheckUIModel r => [
          _ResultDetail(loc(context).band, r.band),
          _ResultDetail(loc(context).channel, '${r.channel}'),
          _ResultDetail(
              loc(context).signal,
              r.connectedDevices == 0
                  ? loc(context).noClients
                  : '${r.rssi} dBm (avg)'),
          if (r.connectedDevices > 0)
            _ResultDetail(
                loc(context).wirelessClients, '${r.connectedDevices}'),
          for (final radio in r.radios.where((rd) => rd.hasClients))
            _ResultDetail(
              radio.isResolved
                  ? '${radio.band} Ch${radio.channel}'
                  : loc(context).unresolved,
              '${radio.averageRssi} dBm avg / min ${radio.minRssi} '
              '(${radio.clientCount} clients)',
            ),
        ],
      DhcpPoolCheckUIModel r => [
          if (!r.dhcpEnabled)
            _ResultDetail(loc(context).status, loc(context).dhcpDisabled)
          else if (r.capacityUnknown)
            _ResultDetail(
                loc(context).status, loc(context).poolRangeUnavailable)
          else ...[
            _ResultDetail(
                loc(context).range, '${r.minAddress} – ${r.maxAddress}'),
            _ResultDetail(loc(context).capacity, '${r.capacity}'),
            _ResultDetail(loc(context).used,
                '${r.usedLeases} (${(r.usageRatio * 100).toInt()}%)'),
          ],
        ],
      ConnectedDevicesCheckUIModel r => [
          _ResultDetail(loc(context).totalDevices, '${r.totalDevices}'),
          _ResultDetail(loc(context).active, '${r.activeDevices}'),
          if (r.highBandwidthDevices.isNotEmpty)
            _ResultDetail(
                loc(context).highBandwidth, r.highBandwidthDevices.join(', ')),
        ],
      DeviceIssuesCheckUIModel r => [
          _ResultDetail(loc(context).totalDevices, '${r.totalDevices}'),
          _ResultDetail(loc(context).withIssues, '${r.devicesWithIssues}'),
          if (r.weakSignalDevices.isNotEmpty)
            _ResultDetail(loc(context).weakSignal,
                r.weakSignalDevices.take(3).join(', ')),
          if (r.lowDataRateDevices.isNotEmpty)
            _ResultDetail(loc(context).lowDataRate,
                r.lowDataRateDevices.take(3).join(', ')),
        ],
      WifiCoverageCheckUIModel r => [
          _ResultDetail(
              loc(context).wirelessDevices, '${r.totalWirelessDevices}'),
          _ResultDetail(
              loc(context).avgSignal, '${r.averageSignalStrength} dBm'),
          _ResultDetail(
              loc(context).weakSignalDevices, '${r.weakSignalDevices.length}'),
          if (r.weakSignalDevices.isNotEmpty)
            _ResultDetail(loc(context).affectedDevices,
                r.weakSignalDevices.take(3).join(', ')),
        ],
      DnsLookupCheckUIModel r => [
          _ResultDetail(loc(context).host, r.hostName),
          _ResultDetail(
            loc(context).resolved,
            r.resolvedIps.isEmpty
                ? loc(context).failed
                : r.resolvedIps.take(2).join(', '),
          ),
          if (r.dnsServerUsed.isNotEmpty)
            _ResultDetail(loc(context).dnsServer, r.dnsServerUsed),
          if (r.responseTimeMs > 0)
            _ResultDetail(loc(context).responseTime, '${r.responseTimeMs} ms'),
          if (r.configuredDnsServers.isNotEmpty)
            _ResultDetail(
              loc(context).configuredDns,
              r.configuredDnsServers.take(3).join(', '),
            ),
        ],
      IntermittentCheckUIModel r => [
          _ResultDetail(loc(context).uptime, r.uptimeFormatted),
          _ResultDetail(loc(context).pingSuccess,
              '${(r.pingSuccessRate * 100).toInt()}%'),
          _ResultDetail(loc(context).avgLatency, '${r.averageLatencyMs} ms'),
          _ResultDetail(loc(context).jitter, '${r.jitterMs} ms'),
          if (r.recentReboot)
            _ResultDetail(loc(context).note, loc(context).recentRebootDetected),
        ],
      TracerouteCheckUIModel r => [
          _ResultDetail(loc(context).target, r.targetHost),
          _ResultDetail(loc(context).hops, '${r.hops.length}'),
          if (r.slowHops.isNotEmpty)
            _ResultDetail(loc(context).slowHops, '${r.slowHops.length}'),
        ],
      MeshBackhaulCheckUIModel r => r.nodes.isEmpty
          ? [
              _ResultDetail(
                  loc(context).mesh, loc(context).singleRouterSetupNoBackhaul),
            ]
          : [
              _ResultDetail(loc(context).nodes, '${r.nodes.length}'),
              if (r.poorCount > 0)
                _ResultDetail(loc(context).poorBackhaul, '${r.poorCount}'),
              if (r.weakCount > 0)
                _ResultDetail(loc(context).weakBackhaul, '${r.weakCount}'),
              ..._buildMeshNodeDetails(context, r.nodes),
            ],
      _ when result.step == DiagnosticStep.runningSpeedTest => [
          if (result.rawData['serverHost'] is String &&
              (result.rawData['serverHost'] as String).isNotEmpty)
            _ResultDetail(
                loc(context).server, result.rawData['serverHost'] as String),
        ],
      _ when result.step == DiagnosticStep.checkingDhcp => [
          _ResultDetail(
              loc(context).status,
              result.isOk
                  ? loc(context).ok
                  : result.isSkipped
                      ? loc(context).staticIp
                      : loc(context).failed),
        ],
      _ => [
          if (result.rawData.containsKey('error'))
            _ResultDetail(
                loc(context).error, result.rawData['error'].toString()),
        ],
    };
  }

  List<_ResultDetail> _buildMeshNodeDetails(
      BuildContext context, List<MeshNodeBackhaulUIModel> nodes) {
    final details = <_ResultDetail>[];
    for (final n in nodes) {
      final severityText = switch (n.severity) {
        MeshBackhaulSeverity.healthy => loc(context).healthy,
        MeshBackhaulSeverity.weak => loc(context).weak,
        MeshBackhaulSeverity.poor => loc(context).poor,
      };
      final staleMarker = n.isStale ? ' ⚠️ ${loc(context).stale}' : '';
      details.add(_ResultDetail(
        n.label,
        '${n.linkType} • $severityText$staleMarker',
      ));
      if (n.parentLabel != null && n.parentLabel!.isNotEmpty) {
        details.add(
            _ResultDetail('  ${loc(context).connectedTo}', n.parentLabel!));
      }
      if (!n.isWired && n.signalStrengthDbm != 0) {
        final signalLevel = getWifiSignalLevel(n.signalStrengthDbm);
        details.add(_ResultDetail('  ${loc(context).signal}',
            '${n.signalStrengthDbm} dBm (${signalLevel.displayTitle})'));
      }
      if (n.lastUplinkRateKbps > 0 || n.lastDownlinkRateKbps > 0) {
        final up = n.lastUplinkRateKbps > 0
            ? '↑${NetworkUtils.formatSpeed(n.lastUplinkRateKbps)}'
            : '--';
        final down = n.lastDownlinkRateKbps > 0
            ? '↓${NetworkUtils.formatSpeed(n.lastDownlinkRateKbps)}'
            : '--';
        details.add(_ResultDetail('  ${loc(context).speed}', '$down / $up'));
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
                loc(context).msLatency(latencyMs),
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
                label: loc(context).download,
                value: downloadMbps,
                icon: Icons.download,
                color: colorScheme.primary,
              ),
            ),
            AppGap.lg(),
            Expanded(
              child: hasUpload
                  ? SpeedGauge(
                      label: loc(context).upload,
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
                          loc(context).notAvailable,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        AppGap.xs(),
                        AppText.labelSmall(loc(context).upload),
                      ],
                    ),
            ),
          ],
        ),
        if (!hasUpload) ...[
          AppGap.sm(),
          AppText.bodySmall(
            loc(context).uploadTestNotSupported,
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
                loc(context).scoreValue(device.overallScore),
                color: scoreColor,
              ),
            ],
          ),
          AppText.bodySmall(
            _formatSubtitle(context, device),
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _formatSubtitle(BuildContext context, DeviceScoreUIModel d) {
    final parts = <String>[];
    if (!d.isWireless) {
      parts.add(loc(context).wired);
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
