import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_auth_provider.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';
import 'package:privacy_gui/page/cs_diagnostic/services/mock_diagnostic_data.dart';

final csDiagnosticProvider = NotifierProvider<CsDiagnosticNotifier, CsDiagnosticState>(
  CsDiagnosticNotifier.new,
);

class CsDiagnosticNotifier extends Notifier<CsDiagnosticState> {
  bool _useMock = false;
  bool _useDegraded = false;

  bool get useMock => _useMock;
  bool get useDegraded => _useDegraded;

  @override
  CsDiagnosticState build() => const CsDiagnosticState();

  /// Helper: send a JNAP action via RouterRepository with diagnostic auth headers.
  Future<Map<String, dynamic>> _send(
    JNAPAction action, {
    bool auth = true,
    Map<String, dynamic> data = const {},
  }) async {
    final repo = ref.read(routerRepositoryProvider);
    final headers = auth ? ref.read(diagnosticAuthProvider).authHeaders : const <String, String>{};
    final result = await repo.send(
      action,
      data: data,
      extraHeaders: headers,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );
    return result.output;
  }

  /// Helper: send a JNAP action, returning empty map on failure (for optional calls).
  Future<Map<String, dynamic>> _sendOptional(JNAPAction action) async {
    try {
      return await _send(action);
    } catch (e) {
      dev.log('Instant-Help: ${action.name} failed: $e');
      return <String, dynamic>{};
    }
  }

