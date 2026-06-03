import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
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
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';

final unifiedDiagnosticsServiceProvider =
    Provider<UnifiedDiagnosticsService?>((ref) {
  final usp = ref.watch(uspClientProvider);
  if (usp == null) return null;
  return UnifiedDiagnosticsService(usp);
});

/// Service encapsulating all USP operations for network diagnostics.
///
/// Uses:
/// - Codegen classes for GET operations (WanStatus, WiFiRadios, ConnectedDevices)
/// - [DiagnosticScope] (via [NetworkDiagnosticsExecutor]) for async Operate
///   commands (Ping, Traceroute, NSLookup). Lifecycle is owned by the
///   notifier — call [attachScope] before invoking any Operate-based method.
class UnifiedDiagnosticsService {
  final UspClient _usp;
  DiagnosticScope? _scope;

  static const _defaultInternetHost =
      '1.1.1.1'; // Cloudflare — for internet check
  static const _defaultDnsHost = '8.8.8.8'; // Google DNS — for DNS check
  static const _defaultTracerouteHost = '8.8.8.8';

  UnifiedDiagnosticsService(this._usp);

  /// Inject the active [DiagnosticScope]. Replaces any prior scope (the prior
  /// scope's release lifecycle is owned by its caller; this method does not
  /// release it). Must be called before any Operate-based method (ping,
  /// nsLookup, traceroute). Owned by notifier.
  void attachScope(DiagnosticScope scope) {
    assert(!scope.isReleased,
        'attachScope received an already-released DiagnosticScope.');
    _scope = scope;
  }

  DiagnosticScope _requireScope() {
    final scope = _scope;
    if (scope == null || scope.isReleased) {
      throw StateError(
          'UnifiedDiagnosticsService has no active DiagnosticScope. '
          'Notifier must call attachScope() before running diagnostics.');
    }
    return scope;
  }

  // ─── WAN Status ──────────────────────────────────────────

