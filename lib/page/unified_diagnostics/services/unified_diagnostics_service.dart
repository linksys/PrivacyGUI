import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dns_client.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/device_score.dart';

final unifiedDiagnosticsServiceProvider =
    Provider<UnifiedDiagnosticsService?>((ref) {
  final usp = ref.watch(uspClientProvider);
  final awaiter = ref.watch(sseOperationAwaiterProvider);
  if (usp == null || awaiter == null) return null;
  return UnifiedDiagnosticsService(usp, awaiter);
});

/// Service encapsulating all USP operations for network diagnostics.
///
/// Uses:
/// - Codegen classes for GET operations (WanStatus, WiFiRadios, ConnectedDevices)
/// - SseOperationAwaiter for async Operate commands (Ping, Traceroute, SpeedTest)
class UnifiedDiagnosticsService {
  final UspClient _usp;
  final SseOperationAwaiter _awaiter;

  static const _defaultInternetHost =
      '1.1.1.1'; // Cloudflare — for internet check
  static const _defaultDnsHost = '8.8.8.8'; // Google DNS — for DNS check
  static const _defaultTracerouteHost = '8.8.8.8';

  UnifiedDiagnosticsService(this._usp, this._awaiter);

  // ─── WAN Status ──────────────────────────────────────────

  /// Check WAN interface status using codegen WanStatus.
  Future<WanStatusUIModel> checkWanStatus() async {
    logger.d('[Diagnostics] Checking WAN status');
    final wan = await WanStatus.fetch(_usp);
    return WanStatusUIModel(
      status: wan.status,
      ipAddress: wan.ipAddress,
      subnetMask: wan.subnetMask,
      addressingType: wan.addressingType,
    );
  }

  // ─── Ping Operations ─────────────────────────────────────

  // ─── Shared Session ──────────────────────────────────────

  /// Start a shared subscription session for batch diagnostics.
  /// Call [endSession] when diagnostics complete.
  Future<void> startSession() async {
    logger.d('[Diagnostics] Starting shared session');
    await _awaiter.startSharedSession(
      referencePath: 'Device.IP.Diagnostics.',
    );
  }

  /// End the shared subscription session.
  Future<void> endSession() async {
    logger.d('[Diagnostics] Ending shared session');
    await _awaiter.endSharedSession();
  }

  // ─── Ping Operations ─────────────────────────────────────

