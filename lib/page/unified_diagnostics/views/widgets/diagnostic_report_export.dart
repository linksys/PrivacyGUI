import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/diagnostic_result.dart';
import '../../models/diagnostic_state.dart';

class DiagnosticReportExporter {
  static Future<void> shareReport(UnifiedDiagnosticsState state) async {
    final report = _generateTextReport(state);
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

    await Share.share(
      report,
      subject: 'Network_Diagnostics_Report_$dateStr',
    );
  }

  static String _generateTextReport(UnifiedDiagnosticsState state) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    buffer.writeln('=== Linksys Network Diagnostics Report ===');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('Flow: ${_getFlowName(state)}');
    buffer.writeln();

    if (state.errorMessage != null) {
      buffer.writeln('ERROR: ${state.errorMessage}');
      buffer.writeln();
    }

    buffer.writeln('--- Diagnostic Results ---');
    for (final result in state.results) {
      final severityIcon = _getSeverityIcon(result.severity);
      buffer.writeln('[$severityIcon] ${_getStepTitle(result.step)}');

      final details = _getDetailsText(result);
      if (details.isNotEmpty) {
        buffer.writeln('    $details');
      }
    }
    buffer.writeln();

    if (state.speedTest != null) {
      buffer.writeln('--- Speed Test ---');
      buffer.writeln(
          'Download: ${state.speedTest!.downloadMbps.toStringAsFixed(1)} Mbps');
      if (state.speedTest!.hasUpload) {
        buffer.writeln(
            'Upload: ${state.speedTest!.uploadMbps.toStringAsFixed(1)} Mbps');
      }
      if (state.speedTest!.hasLatency) {
        buffer.writeln('Latency: ${state.speedTest!.latencyMs} ms');
      }
      buffer.writeln();
    }

    if (state.recommendations.isNotEmpty) {
      buffer.writeln('--- Recommendations ---');
      for (final rec in state.recommendations) {
        buffer.writeln('• ${_getRecTitle(rec.titleKey)}');
        buffer.writeln('  ${_getRecDescription(rec.descriptionKey)}');
      }
      buffer.writeln();
    }

    buffer.writeln('=== End of Report ===');
    return buffer.toString();
  }

  static String _getFlowName(UnifiedDiagnosticsState state) {
    return switch (state.flow) {
      DiagnosticFlow.internet => 'Internet Diagnostics',
      DiagnosticFlow.deviceIssues => 'Device Issues',
      DiagnosticFlow.wifiCoverage => 'WiFi Coverage',
      DiagnosticFlow.intermittent => 'Intermittent Connection',
      null => state.problemType == ProblemType.noInternet
          ? 'No Internet'
          : state.problemType == ProblemType.slowNetwork
              ? 'Slow Network'
              : 'Full Diagnostic',
    };
  }

  static String _getSeverityIcon(DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.ok => '✅',
      DiagnosticSeverity.warning => '⚠️',
      DiagnosticSeverity.error => '❌',
      DiagnosticSeverity.skipped => '⊘',
    };
  }

  static String _getStepTitle(DiagnosticStep step) {
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

  static String _getDetailsText(DiagnosticStepUIModel result) {
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

  static String _getRecTitle(String key) {
    return switch (key) {
      'diagnostics_rec_wan_down_title' => 'WAN Connection Down',
      'diagnostics_rec_no_ip_title' => 'No IP Address',
      'diagnostics_rec_dhcp_fail_title' => 'DHCP Failed',
      'diagnostics_rec_gateway_title' => 'Gateway Unreachable',
      'diagnostics_rec_dns_fail_title' => 'DNS Not Responding',
      'diagnostics_rec_dns_lookup_fail_title' => 'DNS Resolution Failed',
      'diagnostics_rec_internet_title' => 'Internet Unreachable',
      'diagnostics_rec_slow_download_title' => 'Slow Download Speed',
      'diagnostics_rec_slow_upload_title' => 'Slow Upload Speed',
      'diagnostics_rec_weak_wifi_title' => 'Weak WiFi Signal',
      'diagnostics_rec_many_devices_title' => 'Too Many Devices',
      'diagnostics_rec_bandwidth_hog_title' => 'High Bandwidth Devices',
      'diagnostics_rec_bottleneck_title' => 'Network Bottleneck Detected',
      _ => key,
    };
  }

  static String _getRecDescription(String key) {
    return switch (key) {
      'diagnostics_rec_wan_down_desc' =>
        'Check your modem connection and restart if needed.',
      'diagnostics_rec_no_ip_desc' =>
        'Try renewing DHCP lease or configure static IP.',
      'diagnostics_rec_dhcp_fail_desc' =>
        'Renew DHCP lease or check ISP settings.',
      'diagnostics_rec_gateway_desc' =>
        'Check cable connections between router and modem.',
      'diagnostics_rec_dns_fail_desc' =>
        'Try using alternate DNS servers like 8.8.8.8.',
      'diagnostics_rec_dns_lookup_fail_desc' =>
        'DNS servers reachable but cannot resolve names. Try alternate DNS like 8.8.8.8 or 1.1.1.1.',
      'diagnostics_rec_internet_desc' =>
        'Contact your ISP — the issue may be on their end.',
      'diagnostics_rec_slow_download_desc' =>
        'Contact your ISP about download speed issues.',
      'diagnostics_rec_slow_upload_desc' =>
        'Check for devices uploading large files.',
      'diagnostics_rec_weak_wifi_desc' =>
        'Move closer to router or add a mesh node.',
      'diagnostics_rec_many_devices_desc' =>
        'Consider enabling QoS or disconnecting unused devices.',
      'diagnostics_rec_bandwidth_hog_desc' =>
        'Some devices are using a lot of bandwidth.',
      'diagnostics_rec_bottleneck_desc' =>
        'Network latency detected at a specific hop.',
      _ => key,
    };
  }
}
