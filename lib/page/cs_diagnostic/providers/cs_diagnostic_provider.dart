import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';
import 'package:privacy_gui/page/cs_diagnostic/services/jnap_diagnostic_service.dart';
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
      final service = ref.read(jnapDiagnosticServiceProvider);

      // Fetch reliable data first
      final coreResults = await Future.wait([
        service.getWANStatus(),     // 0: WAN state
        service.getDeviceInfo(),    // 1: router info
        service.getSystemStats(),   // 2: uptime, CPU, memory
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
        wirelessData = await service.getNodesWirelessConnections();
        dev.log('Instant-Help: NodesWireless OK, keys: ${wirelessData.keys}');
      } catch (e) {
        dev.log('Instant-Help: NodesWireless failed: $e');
      }

      // Approach 2: GetNetworkConnections (has MAC, IP, hostname, wireless)
      try {
        netConns = await service.getNetworkConnections();
        dev.log('Instant-Help: NetConns OK, keys: ${netConns.keys}');
      } catch (e) {
        dev.log('Instant-Help: NetConns failed: $e');
      }

      // DHCP
      try {
        dhcpData = await service.getDHCPClientLeases();
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
        final deviceList = await service.getDevices();
        final devMap = _buildDeviceMap(deviceList);
        for (final entry in devMap.entries) {
          deviceMap[entry.key] = entry.value;
        }
      } catch (_) {}

      // Parse clients from whichever source worked
      List<DiagnosticClient> clients;
      if (wirelessData.isNotEmpty) {
        clients = _parseClients(wirelessData, deviceMap);
        dev.log('Instant-Help: parsed ${clients.length} from NodesWireless');
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
        service.getRadioInfo().catchError((_) => <String, dynamic>{}),
        service.getGuestNetworkSettings().catchError((_) => <String, dynamic>{}),
        service.getFirmwareUpdateStatus().catchError((_) => <String, dynamic>{}),
        service.getBackhaulInfo().catchError((_) => <String, dynamic>{}),
        service.getMACFilterSettings().catchError((_) => <String, dynamic>{}),
        service.getNetworkSecuritySettings().catchError((_) => <String, dynamic>{}),
        service.getParentalControlSettings().catchError((_) => <String, dynamic>{}),
        service.getWirelessSchedulerSettings().catchError((_) => <String, dynamic>{}),
        service.getSelectedChannels().catchError((_) => <String, dynamic>{}),
        service.getEthernetPortConnections().catchError((_) => <String, dynamic>{}),
      ]);

      Map<String, dynamic> orNull(Map<String, dynamic> m) => m.isNotEmpty ? m : {};

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
        radioInfo: orNull(supplementary[0]).isNotEmpty ? supplementary[0] : null,
        guestNetwork: orNull(supplementary[1]).isNotEmpty ? supplementary[1] : null,
        firmwareUpdate: orNull(supplementary[2]).isNotEmpty ? supplementary[2] : null,
        backhaulInfo: orNull(supplementary[3]).isNotEmpty ? supplementary[3] : null,
        macFilter: orNull(supplementary[4]).isNotEmpty ? supplementary[4] : null,
        networkSecurity: orNull(supplementary[5]).isNotEmpty ? supplementary[5] : null,
        parentalControls: orNull(supplementary[6]).isNotEmpty ? supplementary[6] : null,
        wirelessSchedule: orNull(supplementary[7]).isNotEmpty ? supplementary[7] : null,
        channelInfo: orNull(supplementary[8]).isNotEmpty ? supplementary[8] : null,
        ethernetPorts: orNull(supplementary[9]).isNotEmpty ? supplementary[9] : null,
      );
    } catch (e) {
      state = state.copyWith(
        loadState: DiagnosticLoadState.error,
        errorMessage: 'Failed to load network data: $e',
      );
    }
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

  /// Build a lookup of MAC address → {hostname, ipAddress} from GetDevices3.
  Map<String, Map<String, String?>> _buildDeviceMap(Map<String, dynamic> data) {
    final map = <String, Map<String, String?>>{};
    final devices = data['devices'] as List? ?? [];
    for (final dev in devices) {
      final connections = dev['connections'] as List? ?? [];
      final friendlyName = dev['friendlyName'] as String?;
      final hostname = dev['hostname'] as String?;
      final name = friendlyName ?? hostname;

      for (final conn in connections) {
        final mac = (conn['macAddress'] as String?)?.toUpperCase();
        final ip = conn['ipAddress'] as String?;
        if (mac != null) {
          map[mac] = {'hostname': name, 'ipAddress': ip};
        }
      }
    }
    return map;
  }

  /// Parse GetNetworkConnections2 response, merging hostname/IP from device map.
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
        final deviceInfo = deviceMap[mac];

        // Debug: log first connection's structure
        if (clients.isEmpty && wireless != null) {
          dev.log('Instant-Help: wireless keys: ${wireless.keys.toList()}');
          dev.log('Instant-Help: wireless sample: $wireless');
          dev.log('Instant-Help: deviceInfo for $mac: $deviceInfo');
          dev.log('Instant-Help: conn keys: ${conn.keys.toList()}');
        }

        if (wireless != null) {
          clients.add(DiagnosticClient(
            macAddress: mac,
            hostname: deviceInfo?['hostname'],
            ipAddress: deviceInfo?['ipAddress'],
            band: (wireless['band'] as String?) ?? 'Unknown',
            signalDecibels: wireless['signalDecibels'] as int?,
            txRateMbps: wireless['txRate'] as int?,
            rxRateMbps: wireless['rxRate'] as int?,
            isWireless: true,
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
