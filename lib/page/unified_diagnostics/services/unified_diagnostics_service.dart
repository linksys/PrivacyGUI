import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/usp/services/active_ipv4_connection.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart'
    as wan;
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
import 'package:privacy_gui/generated/data_elements_network_info.g.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dns_client.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/generated/wifi_clients.g.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/device_score.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_probe_ui_models.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';

final unifiedDiagnosticsServiceProvider =
    Provider<UnifiedDiagnosticsService?>((ref) {
  final usp = ref.watch(uspClientProvider);
  if (usp == null) return null;
  var active = true;
  ref.onDispose(() => active = false);
  return UnifiedDiagnosticsService(
    usp,
    fetchWan: ref.watch(uspWanDataServiceProvider).fetch,
    isAvailable: () => active,
    autoIPoESupported:
        ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.autoIPoE),
  );
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
  final Future<wan.WanStatusUIModel> Function() _fetchWan;
  final bool _autoIPoESupported;
  final bool Function()? _isAvailable;
  DiagnosticScope? _scope;

  static const _defaultInternetHost =
      '1.1.1.1'; // Cloudflare — for internet check
  static const _defaultDnsHost = '8.8.8.8'; // Google DNS — for DNS check
  static const _defaultTracerouteHost = '8.8.8.8';

  UnifiedDiagnosticsService(this._usp,
      {required Future<wan.WanStatusUIModel> Function() fetchWan,
      bool autoIPoESupported = false,
      bool Function()? isAvailable})
      : _fetchWan = fetchWan,
        _autoIPoESupported = autoIPoESupported,
        _isAvailable = isAvailable;

  void _checkAvailable() {
    if (_isAvailable?.call() == false) throw const ResourceNotFoundError();
  }

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

  /// Check WAN interface status through the provider-supplied reader.
  Future<WanStatusUIModel> checkWanStatus() async {
    _checkAvailable();
    logger.d('[Diagnostics] Checking WAN status');
    final wan = await _fetchWan();
    _checkAvailable();
    return WanStatusUIModel(
      status: wan.isUp ? 'Up' : 'Down',
      ipAddress: wan.ipAddress,
      subnetMask: wan.subnetMask,
      addressingType: wan.addressingType,
      usesTunnel:
          const ['MAP-E', 'DS-Lite', 'IPIP'].contains(wan.addressingType),
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
  Future<PingResult?> pingGateway({int repeatCount = 3}) async {
    _checkAvailable();
    final active = await ActiveIpv4Connection.fetch(
      _usp,
      autoIPoESupported: _autoIPoESupported,
    );
    _checkAvailable();
    if (active != null) {
      if (!active.isUp) {
        throw const ConnectivityError(detail: 'No active IPv4 route');
      }
      // BR/AFTR reachability by ICMP is not required for a working tunnel.
      if (active.isTunnel || active.pointToPoint && active.gateway.isEmpty) {
        return null;
      }
      if (active.gateway.isEmpty) return null;
      return ping(active.gateway, repeatCount: repeatCount);
    }
    final wan = await _fetchWan();
    _checkAvailable();
    if (!wan.isUp) throw const ConnectivityError(detail: 'WAN is down');
    if (wan.gateway.isEmpty) return null;
    return ping(wan.gateway, repeatCount: repeatCount);
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
    final String? controllerId;
    try {
      final results = await Future.wait([
        DataElementsNetwork.fetch(_usp),
        _fetchControllerId(),
      ]);
      network = results[0] as DataElementsNetwork;
      controllerId = results[1] as String?;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    if (network.items.length < 2) {
      logger.d('[Diagnostics] Mesh backhaul: ${network.items.length} '
          'node(s) — skipping');
      return const [];
    }
    final controllerKey = meshControllerKey(controllerId, network);

    // Build node ID → label map for parent resolution
    final nodeLabels = <String, String>{};
    for (final node in network.items) {
      final normalizedId = node.id.toUpperCase().replaceAll(':', '');
      nodeLabels[normalizedId] = _nodeLabel(node);
    }

    final results = <MeshBackhaulNodeRecord>[];
    for (final node in network.items) {
      // The controller is the ControllerID node, else the node WITHOUT its own
      // backhaul. `isMeshController` is the test `MeshTopologyBuilder` uses —
      // the two disagreeing is how a node ends up an extender on the topology
      // and the controller in diagnostics, whose backhaul then goes unchecked.
      final isController = isMeshController(node, controllerKey);
      if (isController) {
        // Controller doesn't have its own backhaul — skip.
        continue;
      }

      // `LinkType` is the only medium field firmware produces, and it stays
      // nullable all the way to the two tiles that render it. There is no longer
      // a `mediaType` string to fall back to, and the previous revision of this
      // line defaulted to `'Wi-Fi'` instead: that value went onto the record
      // (`:667`), through the UI model, and into `step_result_tile` and
      // `diagnostic_result_card` verbatim — while node detail, reading the same
      // firmware state through `BackhaulInfo`, printed `unknown`. Same node,
      // same session, two mediums, one of them measured by nothing.
      //
      // `wired` is false for an unknown medium either way, so the grading arm is
      // unchanged by carrying the null; what changes is that the user is not
      // told a medium the app never read.
      final linkType = meshBackhaulLinkType(node);
      final wired = isMeshBackhaulEthernet(linkType);

      final lastUplinkRateKbps = (node.backhaulStatsLastDataUplinkRate ?? 0) > 0
          ? node.backhaulStatsLastDataUplinkRate!
          : -1;
      final lastDownlinkRateKbps =
          (node.backhaulStatsLastDataDownlinkRate ?? 0) > 0
              ? node.backhaulStatsLastDataDownlinkRate!
              : -1;
      // RCPI → dBm (#1555, AC5). The backhaul field is `check_range [0, 220]`
      // firmware-side (`device.odl:168`), so the controller rejects the 221-255
      // "not available" band before it reaches us and the null this can return is
      // the `0` case: `BackhaulStats` never populated. The STA field beside it is
      // `check_maximum 255` (`sta.odl:55`) and *can* deliver a reserved value —
      // the asymmetry is deliberate on the firmware's side, and `rcpiToRssi`
      // guards both because it is the single place either is read.
      //
      // `?? 0` rather than a nullable: the record's `signalStrengthDbm` is a
      // non-nullable int and `0` is the sentinel `_gradeMeshBackhaul` tests for
      // (`signalDbm != 0`), so a missing reading grades as unknown rather than as
      // an extremely strong signal.
      final signalDbm = rcpiToRssi(node.backhaulStatsSignalStrengthRcpi) ?? 0;

      // Parent node resolution. Same reader as the discriminator above, so a
      // parent ID this rejects cannot still arrive on the record.
      final parentNodeId = meshBackhaulParentId(node);
      String? parentLabel;
      if (parentNodeId != null) {
        final normalizedParentId =
            parentNodeId.toUpperCase().replaceAll(':', '');
        parentLabel = nodeLabels[normalizedParentId];
      }

      // Last contact time and stale detection
      final lastContactTime =
          nonEpoch(node.multiApLastContactTime)?.toIso8601String();
      final isStale = _isNodeStale(lastContactTime);

      final severity = _gradeMeshBackhaul(
        wired: wired,
        signalDbm: signalDbm,
        lastDownlinkRateKbps: lastDownlinkRateKbps,
        isStale: isStale,
      );

      results.add(MeshBackhaulNodeRecord(
        nodeId: node.id,
        label: _nodeLabel(node),
        linkType: linkType,
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

  /// `Device.WiFi.DataElements.Network.ControllerID`, or null when the read
  /// faults. Isolated so a fault here costs only the ControllerID rule — the
  /// controller is then told apart by backhaul, as before — and never the
  /// backhaul check itself.
  Future<String?> _fetchControllerId() async {
    try {
      return (await DataElementsNetworkInfo.fetch(_usp)).controllerId;
    } catch (e) {
      logger.w('[Diagnostics] DataElements ControllerID unavailable, the '
          'controller is told apart by backhaul: $e');
      return null;
    }
  }

  /// A node's display label: model name, else its ID, else its instance path.
  ///
  /// `ManufacturerModel` is nullable since #1555 and reads as a prplMesh
  /// placeholder on the controller row — which never reaches here, because the
  /// controller is skipped.
  String _nodeLabel(MeshNode node) =>
      nonEmpty(node.manufacturerModel) ??
      (node.id.isNotEmpty ? node.id : node.instancePath);

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

  /// Grades a wireless backhaul from RSSI and observed downlink rate.
  ///
  /// PHY rate used to be a third input, on the same "positive value or ignore"
  /// footing as the other two. `BackhaulPHYRate` is not in the prplMesh schema
  /// and has no replacement anywhere in it (#1555), so those arms could only
  /// ever have been skipped — dropping them changes no verdict this firmware can
  /// produce, and keeping them would have implied a signal we cannot read.
  MeshBackhaulSeverity _gradeMeshBackhaul({
    required bool wired,
    required int signalDbm,
    required int lastDownlinkRateKbps,
    required bool isStale,
  }) {
    // Stale node is always at least a warning
    if (isStale) return MeshBackhaulSeverity.weak;

    if (wired) return MeshBackhaulSeverity.healthy;

    // Wireless backhaul thresholds (RSSI from wifi.dart):
    //   poor   — RSSI < rssiFair (-78) OR very low downlink
    //   weak   — RSSI < rssiExcellent (-65) OR low downlink
    //   healthy— RSSI >= rssiExcellent (-65)
    final lowRssi = signalDbm != 0 && signalDbm < rssiFair;
    final veryLowDownlink =
        lastDownlinkRateKbps > 0 && lastDownlinkRateKbps < 50000; // < 50 Mbps
    if (lowRssi || veryLowDownlink) return MeshBackhaulSeverity.poor;

    final marginalRssi = signalDbm != 0 && signalDbm < rssiExcellent;
    final lowDownlink =
        lastDownlinkRateKbps > 0 && lastDownlinkRateKbps < 200000; // < 200 Mbps
    if (marginalRssi || lowDownlink) return MeshBackhaulSeverity.weak;

    return MeshBackhaulSeverity.healthy;
  }

  // ─── Helpers ─────────────────────────────────────────────
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

  /// "Wi-Fi" or "Ethernet" from `MultiAPDevice.Backhaul.LinkType`, or null when
  /// firmware named no medium for a link it did report.
  ///
  /// **Nullable on purpose (#1555).** The two views that render this record
  /// print it verbatim, so a placeholder here is a claim on screen; a link known
  /// only by its parent ID is a real state on this firmware, and `unknown` is
  /// what `BackhaulInfo` already shows for it.
  ///
  /// The only medium field. `mediaType` and `phyRateMbps` used to travel
  /// alongside it all the way to `MeshNodeBackhaulUIModel`; both were sourced
  /// from `Device.{i}.Backhaul*` paths the prplMesh schema does not define, and
  /// neither was ever displayed.
  final String? linkType;
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
    required this.linkType,
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