  Future<void> fetch() async {
    state = state.copyWith(loadState: DiagnosticLoadState.loading);

    if (_useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      state = _useDegraded
          ? MockDiagnosticData.degraded()
          : MockDiagnosticData.healthy();
      return;
    }

    try {
      // Fetch reliable data first
      final coreResults = await Future.wait([
        _send(JNAPAction.getWANStatus, auth: false),  // 0: WAN state
        _send(JNAPAction.getDeviceInfo, auth: false),  // 1: router info
        _send(JNAPAction.getSystemStats),               // 2: uptime, CPU, memory
      ]);

      final wanData = coreResults[0];
      final deviceInfo = coreResults[1];
      final systemStats = coreResults[2];

      dev.log('Instant-Help: wanData keys: ${wanData.keys}');

      // Try multiple approaches to get client data — firmware varies
      Map<String, dynamic> wirelessData = {};
      Map<String, dynamic> netConns = {};
      Map<String, dynamic> dhcpData = {};

      // Approach 1: GetNodesWirelessNetworkConnections (mesh devices)
      try {
        wirelessData = await _send(JNAPAction.getNodesWirelessNetworkConnections);
        dev.log('Instant-Help: NodesWireless OK, keys: ${wirelessData.keys}');
      } catch (e) {
        dev.log('Instant-Help: NodesWireless failed: $e');
      }

      // Approach 2: GetNetworkConnections (has MAC, IP, hostname, wireless)
      try {
        netConns = await _send(JNAPAction.getNetworkConnections);
        dev.log('Instant-Help: NetConns OK, keys: ${netConns.keys}');
      } catch (e) {
        dev.log('Instant-Help: NetConns failed: $e');
      }

      // DHCP
      try {
        dhcpData = await _send(JNAPAction.getDHCPClientLeases);
      } catch (e) {
        dev.log('Instant-Help: DHCP failed: $e');
      }

      // Build device map from GetNetworkConnections
      Map<String, Map<String, String?>> deviceMap = {};
      if (netConns.isNotEmpty) {
        deviceMap = _buildDeviceMapFromConnections(netConns);
      }

      // Try GetDevices3 for richer names
      try {
        final deviceList = await _send(JNAPAction.getDevices);
        final devMap = _buildDeviceMap(deviceList);
        for (final entry in devMap.entries) {
          deviceMap[entry.key] = entry.value;
        }
      } catch (_) {}

      // Parse clients from whichever source worked
      List<DiagnosticClient> clients;
      if (wirelessData.isNotEmpty) {
        clients = _parseClients(wirelessData, deviceMap);
        dev.log('Instant-Help: parsed ${clients.length} wireless from NodesWireless');
        // NodesWireless only returns wireless clients — add wired from NetConns
        if (netConns.isNotEmpty) {
          final wirelessMacs = clients.map((c) => c.macAddress).toSet();
          final wiredClients = _parseClientsFromNetConns(netConns)
              .where((c) => !c.isWireless && !wirelessMacs.contains(c.macAddress))
              .toList();
          clients.addAll(wiredClients);
          dev.log('Instant-Help: added ${wiredClients.length} wired from NetConns');
        }
      } else if (netConns.isNotEmpty) {
        clients = _parseClientsFromNetConns(netConns);
        dev.log('Instant-Help: parsed ${clients.length} from NetConns');
      } else {
        clients = [];
        dev.log('Instant-Help: no client data available');
      }

      // Parse DHCP leases count — try multiple key names
      final dhcpLeases = (dhcpData['dhcpLeases'] as List?)?.length ??
          (dhcpData['leases'] as List?)?.length ??
          (dhcpData['dhcpClientLeases'] as List?)?.length ?? 0;
      dev.log('Instant-Help: dhcpData keys: ${dhcpData.keys}, leases: $dhcpLeases');

      // Router uptime from GetSystemStats
      final uptimeSeconds = (systemStats['uptimeSeconds'] as int?) ?? 0;
      // CPULoad and MemoryLoad come as decimal strings (e.g. "0.12" = 12%)
      final cpuRaw = systemStats['CPULoad'];
      final memRaw = systemStats['MemoryLoad'];
      final cpuPct = cpuRaw != null ? ((double.tryParse('$cpuRaw') ?? 0) * 100).round() : null;
      final memPct = memRaw != null ? ((double.tryParse('$memRaw') ?? 0) * 100).round() : null;
      dev.log('Instant-Help: uptime=${uptimeSeconds}s, cpuRaw=$cpuRaw→$cpuPct%, memRaw=$memRaw→$memPct%');

      // Fetch supplementary data in parallel (all optional — failures don't block)
      final supplementary = await Future.wait([
        _sendOptional(JNAPAction.getRadioInfo),              // 0
        _sendOptional(JNAPAction.getGuestNetworkSettings),   // 1
        _sendOptional(JNAPAction.getFirmwareUpdateStatus),   // 2
        _sendOptional(JNAPAction.getBackhaulInfo),           // 3
        _sendOptional(JNAPAction.getMACFilterSettings),      // 4
        _sendOptional(JNAPAction.getNetworkSecuritySettings),// 5
        _sendOptional(JNAPAction.getParentalControlSettings),// 6
        _sendOptional(JNAPAction.getWirelessSchedulerSettings),// 7
        _sendOptional(JNAPAction.getSelectedChannels),       // 8
        _sendOptional(JNAPAction.getEthernetPortConnections),// 9
      ]);

      Map<String, dynamic>? orNull(Map<String, dynamic> m) => m.isNotEmpty ? m : null;

      state = state.copyWith(
        loadState: DiagnosticLoadState.loaded,
        clients: clients,
        wanStatus: wanData,
        deviceInfo: deviceInfo,
        dhcpLeasesCount: dhcpLeases,
        routerHealth: {
          'uptimeInSeconds': uptimeSeconds,
          'cpuLoad': cpuPct,
          'memoryLoad': memPct,
        },
        radioInfo: orNull(supplementary[0]),
        guestNetwork: orNull(supplementary[1]),
        firmwareUpdate: orNull(supplementary[2]),
        backhaulInfo: orNull(supplementary[3]),
        macFilter: orNull(supplementary[4]),
        networkSecurity: orNull(supplementary[5]),
        parentalControls: orNull(supplementary[6]),
        wirelessSchedule: orNull(supplementary[7]),
        channelInfo: orNull(supplementary[8]),
        ethernetPorts: orNull(supplementary[9]),
      );
    } catch (e) {
      state = state.copyWith(
        loadState: DiagnosticLoadState.error,
        errorMessage: 'Failed to load network data: $e',
      );
    }
  }

  // ── Speed Test (JNAP HealthCheck) ──────────────────────────────────

