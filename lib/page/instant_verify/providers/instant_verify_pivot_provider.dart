import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
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
  /// Incremented on every fetch(). _runBrowserTests checks this before each
  /// state write — if it changed, a newer fetch started and we abort. (Fix: Item 2)
  int _fetchGeneration = 0;

  /// Timestamp of the last completed speed test. Used to skip re-running
  /// within 3 minutes unless explicitly forced. (Fix: Item 3)
  DateTime? _lastSpeedTestTime;

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
  ///
  /// [forceSpeedTest] bypasses the 3-minute TTL and always runs the speed test.
  /// Use this when the user explicitly requests a re-test (e.g. after a restart
  /// or after changing ISP plan speed). (Fix: Item 3)
  Future<void> fetch({bool forceSpeedTest = false}) async {
    // Increment generation to cancel any in-flight _runBrowserTests. (Fix: Item 2)
    final generation = ++_fetchGeneration;
    // Fresh state clears all prior JNAP data — prevents stale field carry-over. (Fix: Item 6)
    state = InstantVerifyPivotState(
      phase: PivotLoadPhase.loading,
      // Preserve plan speed — user-entered, not from JNAP.
      planSpeedMbps: state.planSpeedMbps,
    );

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

      // HW-6: MX firmware returns 'clientLeases' (not 'dhcpClientLeases')
      final dhcpLeases = (dhcpData['clientLeases'] as List?)?.length ??
          (dhcpData['dhcpLeases'] as List?)?.length ??
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
        _sendOptional(JNAPAction.getLANSettings), // 10 — for actual DHCP pool size
        _sendOptional(JNAPAction.getDeviceMode), // 11 — AP mode detection
      ]);

      Map<String, dynamic>? orNull(Map<String, dynamic> m) =>
          m.isNotEmpty ? m : null;

      final firmwareData = orNull(supplementary[2]);
      final firmwareAvailable = firmwareData != null &&
          firmwareData['firmwareUpdateStatus'] == 'UpdateAvailable';
      final firmwareVersion =
          firmwareData?['availableUpdate']?['firmwareVersion'] as String?;

      // Compute actual DHCP pool size from LAN settings (index 10).
      // firstClientIPAddress..lastClientIPAddress = pool range.
      // Falls back to 150 if GetLANSettings is unavailable. (Fix: Item 9)
      int dhcpPoolLimit = 150;
      final lanData = orNull(supplementary[10]);
      if (lanData != null) {
        final firstIp = lanData['firstClientIPAddress'] as String?;
        final lastIp = lanData['lastClientIPAddress'] as String?;
        if (firstIp != null && lastIp != null) {
          final firstOctet = int.tryParse(firstIp.split('.').last) ?? 0;
          final lastOctet = int.tryParse(lastIp.split('.').last) ?? 0;
          if (lastOctet > firstOctet) {
            dhcpPoolLimit = lastOctet - firstOctet + 1;
          }
        }
      }

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
        isWifiScheduleBlocking: null,
        isInstantPrivacyOn: null,
        isInstantPauseActive: null,
        cpuLoadPct: null,
        memoryLoadPct: null,
        wifiSnrDb: null,
        isPmfRequired: null,
        isBandSteeringMissteer: null,
        hasEthernetNoLink: null,
        hasZombieMeshNode: null,
        dhcpPoolUtilizationPct: null,
        isDeviceInApMode: null,
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
        dhcpPoolLimit: dhcpPoolLimit,
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
      _runBrowserTests(generation: generation, forceSpeedTest: forceSpeedTest);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load: $e');
      dev.log('InstantVerifyPivot: fetch failed: $e');
    }
  }

  // ── Browser tests (Phase 2) ───────────────────────────────────────────

  Future<void> _runBrowserTests({
    required int generation,
    bool forceSpeedTest = false,
  }) async {
    // Helper: abort if a newer fetch() has started. (Fix: Item 2)
    bool _stale() => _fetchGeneration != generation;

    final service = ref.read(browserDiagnosticServiceProvider);

    // Gateway ping
    if (_stale()) return;
    state = state.copyWith(browserTestStep: 'gateway');
    final gateway = await service.pingGateway();
    if (_stale()) return;
    state = state.copyWith(gatewayPing: gateway);

    // DNS check
    if (_stale()) return;
    state = state.copyWith(browserTestStep: 'dns');
    final dns = await service.checkDns();
    if (_stale()) return;
    state = state.copyWith(dnsCheck: dns);

    // Recompute verdict with gateway + dns data (update before slow speed test)
    _recomputeVerdict();

    // Internet speed test — skip if DNS failed (avoids contradictory 0-Mbps verdict),
    // or if results are fresh and not forced. (Fixes: Item 3, Item 4)
    final skipSpeedTest = !dns.resolved ||
        (!forceSpeedTest &&
            _lastSpeedTestTime != null &&
            DateTime.now().difference(_lastSpeedTestTime!) <
                const Duration(minutes: 3));

    if (!skipSpeedTest) {
      if (_stale()) return;
      state = state.copyWith(browserTestStep: 'speed');
      try {
        final speedResult = await service.runInternetSpeedTest(
          onStep: (step) {
            if (!_stale()) {
              state = state.copyWith(browserTestStep: 'speed:$step');
            }
          },
        );
        if (_stale()) return;
        // QA-1: Only store result if download > 0 — a zero result means the CDN
        // was unreachable (not that the internet is actually 0 Mbps).
        // A zero stored as SpeedTestResult would fire a false "0 Mbps" critical finding.
        if (speedResult.downloadMbps > 0) {
          _lastSpeedTestTime = DateTime.now();
          state = state.copyWith(speedTest: speedResult);
        } else {
          dev.log('InstantVerifyPivot: speed test returned 0 — CDN unreachable, discarding result');
        }
      } catch (e) {
        dev.log('InstantVerifyPivot: speed test failed: $e');
      }
    } else if (!dns.resolved) {
      dev.log('InstantVerifyPivot: speed test skipped — DNS failed');
    } else {
      dev.log('InstantVerifyPivot: speed test skipped — result is < 3 min old');
    }

    if (_stale()) return;
    state = state.copyWith(
      browserTestStep: 'complete',
      phase: PivotLoadPhase.complete,
      verdictIsPreliminary: false,
    );

    // QA-3: Check staleness one final time before verdict write —
    // a concurrent fetch() completing Phase 1 between the state write above
    // and this verdict write would otherwise get stomped.
    if (_stale()) return;
    _recomputeVerdict(preliminary: false);
  }

  void _recomputeVerdict({bool preliminary = true}) {
    final s = state;

    // ── New params for Checks 12-15 ──────────────────────────────────────
    final isWifiScheduleBlocking = s.wirelessSchedule != null &&
        (s.wirelessSchedule!['isEnabled'] as bool? ?? false);
    final isInstantPrivacyOn = s.isMacFilterEnabled;
    final isInstantPauseActive = s.parentalControls != null &&
        ((s.parentalControls!['isParentalControlEnabled'] as bool?) ??
         (s.parentalControls!['isParentalControlsEnabled'] as bool?) ??
         (s.parentalControls!['enabled'] as bool?) ?? false);
    final cpuLoadPct = s.routerHealth?['cpuLoad'] as int?;
    final memoryLoadPct = s.routerHealth?['memoryLoad'] as int?;

    // HW-2: signalToNoiseRatio does NOT exist in GetRadioInfo3 on any platform.
    // GetRadioInfo3 is a config API, not a live RF metrics API.
    // SNR/interference detection via this field is permanently null.
    // Check 14 passes null → no firing. Keep as null until an alternative source
    // is identified (e.g., client signal spread, GetSelectedChannels on supported FW).
    const int? wifiSnrDb = null;

    final isPmfRequired = s.networkSecurity != null &&
        (s.networkSecurity!.values.whereType<String>().any(
          (v) => v.toUpperCase().contains('PMF') && v.toUpperCase().contains('REQUIRED')
        ) || (s.networkSecurity!['pmfMode'] as String?)?.toUpperCase() == 'REQUIRED');

    // ── New params for Checks 16-19 ──────────────────────────────────────────

    // Band steering mis-steer (item 28): 5GHz-capable device on 2.4 GHz with steering on
    bool? isBandSteeringMissteer;
    if (s.radioInfo != null) {
      final steeringEnabled = s.radioInfo!['isBandSteeringSupported'] as bool? ?? false;
      if (steeringEnabled && s.clients.isNotEmpty) {
        // A device is likely 5GHz-capable if its max TX rate suggests 5GHz hardware
        // (threshold: txRateMbps > 150 Mbps suggests 802.11ac/ax)
        final misSteered = s.clients.any((c) =>
            c.isWireless &&
            c.band.contains('2.4') &&
            (c.txRateMbps != null && c.txRateMbps! > 150));
        isBandSteeringMissteer = misSteered;
      }
    }

    // Ethernet no-link (item 30): wired device with port showing no physical link
    // AP mode detection: suppress double-NAT finding when device is intentionally in AP mode.
    // getDeviceMode returns e.g. {'deviceMode': 'AccessPoint'} or {'mode': 'AP'}
    final deviceModeData = s.routerHealth?['deviceMode'] as String? ??
        (s.deviceInfo?['deviceMode'] as String?);
    final isDeviceInApMode = deviceModeData != null &&
        (deviceModeData.toUpperCase().contains('AP') ||
         deviceModeData.toUpperCase().contains('ACCESSPOINT') ||
         deviceModeData.toUpperCase().contains('ACCESS_POINT'));

    // HW-3: GetEthernetPortConnections real response shape:
    //   { 'wanPortConnection': 'Connected', 'lanPortConnections': ['Connected', 'Disconnected', ...] }
    // NOT a list of objects with isConnected/macAddress fields.
    bool? hasEthernetNoLink;
    if (s.ethernetPorts != null) {
      final lanPorts = s.ethernetPorts!['lanPortConnections'] as List?;
      if (lanPorts != null) {
        hasEthernetNoLink = lanPorts.any(
            (p) => (p as String?)?.toLowerCase() == 'disconnected');
      }
    }

    // Zombie mesh node (item 38): node with good RSSI but low throughput speedMbps
    bool? hasZombieMeshNode;
    if (s.meshNodes.length > 1) {
      hasZombieMeshNode = s.meshNodes.any((n) =>
          !n.isController &&
          n.backhaulRssi != null &&
          n.backhaulRssi! > -70 && // RSSI looks fine
          n.backhaulSpeedMbps != null &&
          n.backhaulSpeedMbps! < 80); // but throughput is degraded
    }

    // DHCP pool utilization (item 43)
    int? dhcpPoolUtilizationPct;
    if (s.dhcpPoolLimit > 0) {
      dhcpPoolUtilizationPct =
          ((s.dhcpLeasesCount / s.dhcpPoolLimit) * 100).round().clamp(0, 100);
    }

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
      isWifiScheduleBlocking: isWifiScheduleBlocking,
      isInstantPrivacyOn: isInstantPrivacyOn,
      isInstantPauseActive: isInstantPauseActive,
      cpuLoadPct: cpuLoadPct,
      memoryLoadPct: memoryLoadPct,
      wifiSnrDb: wifiSnrDb,
      isPmfRequired: isPmfRequired,
      isBandSteeringMissteer: isBandSteeringMissteer,
      hasEthernetNoLink: hasEthernetNoLink,
      hasZombieMeshNode: hasZombieMeshNode,
      dhcpPoolUtilizationPct: dhcpPoolUtilizationPct,
      isDeviceInApMode: isDeviceInApMode,
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

  Future<void> disableMacFilter() async {
    if (state.macFilter == null) return;
    final payload = Map<String, dynamic>.from(state.macFilter!);
    payload['macFilterMode'] = 'Disabled';
    // QA-2: capture generation before async work to guard against concurrent fetch()
    final gen = _fetchGeneration;
    try {
      await _send(JNAPAction.setMACFilterSettings, data: payload);
      if (_fetchGeneration == gen) {
        state = state.copyWith(macFilter: payload);
      }
    } catch (e) {
      dev.log('InstantVerifyPivot: disableMacFilter failed: $e');
    }
  }

  Future<void> setGuestNetworkEnabled(bool enabled) async {
    if (state.guestNetwork == null) return;
    final payload = Map<String, dynamic>.from(state.guestNetwork!);
    payload['isGuestNetworkEnabled'] = enabled;
    final gen = _fetchGeneration;
    try {
      await _send(JNAPAction.setGuestNetworkSettings, data: payload);
      if (_fetchGeneration == gen) {
        state = state.copyWith(guestNetwork: payload);
      }
    } catch (e) {
      dev.log('InstantVerifyPivot: setGuestNetwork failed: $e');
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
      isWifiScheduleBlocking: null,
      isInstantPrivacyOn: null,
      isInstantPauseActive: null,
      cpuLoadPct: null,
      memoryLoadPct: null,
      wifiSnrDb: null,
      isPmfRequired: null,
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

  /// Fires a JNAP ping then polls GetPingStatus every second until complete.
  /// Previously the polling was missing — isPingRunning was set to true and
  /// never reset, and results were never surfaced. (Fix: Item 5)
  Future<void> startPing(String host) async {
    state = state.copyWith(isPingRunning: true, pingOutput: null);
    try {
      await _send(JNAPAction.startPing, data: {
        'host': host,
        'packetSizeBytes': 32,
        'pingCount': 5,
      });
      // Poll for results
      await _pollPingStatus();
    } catch (e) {
      dev.log('InstantVerifyPivot: startPing failed: $e');
      state = state.copyWith(isPingRunning: false, pingOutput: 'Error: $e');
    }
  }

  Future<void> _pollPingStatus() async {
    const maxAttempts = 30;
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!state.isPingRunning) return; // aborted externally
      try {
        final result = await _send(JNAPAction.getPingStatus);
        final status = PingStatus.fromMap(result);
        state = state.copyWith(pingOutput: status.pingLog);
        if (!status.isRunning) {
          state = state.copyWith(isPingRunning: false);
          return;
        }
      } catch (e) {
        dev.log('InstantVerifyPivot: getPingStatus failed: $e');
        state = state.copyWith(isPingRunning: false, pingOutput: 'Error: $e');
        return;
      }
    }
    // Timeout
    state = state.copyWith(isPingRunning: false);
  }

  Future<void> startTraceroute(String host) async {
    state = state.copyWith(isPingRunning: true, tracerouteOutput: null);
    try {
      await _send(JNAPAction.startTracroute, data: {'host': host});
      // Poll for results
      await _pollTracerouteStatus();
    } catch (e) {
      dev.log('InstantVerifyPivot: startTraceroute failed: $e');
      state = state.copyWith(isPingRunning: false, tracerouteOutput: 'Error: $e');
    }
  }

  Future<void> _pollTracerouteStatus() async {
    const maxAttempts = 60; // Traceroute can take longer
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!state.isPingRunning) return; // aborted externally
      try {
        final result = await _send(JNAPAction.getTracerouteStatus);
        final isRunning = result['isRunning'] as bool? ?? false;
        final log = result['tracerouteLog'] as String? ?? '';
        state = state.copyWith(tracerouteOutput: log);
        if (!isRunning) {
          state = state.copyWith(isPingRunning: false);
          return;
        }
      } catch (e) {
        dev.log('InstantVerifyPivot: getTracerouteStatus failed: $e');
        state = state.copyWith(isPingRunning: false, tracerouteOutput: 'Error: $e');
        return;
      }
    }
    state = state.copyWith(isPingRunning: false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// HW-5: GetNetworkConnections returns rates in Kbps; convert to Mbps.
  /// Returns null if raw is null.
  int? _kbpsToMbps(dynamic raw) {
    if (raw == null) return null;
    final kbps = raw is int ? raw : int.tryParse('$raw');
    if (kbps == null) return null;
    return kbps ~/ 1000;
  }

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
        // HW-5: GetNetworkConnections returns txRate in Kbps, convert to Mbps
        txRateMbps: isWireless ? _kbpsToMbps(wireless['txRate']) : null,
        rxRateMbps: isWireless ? _kbpsToMbps(wireless['rxRate']) : null,
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
        // HW-1: firmware returns speedMbps as a numeric String, not int
        backhaulSpeedMbps: int.tryParse(
            (backhaul['speedMbps'] ?? '').toString()),
      );
    }).toList();
  }
}