  /// Check WAN interface status using codegen WanStatus.
  Future<WanStatusUIModel> checkWanStatus() async {
    logger.d('[Diagnostics] Checking WAN status');
    final WanStatus wan;
    try {
      wan = await WanStatus.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    return WanStatusUIModel(
      status: wan.status,
      ipAddress: wan.ipAddress,
      subnetMask: wan.subnetMask,
      addressingType: wan.addressingType,
    );
  }

  // ─── Ping Operations ─────────────────────────────────────

  /// Ping a host and return parsed result (requires active scope).
  Future<PingResult> ping(
    String host, {
    int repeatCount = 3,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    logger.d('[Diagnostics] Pinging $host (count=$repeatCount)');
    final OperateResult result;
    try {
      result = await _requireScope().ping(
        host: host,
        numberOfRepetitions: repeatCount,
        timeout: timeout,
      );
    } on ServiceError {
      rethrow;
    } on StateError {
      rethrow;
    } catch (e) {
      logger.e('[Diagnostics] Ping $host failed: $e');
      throw mapUspErrorToServiceError(e);
    }
    logger.d('[Diagnostics] Ping $host complete: ${result.status}');
    return PingResult.fromOperateResult(result, host);
  }

  /// Ping the default gateway.
  Future<PingResult> pingGateway({int repeatCount = 3}) async {
    final wan = await checkWanStatus();
    if (wan.ipAddress.isEmpty) {
      throw const InvalidInputError(
          field: 'wanIp',
          message: 'No WAN IP address — cannot determine gateway');
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
    try {
      return await DnsClient.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Run NSLookup to validate that DNS resolution actually works
  /// (requires active scope).
  Future<NsLookupResult> nsLookup(
    String hostName, {
    String? dnsServer,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    logger.d('[Diagnostics] NSLookup $hostName'
        '${dnsServer != null ? ' via $dnsServer' : ''}');
    final OperateResult result;
    try {
      result = await _requireScope().nsLookup(
        hostName: hostName,
        dnsServer:
            (dnsServer != null && dnsServer.isNotEmpty) ? dnsServer : null,
        timeout: timeout,
      );
    } on ServiceError {
      rethrow;
    } on StateError {
      rethrow;
    } catch (e) {
      logger.e('[Diagnostics] NSLookup $hostName failed: $e');
      throw mapUspErrorToServiceError(e);
    }
    logger.d('[Diagnostics] NSLookup $hostName complete: ${result.status}');
    return NsLookupResult.fromOperateResult(result, hostName);
  }

  // ─── Traceroute ──────────────────────────────────────────

  /// Run traceroute to identify network path and bottlenecks.
  Future<TracerouteResult> traceroute({
    String host = _defaultTracerouteHost,
    int maxHops = 30,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    logger.d('[Diagnostics] Running traceroute to $host');
    final OperateResult result;
    try {
      result = await _requireScope().traceRoute(
        host: host,
        maxHopCount: maxHops,
        timeout: timeout,
      );
    } on ServiceError {
      rethrow;
    } on StateError {
      rethrow;
    } catch (e) {
      logger.e('[Diagnostics] Traceroute $host failed: $e');
      throw mapUspErrorToServiceError(e);
    }
    return TracerouteResult.fromOperateResult(result, host);
  }

  // ─── WiFi & Devices ──────────────────────────────────────

  /// Fetch WiFi radio status (channels, signal info).
  Future<List<WiFiRadioUIModel>> checkWifiRadios() async {
    logger.d('[Diagnostics] Checking WiFi radios');
    final WiFiRadios radios;
    try {
      radios = await WiFiRadios.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
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
    final ConnectedDevices devices;
    try {
      devices = await ConnectedDevices.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

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
    final ConnectedDevices devices;
    try {
      devices = await ConnectedDevices.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

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
    final List<Object> results;
    try {
      results = await Future.wait([
        LanNetworkInfo.fetch(_usp),
        DhcpClients.fetch(_usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    final lan = results[0] as LanNetworkInfo;
    final clients = results[1] as DhcpClients;

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
    final List<Object> results;
    try {
      results = await Future.wait([
        ConnectedDevices.fetch(_usp),
        WiFiRadios.fetch(_usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    final devices = results[0] as ConnectedDevices;
    final radios = results[1] as WiFiRadios;

    final wirelessDevices = devices.items
        .where((d) => d.isActive && d.signalStrength != null)
        .toList();

    final weakSignalDevices = wirelessDevices
        .where((d) => d.signalStrength! < rssiGood)
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
    final List<Object> results;
    try {
      results = await Future.wait([
        WiFiRadios.fetch(_usp),
        WiFiAccessPoints.fetch(_usp),
        WiFiSsids.fetch(_usp),
        WifiClients.fetch(_usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    final radios = results[0] as WiFiRadios;
    final accessPoints = results[1] as WiFiAccessPoints;
    final ssids = results[2] as WiFiSsids;
    final clients = results[3] as WifiClients;

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
    final SystemInfo systemInfo;
    try {
      systemInfo = await SystemInfo.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

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

  // ─── Mesh Backhaul Check ─────────────────────────────────

  /// Inspect mesh node backhaul health using EasyMesh DataElements.
  ///
  /// Returns a record per non-controller node with media type, PHY rate,
  /// signal strength, and a derived severity bucket. The controller (the
  /// router itself) is excluded — it has no backhaul.
  ///
  /// When fewer than 2 nodes exist (single-router deployment) this returns
  /// an empty list, signalling the caller to mark the step as skipped.
  Future<List<MeshBackhaulNodeRecord>> checkMeshBackhaul() async {
    logger.d('[Diagnostics] Inspecting mesh backhaul');
    final DataElementsNetwork network;
    try {
      network = await DataElementsNetwork.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    if (network.items.length < 2) {
      logger.d('[Diagnostics] Mesh backhaul: ${network.items.length} '
          'node(s) — skipping');
      return const [];
    }

    // Build node ID → label map for parent resolution
    final nodeLabels = <String, String>{};
    for (final node in network.items) {
      final normalizedId = node.id.toUpperCase().replaceAll(':', '');
      final label = node.manufacturerModel.isNotEmpty
          ? node.manufacturerModel
          : (node.id.isNotEmpty ? node.id : node.instancePath);
      nodeLabels[normalizedId] = label;
    }

    final results = <MeshBackhaulNodeRecord>[];
    for (final node in network.items) {
      // Controller is the node WITHOUT its own backhaul. Detect by absence of
      // backhaul-link evidence — BackhaulMediaType / BackhaulALID /
      // BackhaulPHYRate are all the controller's own uplink to its parent
      // (agents only). MultiAPDevice.AssocIEEE1905DeviceRef and
      // EasyMeshAgentOperationMode are unreliable: some firmware (verified on
      // M60TB-EU 1.0.18) leaves both empty on connected agents.
      final hasBackhaulLink = node.backhaulMediaType.isNotEmpty ||
          node.backhaulAlId.isNotEmpty ||
          node.backhaulPhyRate > 0;
      final isController = !hasBackhaulLink;
      if (isController) {
        // Controller doesn't have its own backhaul — skip.
        continue;
      }

      // Use backhaulLinkType if available, fallback to mediaType parsing
      final linkType = node.backhaulLinkType.isNotEmpty
          ? node.backhaulLinkType
          : (node.backhaulMediaType.contains('Ethernet')
              ? 'Ethernet'
              : 'Wi-Fi');
      final wired = linkType == 'Ethernet';

      final phyRateMbps = node.backhaulPhyRate > 0 ? node.backhaulPhyRate : -1;
      final lastUplinkRateKbps = node.backhaulStatsLastDataUplinkRate > 0
          ? node.backhaulStatsLastDataUplinkRate
          : -1;
      final lastDownlinkRateKbps = node.backhaulStatsLastDataDownlinkRate > 0
          ? node.backhaulStatsLastDataDownlinkRate
          : -1;
      final signalDbm = rcpiToRssi(node.backhaulStatsSignalStrength) ?? 0;

      // Parent node resolution
      final parentNodeId = node.backhaulBackhaulDeviceId.isNotEmpty
          ? node.backhaulBackhaulDeviceId
          : null;
      String? parentLabel;
      if (parentNodeId != null) {
        final normalizedParentId =
            parentNodeId.toUpperCase().replaceAll(':', '');
        parentLabel = nodeLabels[normalizedParentId];
      }

      // Last contact time and stale detection
      final lastContactTime = node.multiApLastContactTime.isNotEmpty
          ? node.multiApLastContactTime
          : null;
      final isStale = _isNodeStale(lastContactTime);

      final severity = _gradeMeshBackhaul(
        wired: wired,
        phyRateMbps: phyRateMbps,
        signalDbm: signalDbm,
        lastDownlinkRateKbps: lastDownlinkRateKbps,
        isStale: isStale,
      );

      final label = node.manufacturerModel.isNotEmpty
          ? node.manufacturerModel
          : (node.id.isNotEmpty ? node.id : node.instancePath);

      results.add(MeshBackhaulNodeRecord(
        nodeId: node.id,
        label: label,
        mediaType:
            node.backhaulMediaType.isEmpty ? 'Unknown' : node.backhaulMediaType,
        linkType: linkType,
        phyRateMbps: phyRateMbps,
        lastUplinkRateKbps: lastUplinkRateKbps,
        lastDownlinkRateKbps: lastDownlinkRateKbps,
        signalStrengthDbm: signalDbm,
        isController: isController,
        severity: severity,
        parentNodeId: parentNodeId,
        parentLabel: parentLabel,
        lastContactTime: lastContactTime,
        isStale: isStale,
      ));
    }

    return results;
  }

  /// Threshold for considering a mesh node "stale" (no TR-181 standard).
  /// Mesh nodes typically report every 30s-60s; 10 minutes allows for
  /// network congestion while still flagging truly unresponsive nodes.
  static const _staleThresholdMinutes = 10;

  /// Check if a node is stale (last contact > threshold).
  bool _isNodeStale(String? lastContactTime) {
    if (lastContactTime == null || lastContactTime.isEmpty) return false;
    try {
      final contactTime = DateTime.parse(lastContactTime);
      final now = DateTime.now().toUtc();
      return now.difference(contactTime).inMinutes > _staleThresholdMinutes;
    } catch (_) {
      return false;
    }
  }

  MeshBackhaulSeverity _gradeMeshBackhaul({
    required bool wired,
    required int phyRateMbps,
    required int signalDbm,
    required int lastDownlinkRateKbps,
    required bool isStale,
  }) {
    // Stale node is always at least a warning
    if (isStale) return MeshBackhaulSeverity.weak;

    if (wired) return MeshBackhaulSeverity.healthy;

    // Wireless backhaul thresholds (RSSI from wifi.dart):
    //   poor   — PHY < 100 Mbps OR RSSI < rssiFair (-78) OR very low downlink
    //   weak   — PHY 100-400 Mbps OR RSSI < rssiExcellent (-65) OR low downlink
    //   healthy— PHY >= 400 Mbps AND RSSI >= rssiExcellent (-65)
    final lowPhy = phyRateMbps > 0 && phyRateMbps < 100;
    final lowRssi = signalDbm != 0 && signalDbm < rssiFair;
    final veryLowDownlink =
        lastDownlinkRateKbps > 0 && lastDownlinkRateKbps < 50000; // < 50 Mbps
    if (lowPhy || lowRssi || veryLowDownlink) return MeshBackhaulSeverity.poor;

    final marginalPhy = phyRateMbps > 0 && phyRateMbps < 400;
    final marginalRssi = signalDbm != 0 && signalDbm < rssiExcellent;
    final lowDownlink =
        lastDownlinkRateKbps > 0 && lastDownlinkRateKbps < 200000; // < 200 Mbps
    if (marginalPhy || marginalRssi || lowDownlink)
      return MeshBackhaulSeverity.weak;

    return MeshBackhaulSeverity.healthy;
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
    if (rssiDbm >= rssiExcellent) return 'Excellent';
    if (rssiDbm >= rssiGood) return 'Good';
    if (rssiDbm >= rssiFair) return 'Fair';
    return 'Weak';
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
  bool get isWeakAverage => hasClients && averageRssi < rssiGood;
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

/// Per-node backhaul snapshot returned by
/// [UnifiedDiagnosticsService.checkMeshBackhaul]. Notifier maps this into the
/// presentation-layer `MeshBackhaulCheckUIModel` / `MeshNodeBackhaulUIModel`.
class MeshBackhaulNodeRecord {
  final String nodeId;
  final String label;
  final String mediaType;
  final String linkType; // "Wi-Fi" or "Ethernet" from codegen
  final int phyRateMbps;
  final int lastUplinkRateKbps;
  final int lastDownlinkRateKbps;
  final int signalStrengthDbm;
  final bool isController;
  final MeshBackhaulSeverity severity;

  // Parent node tracking
  final String? parentNodeId;
  final String? parentLabel;

  // Last contact time tracking
  final String? lastContactTime;
  final bool isStale; // > 5 minutes since last contact

  const MeshBackhaulNodeRecord({
    required this.nodeId,
    required this.label,
    required this.mediaType,
    required this.linkType,
    required this.phyRateMbps,
    required this.lastUplinkRateKbps,
    required this.lastDownlinkRateKbps,
    required this.signalStrengthDbm,
    required this.isController,
    required this.severity,
    this.parentNodeId,
    this.parentLabel,
    this.lastContactTime,
    this.isStale = false,
  });
}

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