  Future<void> runSpeedTest() async {
    state = state.copyWith(
      speedTestStep: 'latency',
      clearSpeedTestLatency: true,
      clearSpeedTestDownload: true,
      clearSpeedTestUpload: true,
      clearSpeedTestError: true,
    );

    try {
      // 1. Trigger RunHealthCheck
      final runResult = await _send(
        JNAPAction.runHealthCheck,
        data: {'runHealthCheckModule': 'SpeedTest'},
      );
      if (runResult['resultID'] == null) {
        state = state.copyWith(
          speedTestStep: 'error',
          speedTestError: 'Router returned empty resultID',
        );
        return;
      }

      // 2. Poll GetHealthCheckStatus until done
      const pollInterval = Duration(milliseconds: 500);
      const maxPolls = 120; // 60 seconds max
      for (var i = 0; i < maxPolls; i++) {
        await Future<void>.delayed(pollInterval);

        Map<String, dynamic> statusData;
        try {
          statusData = await _send(JNAPAction.getHealthCheckStatus);
        } catch (e) {
          dev.log('Instant-Help: speed test poll error: $e');
          continue; // Transient failure, keep polling
        }

        final speedResult = statusData['speedTestResult'] as Map<String, dynamic>?;
        if (speedResult == null) continue;

        final exitCode = speedResult['exitCode'] as String?;

        // Check for error exit codes
        if (exitCode != null && exitCode != 'Success' && exitCode != 'Unavailable') {
          state = state.copyWith(
            speedTestStep: 'error',
            speedTestError: exitCode,
          );
          return;
        }

        // Update progress based on which fields are populated
        final latency = speedResult['latency'] as int?;
        final download = speedResult['downloadBandwidth'] as int?;
        final upload = speedResult['uploadBandwidth'] as int?;

        if (upload != null && upload != 0) {
          state = state.copyWith(
            speedTestStep: 'upload',
            speedTestLatencyMs: latency,
            speedTestDownloadKbps: download,
            speedTestUploadKbps: upload,
          );
        } else if (download != null && download != 0) {
          state = state.copyWith(
            speedTestStep: 'download',
            speedTestLatencyMs: latency,
            speedTestDownloadKbps: download,
          );
        } else if (latency != null && latency != 0) {
          state = state.copyWith(
            speedTestStep: 'latency',
            speedTestLatencyMs: latency,
          );
        }

        // Check if test is done
        if (exitCode == 'Success') {
          state = state.copyWith(
            speedTestStep: 'complete',
            speedTestLatencyMs: latency,
            speedTestDownloadKbps: download,
            speedTestUploadKbps: upload,
          );
          return;
        }

        final stillRunning = statusData['healthCheckModuleCurrentlyRunning'];
        if (stillRunning == false || stillRunning == null) {
          // Module stopped but exitCode wasn't 'Success' — treat as complete with whatever we have
          state = state.copyWith(
            speedTestStep: 'complete',
            speedTestLatencyMs: latency,
            speedTestDownloadKbps: download,
            speedTestUploadKbps: upload,
          );
          return;
        }
      }

      // Timed out
      state = state.copyWith(
        speedTestStep: 'error',
        speedTestError: 'Speed test timed out',
      );
    } catch (e) {
      state = state.copyWith(
        speedTestStep: 'error',
        speedTestError: 'Failed to start speed test: $e',
      );
    }
  }

  Future<void> stopSpeedTest() async {
    try {
      await _send(JNAPAction.stopHealthCheck);
    } catch (_) {}
    state = state.copyWith(speedTestStep: 'idle');
  }

  void toggleMock() {
    _useMock = !_useMock;
    fetch();
  }

  void toggleDegraded() {
    _useDegraded = !_useDegraded;
    if (_useMock) {
      fetch();
    }
  }

  /// Build lookup from GetNetworkConnections (has macAddress + ipAddress per connection).
  Map<String, Map<String, String?>> _buildDeviceMapFromConnections(Map<String, dynamic> data) {
    final map = <String, Map<String, String?>>{};
    final connections = data['connections'] as List? ?? [];
    for (final conn in connections) {
      final mac = (conn['macAddress'] as String?)?.toUpperCase();
      final ip = conn['ipAddress'] as String?;
      final hostname = conn['hostname'] as String?;
      if (mac != null) {
        map[mac] = {'hostname': hostname, 'ipAddress': ip};
      }
    }
    dev.log('Instant-Help: deviceMapFromConnections: ${map.length} entries');
    return map;
  }

