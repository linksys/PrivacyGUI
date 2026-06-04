import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/diagnostic_result.dart';
import '../models/diagnostic_state.dart';
import '../models/recommendation_catalog.dart';

/// Builds and shares a plain-text diagnostic report. Pure logic — no widgets.
class DiagnosticReportService {
  const DiagnosticReportService();

  Future<void> share(UnifiedDiagnosticsState state) async {
    final report = buildTextReport(state);
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    await Share.share(
      report,
      subject: 'Network_Diagnostics_Report_$dateStr',
    );
  }

  String buildTextReport(UnifiedDiagnosticsState state) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    buffer.writeln('=== Linksys Network Diagnostics Report ===');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('Flow: ${_flowName(state)}');
    buffer.writeln();

    if (state.error != null) {
      buffer.writeln('ERROR: ${state.error}');
      buffer.writeln();
    }

    buffer.writeln('--- Diagnostic Results ---');
    for (final result in state.results) {
      buffer.writeln(
          '[${_severityIcon(result.severity)}] ${_stepTitle(result.step)}');
      final details = _detailsText(result);
      if (details.isNotEmpty) buffer.writeln('    $details');
    }
    buffer.writeln();

    final speed = state.speedTest;
    if (speed != null) {
      buffer.writeln('--- Speed Test ---');
      buffer.writeln('Download: ${speed.downloadMbps.toStringAsFixed(1)} Mbps');
      if (speed.hasUpload) {
        buffer.writeln('Upload: ${speed.uploadMbps.toStringAsFixed(1)} Mbps');
      }
      if (speed.hasLatency) {
        buffer.writeln('Latency: ${speed.latencyMs} ms');
      }
      buffer.writeln();
    }

    if (state.recommendations.isNotEmpty) {
      buffer.writeln('--- Recommendations ---');
      for (final rec in state.recommendations) {
        buffer.writeln('• ${RecommendationCatalog.title(rec.titleKey)}');
        buffer.writeln(
            '  ${RecommendationCatalog.description(rec.descriptionKey)}');
      }
      buffer.writeln();
    }

    buffer.writeln('=== End of Report ===');
    return buffer.toString();
  }

  String _flowName(UnifiedDiagnosticsState state) {
    return switch (state.flow) {
      DiagnosticFlow.internet => 'Internet Diagnostics',
      DiagnosticFlow.deviceIssues => 'Device Issues',
      DiagnosticFlow.wifiCoverage => 'WiFi Coverage',
      DiagnosticFlow.meshBackhaul => 'Mesh Backhaul',
      DiagnosticFlow.intermittent => 'Intermittent Connection',
      null => 'Full Diagnostic',
    };
  }

  String _severityIcon(DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.ok => 'OK',
      DiagnosticSeverity.warning => 'WARN',
      DiagnosticSeverity.error => 'FAIL',
      DiagnosticSeverity.skipped => 'SKIP',
    };
  }

  String _stepTitle(DiagnosticStep step) {
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

  String _detailsText(DiagnosticStepUIModel result) {
    return switch (result) {
      WanStatusCheckUIModel r =>
        'Status: ${r.status}, IP: ${r.ipAddress}, Type: ${r.addressingType}',
      PingCheckUIModel r =>
        'Host: ${r.host}, Latency: ${r.avgResponseTime}ms, Success: ${r.successCount}/${r.totalCount}',
      WifiSignalCheckUIModel r =>
        'RSSI: ${r.rssi}dBm, Band: ${r.band}, Clients: ${r.connectedDevices}',
      DhcpPoolCheckUIModel r => r.dhcpEnabled
          ? 'Used: ${r.usedLeases}/${r.capacity} (${(r.usageRatio * 100).toInt()}%)'
          : 'DHCP Disabled',
      ConnectedDevicesCheckUIModel r =>
        'Total: ${r.totalDevices}, Active: ${r.activeDevices}',
      DnsLookupCheckUIModel r =>
        'Host: ${r.hostName}, Resolved: ${r.resolvedIps.join(", ")}',
      TracerouteCheckUIModel r =>
        'Target: ${r.targetHost}, Hops: ${r.hops.length}',
      _ => '',
    };
  }
}
