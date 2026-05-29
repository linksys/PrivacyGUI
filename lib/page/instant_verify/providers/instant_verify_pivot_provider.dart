import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/providers/local_storage_stub.dart'
    if (dart.library.html) 'package:privacy_gui/page/instant_verify/providers/local_storage_web.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_verify/models/customer_journey.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/jnap_capability.dart';
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
      // Preserve journey actions — accumulated across session for V2.0 handoff.
      journeyActions: state.journeyActions,
      flowEntered: state.flowEntered,
      escalationReason: state.escalationReason,
      // Preserve restart flag — session-scoped, not re-fetchable.
      hasRestartedThisSession: state.hasRestartedThisSession,
      // B-6: Check localStorage for recent prior restart on first load.
      recentPriorRestart: state.recentPriorRestart || _checkRecentPriorRestart(),
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

      // Enrich device map with DHCP lease IPs + hostnames.
      // This fills in missing IPs when GetDevices (old) returns no ipAddress fields,
      // which happens when the router doesn't advertise deviceList4 capability.
      // DHCP leases are the most reliable source for current IP assignments.
      _enrichDeviceMapWithDhcp(deviceMap, dhcpData);

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

      // Probe confirmed: Pinnacle M60 returns 'leases' key.
      // Other platforms use 'clientLeases', 'dhcpLeases', 'dhcpClientLeases'.
      // NOTE for porting: run jnap_capability_probe.dart on each platform to verify.
      final dhcpLeases = (dhcpData['leases'] as List?)?.length ??
          (dhcpData['clientLeases'] as List?)?.length ??
          (dhcpData['dhcpLeases'] as List?)?.length ??
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
      int? dhcpLeaseMinutes;
      final lanData = orNull(supplementary[10]);
      if (lanData != null) {
        final dhcpSettings = lanData['dhcpSettings'] as Map<String, dynamic>?;
        final firstIp = (dhcpSettings?['firstClientIPAddress'] as String?) ??
            lanData['firstClientIPAddress'] as String?;
        final lastIp = (dhcpSettings?['lastClientIPAddress'] as String?) ??
            lanData['lastClientIPAddress'] as String?;
        if (firstIp != null && lastIp != null) {
          final firstOctet = int.tryParse(firstIp.split('.').last) ?? 0;
          final lastOctet = int.tryParse(lastIp.split('.').last) ?? 0;
          if (lastOctet > firstOctet) {
            dhcpPoolLimit = lastOctet - firstOctet + 1;
          }
        }
        dhcpLeaseMinutes = (dhcpSettings?['leaseTime'] as int?) ??
            (lanData['leaseTime'] as int?);
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

      // Build capability map from what was actually returned by this firmware.
      // This gates VerdictEngine checks so absent fields don't produce wrong results.
      final routerHealthMap = {
        'uptimeInSeconds': uptimeSeconds,
        'cpuLoad': _parsePct(systemStats['CPULoad'] ?? systemStats['cpuUsage']),
        'memoryLoad': _parsePct(systemStats['MemoryLoad'] ?? systemStats['memUsage']),
      };
      final caps = _buildCapabilityMap(
        systemStats: systemStats,
        radioInfo: orNull(supplementary[0]),
        backhaulInfo: orNull(supplementary[3]),
        networkSecurity: orNull(supplementary[5]),
        parentalControls: orNull(supplementary[6]),
        wirelessSchedule: orNull(supplementary[7]),
        ethernetPorts: orNull(supplementary[9]),
        lanSettings: orNull(supplementary[10]),
        deviceMode: orNull(supplementary[11]),
        meshNodes: meshNodesList,
        clients: clients,
      );
      dev.log('InstantVerifyPivot: capabilities = $caps');

      // Store first CPU sample for two-sample measurement (#24)
      final cpuStart = routerHealthMap['cpuLoad'] as int?;

      state = state.copyWith(
        phase: PivotLoadPhase.jnapLoaded,
        wanStatus: wanData,
        deviceInfo: deviceInfoData,
        routerHealth: routerHealthMap,
        cpuLoadPctStart: cpuStart,
        clients: clients,
        dhcpLeasesCount: dhcpLeases,
        dhcpPoolLimit: dhcpPoolLimit,
        dhcpLeaseMinutes: dhcpLeaseMinutes,
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
        jnapCapabilities: caps,
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

    // Recompute verdict immediately so the customer sees a finding right away.
    // The public DNS refinement will update it a few seconds later.
    _recomputeVerdict();

    // Parallel DNS diagnostics — run AFTER showing initial finding so the
    // customer isn't blocked. Both checks run concurrently:
    //   • checkPublicDns()     — DoH to 8.8.8.8, tests internet connectivity
    //   • _pingFromRouter()    — JNAP ping to configured DNS IPs, tests routing
    // Together they give three-way diagnosis (see VerdictEngine Check 4).
    if (!dns.resolved) {
      if (_stale()) return;
      final dnsIps = state.wanDnsServers;
      // Start both futures concurrently
      final publicDnsFuture = service.checkPublicDns();
      final pingFuture = dnsIps.isNotEmpty
          ? _pingFromRouter(dnsIps.first)
          : Future<bool?>.value(null);
      // Await results (both were already running)
      final publicDns = await publicDnsFuture;
      if (_stale()) return;
      final dnsReachable = await pingFuture;
      if (!_stale()) {
        state = state.copyWith(
          publicDnsCheck: publicDns,
          configuredDnsReachable: dnsReachable,
        );
        _recomputeVerdict();
      }
    }

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
          _recordAction('speed_test', result: '${speedResult.downloadMbps.toStringAsFixed(1)}_mbps');
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

    // Two-sample CPU measurement (#24): take second sample at end of run.
    // Overlaps with tail-end work — no noticeable latency added.
    if (_stale()) return;
    final endStats = await _sendOptional(JNAPAction.getSystemStats);
    if (_stale()) return;
    final cpuEnd = _parsePct(endStats['CPULoad'] ?? endStats['cpuUsage']);
    if (cpuEnd != null) {
      state = state.copyWith(cpuLoadPctEnd: cpuEnd);
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
    // Gate CPU/memory on capability map — keys vary by firmware.
    // Only pass values if this device confirmed returning them.
    // Two-sample CPU (#24): only use the END sample for the CPU verdict.
    // The start sample is taken during our JNAP burst and may be a false spike.
    // During preliminary verdict (before end sample exists), skip CPU check entirely.
    final int? cpuLoadPct;
    final int? cpuLoadPctStart;
    if (s.jnapCapabilities[JnapCapability.cpuLoad] ?? false) {
      cpuLoadPct = s.cpuLoadPctEnd; // null until browser tests complete
      cpuLoadPctStart = s.cpuLoadPctStart;
    } else {
      cpuLoadPct = null;
      cpuLoadPctStart = null;
    }
    final int? memoryLoadPct;
    if (s.jnapCapabilities[JnapCapability.memoryLoad] ?? false) {
      memoryLoadPct = s.routerHealth?['memoryLoad'] as int?;
    } else {
      memoryLoadPct = null;
    }

    // HW-2: SNR does NOT exist in GetRadioInfo3. Permanently null.
    // NOTE: GetSelectedChannels WORKS on Pinnacle M60 (firmware 1.0.18+).
    // The PRD listed it as unsupported — live probe confirmed it works.
    // We use channel data as a proxy for interference (non-standard 2.4 GHz channel).
    const int? wifiSnrDb = null; // No SNR source available on any platform

    // Parse channel data from GetSelectedChannels (confirmed working on Pinnacle M60).
    // Response: { selectedChannels: [{ deviceID, channels: [{ radioID, band, channel }] }] }
    String? wifi24GhzChannelNum;
    if (s.channelInfo != null && !s.channelInfo!.containsKey('_error')) {
      final selectedChannels = s.channelInfo!['selectedChannels'] as List?;
      if (selectedChannels != null && selectedChannels.isNotEmpty) {
        final channels = (selectedChannels.first as Map<String, dynamic>?)
            ?['channels'] as List?;
        if (channels != null) {
          for (final ch in channels) {
            final band = (ch as Map<String, dynamic>)['band'] as String? ?? '';
            final channelNum = ch['channel']?.toString();
            if (band.contains('2.4') && channelNum != null) {
              wifi24GhzChannelNum = channelNum;
            }
          }
        }
      }
    }
    // Non-standard 2.4 GHz channel (not 1, 6, or 11) indicates co-channel interference.
    // Use as interference proxy since SNR is unavailable.
    // TODO (Pinnacle): Standard channels differ in some regions (EU uses 13).
    //   For a US-only tool, 1/6/11 is correct. Add region detection for porting.
    final bool? channelInterferenceProxy = wifi24GhzChannelNum != null
        ? !['1', '6', '11', '13'].contains(wifi24GhzChannelNum)
        : null;
    // Re-use the wifiSnrDb parameter slot — pass a synthetic "bad" value when
    // channel interference is detected so Check 14 fires. 15 dB = interference threshold.
    // ignore: unused_local_variable
    final int? wifiSnrDbFromChannel = channelInterferenceProxy == true ? 15 : null;

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

    // Zombie mesh node (item 38): only check if this firmware returns speedMbps.
    // If the capability isn't confirmed, null = skip rather than false all-clear.
    bool? hasZombieMeshNode;
    if (s.meshNodes.length > 1 &&
        (s.jnapCapabilities[JnapCapability.backhaulSpeedMbps] ?? false)) {
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
      cpuLoadPctStart: cpuLoadPctStart,
      memoryLoadPct: memoryLoadPct,
      wifiSnrDb: wifiSnrDb,
      isPmfRequired: isPmfRequired,
      isBandSteeringMissteer: isBandSteeringMissteer,
      hasEthernetNoLink: hasEthernetNoLink,
      hasZombieMeshNode: hasZombieMeshNode,
      dhcpPoolUtilizationPct: dhcpPoolUtilizationPct,
      isDeviceInApMode: isDeviceInApMode,
      dnsServers: s.wanDnsServers.isNotEmpty ? s.wanDnsServers : null,
      wanIpv6Connected: s.wanStatus != null ? s.wanIpv6Connected : null,
      wanType: s.wanConnectionType,
      publicDnsWorking: s.publicDnsCheck?.resolved,
      configuredDnsReachable: s.configuredDnsReachable,
    );
    state = state.copyWith(verdict: verdict, verdictIsPreliminary: preliminary);
  }

  // ── Journey tracking ──────────────────────────────────────────────────

  void _recordAction(String action, {String? result}) {
    state = state.copyWith(
      journeyActions: [
        ...state.journeyActions,
        JourneyAction(action: action, timestamp: DateTime.now(), result: result),
      ],
    );
  }

  void recordFlowEntered(String flowName) {
    state = state.copyWith(flowEntered: flowName);
    _recordAction('flow_entered', result: flowName);
  }

  void recordEscalation(String reason) {
    state = state.copyWith(escalationReason: reason);
    _recordAction('escalation', result: reason);
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> restartRouter() async {
    state = state.copyWith(isRestarting: true, hasRestartedThisSession: true);
    _recordAction('restart_router');
    _persistRestartTimestamp();
    try {
      await _send(JNAPAction.reboot);
    } catch (e) {
      dev.log('InstantVerifyPivot: reboot failed: $e');
    }
    // Keep isRestarting=true — page shows countdown until router comes back
  }

  Future<void> triggerFirmwareUpdate() async {
    state = state.copyWith(isUpdatingFirmware: true);
    _recordAction('firmware_update');
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
    _recordAction('disable_mac_filter');
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
    _recordAction('set_guest_network', result: enabled ? 'enabled' : 'disabled');
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

  /// Loads one of 5 pre-built mock scenarios for UI/flow testing.
  ///
  /// Covers all 19 VerdictEngine checks so every Tab 0 finding and
  /// flow CTA can be exercised without a physical router. No JNAP calls.
  ///
  ///  0 = No internet connection      (Check 2 — WAN disconnected)
  ///  1 = Websites aren't loading     (Check 4 — DNS failure)
  ///  2 = Slow internet + weak WiFi   (Checks 5, 6, 7, 10, 11)
  ///  3 = Router overloaded + mesh    (Checks 13, 17, 18)
  ///  4 = Config blocks               (Checks 8, 12, 15, 16, 19)
  void loadMockScenario(int index) {
    switch (index) {
      case 0: _mockScenarioA();
      case 1: _mockScenarioB();
      case 2: _mockScenarioC();
      case 3: _mockScenarioD();
      case 4: _mockScenarioE();
      default: _mockScenarioC();
    }
  }

  /// Backwards-compat alias — maps to Scenario C (slow + weak devices).
  void loadMockFails() => loadMockScenario(2);

  static const _kMockDeviceInfo = {
    'modelNumber': 'MX6200 (Mock)',
    'firmwareVersion': '1.0.6.215469',
    'serialNumber': 'SN-MOCK-12345',
    'macAddress': 'AA:BB:CC:DD:EE:FF',
  };

  /// Good-signal clients for scenarios where devices are not the issue.
  static List<DiagnosticClient> _goodMockClients() => const [
    DiagnosticClient(
      macAddress: 'AA:BB:CC:11:22:33', hostname: 'Devens-MacBook',
      ipAddress: '192.168.1.100', band: '5 GHz',
      signalDecibels: -52, txRateMbps: 450, rxRateMbps: 400, isWireless: true,
    ),
    DiagnosticClient(
      macAddress: 'AA:BB:CC:44:55:66', hostname: 'Devens-iPhone',
      ipAddress: '192.168.1.101', band: '5 GHz',
      signalDecibels: -58, txRateMbps: 200, rxRateMbps: 180, isWireless: true,
    ),
    DiagnosticClient(
      macAddress: 'AA:BB:CC:77:88:99', hostname: 'Apple-TV',
      ipAddress: '192.168.1.102', band: '5 GHz',
      signalDecibels: -62, txRateMbps: 180, rxRateMbps: 150, isWireless: true,
    ),
  ];

  /// ── Scenario A: No internet connection ──────────────────────────────────
  /// Triggers Check 2 (WAN disconnected → critical).
  void _mockScenarioA() {
    final clients = _goodMockClients();
    final scores = clients.map(DeviceScore.compute).toList();
    final verdict = VerdictEngine.compute(
      gatewayReachable: true,
      wanConnected: false,
      wanIpAddress: null,
      dnsWorking: null,
      downloadMbps: null,
      latencyMs: null,
      firmwareUpdateAvailable: false,
      firmwareVersion: null,
      uptimeSeconds: null,
      deviceScores: scores,
      clients: clients,
      meshNodes: const [],
      planSpeedMbps: null,
    );
    state = InstantVerifyPivotState(
      phase: PivotLoadPhase.complete,
      deviceInfo: _kMockDeviceInfo,
      wanStatus: {'wanStatus': 'Disconnected'},
      routerHealth: {'uptimeInSeconds': 3 * 86400},
      clients: clients,
      deviceScores: scores,
      gatewayPing: const GatewayPingResult(reachable: true, latencyMs: 2),
      browserTestStep: 'complete',
      verdict: verdict,
      verdictIsPreliminary: false,
    );
  }

  /// ── Scenario B: Connected to ISP but websites aren't loading ────────────
  /// Triggers Check 4 (DNS failure) with ISP-assigned DNS servers surfaced.
  void _mockScenarioB() {
    final clients = _goodMockClients();
    final scores = clients.map(DeviceScore.compute).toList();
    const wanIp = '203.0.113.45';
    const mockDns = ['172.30.1.105', '172.30.1.106']; // ISP-assigned
    final verdict = VerdictEngine.compute(
      gatewayReachable: true,
      wanConnected: true,
      wanIpAddress: wanIp,
      dnsWorking: false,
      downloadMbps: null,
      latencyMs: null,
      firmwareUpdateAvailable: false,
      firmwareVersion: null,
      uptimeSeconds: null,
      deviceScores: scores,
      clients: clients,
      meshNodes: const [],
      planSpeedMbps: null,
      dnsServers: mockDns,
      wanIpv6Connected: false,
      wanType: 'DHCP',
      publicDnsWorking: true,       // internet works
      configuredDnsReachable: true, // DNS servers up but service broken
    );
    state = InstantVerifyPivotState(
      phase: PivotLoadPhase.complete,
      deviceInfo: _kMockDeviceInfo,
      wanStatus: {
        'wanStatus': 'Connected',
        'detectedWANType': 'DHCP',
        'wanIPv6Status': 'Disconnected',
        'wanConnection': {
          'ipAddress': wanIp,
          'gateway': '10.83.71.254',
          'dnsServer1': mockDns[0],
          'dnsServer2': mockDns[1],
        },
      },
      routerHealth: {'uptimeInSeconds': 5 * 86400},
      clients: clients,
      deviceScores: scores,
      gatewayPing: const GatewayPingResult(reachable: true, latencyMs: 3),
      dnsCheck: const DnsCheckResult(resolved: false),
      browserTestStep: 'complete',
      verdict: verdict,
      verdictIsPreliminary: false,
    );
  }

  /// ── Scenario C: Slow internet + weak devices ────────────────────────────
  /// Triggers Checks 5 (very slow, 3.2 Mbps), 6 (high latency, 148ms),
  /// 7 (2 weak-signal devices), 10 (firmware update), 11 (38-day uptime).
  void _mockScenarioC() {
    final clients = [
      const DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:33', hostname: 'Bedroom-TV',
        ipAddress: '192.168.1.101', band: '2.4 GHz',
        signalDecibels: -82, txRateMbps: 12, rxRateMbps: 8, isWireless: true,
      ),
      const DiagnosticClient(
        macAddress: 'AA:BB:CC:44:55:66', hostname: 'Smart-TV-Living',
        ipAddress: '192.168.1.102', band: '5 GHz',
        signalDecibels: -78, txRateMbps: 25, rxRateMbps: 20, isWireless: true,
      ),
      const DiagnosticClient(
        macAddress: 'AA:BB:CC:77:88:99', hostname: 'Laptop-Office',
        ipAddress: '192.168.1.103', band: '5 GHz',
        signalDecibels: -55, txRateMbps: 300, rxRateMbps: 250, isWireless: true,
      ),
    ];
    final scores = clients.map(DeviceScore.compute).toList();
    const wanIp = '10.83.68.45';
    final verdict = VerdictEngine.compute(
      gatewayReachable: true,
      wanConnected: true,
      wanIpAddress: wanIp,
      dnsWorking: true, // DNS ok so Check 5 (speed) fires
      downloadMbps: 3.2,
      latencyMs: 148,
      firmwareUpdateAvailable: true,
      firmwareVersion: '1.0.8.220100',
      uptimeSeconds: 38 * 86400,
      deviceScores: scores,
      clients: clients,
      meshNodes: const [],
      planSpeedMbps: 200,
    );
    state = InstantVerifyPivotState(
      phase: PivotLoadPhase.complete,
      deviceInfo: _kMockDeviceInfo,
      wanStatus: {
        'wanStatus': 'Connected',
        'wanConnection': {'ipAddress': wanIp, 'gateway': '10.83.71.254'},
      },
      routerHealth: {
        'uptimeInSeconds': 38 * 86400,
        'cpuLoad': 42,
        'memoryLoad': 71,
      },
      clients: clients,
      dhcpLeasesCount: 14,
      firmwareUpdate: {
        'firmwareUpdateStatus': 'UpdateAvailable',
        'availableUpdate': {'firmwareVersion': '1.0.8.220100'},
      },
      gatewayPing: const GatewayPingResult(reachable: true, latencyMs: 3),
      dnsCheck: const DnsCheckResult(resolved: true),
      speedTest: const SpeedTestResult(
        downloadMbps: 3.2, uploadMbps: 1.1, latencyMs: 148, jitterMs: 22,
      ),
      browserTestStep: 'complete',
      deviceScores: scores,
      planSpeedMbps: 200,
      verdict: verdict,
      verdictIsPreliminary: false,
    );
  }

  /// ── Scenario D: Router overloaded + mesh issues ──────────────────────────
  /// Triggers Check 13 (CPU 88%, memory 90%), Check 17 (ethernet no-link),
  /// Check 18 (zombie mesh node — good RSSI but degraded throughput).
  void _mockScenarioD() {
    final clients = _goodMockClients();
    final scores = clients.map(DeviceScore.compute).toList();
    const wanIp = '10.83.68.45';
    final meshNodes = [
      const MeshNodeInfo(
        deviceId: 'node-ctrl-001', name: 'MX6200 Main', model: 'MX6200',
        firmware: '1.0.6.215469', isController: true,
      ),
      const MeshNodeInfo(
        deviceId: 'node-sat-002', name: 'MX6200 Living Room', model: 'MX6200',
        firmware: '1.0.6.215469', isController: false,
        backhaulType: 'Wireless', backhaulRssi: -55, backhaulSpeedMbps: 480,
      ),
      const MeshNodeInfo(
        deviceId: 'node-sat-003', name: 'MX6200 Bedroom', model: 'MX6200',
        firmware: '1.0.6.215469', isController: false,
        // Zombie: RSSI looks fine (-52 > -70) but throughput is degraded (45 < 80)
        backhaulType: 'Wireless', backhaulRssi: -52, backhaulSpeedMbps: 45,
      ),
    ];
    final verdict = VerdictEngine.compute(
      gatewayReachable: true,
      wanConnected: true,
      wanIpAddress: wanIp,
      dnsWorking: true,
      downloadMbps: 120.0,
      latencyMs: 18,
      firmwareUpdateAvailable: false,
      firmwareVersion: null,
      uptimeSeconds: 12 * 86400,
      deviceScores: scores,
      clients: clients,
      meshNodes: meshNodes,
      planSpeedMbps: null,
      cpuLoadPct: 88,
      memoryLoadPct: 90,
      hasEthernetNoLink: true,
      hasZombieMeshNode: true,
    );
    state = InstantVerifyPivotState(
      phase: PivotLoadPhase.complete,
      deviceInfo: _kMockDeviceInfo,
      wanStatus: {
        'wanStatus': 'Connected',
        'wanConnection': {'ipAddress': wanIp, 'gateway': '10.83.71.254'},
      },
      routerHealth: {
        'uptimeInSeconds': 12 * 86400,
        'cpuLoad': 88,
        'memoryLoad': 90,
      },
      ethernetPorts: {
        'wanPortConnection': 'Connected',
        'lanPortConnections': ['Connected', 'Disconnected', 'Connected', 'Connected'],
      },
      clients: clients,
      deviceScores: scores,
      meshNodes: meshNodes,
      gatewayPing: const GatewayPingResult(reachable: true, latencyMs: 4),
      dnsCheck: const DnsCheckResult(resolved: true),
      speedTest: const SpeedTestResult(
        downloadMbps: 120.0, uploadMbps: 45.0, latencyMs: 18, jitterMs: 3,
      ),
      jnapCapabilities: {
        JnapCapability.cpuLoad: true,
        JnapCapability.memoryLoad: true,
        JnapCapability.backhaulSpeedMbps: true,
        JnapCapability.backhaulRssi: true,
        JnapCapability.backhaulDataPresent: true,
        JnapCapability.ethernetPortStatus: true,
      },
      browserTestStep: 'complete',
      verdict: verdict,
      verdictIsPreliminary: false,
    );
  }

  /// ── Scenario E: Configuration blocks ────────────────────────────────────
  /// Triggers Check 8 (2.4 GHz overcrowded: 8/10 wireless on 2.4),
  /// Check 12 (WiFi schedule blocking, Instant Privacy on),
  /// Check 15 (PMF required — breaks IoT), Check 16 (band steering missteer),
  /// Check 19 (DHCP pool 92% full — 138/150).
  void _mockScenarioE() {
    // 8 of 10 wireless devices on 2.4 GHz — triggers Check 8
    final clients = [
      for (var i = 0; i < 8; i++)
        DiagnosticClient(
          macAddress: 'AA:BB:CC:EE:${i.toString().padLeft(2, '0')}:FF',
          hostname: '2.4GHz-Device-${i + 1}',
          ipAddress: '192.168.1.${110 + i}',
          band: '2.4 GHz',
          signalDecibels: -62 - i,
          // One 5GHz-capable device (high tx rate) stuck on 2.4 — band steering missteer
          txRateMbps: i == 0 ? 200 : 30 + i * 5,
          rxRateMbps: i == 0 ? 180 : 25 + i * 5,
          isWireless: true,
        ),
      const DiagnosticClient(
        macAddress: 'AA:BB:CC:FF:01:01', hostname: 'Gaming-PC',
        ipAddress: '192.168.1.120', band: '5 GHz',
        signalDecibels: -48, txRateMbps: 650, rxRateMbps: 600, isWireless: true,
      ),
      const DiagnosticClient(
        macAddress: 'AA:BB:CC:FF:01:02', hostname: 'Work-Laptop',
        ipAddress: '192.168.1.121', band: '5 GHz',
        signalDecibels: -55, txRateMbps: 450, rxRateMbps: 400, isWireless: true,
      ),
    ];
    final scores = clients.map(DeviceScore.compute).toList();
    const wanIp = '10.83.68.45';
    final verdict = VerdictEngine.compute(
      gatewayReachable: true,
      wanConnected: true,
      wanIpAddress: wanIp,
      dnsWorking: true,
      downloadMbps: 250.0,
      latencyMs: 12,
      firmwareUpdateAvailable: false,
      firmwareVersion: null,
      uptimeSeconds: 8 * 86400,
      deviceScores: scores,
      clients: clients,
      meshNodes: const [],
      planSpeedMbps: null,
      isWifiScheduleBlocking: true,
      isInstantPrivacyOn: true,
      isPmfRequired: true,
      isBandSteeringMissteer: true,
      dhcpPoolUtilizationPct: 92,
    );
    state = InstantVerifyPivotState(
      phase: PivotLoadPhase.complete,
      deviceInfo: _kMockDeviceInfo,
      wanStatus: {
        'wanStatus': 'Connected',
        'wanConnection': {'ipAddress': wanIp, 'gateway': '10.83.71.254'},
      },
      routerHealth: {'uptimeInSeconds': 8 * 86400},
      clients: clients,
      deviceScores: scores,
      dhcpLeasesCount: 138,
      dhcpPoolLimit: 150,
      // macFilter set so isMacFilterEnabled = true (consistent with Instant Privacy finding)
      macFilter: {'macFilterMode': 'BlockList'},
      // wirelessSchedule set so isWifiScheduleBlocking = true on any re-compute
      wirelessSchedule: {'isEnabled': true},
      // networkSecurity with PMF required
      networkSecurity: {'pmfMode': 'Required'},
      gatewayPing: const GatewayPingResult(reachable: true, latencyMs: 2),
      dnsCheck: const DnsCheckResult(resolved: true),
      speedTest: const SpeedTestResult(
        downloadMbps: 250.0, uploadMbps: 95.0, latencyMs: 12, jitterMs: 1,
      ),
      browserTestStep: 'complete',
      verdict: verdict,
      verdictIsPreliminary: false,
    );
  }

  /// Deauthenticate a client device — forces it to disconnect and reconnect.
  /// The device will lose internet for 5-15 seconds while it reassociates.
  Future<void> deauthClient(String macAddress) async {
    try {
      await _send(JNAPAction.clientDeauth, data: {'macAddress': macAddress});
      dev.log('InstantVerifyPivot: deauthed $macAddress');
    } catch (e) {
      dev.log('InstantVerifyPivot: clientDeauth failed: $e');
    }
  }

  /// Change the operating channel on a specific radio.
  /// Pass radioID (e.g., 'RADIO_2.4GHz') and the desired channel number.
  /// The router will briefly restart that radio — clients may disconnect for a few seconds.
  Future<bool> changeRadioChannel(String radioID, int channel) async {
    try {
      // GetRadioInfo3 to read current settings first — we must send the full settings object
      final current = await _sendOptional(JNAPAction.getRadioInfo);
      if (current.isEmpty) return false;
      final radios = current['radios'] as List?;
      if (radios == null) return false;

      // Build settings-only payload — SetRadioSettings only accepts
      // radioID + settings, not the full GetRadioInfo3 object (band, bssid,
      // supportedModes, etc. cause _ErrorInvalidInput).
      final updated = radios.map((r) {
        final radioMap = r as Map<String, dynamic>;
        final settings = Map<String, dynamic>.from(
            radioMap['settings'] as Map<String, dynamic>? ?? {});
        if (radioMap['radioID'] == radioID) {
          settings['channel'] = channel;
        }
        return {'radioID': radioMap['radioID'], 'settings': settings};
      }).toList();

      await _send(JNAPAction.setRadioSettings,
          data: {'radios': updated});
      dev.log('InstantVerifyPivot: changed $radioID to channel $channel');
      return true;
    } catch (e) {
      dev.log('InstantVerifyPivot: changeRadioChannel failed: $e');
      return false;
    }
  }

  void setPlanSpeed(double? mbps) {
    state = state.copyWith(planSpeedMbps: mbps);
    if (state.phase != PivotLoadPhase.loading) {
      _recomputeVerdict(preliminary: state.verdictIsPreliminary);
    }
  }

  // ── Internal router ping (diagnostic, no state side-effects) ─────────

  /// Pings [ip] from the router via JNAP and returns whether it responded.
  /// Uses only 2 packets to stay fast (~2-3s). Returns null on error.
  /// Does NOT touch isPingRunning / pingOutput state — purely internal.
  Future<bool?> _pingFromRouter(String ip) async {
    try {
      await _send(JNAPAction.startPing, data: {
        'host': ip,
        'packetSizeBytes': 32,
        'pingCount': 2,
      });
      // Poll for completion (max ~6s for 2-packet ping)
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        try {
          final result = await _send(JNAPAction.getPingStatus);
          final status = PingStatus.fromMap(result);
          if (!status.isRunning) {
            // Success: at least one packet received (0% packet loss line present)
            return status.pingLog.contains('0% packet loss') ||
                status.pingLog.contains('bytes from') ||
                status.pingLog.contains('ttl=');
          }
        } catch (_) {}
      }
      return null; // timed out polling
    } catch (e) {
      dev.log('InstantVerifyPivot: _pingFromRouter($ip) failed: $e');
      return null;
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

  // ── JNAP Capability Map ───────────────────────────────────────────────

  /// Builds a map of which JNAP fields were actually present on this device.
  /// Called once per fetch() after Phase 1c supplementary calls complete.
  /// Logged to dev console so developers can see what a specific router returns.
  Map<String, bool> _buildCapabilityMap({
    required Map<String, dynamic> systemStats,
    required Map<String, dynamic>? radioInfo,
    required Map<String, dynamic>? backhaulInfo,
    required Map<String, dynamic>? networkSecurity,
    required Map<String, dynamic>? parentalControls,
    required Map<String, dynamic>? wirelessSchedule,
    required Map<String, dynamic>? ethernetPorts,
    required Map<String, dynamic>? lanSettings,
    required Map<String, dynamic>? deviceMode,
    required List<MeshNodeInfo> meshNodes,
    required List<DiagnosticClient> clients,
  }) {
    final caps = <String, bool>{};

    // System stats — firmware uses different key names across platforms
    // Pinnacle/MX: cpuUsage/memUsage (float 0.0-1.0)
    // Velop Olympus: CPULoad/MemoryLoad (may be int 0-100 or float)
    final hasCpu = systemStats['CPULoad'] != null ||
        systemStats['cpuUsage'] != null ||
        systemStats['cpuLoad'] != null;
    final hasMem = systemStats['MemoryLoad'] != null ||
        systemStats['memUsage'] != null ||
        systemStats['memoryLoad'] != null;
    caps[JnapCapability.cpuLoad] = hasCpu;
    caps[JnapCapability.memoryLoad] = hasMem;

    // Radio info
    final radios = radioInfo?['radios'] as List?;
    caps[JnapCapability.radioInfoPresent] = radios != null && radios.isNotEmpty;
    caps[JnapCapability.bandSteeringState] =
        radioInfo?['isBandSteeringSupported'] != null;
    // SNR — confirmed absent on all known Pinnacle/MX firmware
    caps[JnapCapability.radioSnr] = false;

    // Backhaul
    final backhaulDevices = backhaulInfo?['backhaulDevices'] as List?;
    caps[JnapCapability.backhaulDataPresent] =
        backhaulDevices != null && backhaulDevices.isNotEmpty;
    if (backhaulDevices != null && backhaulDevices.isNotEmpty) {
      // Check if speedMbps field is present and parseable on first entry
      final firstBh = backhaulDevices.first as Map<String, dynamic>?;
      final rawSpeed = firstBh?['speedMbps'];
      caps[JnapCapability.backhaulSpeedMbps] = rawSpeed != null &&
          int.tryParse(rawSpeed.toString()) != null;
      caps[JnapCapability.backhaulRssi] = firstBh?['rssi'] != null;
    } else {
      caps[JnapCapability.backhaulSpeedMbps] = false;
      caps[JnapCapability.backhaulRssi] = false;
    }

    // Ethernet ports
    final lanPorts = ethernetPorts?['lanPortConnections'] as List?;
    caps[JnapCapability.ethernetPortStatus] =
        lanPorts != null && lanPorts.isNotEmpty;

    // LAN/DHCP pool range
    final dhcpSettings = lanSettings?['dhcpSettings'] as Map<String, dynamic>?;
    caps[JnapCapability.dhcpPoolRange] =
        dhcpSettings?['firstClientIPAddress'] != null;

    // Security / PMF
    caps[JnapCapability.pmfModePresent] = networkSecurity != null &&
        networkSecurity.isNotEmpty;

    // Parental controls
    final pcEnabled = parentalControls?['isParentalControlEnabled'] ??
        parentalControls?['isParentalControlsEnabled'] ??
        parentalControls?['enabled'];
    caps[JnapCapability.parentalControlsPresent] = pcEnabled != null;

    // WiFi scheduler
    caps[JnapCapability.wifiSchedulePresent] =
        wirelessSchedule?['isEnabled'] != null;

    // Device mode
    caps[JnapCapability.deviceModePresent] = deviceMode != null &&
        deviceMode.isNotEmpty;

    // Client tx/rx rates — verify at least one client returned rate data
    final hasRates = clients.any(
        (c) => c.isWireless && (c.txRateMbps != null || c.rxRateMbps != null));
    caps[JnapCapability.clientTxRxRates] = hasRates;

    return caps;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Supplement [deviceMap] with IP address and hostname from DHCP leases.
  ///
  /// GetDevices (old version, used when router doesn't advertise deviceList4)
  /// does not return ipAddress in its connection objects. DHCP leases are
  /// the most reliable fallback — they always contain MAC + current IP.
  void _enrichDeviceMapWithDhcp(
    Map<String, Map<String, String?>> deviceMap,
    Map<String, dynamic> dhcpData,
  ) {
    final leases = dhcpData['leases'] as List?
        ?? dhcpData['clientLeases'] as List?
        ?? dhcpData['dhcpLeases'] as List?
        ?? dhcpData['dhcpClientLeases'] as List?
        ?? [];
    for (final lease in leases) {
      final mac = (lease['macAddress'] as String?)?.toUpperCase();
      if (mac == null) continue;
      final ip = lease['ipAddress'] as String?;
      final hostname = lease['hostName'] as String?
          ?? lease['hostname'] as String?;
      if (deviceMap.containsKey(mac)) {
        final existing = deviceMap[mac]!;
        if (existing['ipAddress'] == null && ip != null) {
          existing['ipAddress'] = ip;
        }
        if (existing['hostname'] == null && hostname != null) {
          existing['hostname'] = hostname;
        }
      } else {
        deviceMap[mac] = {'ipAddress': ip, 'hostname': hostname};
      }
    }
  }

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

      // GetBackhaulInfo2 nests signal/channel data inside wirelessConnectionInfo.
      // GetBackhaulInfo (v1) put rssi at the top level — keep backward compat.
      final wci = backhaul['wirelessConnectionInfo'] as Map<String, dynamic>?;
      final apRssi = wci?['apRSSI'] as int? ?? backhaul['rssi'] as int?;
      final stationRssi = wci?['stationRSSI'] as int?;
      final channel = wci?['channel'] as int?;
      final radioId = wci?['radioID'] as String?;

      return MeshNodeInfo(
        deviceId: node.deviceId,
        name: node.name,
        model: node.model,
        firmware: node.firmware,
        serialNumber: node.serialNumber,
        isController: node.isController,
        backhaulType: backhaul['connectionType'] as String?,
        backhaulRssi: apRssi,
        // HW-1: firmware returns speedMbps as a numeric String, not int
        backhaulSpeedMbps: int.tryParse(
            (backhaul['speedMbps'] ?? '').toString()),
        backhaulApRssi: apRssi,
        backhaulStationRssi: stationRssi,
        backhaulChannel: channel,
        backhaulRadioId: radioId,
      );
    }).toList();
  }

  // ── B-6: Recurrence detection (localStorage) ─────────────────────────

  static const _restartKey = 'instant_test_last_restart';

  void _persistRestartTimestamp() {
    setStoredValue(_restartKey, DateTime.now().toUtc().toIso8601String());
  }

  bool _checkRecentPriorRestart() {
    final stored = getStoredValue(_restartKey);
    if (stored == null) return false;
    final timestamp = DateTime.tryParse(stored);
    if (timestamp == null) return false;
    return DateTime.now().toUtc().difference(timestamp).inHours < 24;
  }
}
