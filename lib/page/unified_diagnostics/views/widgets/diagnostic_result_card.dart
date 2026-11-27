import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_result.dart';
import '../../models/diagnostic_state.dart';
import '../../models/diagnostic_probe_ui_models.dart';
import 'signal_level_label.dart';

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
    final (title, metric, unit, subtitle) = _extractMetrics(context, result);

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
    final (title, _, _, _) = _extractMetrics(context, result);
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
          AppButton.text(
            identifier: 'diagnostic-result-close',
            label: loc(context).close,
            onTap: () => Navigator.of(context).pop(),
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
    BuildContext context,
    DiagnosticStepUIModel result,
  ) {
    final l = loc(context);
    return switch (result) {
      WanStatusCheckUIModel r => (
          l.wanStatus,
          r.isUp ? l.diagnosticsWanUp : l.diagnosticsWanDown,
          '',
          r.ipAddress.isNotEmpty ? r.ipAddress : l.diagnosticsNoIpAssigned,
        ),
      PingCheckUIModel r => (
          _pingTitle(context, r.step),
          r.allFailed ? '--' : '${r.avgResponseTime}',
          r.allFailed ? '' : 'ms',
          r.allFailed
              ? l.diagnosticsConnectionFailed
              : l.diagnosticsPacketsReceived(r.successCount, r.totalCount),
        ),
      WifiSignalCheckUIModel r => (
          l.wifiSignal,
          r.connectedDevices == 0 ? '--' : '${r.rssi}',
          r.connectedDevices == 0 ? '' : 'dBm',
          r.connectedDevices == 0
              ? l.diagnosticsNoWirelessClients
              : l.diagnosticsClientsOnBand(r.connectedDevices, r.band),
        ),
      DhcpPoolCheckUIModel r => (
          l.diagnosticsDhcpPool,
          r.dhcpEnabled ? '${(r.usageRatio * 100).toInt()}' : '--',
          r.dhcpEnabled ? '%' : '',
          r.dhcpEnabled
              ? l.diagnosticsAddressesUsed(r.usedLeases, r.capacity)
              : l.dhcpDisabled,
        ),
      ConnectedDevicesCheckUIModel r => (
          l.connectedDevices,
          '${r.totalDevices}',
          '',
          l.diagnosticsActiveDevices(r.activeDevices),
        ),
      DeviceIssuesCheckUIModel r => (
          l.deviceIssues,
          '${r.devicesWithIssues}',
          '',
          r.devicesWithIssues == 0
              ? l.diagnosticsAllDevicesHealthy
              : l.diagnosticsTotalDevices(r.totalDevices),
        ),
      WifiCoverageCheckUIModel r => (
          l.wifiCoverage,
          '${r.averageSignalStrength}',
          'dBm',
          r.weakSignalDevices.isEmpty
              ? l.diagnosticsDevicesGoodSignal(r.totalWirelessDevices)
              : l.diagnosticsDevicesWeakSignal(r.weakSignalDevices.length),
        ),
      DnsLookupCheckUIModel r => (
          l.dnsResolution,
          r.hasResolved ? '${r.responseTimeMs}' : '--',
          r.hasResolved ? 'ms' : '',
          r.hasResolved
              ? l.diagnosticsResolvedHost(r.hostName)
              : l.failedToResolve,
        ),
      IntermittentCheckUIModel r => (
          l.diagnosticsConnectionStability,
          '${(r.pingSuccessRate * 100).toInt()}',
          '%',
          l.diagnosticsJitterAndLatency(r.jitterMs, r.averageLatencyMs),
        ),
      MeshBackhaulCheckUIModel r => (
          l.diagnosticsMeshBackhaul,
          r.nodes.isEmpty ? '--' : '${r.nodes.length}',
          r.nodes.isEmpty ? '' : l.diagnosticsNodesUnit(r.nodes.length),
          r.nodes.isEmpty
              ? l.diagnosticsSingleRouter
              : _getMeshSummary(context, r),
        ),
      TracerouteCheckUIModel r => (
          l.diagnosticsNetworkPath,
          '${r.hops.length}',
          l.diagnosticsHopsUnit(r.hops.length),
          r.slowHops.isEmpty
              ? l.diagnosticsAllHopsResponsive
              : l.diagnosticsSlowHops(r.slowHops.length),
        ),
      ChannelCongestionCheckUIModel r => (
          l.diagnosticsChannelCongestion,
          r.busiest?.utilizationPercent?.toString() ?? '--',
          r.busiest?.utilizationPercent == null ? '' : '%',
          switch (r.busiest) {
            ChannelCongestionRadioUIModel(:final band, :final channel?) =>
              l.diagnosticsBusiestChannel(channel, band),
            _ => l.diagnosticsNoChannelReading,
          },
        ),
      _ when result.step == DiagnosticStep.runningSpeedTest => (
          l.speedTest,
          _getSpeedMetric(result.rawData),
          'Mbps',
          _getSpeedSubtitle(context, result.rawData),
        ),
      _ => (
          _stepTitle(context, result.step),
          '--',
          '',
          '',
        ),
    };
  }

  String _getMeshSummary(BuildContext context, MeshBackhaulCheckUIModel r) {
    final issues = <String>[];
    if (r.poorCount > 0) {
      issues.add(loc(context).diagnosticsPoorNodes(r.poorCount));
    }
    if (r.weakCount > 0) {
      issues.add(loc(context).diagnosticsWeakNodes(r.weakCount));
    }
    if (issues.isEmpty) return loc(context).diagnosticsAllNodesHealthy;
    return issues.join(', ');
  }

  String _getSpeedMetric(Map<String, dynamic> rawData) {
    final download = (rawData['downloadMbps'] as num?)?.toDouble() ?? 0;
    return download.toStringAsFixed(0);
  }

  String _getSpeedSubtitle(BuildContext context, Map<String, dynamic> rawData) {
    final upload = (rawData['uploadMbps'] as num?)?.toDouble();
    final latency = rawData['latencyMs'] as int?;
    final parts = <String>[];
    if (upload != null && upload > 0) {
      parts.add(loc(context).diagnosticsUploadSpeed(upload.toStringAsFixed(0)));
    }
    if (latency != null) {
      parts.add(loc(context).diagnosticsLatencyMs(latency));
    }
    return parts.join(' | ');
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
      DiagnosticSeverity.ok => (
          Icons.check_circle_outline,
          loc(context).diagnosticsStatusOk
        ),
      DiagnosticSeverity.warning => (
          Icons.warning_amber_outlined,
          loc(context).warning
        ),
      DiagnosticSeverity.error => (Icons.error_outline, loc(context).error),
      DiagnosticSeverity.skipped => (
          Icons.remove_circle_outline,
          loc(context).skipped
        ),
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
        // Flexible, so a word too wide for the card (a translated "Down", say)
        // goes on to a second line instead of overflowing (#1778).
        Flexible(child: AppText.displaySmall(metric, color: color)),
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
                    // See `step_result_tile.dart`: the medium is nullable and
                    // the honest word for absent is `unknown` (#1555).
                    node.linkType ?? loc(context).unknown,
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
                      '${node.signalStrengthDbm} dBm '
                      '(${diagnosticsSignalLevelLabel(context, node.signalStrengthDbm)})',
                      colorScheme,
                    ),
                  if (node.lastDownlinkRateKbps > 0)
                    _buildChip(
                      NetworkUtils.formatSpeed(node.lastDownlinkRateKbps),
                      colorScheme,
                      icon: Icons.arrow_downward,
                    ),
                  if (node.lastUplinkRateKbps > 0)
                    _buildChip(
                      NetworkUtils.formatSpeed(node.lastUplinkRateKbps),
                      colorScheme,
                      icon: Icons.arrow_upward,
                    ),
                  if (node.isStale)
                    _buildChip(
                      loc(context).stale,
                      colorScheme,
                      icon: Icons.timer_outlined,
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

  /// A chip is text, optionally prefixed by an [icon].
  ///
  /// The icon is a real icon rather than a Unicode character in [text] (these
  /// chips used to read '↓12 Mbps' / '⏱ Stale'): neither the primary font nor
  /// any bundled fallback maps U+2191/U+2193/U+23F1, so the glyph's presence
  /// depended on whatever font happened to resolve it.
  Widget _buildChip(String text, ColorScheme colorScheme,
      {IconData? icon, bool isWarning = false}) {
    final color =
        isWarning ? colorScheme.tertiary : colorScheme.onSurfaceVariant;
    final label = AppText.bodySmall(text, color: color);
    if (icon == null) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon.font(icon, size: 12, color: color),
        AppGap.xs(),
        label,
      ],
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
            '${radio.averageRssi} dBm '
            '(${diagnosticsSignalLevelLabel(context, radio.averageRssi)})',
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.sm(),
          AppText.bodySmall(
            loc(context).diagnosticsClients(radio.clientCount),
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
    final (title, metric, unit, subtitle) =
        _extractIssueMetrics(context, result);

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
                isError ? loc(context).error : loc(context).warning,
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
    BuildContext context,
    DiagnosticStepUIModel result,
  ) {
    final l = loc(context);
    return switch (result) {
      MeshBackhaulCheckUIModel r => (
          l.diagnosticsMeshBackhaul,
          '${r.nodes.length}',
          l.diagnosticsNodesUnit(r.nodes.length),
          l.diagnosticsNodesWithIssues(r.poorCount + r.weakCount),
        ),
      WifiSignalCheckUIModel r => (
          l.wifiSignal,
          '${r.rssi}',
          'dBm',
          r.isWeakSignal
              ? l.diagnosticsWeakSignalDetected
              : l.diagnosticsClients(r.connectedDevices),
        ),
      PingCheckUIModel r => (
          _pingTitle(context, r.step),
          r.allFailed ? '--' : '${r.avgResponseTime}',
          r.allFailed ? '' : 'ms',
          r.allFailed
              ? l.diagnosticsConnectionFailed
              : l.diagnosticsPacketsLost(r.failureCount),
        ),
      WanStatusCheckUIModel r => (
          l.wanStatus,
          r.isUp ? l.diagnosticsWanUp : l.diagnosticsWanDown,
          '',
          r.ipAddress.isEmpty ? l.diagnosticsNoIpAssigned : r.ipAddress,
        ),
      DhcpPoolCheckUIModel r => (
          l.diagnosticsDhcpPool,
          '${(r.usageRatio * 100).toInt()}',
          '%',
          r.isExhausted
              ? l.diagnosticsPoolExhausted
              : l.diagnosticsNearCapacity,
        ),
      // Any other step: its name and no metric. Before #1778 this showed the
      // step's enum name and its description key, untranslated.
      _ => (_stepTitle(context, result.step), '--', '', ''),
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

/// A ping step's name on a result card.
String _pingTitle(BuildContext context, DiagnosticStep step) => switch (step) {
      DiagnosticStep.pingGateway => loc(context).gateway,
      DiagnosticStep.pingDns => loc(context).dnsServer,
      DiagnosticStep.pingInternet => loc(context).internet,
      _ => loc(context).ping,
    };

/// A step's name on a result card, for a result with no card of its own.
String _stepTitle(BuildContext context, DiagnosticStep step) {
  final l = loc(context);
  return switch (step) {
    DiagnosticStep.checkingWanStatus => l.wanStatus,
    DiagnosticStep.checkingDhcp => l.dhcp,
    DiagnosticStep.checkingDhcpPool => l.diagnosticsDhcpPool,
    DiagnosticStep.pingGateway => l.gateway,
    DiagnosticStep.pingDns => l.dnsServer,
    DiagnosticStep.pingInternet => l.internet,
    DiagnosticStep.dnsLookup => l.dnsLookupStep,
    DiagnosticStep.runningSpeedTest => l.speedTest,
    DiagnosticStep.checkingWifiSignal => l.wifiSignal,
    DiagnosticStep.checkingChannelCongestion => l.diagnosticsChannelCongestion,
    DiagnosticStep.checkingConnectedDevices => l.connectedDevices,
    DiagnosticStep.runningTraceroute => l.traceroute,
    DiagnosticStep.checkingMeshBackhaul => l.diagnosticsMeshBackhaul,
    _ => l.unknown,
  };
}
