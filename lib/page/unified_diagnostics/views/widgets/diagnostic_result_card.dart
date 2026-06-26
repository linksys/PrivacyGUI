import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_result.dart';
import '../../models/diagnostic_state.dart';
import '../../services/unified_diagnostics_service.dart';

/// A card displaying a single diagnostic result with metric-focused layout.
///
/// Shows the primary metric prominently (large text) with severity-colored
/// accent and supporting details below. Tap to view details in bottom sheet.
class DiagnosticResultCard extends StatelessWidget {
  final DiagnosticStepUIModel result;

  const DiagnosticResultCard({super.key, required this.result});

  bool get _hasDetails {
    return switch (result) {
      MeshBackhaulCheckUIModel r => r.nodes.isNotEmpty,
      WifiSignalCheckUIModel r => r.radios.isNotEmpty,
      _ => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    final severityColor =
        _getSeverityColor(result.severity, colorScheme, appColors);
    final (title, metric, unit, subtitle) = _extractMetrics(result);

    return LayoutBlock(
      onTap: _hasDetails ? () => _showDetailsSheet(context, colorScheme) : null,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Title + Status indicator
          Row(
            children: [
              Expanded(
                child: AppText.titleSmall(title),
              ),
              _StatusBadge(
                severity: result.severity,
                color: severityColor,
              ),
            ],
          ),
          AppGap.lg(),
          // Primary metric
          _MetricDisplay(
            metric: metric,
            unit: unit,
            color: severityColor,
          ),
          if (subtitle.isNotEmpty) ...[
            AppGap.sm(),
            AppText.bodySmall(
              subtitle,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
          // Spacer for consistent card height (icon shown only if has details)
          AppGap.xs(),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: _hasDetails
                  ? colorScheme.onSurfaceVariant
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, ColorScheme colorScheme) {
    final (title, _, _, _) = _extractMetrics(result);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.titleMedium(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildAdditionalDetails(result, colorScheme),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc(context).close),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(
    DiagnosticSeverity severity,
    ColorScheme colorScheme,
    AppColorScheme? appColors,
  ) {
    return switch (severity) {
      DiagnosticSeverity.ok => appColors?.semanticSuccess ?? Colors.green,
      DiagnosticSeverity.warning => colorScheme.tertiary,
      DiagnosticSeverity.error => colorScheme.error,
      DiagnosticSeverity.skipped => colorScheme.onSurfaceVariant,
    };
  }

  (String title, String metric, String unit, String subtitle) _extractMetrics(
    DiagnosticStepUIModel result,
  ) {
    return switch (result) {
      WanStatusCheckUIModel r => (
          'WAN Status',
          r.isUp ? 'Up' : 'Down',
          '',
          r.ipAddress.isNotEmpty ? r.ipAddress : 'No IP assigned',
        ),
      PingCheckUIModel r => (
          _getPingTitle(r.step),
          r.allFailed ? '--' : '${r.avgResponseTime}',
          r.allFailed ? '' : 'ms',
          r.allFailed
              ? 'Connection failed'
              : '${r.successCount}/${r.totalCount} packets received',
        ),
      WifiSignalCheckUIModel r => (
          'WiFi Signal',
          r.connectedDevices == 0 ? '--' : '${r.rssi}',
          r.connectedDevices == 0 ? '' : 'dBm',
          r.connectedDevices == 0
              ? 'No wireless clients'
              : '${r.connectedDevices} clients on ${r.band}',
        ),
      DhcpPoolCheckUIModel r => (
          'DHCP Pool',
          r.dhcpEnabled ? '${(r.usageRatio * 100).toInt()}' : '--',
          r.dhcpEnabled ? '%' : '',
          r.dhcpEnabled
              ? '${r.usedLeases} of ${r.capacity} addresses used'
              : 'DHCP disabled',
        ),
      ConnectedDevicesCheckUIModel r => (
          'Connected Devices',
          '${r.totalDevices}',
          '',
          '${r.activeDevices} active',
        ),
      DeviceIssuesCheckUIModel r => (
          'Device Issues',
          '${r.devicesWithIssues}',
          '',
          r.devicesWithIssues == 0
              ? 'All devices healthy'
              : '${r.totalDevices} total devices',
        ),
      WifiCoverageCheckUIModel r => (
          'WiFi Coverage',
          '${r.averageSignalStrength}',
          'dBm',
          r.weakSignalDevices.isEmpty
              ? '${r.totalWirelessDevices} devices with good signal'
              : '${r.weakSignalDevices.length} devices with weak signal',
        ),
      DnsLookupCheckUIModel r => (
          'DNS Resolution',
          r.hasResolved ? '${r.responseTimeMs}' : '--',
          r.hasResolved ? 'ms' : '',
          r.hasResolved ? 'Resolved ${r.hostName}' : 'Failed to resolve',
        ),
      IntermittentCheckUIModel r => (
          'Connection Stability',
          '${(r.pingSuccessRate * 100).toInt()}',
          '%',
          'Jitter: ${r.jitterMs}ms, Latency: ${r.averageLatencyMs}ms',
        ),
      MeshBackhaulCheckUIModel r => (
          'Mesh Backhaul',
          r.nodes.isEmpty ? '--' : '${r.nodes.length}',
          r.nodes.isEmpty ? '' : 'nodes',
          r.nodes.isEmpty ? 'Single router setup' : _getMeshSummary(r),
        ),
      TracerouteCheckUIModel r => (
          'Network Path',
          '${r.hops.length}',
          'hops',
          r.slowHops.isEmpty
              ? 'All hops responsive'
              : '${r.slowHops.length} slow hops detected',
        ),
      _ when result.step == DiagnosticStep.runningSpeedTest => (
          'Speed Test',
          _getSpeedMetric(result.rawData),
          'Mbps',
          _getSpeedSubtitle(result.rawData),
        ),
      _ => (
          _getStepTitle(result.step),
          '--',
          '',
          '',
        ),
    };
  }

  String _getPingTitle(DiagnosticStep step) {
    return switch (step) {
      DiagnosticStep.pingGateway => 'Gateway',
      DiagnosticStep.pingDns => 'DNS Server',
      DiagnosticStep.pingInternet => 'Internet',
      _ => 'Ping',
    };
  }

  String _getMeshSummary(MeshBackhaulCheckUIModel r) {
    final issues = <String>[];
    if (r.poorCount > 0) issues.add('${r.poorCount} poor');
    if (r.weakCount > 0) issues.add('${r.weakCount} weak');
    if (issues.isEmpty) return 'All nodes healthy';
    return issues.join(', ');
  }

  String _getSpeedMetric(Map<String, dynamic> rawData) {
    final download = (rawData['downloadMbps'] as num?)?.toDouble() ?? 0;
    return download.toStringAsFixed(0);
  }

  String _getSpeedSubtitle(Map<String, dynamic> rawData) {
    final upload = (rawData['uploadMbps'] as num?)?.toDouble();
    final latency = rawData['latencyMs'] as int?;
    final parts = <String>[];
    if (upload != null && upload > 0) {
      parts.add('Upload: ${upload.toStringAsFixed(0)} Mbps');
    }
    if (latency != null) {
      parts.add('Latency: ${latency}ms');
    }
    return parts.join(' | ');
  }

  String _getStepTitle(DiagnosticStep step) {
    return switch (step) {
      DiagnosticStep.checkingWanStatus => 'WAN Status',
      DiagnosticStep.checkingDhcp => 'DHCP',
      DiagnosticStep.checkingDhcpPool => 'DHCP Pool',
      DiagnosticStep.pingGateway => 'Gateway',
      DiagnosticStep.pingDns => 'DNS Server',
      DiagnosticStep.pingInternet => 'Internet',
      DiagnosticStep.dnsLookup => 'DNS Lookup',
      DiagnosticStep.runningSpeedTest => 'Speed Test',
      DiagnosticStep.checkingWifiSignal => 'WiFi Signal',
      DiagnosticStep.checkingConnectedDevices => 'Connected Devices',
      DiagnosticStep.runningTraceroute => 'Traceroute',
      DiagnosticStep.checkingMeshBackhaul => 'Mesh Backhaul',
      _ => step.name,
    };
  }

  List<Widget> _buildAdditionalDetails(
    DiagnosticStepUIModel result,
    ColorScheme colorScheme,
  ) {
    return switch (result) {
      MeshBackhaulCheckUIModel r when r.nodes.isNotEmpty => [
          AppGap.lg(),
          _MeshNodesDetail(nodes: r.nodes, colorScheme: colorScheme),
        ],
      WifiSignalCheckUIModel r when r.radios.isNotEmpty => [
          AppGap.lg(),
          _RadioStatsDetail(radios: r.radios, colorScheme: colorScheme),
        ],
      _ => const [],
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final DiagnosticSeverity severity;
  final Color color;

  const _StatusBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (severity) {
      DiagnosticSeverity.ok => (Icons.check_circle_outline, 'OK'),
      DiagnosticSeverity.warning => (Icons.warning_amber_outlined, 'Warning'),
      DiagnosticSeverity.error => (Icons.error_outline, 'Error'),
      DiagnosticSeverity.skipped => (Icons.remove_circle_outline, 'Skipped'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        AppGap.xs(),
        AppText.labelSmall(label, color: color),
      ],
    );
  }
}

class _MetricDisplay extends StatelessWidget {
  final String metric;
  final String unit;
  final Color color;

  const _MetricDisplay({
    required this.metric,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AppText.displaySmall(metric, color: color),
        if (unit.isNotEmpty) ...[
          AppGap.xs(),
          AppText.titleMedium(unit, color: color),
        ],
      ],
    );
  }
}

class _MeshNodesDetail extends StatelessWidget {
  final List<MeshNodeBackhaulUIModel> nodes;
  final ColorScheme colorScheme;
  final AppColorScheme? appColors;

  const _MeshNodesDetail({
    required this.nodes,
    required this.colorScheme,
    this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors ?? Theme.of(context).extension<AppColorScheme>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final node in nodes) ...[
          _MeshNodeRow(node: node, colorScheme: colorScheme, appColors: colors),
          if (node != nodes.last) AppGap.sm(),
        ],
      ],
    );
  }
}

class _MeshNodeRow extends StatelessWidget {
  final MeshNodeBackhaulUIModel node;
  final ColorScheme colorScheme;
  final AppColorScheme? appColors;

  const _MeshNodeRow({
    required this.node,
    required this.colorScheme,
    this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (node.severity) {
      MeshBackhaulSeverity.healthy =>
        appColors?.semanticSuccess ?? Colors.green,
      MeshBackhaulSeverity.weak => colorScheme.tertiary,
      MeshBackhaulSeverity.poor => colorScheme.error,
    };

    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: severityColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        AppGap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText.labelMedium(node.label),
                  ),
                  AppText.bodySmall(
                    node.linkType,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (!node.isWired && node.signalStrengthDbm != 0)
                    _buildChip(
                      '${node.signalStrengthDbm} dBm (${getWifiSignalLevel(node.signalStrengthDbm).displayTitle})',
                      colorScheme,
                    ),
                  if (node.lastDownlinkRateKbps > 0)
                    _buildChip(
                      '↓${NetworkUtils.formatSpeed(node.lastDownlinkRateKbps)}',
                      colorScheme,
                    ),
                  if (node.lastUplinkRateKbps > 0)
                    _buildChip(
                      '↑${NetworkUtils.formatSpeed(node.lastUplinkRateKbps)}',
                      colorScheme,
                    ),
                  if (node.isStale)
                    _buildChip(
                      '⏱ Stale',
                      colorScheme,
                      isWarning: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String text, ColorScheme colorScheme,
      {bool isWarning = false}) {
    return AppText.bodySmall(
      text,
      color: isWarning ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
    );
  }
}

class _RadioStatsDetail extends StatelessWidget {
  final List<RadioSignalStatsUIModel> radios;
  final ColorScheme colorScheme;

  const _RadioStatsDetail({required this.radios, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final activeRadios = radios.where((r) => r.hasClients).toList();
    if (activeRadios.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final radio in activeRadios)
          _RadioStatChip(radio: radio, colorScheme: colorScheme),
      ],
    );
  }
}

class _RadioStatChip extends StatelessWidget {
  final RadioSignalStatsUIModel radio;
  final ColorScheme colorScheme;

  const _RadioStatChip({required this.radio, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final signalLevel = getWifiSignalLevel(radio.averageRssi);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.labelSmall(radio.band),
          AppGap.xs(),
          AppText.bodySmall(
            '${radio.averageRssi} dBm (${signalLevel.displayTitle})',
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.sm(),
          AppText.bodySmall(
            '${radio.clientCount} clients',
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Full-width card for displaying diagnostic issues with expanded details.
class DiagnosticIssueCard extends StatelessWidget {
  final DiagnosticStepUIModel result;

  const DiagnosticIssueCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorScheme>();

    final isError = result.severity == DiagnosticSeverity.error;
    final severityColor = isError ? colorScheme.error : colorScheme.tertiary;
    final (title, metric, unit, subtitle) = _extractIssueMetrics(result);

    return LayoutBlock(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with severity indicator
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: AppText.titleSmall(title),
              ),
              Icon(
                isError ? Icons.error_outline : Icons.warning_amber_outlined,
                color: severityColor,
                size: 20,
              ),
              AppGap.xs(),
              AppText.labelSmall(
                isError ? 'Error' : 'Warning',
                color: severityColor,
              ),
            ],
          ),
          AppGap.md(),
          // Metric + subtitle in row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.displaySmall(
                metric,
                color: severityColor,
              ),
              if (unit.isNotEmpty) ...[
                AppGap.xs(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AppText.titleSmall(unit, color: severityColor),
                ),
              ],
              AppGap.lg(),
              Expanded(
                child: AppText.bodyMedium(
                  subtitle,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Details section
          ..._buildIssueDetails(result, colorScheme, appColors),
        ],
      ),
    );
  }

  (String, String, String, String) _extractIssueMetrics(
    DiagnosticStepUIModel result,
  ) {
    return switch (result) {
      MeshBackhaulCheckUIModel r => (
          'Mesh Backhaul',
          '${r.nodes.length}',
          'nodes',
          '${r.poorCount + r.weakCount} with issues',
        ),
      WifiSignalCheckUIModel r => (
          'WiFi Signal',
          '${r.rssi}',
          'dBm',
          r.isWeakSignal
              ? 'Weak signal detected'
              : '${r.connectedDevices} clients',
        ),
      PingCheckUIModel r => (
          _getPingTitleStatic(r.step),
          r.allFailed ? '--' : '${r.avgResponseTime}',
          r.allFailed ? '' : 'ms',
          r.allFailed ? 'Connection failed' : '${r.failureCount} packets lost',
        ),
      WanStatusCheckUIModel r => (
          'WAN Status',
          r.isUp ? 'Up' : 'Down',
          '',
          r.ipAddress.isEmpty ? 'No IP assigned' : r.ipAddress,
        ),
      DhcpPoolCheckUIModel r => (
          'DHCP Pool',
          '${(r.usageRatio * 100).toInt()}',
          '%',
          r.isExhausted ? 'Pool exhausted' : 'Near capacity',
        ),
      _ => (
          result.step.name,
          '--',
          '',
          result.descriptionKey,
        ),
    };
  }

  static String _getPingTitleStatic(DiagnosticStep step) {
    return switch (step) {
      DiagnosticStep.pingGateway => 'Gateway',
      DiagnosticStep.pingDns => 'DNS Server',
      DiagnosticStep.pingInternet => 'Internet',
      _ => 'Ping',
    };
  }

  List<Widget> _buildIssueDetails(
    DiagnosticStepUIModel result,
    ColorScheme colorScheme,
    AppColorScheme? appColors,
  ) {
    return switch (result) {
      MeshBackhaulCheckUIModel r when r.nodes.isNotEmpty => [
          AppGap.lg(),
          _MeshNodesDetail(
              nodes: r.nodes, colorScheme: colorScheme, appColors: appColors),
        ],
      WifiSignalCheckUIModel r when r.radios.isNotEmpty => [
          AppGap.lg(),
          _RadioStatsDetail(radios: r.radios, colorScheme: colorScheme),
        ],
      _ => const [],
    };
  }
}