  /// Ping a host and return parsed result (uses shared session if active).
  Future<PingResult> ping(
    String host, {
    int repeatCount = 3,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    logger.d('[Diagnostics] Pinging $host (count=$repeatCount)');
    try {
      final result = await _awaiter.executeInSession(
        operateCommand: 'Device.IP.Diagnostics.IPPing()',
        args: {
          'Host': host,
          'NumberOfRepetitions': repeatCount.toString(),
        },
        timeout: timeout,
      );
      logger.d('[Diagnostics] Ping $host complete: ${result.status}');
      return PingResult.fromOperateResult(result, host);
    } catch (e) {
      logger.e('[Diagnostics] Ping $host failed: $e');
      rethrow;
    }
  }

  /// Ping the default gateway.
  Future<PingResult> pingGateway({int repeatCount = 3}) async {
    final wan = await checkWanStatus();
    if (wan.ipAddress.isEmpty) {
      throw Exception('No WAN IP address — cannot determine gateway');
    }
    final gateway = _deriveGateway(wan.ipAddress, wan.subnetMask);
    return ping(gateway, repeatCount: repeatCount);
  }

  /// Ping DNS server (Google 8.8.8.8).
  Future<PingResult> pingDns({
    String host = _defaultDnsHost,
    int repeatCount = 3,
  }) async {
    logger.d('[Diagnostics] Pinging DNS $host');
    return ping(host, repeatCount: repeatCount);
  }

  /// Ping an external host to verify internet connectivity (Cloudflare 1.1.1.1).
  Future<PingResult> pingInternet({
    String host = _defaultInternetHost,
    int repeatCount = 3,
  }) async {
    logger.d('[Diagnostics] Pinging Internet $host');
    return ping(host, repeatCount: repeatCount);
  }

  // ─── DNS ─────────────────────────────────────────────────

  /// Fetch DNS client configuration and configured server list.
  Future<DnsClient> getDnsClient() async {
    logger.d('[Diagnostics] Getting DNS client info');
    return DnsClient.fetch(_usp);
  }

  /// Run NSLookup to validate that DNS resolution actually works
  /// (uses shared session if active).
  Future<NsLookupResult> nsLookup(
    String hostName, {
    String? dnsServer,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    logger.d('[Diagnostics] NSLookup $hostName'
        '${dnsServer != null ? ' via $dnsServer' : ''}');
    try {
      final args = <String, String>{'HostName': hostName};
      if (dnsServer != null && dnsServer.isNotEmpty) {
        args['DNSServer'] = dnsServer;
      }
      final result = await _awaiter.executeInSession(
        operateCommand: 'Device.DNS.Diagnostics.NSLookupDiagnostics()',
        args: args,
        timeout: timeout,
      );
      logger.d('[Diagnostics] NSLookup $hostName complete: ${result.status}');
      return NsLookupResult.fromOperateResult(result, hostName);
    } catch (e) {
      logger.e('[Diagnostics] NSLookup $hostName failed: $e');
      rethrow;
    }
  }

  // ─── Traceroute ──────────────────────────────────────────

  /// Run traceroute to identify network path and bottlenecks.
  Future<TracerouteResult> traceroute({
    String host = _defaultTracerouteHost,
    int maxHops = 30,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    logger.d('[Diagnostics] Running traceroute to $host');
    final result = await _awaiter.execute(
      operateCommand: 'Device.IP.Diagnostics.TraceRoute()',
      referencePath: 'Device.IP.Diagnostics.TraceRoute.',
      args: {
        'Host': host,
        'MaxHopCount': maxHops.toString(),
      },
      timeout: timeout,
    );
    return TracerouteResult.fromOperateResult(result, host);
  }

  // ─── WiFi & Devices ──────────────────────────────────────

  /// Fetch WiFi radio status (channels, signal info).
  Future<List<WiFiRadioUIModel>> checkWifiRadios() async {
    logger.d('[Diagnostics] Checking WiFi radios');
    final radios = await WiFiRadios.fetch(_usp);
    return radios.items
        .map((r) => WiFiRadioUIModel(
              instancePath: r.instancePath,
              band: r.operatingFrequencyBand,
              channel: r.channel,
              channelBandwidth: r.operatingChannelBandwidth,
              transmitPower: r.transmitPower,
              status: r.status,
              autoChannel: r.autoChannelEnable,
            ))
        .toList();
  }

  /// Fetch connected devices for bandwidth analysis.
  Future<ConnectedDevicesUIModel> checkConnectedDevices() async {
    logger.d('[Diagnostics] Checking connected devices');
    final devices = await ConnectedDevices.fetch(_usp);

    final activeDevices = devices.items.where((d) => d.isActive).toList();

    // Identify high-bandwidth devices (simplified heuristic)
    final highBandwidth = activeDevices
        .where((d) =>
            (d.lastDataDownlinkRate ?? 0) > 50000000 ||
            (d.lastDataUplinkRate ?? 0) > 10000000)
        .map((d) => d.hostName.isNotEmpty ? d.hostName : d.macAddress)
        .toList();

    return ConnectedDevicesUIModel(
      totalDevices: devices.items.length,
      activeDevices: activeDevices.length,
      highBandwidthDevices: highBandwidth,
    );
  }

  // ─── Device Scores ────────────────────────────────────────

  /// Get device scores for all connected devices.
  Future<List<DeviceScoreUIModel>> getDeviceScores() async {
    logger.d('[Diagnostics] Getting device scores');
    final devices = await ConnectedDevices.fetch(_usp);

    return devices.items
        .where((d) => d.isActive)
        .map((d) => DeviceScoreUIModel(
              macAddress: d.macAddress,
              name: d.hostName.isNotEmpty
                  ? d.hostName
                  : d.friendlyName ?? d.macAddress,
              rssiDbm: d.signalStrength,
              downlinkKbps: d.lastDataDownlinkRate,
              uplinkKbps: d.lastDataUplinkRate,
              isWireless:
                  d.interfaceType?.contains('WiFi') ?? d.signalStrength != null,
            ))
        .toList();
  }

  /// Get device score for a specific device by MAC address.
  Future<DeviceScoreUIModel?> getDeviceScore(String macAddress) async {
    final scores = await getDeviceScores();
    return scores.where((s) => s.macAddress == macAddress).firstOrNull;
  }

  // ─── DHCP Pool ────────────────────────────────────────────

  /// Check DHCP pool capacity and current usage.
  ///
  /// Capacity = MaxAddress - MinAddress + 1.
  /// Used = number of active DHCP leases in `Device.DHCPv4.Server.Pool.1.Client.*`.
  Future<DhcpPoolUsageUIModel> checkDhcpPool() async {
    logger.d('[Diagnostics] Checking DHCP pool usage');
    final lan = await LanNetworkInfo.fetch(_usp);
    final clients = await DhcpClients.fetch(_usp);

    final capacity = _ipRangeSize(lan.minAddress, lan.maxAddress);
    final activeLeases = clients.items.where((c) => c.active).length;

    return DhcpPoolUsageUIModel(
      enabled: lan.dhcpEnabled,
      minAddress: lan.minAddress,
      maxAddress: lan.maxAddress,
      capacity: capacity,
      usedLeases: activeLeases,
      totalLeases: clients.items.length,
    );
  }

  /// Compute the inclusive size of an IPv4 address range.
  /// Returns 0 when either endpoint is malformed or the range is inverted.
  int _ipRangeSize(String minAddress, String maxAddress) {
    final lo = _ipv4ToInt(minAddress);
    final hi = _ipv4ToInt(maxAddress);
    if (lo == null || hi == null || hi < lo) return 0;
    return hi - lo + 1;
  }

  int? _ipv4ToInt(String address) {
    final parts = address.split('.');
    if (parts.length != 4) return null;
    int result = 0;
    for (final p in parts) {
      final octet = int.tryParse(p);
      if (octet == null || octet < 0 || octet > 255) return null;
      result = (result << 8) | octet;
    }
    return result;
  }

  // ─── WiFi Coverage ───────────────────────────────────────

  /// Analyze WiFi coverage based on device signal strengths.
  Future<WifiCoverageUIModel> analyzeWifiCoverage() async {
    logger.d('[Diagnostics] Analyzing WiFi coverage');
    final devices = await ConnectedDevices.fetch(_usp);
    final radios = await WiFiRadios.fetch(_usp);

    final wirelessDevices = devices.items
        .where((d) => d.isActive && d.signalStrength != null)
        .toList();

    final weakSignalDevices = wirelessDevices
        .where((d) => d.signalStrength! < -70)
        .map((d) => DeviceSignalUIModel(
              name: d.hostName.isNotEmpty ? d.hostName : d.macAddress,
              macAddress: d.macAddress,
              rssiDbm: d.signalStrength!,
            ))
        .toList();

    final avgSignal = wirelessDevices.isNotEmpty
        ? wirelessDevices
                .map((d) => d.signalStrength!)
                .reduce((a, b) => a + b) ~/
            wirelessDevices.length
        : 0;

    return WifiCoverageUIModel(
      totalWirelessDevices: wirelessDevices.length,
      weakSignalDevices: weakSignalDevices,
      averageSignalStrength: avgSignal,
      radios: radios.items
          .map((r) => WiFiRadioUIModel(
                instancePath: r.instancePath,
                band: r.operatingFrequencyBand,
                channel: r.channel,
                channelBandwidth: r.operatingChannelBandwidth,
                transmitPower: r.transmitPower,
                status: r.status,
                autoChannel: r.autoChannelEnable,
              ))
          .toList(),
    );
  }

  // ─── Per-Radio WiFi Signal ───────────────────────────────

  /// Analyze WiFi signal strength per radio by joining
  /// `WiFi.AccessPoint → SSIDReference → SSID.LowerLayers → Radio`
  /// and aggregating RSSI from each AP's associated devices.
  ///
  /// Falls back gracefully when the join cannot be resolved for a given AP —
  /// affected clients are reported under the `unknown` radio bucket.
  Future<WifiSignalPerRadioUIModel> analyzeWifiSignalPerRadio() async {
    logger.d('[Diagnostics] Analyzing WiFi signal per radio');
    final radios = await WiFiRadios.fetch(_usp);
    final accessPoints = await WiFiAccessPoints.fetch(_usp);
    final ssids = await WiFiSsids.fetch(_usp);
    final clients = await WifiClients.fetch(_usp);

    final ssidByPath = {for (final s in ssids.items) s.instancePath: s};
    final apToRadio = <String, String>{};
    for (final ap in accessPoints.items) {
      final ssidPath = _normalizeRefPath(ap.ssidReference);
      if (ssidPath.isEmpty) continue;
      final ssid = ssidByPath[ssidPath];
      if (ssid == null) continue;
      final radioPath = _firstReference(ssid.lowerLayers);
      if (radioPath.isEmpty) continue;
      apToRadio[ap.instancePath] = radioPath;
    }

    final perRadio = <String, _RadioBucket>{};
    for (final r in radios.items) {
      perRadio[r.instancePath] = _RadioBucket(
        instancePath: r.instancePath,
        band: r.operatingFrequencyBand,
        channel: r.channel,
        status: r.status,
      );
    }
    final unknownBucket = _RadioBucket(
      instancePath: '',
      band: 'Unknown',
      channel: 0,
      status: 'Unknown',
    );

    for (final c in clients.items) {
      if (!c.active) continue;
      final radioPath = apToRadio[c.parentPath];
      final bucket =
          (radioPath != null ? perRadio[radioPath] : null) ?? unknownBucket;
      bucket.rssiSamples.add(c.signalStrength);
      bucket.clientCount += 1;
    }

    final radioStats = perRadio.values
        .map((b) => RadioSignalStatsUIModel(
              instancePath: b.instancePath,
              band: b.band,
              channel: b.channel,
              status: b.status,
              clientCount: b.clientCount,
              averageRssi: b.averageRssi,
              minRssi: b.minRssi,
            ))
        .toList()
      ..sort((a, b) => a.instancePath.compareTo(b.instancePath));

    if (unknownBucket.clientCount > 0) {
      radioStats.add(RadioSignalStatsUIModel(
        instancePath: '',
        band: 'Unknown',
        channel: 0,
        status: 'Unknown',
        clientCount: unknownBucket.clientCount,
        averageRssi: unknownBucket.averageRssi,
        minRssi: unknownBucket.minRssi,
      ));
    }

    return WifiSignalPerRadioUIModel(radios: radioStats);
  }

  /// Normalize a TR-181 reference path so it always ends with `.`.
  /// Returns empty string if input is empty.
  String _normalizeRefPath(String ref) {
    final trimmed = ref.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('.') ? trimmed : '$trimmed.';
  }

  /// Pick the first reference in a comma-separated `LowerLayers` value.
  String _firstReference(String lowerLayers) {
    if (lowerLayers.isEmpty) return '';
    final first = lowerLayers.split(',').first;
    return _normalizeRefPath(first);
  }

  // ─── Intermittent Check ──────────────────────────────────

  /// Check for intermittent connection issues.
  Future<IntermittentUIModel> checkIntermittent() async {
    logger.d('[Diagnostics] Checking intermittent issues');
    final systemInfo = await SystemInfo.fetch(_usp);

    // Run multiple pings to detect jitter
    final pingResults = <int>[];
    for (int i = 0; i < 5; i++) {
      try {
        final result = await ping('1.1.1.1', repeatCount: 1);
        if (result.successCount > 0) {
          pingResults.add(result.avgResponseTime);
        } else {
          pingResults.add(-1); // Failed ping
        }
      } catch (e) {
        pingResults.add(-1);
      }
    }

    final successfulPings = pingResults.where((p) => p > 0).toList();
    final failedPings = pingResults.where((p) => p < 0).length;
    final avgLatency = successfulPings.isNotEmpty
        ? successfulPings.reduce((a, b) => a + b) ~/ successfulPings.length
        : 0;
    final jitter =
        successfulPings.length >= 2 ? _calculateJitter(successfulPings) : 0;

    return IntermittentUIModel(
      uptimeSeconds: systemInfo.uptime,
      pingSuccessRate: (pingResults.length - failedPings) / pingResults.length,
      averageLatencyMs: avgLatency,
      jitterMs: jitter,
      hasHighJitter: jitter > 50,
      hasPacketLoss: failedPings > 0,
      recentReboot: systemInfo.uptime < 300, // Less than 5 minutes
    );
  }

  int _calculateJitter(List<int> latencies) {
    if (latencies.length < 2) return 0;
    int totalDiff = 0;
    for (int i = 1; i < latencies.length; i++) {
      totalDiff += (latencies[i] - latencies[i - 1]).abs();
    }
    return totalDiff ~/ (latencies.length - 1);
  }

  // ─── Helpers ─────────────────────────────────────────────

  /// Derive default gateway from IP and subnet mask.
  /// Simple heuristic: assume gateway is .1 in the subnet.
  String _deriveGateway(String ipAddress, String subnetMask) {
    final ipParts = ipAddress.split('.').map(int.parse).toList();
    final maskParts = subnetMask.split('.').map(int.parse).toList();

    if (ipParts.length != 4 || maskParts.length != 4) {
      return '192.168.1.1'; // fallback
    }

    // Network address + .1
    final gateway = <int>[];
    for (int i = 0; i < 4; i++) {
      gateway.add(ipParts[i] & maskParts[i]);
    }
    gateway[3] = 1;

    return gateway.join('.');
  }
}

/// WAN status information.
class WanStatusUIModel {
  final String status;
  final String ipAddress;
  final String subnetMask;
  final String addressingType;

  const WanStatusUIModel({
    required this.status,
    required this.ipAddress,
    required this.subnetMask,
    required this.addressingType,
  });

  bool get isUp => status == 'Up';
  bool get hasIp => ipAddress.isNotEmpty;
}

/// DHCP pool usage information.
class DhcpPoolUsageUIModel {
  final bool enabled;
  final String minAddress;
  final String maxAddress;
  final int capacity;
  final int usedLeases;
  final int totalLeases;

  const DhcpPoolUsageUIModel({
    required this.enabled,
    required this.minAddress,
    required this.maxAddress,
    required this.capacity,
    required this.usedLeases,
    required this.totalLeases,
  });

  /// Fraction of pool used (0.0–1.0). Returns 0 when capacity is unknown.
  double get usageRatio => capacity > 0 ? usedLeases / capacity : 0;

  /// Pool is at or beyond capacity — new clients cannot get a lease.
  bool get isExhausted => capacity > 0 && usedLeases >= capacity;

  /// Pool is approaching capacity (>=90%).
  bool get isNearCapacity => usageRatio >= 0.9;

  /// Capacity unknown — Min/Max malformed or DHCP disabled.
  bool get capacityUnknown => capacity == 0;
}

/// WiFi radio information.
class WiFiRadioUIModel {
  final String instancePath;
  final String band;
  final int channel;
  final String channelBandwidth;
  final int transmitPower;
  final String status;
  final bool autoChannel;

  const WiFiRadioUIModel({
    required this.instancePath,
    required this.band,
    required this.channel,
    required this.channelBandwidth,
    required this.transmitPower,
    required this.status,
    required this.autoChannel,
  });

  bool get is2_4GHz => band.contains('2.4');
  bool get is5GHz => band.contains('5');
  bool get is6GHz => band.contains('6');
}

/// Connected devices summary.
class ConnectedDevicesUIModel {
  final int totalDevices;
  final int activeDevices;
  final List<String> highBandwidthDevices;

  const ConnectedDevicesUIModel({
    required this.totalDevices,
    required this.activeDevices,
    required this.highBandwidthDevices,
  });

  bool get hasManyDevices => totalDevices > 20;
  bool get hasHighBandwidthDevices => highBandwidthDevices.isNotEmpty;
}

/// Device signal information for WiFi coverage analysis.
class DeviceSignalUIModel {
  final String name;
  final String macAddress;
  final int rssiDbm;

  const DeviceSignalUIModel({
    required this.name,
    required this.macAddress,
    required this.rssiDbm,
  });

  String get signalLabel {
    if (rssiDbm >= -50) return 'Excellent';
    if (rssiDbm >= -60) return 'Good';
    if (rssiDbm >= -70) return 'Fair';
    if (rssiDbm >= -80) return 'Weak';
    return 'Very Weak';
  }
}

/// WiFi coverage analysis result.
class WifiCoverageUIModel {
  final int totalWirelessDevices;
  final List<DeviceSignalUIModel> weakSignalDevices;
  final int averageSignalStrength;
  final List<WiFiRadioUIModel> radios;

  const WifiCoverageUIModel({
    required this.totalWirelessDevices,
    required this.weakSignalDevices,
    required this.averageSignalStrength,
    required this.radios,
  });

  bool get hasWeakSignalDevices => weakSignalDevices.isNotEmpty;
  bool get hasCoverageIssues =>
      weakSignalDevices.length > totalWirelessDevices * 0.3;
}

/// Aggregated RSSI / client count for a single WiFi radio.
class RadioSignalStatsUIModel {
  /// Empty when this bucket holds clients whose radio could not be resolved.
  final String instancePath;
  final String band;
  final int channel;
  final String status;
  final int clientCount;

  /// Average RSSI across active clients on this radio. 0 when no clients.
  final int averageRssi;

  /// Worst RSSI seen on this radio. 0 when no clients.
  final int minRssi;

  const RadioSignalStatsUIModel({
    required this.instancePath,
    required this.band,
    required this.channel,
    required this.status,
    required this.clientCount,
    required this.averageRssi,
    required this.minRssi,
  });

  bool get hasClients => clientCount > 0;
  bool get isResolved => instancePath.isNotEmpty;
  bool get isWeakAverage => hasClients && averageRssi < -70;
}

/// Per-radio WiFi signal analysis result.
class WifiSignalPerRadioUIModel {
  final List<RadioSignalStatsUIModel> radios;

  const WifiSignalPerRadioUIModel({required this.radios});

  /// Radios with at least one active client.
  List<RadioSignalStatsUIModel> get activeRadios =>
      radios.where((r) => r.hasClients).toList();

  /// Total active wireless clients across all radios.
  int get totalClients => radios.fold<int>(0, (sum, r) => sum + r.clientCount);

  /// Weighted average RSSI across all clients (0 when no clients).
  int get weightedAverageRssi {
    int total = 0;
    int count = 0;
    for (final r in radios) {
      if (!r.hasClients) continue;
      total += r.averageRssi * r.clientCount;
      count += r.clientCount;
    }
    return count > 0 ? total ~/ count : 0;
  }

  /// True when any active radio shows weak average RSSI.
  bool get hasWeakRadio => activeRadios.any((r) => r.isWeakAverage);
}

/// Internal mutable accumulator used while joining APs/SSIDs/Radios.
class _RadioBucket {
  final String instancePath;
  final String band;
  final int channel;
  final String status;
  final List<int> rssiSamples = [];
  int clientCount = 0;

  _RadioBucket({
    required this.instancePath,
    required this.band,
    required this.channel,
    required this.status,
  });

  int get averageRssi {
    if (rssiSamples.isEmpty) return 0;
    final sum = rssiSamples.reduce((a, b) => a + b);
    return sum ~/ rssiSamples.length;
  }

  int get minRssi {
    if (rssiSamples.isEmpty) return 0;
    return rssiSamples.reduce((a, b) => a < b ? a : b);
  }
}

/// Intermittent connection check result.
class IntermittentUIModel {
  final int uptimeSeconds;
  final double pingSuccessRate;
  final int averageLatencyMs;
  final int jitterMs;
  final bool hasHighJitter;
  final bool hasPacketLoss;
  final bool recentReboot;

  const IntermittentUIModel({
    required this.uptimeSeconds,
    required this.pingSuccessRate,
    required this.averageLatencyMs,
    required this.jitterMs,
    required this.hasHighJitter,
    required this.hasPacketLoss,
    required this.recentReboot,
  });

  bool get hasIssues => hasHighJitter || hasPacketLoss || recentReboot;

  String get uptimeFormatted {
    final days = uptimeSeconds ~/ 86400;
    final hours = (uptimeSeconds % 86400) ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
