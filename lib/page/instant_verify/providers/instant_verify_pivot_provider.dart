import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';

final instantVerifyPivotProvider =
    NotifierProvider<InstantVerifyPivotNotifier, InstantVerifyPivotState>(
  InstantVerifyPivotNotifier.new,
);

class InstantVerifyPivotNotifier extends Notifier<InstantVerifyPivotState> {
  @override
  InstantVerifyPivotState build() => const InstantVerifyPivotState();

  // ── JNAP helpers ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _send(
    JNAPAction action, {
    bool auth = true,
    Map<String, dynamic> data = const {},
  }) async {
    final repo = ref.read(routerRepositoryProvider);
    final result = await repo.send(
      action,
      data: data,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      auth: auth,
    );
    return result.output;
  }

  Future<Map<String, dynamic>> _sendOptional(JNAPAction action) async {
    try {
      return await _send(action);
    } catch (e) {
      dev.log('InstantVerifyPivot: ${action.name} failed (optional): $e');
      return <String, dynamic>{};
    }
  }

  // ── Main load ─────────────────────────────────────────────────────────

  /// Load all JNAP data (Phase 1) then run browser tests in background (Phase 2).
  Future<void> fetch() async {
    state = const InstantVerifyPivotState(phase: PivotLoadPhase.loading);

    try {
      // Phase 1a: Core required calls
      final coreResults = await Future.wait([
        _send(JNAPAction.getWANStatus, auth: false), // 0: WAN state
        _send(JNAPAction.getDeviceInfo, auth: false), // 1: router info
        _sendOptional(JNAPAction.getSystemStats), // 2: uptime, CPU, mem
      ]);

      final wanData = coreResults[0];
      final deviceInfoData = coreResults[1];
      final systemStats = coreResults[2];

      // Parse uptime from GetSystemStats
      final uptimeSeconds = (systemStats['uptimeSeconds'] as int?) ?? 0;

      // Phase 1b: Client data — try mesh first, fall back to network connections
      Map<String, dynamic> wirelessData = {};
      Map<String, dynamic> netConns = {};
      Map<String, dynamic> dhcpData = {};

      try {
        wirelessData =
            await _send(JNAPAction.getNodesWirelessNetworkConnections);
      } catch (e) {
        dev.log('InstantVerifyPivot: NodesWireless failed: $e');
      }

      try {
        netConns = await _send(JNAPAction.getNetworkConnections);
      } catch (e) {
        dev.log('InstantVerifyPivot: NetConns failed: $e');
      }

      try {
        dhcpData = await _send(JNAPAction.getDHCPClientLeases);
      } catch (e) {
        dev.log('InstantVerifyPivot: DHCP failed: $e');
      }

      // Build device name map + extract mesh node data
      var deviceMap = <String, Map<String, String?>>{};
      var meshNodesList = <MeshNodeInfo>[];
      var clientToNodeIdMap = <String, String>{};
      if (netConns.isNotEmpty) {
        deviceMap = _buildDeviceMapFromConnections(netConns);
      }
      try {
        final deviceList = await _send(JNAPAction.getDevices);
        final richMap = _buildDeviceMap(deviceList);
        for (final entry in richMap.entries) {
          deviceMap[entry.key] = entry.value;
        }
        // Build client→node map from parentDeviceID
        clientToNodeIdMap = _buildClientToNodeMap(deviceList);
        // Extract infrastructure nodes (nodeType field present = mesh node)
        meshNodesList = _parseMeshNodes(deviceList);
      } catch (_) {}

      // Parse clients
      List<DiagnosticClient> clients;
      if (wirelessData.isNotEmpty) {
        clients = _parseClients(wirelessData, deviceMap);
        if (netConns.isNotEmpty) {
          final wirelessMacs = clients.map((c) => c.macAddress).toSet();
          final wiredClients = _parseClientsFromNetConns(netConns)
              .where(
                  (c) => !c.isWireless && !wirelessMacs.contains(c.macAddress))
              .toList();
          clients.addAll(wiredClients);
        }
      } else if (netConns.isNotEmpty) {
        clients = _parseClientsFromNetConns(netConns);
      } else {
        clients = [];
      }

      final dhcpLeases = (dhcpData['dhcpLeases'] as List?)?.length ??
          (dhcpData['leases'] as List?)?.length ??
          (dhcpData['dhcpClientLeases'] as List?)?.length ??
          0;

      // Phase 1c: Supplementary data (all optional)
      final supplementary = await Future.wait([
        _sendOptional(JNAPAction.getRadioInfo), // 0
        _sendOptional(JNAPAction.getGuestNetworkSettings), // 1
        _sendOptional(JNAPAction.getFirmwareUpdateStatus), // 2
        _sendOptional(JNAPAction.getBackhaulInfo), // 3
        _sendOptional(JNAPAction.getMACFilterSettings), // 4
        _sendOptional(JNAPAction.getNetworkSecuritySettings), // 5
        _sendOptional(JNAPAction.getParentalControlSettings), // 6
        _sendOptional(JNAPAction.getWirelessSchedulerSettings), // 7
        _sendOptional(JNAPAction.getSelectedChannels), // 8
        _sendOptional(JNAPAction.getEthernetPortConnections), // 9
      ]);

      Map<String, dynamic>? orNull(Map<String, dynamic> m) =>
          m.isNotEmpty ? m : null;

      final firmwareData = orNull(supplementary[2]);
      final firmwareAvailable = firmwareData != null &&
          firmwareData['firmwareUpdateStatus'] == 'UpdateAvailable';
      final firmwareVersion =
          firmwareData?['availableUpdate']?['firmwareVersion'] as String?;

      // Merge backhaul data into mesh nodes
      final backhaulRaw = orNull(supplementary[3]);
      if (backhaulRaw != null && meshNodesList.isNotEmpty) {
        meshNodesList = _mergeBackhaul(meshNodesList, backhaulRaw);
      }

      // Compute device scores
      final scores = clients.map(DeviceScore.compute).toList()
        ..sort((a, b) => a.score.compareTo(b.score));

      // Phase 1 verdict (preliminary — no speed data yet)
      final wanConnected = _isWanConnected(wanData);
      final wanIpAddress = (wanData['wanConnection'] as Map<String, dynamic>?)?['ipAddress'] as String?;
      final phase1Verdict = VerdictEngine.compute(
        gatewayReachable: null, // browser test pending
        wanConnected: wanConnected,
        wanIpAddress: wanIpAddress,
        dnsWorking: null, // browser test pending
        downloadMbps: null, // browser test pending
        latencyMs: null, // browser test pending
        firmwareUpdateAvailable: firmwareAvailable,
        firmwareVersion: firmwareVersion,
        uptimeSeconds: uptimeSeconds,
        deviceScores: scores,
        clients: clients,
        meshNodes: meshNodesList,
        planSpeedMbps: state.planSpeedMbps,
      );

      state = state.copyWith(
        phase: PivotLoadPhase.jnapLoaded,
        wanStatus: wanData,
        deviceInfo: deviceInfoData,
        routerHealth: {
          'uptimeInSeconds': uptimeSeconds,
          'cpuLoad': _parsePct(systemStats['CPULoad']),
          'memoryLoad': _parsePct(systemStats['MemoryLoad']),
        },
        clients: clients,
        dhcpLeasesCount: dhcpLeases,
        radioInfo: orNull(supplementary[0]),
        guestNetwork: orNull(supplementary[1]),
        firmwareUpdate: firmwareData,
        backhaulInfo: orNull(supplementary[3]),
        macFilter: orNull(supplementary[4]),
        networkSecurity: orNull(supplementary[5]),
        parentalControls: orNull(supplementary[6]),
        wirelessSchedule: orNull(supplementary[7]),
        channelInfo: orNull(supplementary[8]),
        ethernetPorts: orNull(supplementary[9]),
        meshNodes: meshNodesList,
        clientToNodeId: clientToNodeIdMap,
        deviceScores: scores,
        verdict: phase1Verdict,
        verdictIsPreliminary: true,
      );

      // Phase 2: Run browser tests in background (unawaited)
      _runBrowserTests();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load: $e');
      dev.log('InstantVerifyPivot: fetch failed: $e');
    }
  }

  // ── Browser tests (Phase 2) ───────────────────────────────────────────

  Future<void> _runBrowserTests() async {
    final service = ref.read(browserDiagnosticServiceProvider);

    // Gateway ping
    state = state.copyWith(browserTestStep: 'gateway');
    final gateway = await service.pingGateway();
    state = state.copyWith(gatewayPing: gateway);

    // DNS check
    state = state.copyWith(browserTestStep: 'dns');
    final dns = await service.checkDns();
    state = state.copyWith(dnsCheck: dns);

    // Recompute verdict with gateway + dns data (update before slow speed test)
    _recomputeVerdict();

    // Internet speed test
    state = state.copyWith(browserTestStep: 'speed');
    SpeedTestResult? speedResult;
    try {
      speedResult = await service.runInternetSpeedTest(
        onStep: (step) => state = state.copyWith(browserTestStep: 'speed:$step'),
      );
      state = state.copyWith(speedTest: speedResult);
    } catch (e) {
      dev.log('InstantVerifyPivot: speed test failed: $e');
    }

    state = state.copyWith(
      browserTestStep: 'complete',
      phase: PivotLoadPhase.complete,
      verdictIsPreliminary: false,
    );

    // Final verdict with all data
    _recomputeVerdict(preliminary: false);
  }

  void _recomputeVerdict({bool preliminary = true}) {
    final s = state;
    final verdict = VerdictEngine.compute(
      gatewayReachable: s.gatewayPing?.reachable,
      wanConnected: s.wanStatus != null ? s.wanConnected : null,
      wanIpAddress: s.wanIpAddress,
      dnsWorking: s.dnsCheck?.resolved,
      downloadMbps: s.speedTest?.downloadMbps,
      latencyMs: s.speedTest?.latencyMs,
      firmwareUpdateAvailable: s.firmwareUpdateAvailable,
      firmwareVersion: s.availableFirmwareVersion,
      uptimeSeconds: s.uptimeSeconds > 0 ? s.uptimeSeconds : null,
      deviceScores: s.deviceScores,
      clients: s.clients,
      meshNodes: s.meshNodes,
      planSpeedMbps: s.planSpeedMbps,
    );
    state = state.copyWith(verdict: verdict, verdictIsPreliminary: preliminary);
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> restartRouter() async {
    state = state.copyWith(isRestarting: true);
    try {
      await _send(JNAPAction.reboot);
    } catch (e) {
      dev.log('InstantVerifyPivot: reboot failed: $e');
    }
    // Keep isRestarting=true — page shows countdown until router comes back
  }

  Future<void> triggerFirmwareUpdate() async {
    state = state.copyWith(isUpdatingFirmware: true);
    try {
      await _send(JNAPAction.updateFirmwareNow);
    } catch (e) {
      dev.log('InstantVerifyPivot: firmware update failed: $e');
      state = state.copyWith(isUpdatingFirmware: false);
    }
  }

  /// Injects a realistic failure scenario for UI testing — no router calls made.
  void loadMockFails() {
    final mockClients = [
      const DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:33',
        hostname: 'Devens-iPhone',
        ipAddress: '192.168.1.101',
        band: '2.4 GHz',
        signalDecibels: -82,
        txRateMbps: 12,
        rxRateMbps: 8,
        isWireless: true,
      ),
      const DiagnosticClient(
        macAddress: 'AA:BB:CC:44:55:66',
        hostname: 'Smart-TV-Living',
        ipAddress: '192.168.1.102',
        band: '5 GHz',
        signalDecibels: -78,
        txRateMbps: 25,
        rxRateMbps: 20,
        isWireless: true,
      ),
      const DiagnosticClient(
        macAddress: 'AA:BB:CC:77:88:99',
        hostname: 'Laptop-Office',
        ipAddress: '192.168.1.103',
        band: '5 GHz',
        signalDecibels: -55,
        txRateMbps: 300,
        rxRateMbps: 250,
        isWireless: true,
      ),
    ];
    final mockScores = mockClients.map(DeviceScore.compute).toList();
    const mockGateway = GatewayPingResult(reachable: true, latencyMs: 3);
    const mockDns = DnsCheckResult(resolved: false);
    const mockSpeed = SpeedTestResult(
      downloadMbps: 3.2,
      uploadMbps: 1.1,
      latencyMs: 148,
      jitterMs: 22,
    );
    const mockWanIp = '10.83.68.45';
    final mockVerdict = VerdictEngine.compute(
      gatewayReachable: true,
      wanConnected: true,
      wanIpAddress: mockWanIp,
      dnsWorking: false,
      downloadMbps: 3.2,
      latencyMs: 148,
      firmwareUpdateAvailable: true,
      firmwareVersion: '1.0.8.220100',
      uptimeSeconds: 38 * 86400,
      deviceScores: mockScores,
      clients: mockClients,
      meshNodes: const [],
      planSpeedMbps: 200,
    );
    state = InstantVerifyPivotState(
      phase: PivotLoadPhase.complete,
      deviceInfo: {
        'modelNumber': 'MX6200 (Mock)',
        'firmwareVersion': '1.0.6.215469',
        'serialNumber': 'SN-MOCK-12345',
        'macAddress': 'AA:BB:CC:DD:EE:FF',
      },
      wanStatus: {
        'wanStatus': 'Connected',
        'wanConnection': {
          'ipAddress': mockWanIp,
          'gateway': '10.83.71.254',
        },
      },
      routerHealth: {
        'uptimeInSeconds': 38 * 86400,
        'cpuLoad': 42,
        'memoryLoad': 71,
      },
      clients: mockClients,
      dhcpLeasesCount: 14,
      firmwareUpdate: {
        'firmwareUpdateStatus': 'UpdateAvailable',
        'availableUpdate': {'firmwareVersion': '1.0.8.220100'},
      },
      gatewayPing: mockGateway,
      dnsCheck: mockDns,
      speedTest: mockSpeed,
      browserTestStep: 'complete',
      deviceScores: mockScores,
      verdict: mockVerdict,
      verdictIsPreliminary: false,
    );
  }

  void setPlanSpeed(double? mbps) {
    state = state.copyWith(planSpeedMbps: mbps);
    if (state.phase != PivotLoadPhase.loading) {
      _recomputeVerdict(preliminary: state.verdictIsPreliminary);
    }
  }

  // ── Ping / Traceroute ─────────────────────────────────────────────────

  Future<void> startPing(String host) async {
    state = state.copyWith(isPingRunning: true, pingOutput: null);
    try {
      await _send(JNAPAction.startPing, data: {
        'host': host,
        'packetSizeBytes': 32,
        'pingCount': 5,
      });
    } catch (e) {
      state = state.copyWith(isPingRunning: false, pingOutput: 'Error: $e');
    }
  }

  Future<void> startTraceroute(String host) async {
    state = state.copyWith(isPingRunning: true, tracerouteOutput: null);
    try {
      await _send(JNAPAction.startTracroute, data: {'host': host});
    } catch (e) {
      state =
          state.copyWith(isPingRunning: false, tracerouteOutput: 'Error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  bool _isWanConnected(Map<String, dynamic> wanData) {
    final status = wanData['wanStatus'] as String?;
    return status == 'Connected' || status == 'connected';
  }

  int? _parsePct(dynamic raw) {
    if (raw == null) return null;
    return ((double.tryParse('$raw') ?? 0) * 100).round();
  }

  Map<String, Map<String, String?>> _buildDeviceMapFromConnections(
      Map<String, dynamic> data) {
    final map = <String, Map<String, String?>>{};
    final connections = data['connections'] as List? ?? [];
    for (final conn in connections) {
      final mac = (conn['macAddress'] as String?)?.toUpperCase();
      if (mac != null) {
        map[mac] = {
          'hostname': conn['hostname'] as String?,
          'ipAddress': conn['ipAddress'] as String?,
        };
      }
    }
    return map;
  }

  Map<String, Map<String, String?>> _buildDeviceMap(
      Map<String, dynamic> data) {
    final map = <String, Map<String, String?>>{};
    final devices = data['devices'] as List? ?? [];
    for (final d in devices) {
      final connections = d['connections'] as List? ?? [];
      final friendlyName = d['friendlyName'] as String?;
      final hostname = d['hostname'] as String?;
      final name = friendlyName ?? hostname;
      final deviceType =
          (d['model'] as Map<String, dynamic>?)?['deviceType'] as String?;
      for (final conn in connections) {
        final mac = (conn['macAddress'] as String?)?.toUpperCase();
        final ip = conn['ipAddress'] as String?;
        if (mac != null) {
          final entry = <String, String?>{'hostname': name, 'ipAddress': ip};
          if (deviceType != null && deviceType.isNotEmpty) {
            entry['deviceType'] = deviceType;
          }
          final wcInfo =
              conn['wirelessConnectionInfo'] as Map<String, dynamic>?;
          if (wcInfo != null) {
            final txRaw = wcInfo['txRate'];
            final rxRaw = wcInfo['rxRate'];
            if (txRaw != null) entry['txRate'] = '${(txRaw as int) ~/ 1000}';
            if (rxRaw != null) entry['rxRate'] = '${(rxRaw as int) ~/ 1000}';
          }
          map[mac] = entry;
        }
      }
    }
    return map;
  }

  List<DiagnosticClient> _parseClients(
    Map<String, dynamic> netConns,
    Map<String, Map<String, String?>> deviceMap,
  ) {
    final clients = <DiagnosticClient>[];
    final nodeConnections =
        netConns['nodeWirelessConnections'] as List? ?? [];
    for (final node in nodeConnections) {
      final connections = node['connections'] as List? ?? [];
      for (final conn in connections) {
        final mac =
            ((conn['macAddress'] as String?) ?? '').toUpperCase();
        final wireless = conn['wireless'] as Map<String, dynamic>?;
        if (wireless != null) {
          final devInfo = deviceMap[mac];
          final txWireless = wireless['txRate'] as int?;
          final rxWireless = wireless['rxRate'] as int?;
          final txFromDevices = devInfo?['txRate'] != null
              ? int.tryParse(devInfo!['txRate']!)
              : null;
          final rxFromDevices = devInfo?['rxRate'] != null
              ? int.tryParse(devInfo!['rxRate']!)
              : null;
          final negotiated = conn['negotiatedMbps'] as int?;
          final negotiatedMbps =
              negotiated != null ? negotiated ~/ 1000 : null;
          clients.add(DiagnosticClient(
            macAddress: mac,
            hostname: devInfo?['hostname'],
            ipAddress: devInfo?['ipAddress'],
            band: (wireless['band'] as String?) ?? 'Unknown',
            signalDecibels: wireless['signalDecibels'] as int?,
            txRateMbps: txWireless ?? txFromDevices ?? negotiatedMbps,
            rxRateMbps: rxWireless ?? rxFromDevices ?? negotiatedMbps,
            isWireless: true,
            deviceType: devInfo?['deviceType'],
          ));
        }
      }
    }
    clients.sort((a, b) {
      if (a.isFlagged != b.isFlagged) return a.isFlagged ? -1 : 1;
      return (a.signalDecibels ?? 0).compareTo(b.signalDecibels ?? 0);
    });
    return clients;
  }

  List<DiagnosticClient> _parseClientsFromNetConns(
      Map<String, dynamic> data) {
    final clients = <DiagnosticClient>[];
    final connections = data['connections'] as List? ?? [];
    for (final conn in connections) {
      final mac =
          ((conn['macAddress'] as String?) ?? '').toUpperCase();
      final wireless = conn['wireless'] as Map<String, dynamic>?;
      final isWireless = wireless != null;
      clients.add(DiagnosticClient(
        macAddress: mac,
        hostname: conn['hostname'] as String?,
        ipAddress: conn['ipAddress'] as String?,
        band: isWireless
            ? ((wireless['band'] as String?) ?? 'Unknown')
            : 'Wired',
        signalDecibels:
            isWireless ? wireless['signalDecibels'] as int? : null,
        txRateMbps: isWireless ? wireless['txRate'] as int? : null,
        rxRateMbps: isWireless ? wireless['rxRate'] as int? : null,
        isWireless: isWireless,
      ));
    }
    return clients;
  }

  /// Builds a MAC → parentDeviceID map from GetDevices3 response.
  Map<String, String> _buildClientToNodeMap(Map<String, dynamic> data) {
    final map = <String, String>{};
    final devices = data['devices'] as List? ?? [];
    for (final d in devices) {
      for (final conn in (d['connections'] as List? ?? [])) {
        final mac = (conn['macAddress'] as String?)?.toUpperCase();
        final parent = conn['parentDeviceID'] as String?;
        if (mac != null && parent != null) {
          map[mac] = parent;
        }
      }
    }
    return map;
  }

  /// Extracts mesh nodes from GetDevices3 — devices with a nodeType field.
  List<MeshNodeInfo> _parseMeshNodes(Map<String, dynamic> data) {
    final nodes = <MeshNodeInfo>[];
    final devices = data['devices'] as List? ?? [];
    for (final d in devices) {
      final nodeType = d['nodeType'] as String?;
      if (nodeType == null) continue; // not a mesh node

      final deviceId = d['deviceID'] as String? ?? '';
      final friendlyName = d['friendlyName'] as String?;
      final unit = d['unit'] as Map<String, dynamic>?;
      final model = d['model'] as Map<String, dynamic>?;

      nodes.add(MeshNodeInfo(
        deviceId: deviceId,
        name: friendlyName ?? model?['modelNumber'] as String? ?? 'Node',
        model: model?['modelNumber'] as String?,
        firmware: unit?['firmwareVersion'] as String?,
        serialNumber: unit?['serialNumber'] as String?,
        isController: (d['isAuthority'] as bool?) ?? false,
      ));
    }
    // Sort: controller first
    nodes.sort((a, b) => b.isController ? 1 : -1);
    return nodes;
  }

  /// Merges backhaul RSSI/type from GetBackhaulInfo into parsed mesh nodes.
  List<MeshNodeInfo> _mergeBackhaul(
      List<MeshNodeInfo> nodes, Map<String, dynamic> backhaulData) {
    final backhaulDevices = backhaulData['backhaulDevices'] as List? ?? [];
    if (backhaulDevices.isEmpty) return nodes;

    // Build lookup: deviceUUID → backhaul info
    final backhaulMap = <String, Map<String, dynamic>>{};
    for (final b in backhaulDevices) {
      final uuid = b['deviceUUID'] as String?;
      if (uuid != null) backhaulMap[uuid] = b as Map<String, dynamic>;
    }

    return nodes.map((node) {
      final backhaul = backhaulMap[node.deviceId];
      if (backhaul == null) return node;
      return MeshNodeInfo(
        deviceId: node.deviceId,
        name: node.name,
        model: node.model,
        firmware: node.firmware,
        serialNumber: node.serialNumber,
        isController: node.isController,
        backhaulType: backhaul['connectionType'] as String?,
        backhaulRssi: backhaul['rssi'] as int?,
        backhaulSpeedMbps: backhaul['speedMbps'] as int?,
      );
    }).toList();
  }
}