  /// Build a lookup of MAC address → {hostname, ipAddress, txRate, rxRate, deviceType} from GetDevices3.
  Map<String, Map<String, String?>> _buildDeviceMap(Map<String, dynamic> data) {
    final map = <String, Map<String, String?>>{};
    final devices = data['devices'] as List? ?? [];
    for (final d in devices) {
      final connections = d['connections'] as List? ?? [];
      final friendlyName = d['friendlyName'] as String?;
      final hostname = d['hostname'] as String?;
      final name = friendlyName ?? hostname;
      // Device type from model.deviceType (e.g. "Mobile", "Computer", "")
      final deviceType = (d['model'] as Map<String, dynamic>?)?['deviceType'] as String?;

      for (final conn in connections) {
        final mac = (conn['macAddress'] as String?)?.toUpperCase();
        final ip = conn['ipAddress'] as String?;
        if (mac != null) {
          final entry = <String, String?>{'hostname': name, 'ipAddress': ip};

          // Device type
          if (deviceType != null && deviceType.isNotEmpty) {
            entry['deviceType'] = deviceType;
          }

          // GetDevices has txRate/rxRate in wirelessConnectionInfo (not in GetNodesWireless)
          final wcInfo = conn['wirelessConnectionInfo'] as Map<String, dynamic>?;
          if (wcInfo != null) {
            final txRaw = wcInfo['txRate'];
            final rxRaw = wcInfo['rxRate'];
            // Values are in Kbps — convert to Mbps
            if (txRaw != null) entry['txRate'] = '${(txRaw as int) ~/ 1000}';
            if (rxRaw != null) entry['rxRate'] = '${(rxRaw as int) ~/ 1000}';
          }

          map[mac] = entry;
        }
      }
    }
    return map;
  }

  /// Parse GetNodesWirelessNetworkConnections response, merging hostname/IP from device map.
  List<DiagnosticClient> _parseClients(
    Map<String, dynamic> netConns,
    Map<String, Map<String, String?>> deviceMap,
  ) {
    final clients = <DiagnosticClient>[];
    final nodeConnections = netConns['nodeWirelessConnections'] as List? ?? [];

    for (final node in nodeConnections) {
      final connections = node['connections'] as List? ?? [];
      for (final conn in connections) {
        final mac = ((conn['macAddress'] as String?) ?? '').toUpperCase();
        final wireless = conn['wireless'] as Map<String, dynamic>?;
        final devInfo = deviceMap[mac];

        // Debug: log first connection's structure
        if (clients.isEmpty && wireless != null) {
          dev.log('Instant-Help: wireless keys: ${wireless.keys.toList()}');
          dev.log('Instant-Help: wireless sample: $wireless');
          dev.log('Instant-Help: deviceInfo for $mac: $devInfo');
          dev.log('Instant-Help: conn keys: ${conn.keys.toList()}');
        }

        if (wireless != null) {
          // TX/RX: prefer wireless object, fallback to negotiatedMbps, then GetDevices
          final txWireless = wireless['txRate'] as int?;
          final rxWireless = wireless['rxRate'] as int?;
          final txFromDevices = devInfo?['txRate'] != null ? int.tryParse(devInfo!['txRate']!) : null;
          final rxFromDevices = devInfo?['rxRate'] != null ? int.tryParse(devInfo!['rxRate']!) : null;
          // negotiatedMbps is in Kbps (despite the name) — convert to Mbps
          final negotiated = conn['negotiatedMbps'] as int?;
          final negotiatedMbps = negotiated != null ? negotiated ~/ 1000 : null;

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

    // Sort: flagged first, then by signal ascending (worst first)
    clients.sort((a, b) {
      if (a.isFlagged != b.isFlagged) return a.isFlagged ? -1 : 1;
      final aSig = a.signalDecibels ?? 0;
      final bSig = b.signalDecibels ?? 0;
      return aSig.compareTo(bSig);
    });
    return clients;
  }

  /// Parse GetNetworkConnections response — flatter structure than NodesWireless.
  List<DiagnosticClient> _parseClientsFromNetConns(Map<String, dynamic> data) {
    final clients = <DiagnosticClient>[];
    final connections = data['connections'] as List? ?? [];

    for (final conn in connections) {
      final mac = ((conn['macAddress'] as String?) ?? '').toUpperCase();
      final ip = conn['ipAddress'] as String?;
      final hostname = conn['hostname'] as String?;
      final wireless = conn['wireless'] as Map<String, dynamic>?;
      final isWireless = wireless != null;

      clients.add(DiagnosticClient(
        macAddress: mac,
        hostname: hostname,
        ipAddress: ip,
        band: isWireless ? ((wireless['band'] as String?) ?? 'Unknown') : 'Wired',
        signalDecibels: isWireless ? wireless['signalDecibels'] as int? : null,
        txRateMbps: isWireless ? wireless['txRate'] as int? : null,
        rxRateMbps: isWireless ? wireless['rxRate'] as int? : null,
        isWireless: isWireless,
      ));
    }

    // Sort: flagged first, then by signal ascending (worst first)
    clients.sort((a, b) {
      if (a.isFlagged != b.isFlagged) return a.isFlagged ? -1 : 1;
      final aSig = a.signalDecibels ?? 0;
      final bSig = b.signalDecibels ?? 0;
      return aSig.compareTo(bSig);
    });
    return clients;
  }
}
