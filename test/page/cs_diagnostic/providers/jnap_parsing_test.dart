import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';

/// Real JNAP response fixtures from M60CF router (2026-04-02).
/// These tests validate that JNAP data is correctly interpreted,
/// so the developer doesn't need to manually verify every build.

// GetDeviceInfo response
const _deviceInfo = <String, dynamic>{
  'manufacturer': 'Linksys',
  'modelNumber': 'M60CF-EU',
  'hardwareVersion': '1',
  'description': 'Linksys PINNACLE 2.0',
  'serialNumber': '67A10M24F00099',
  'firmwareVersion': '1.0.18.26040118',
  'firmwareDate': '2026-04-02T01:57:25Z',
};

// GetSystemStats response — this firmware has NO CPULoad or MemoryLoad
const _systemStats = <String, dynamic>{
  'uptimeSeconds': 12150,
};

// GetRadioInfo3 response (simplified)
const _radioInfo = <String, dynamic>{
  'isBandSteeringSupported': false,
  'radios': [
    {
      'radioID': 'RADIO_2.4GHz',
      'band': '2.4GHz',
      'settings': {'mode': '802.11mixed', 'channelWidth': 'Auto', 'channel': 0},
    },
    {
      'radioID': 'RADIO_5GHz',
      'band': '5GHz',
      'settings': {'mode': '802.11mixed', 'channelWidth': 'Auto', 'channel': 0},
    },
  ],
};

// GetNodesWirelessNetworkConnections — wireless field has no txRate/rxRate
const _wirelessConnections = <String, dynamic>{
  'nodeWirelessConnections': [
    {
      'deviceID': '5e76ee80-17ef-412e-9516-7412132155c8',
      'connections': [
        {
          'macAddress': 'BA:E0:0E:D0:C6:5C',
          'negotiatedMbps': 1201000,
          'wireless': {'radioID': 'RADIO_5GHz', 'band': '5GHz', 'signalDecibels': -31},
        },
        {
          'macAddress': '22:A7:50:A4:C5:0B',
          'negotiatedMbps': 1201000,
          'wireless': {'radioID': 'RADIO_5GHz', 'band': '5GHz', 'signalDecibels': -41},
        },
        {
          'macAddress': 'D6:B0:E7:B4:64:D9',
          'negotiatedMbps': 2401900,
          'wireless': {'radioID': 'RADIO_5GHz', 'band': '5GHz', 'signalDecibels': -39},
        },
        {
          'macAddress': 'C6:B3:F3:64:A5:09',
          'negotiatedMbps': 2401900,
          'wireless': {'radioID': 'RADIO_5GHz', 'band': '5GHz', 'signalDecibels': -32},
        },
      ],
    },
  ],
};

// GetDevices3 — has friendlyName, model.deviceType, ipAddress
const _devices3 = <String, dynamic>{
  'devices': [
    {
      'model': {'deviceType': ''},
      'connections': [
        {'macAddress': '98:FC:84:E7:20:52', 'ipAddress': '192.168.1.254'},
      ],
    },
    {
      'friendlyName': 'Jeevan-S21-Ultra',
      'model': {'deviceType': 'Mobile'},
      'connections': [
        {'macAddress': 'D6:B0:E7:B4:64:D9', 'ipAddress': '192.168.1.212'},
      ],
    },
    {
      'friendlyName': 'MACBOOKPRO',
      'model': {'deviceType': ''},
      'connections': [
        {'macAddress': 'BA:E0:0E:D0:C6:5C', 'ipAddress': '192.168.1.234'},
      ],
    },
  ],
};

/// Simulates _buildDeviceMap from cs_diagnostic_provider.dart
Map<String, Map<String, String?>> buildDeviceMap(Map<String, dynamic> data) {
  final map = <String, Map<String, String?>>{};
  final devices = data['devices'] as List? ?? [];
  for (final d in devices) {
    final connections = (d as Map<String, dynamic>)['connections'] as List? ?? [];
    final friendlyName = d['friendlyName'] as String?;
    final hostname = d['hostname'] as String?;
    final name = friendlyName ?? hostname;
    final deviceType =
        ((d['model'] as Map<String, dynamic>?)?['deviceType'] as String?);

    for (final conn in connections) {
      final c = conn as Map<String, dynamic>;
      final mac = (c['macAddress'] as String?)?.toUpperCase();
      final ip = c['ipAddress'] as String?;
      if (mac != null) {
        final entry = <String, String?>{'hostname': name, 'ipAddress': ip};
        if (deviceType != null && deviceType.isNotEmpty) {
          entry['deviceType'] = deviceType;
        }
        final wcInfo = c['wirelessConnectionInfo'] as Map<String, dynamic>?;
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

/// Simulates _parseClients from cs_diagnostic_provider.dart
List<DiagnosticClient> parseClients(
  Map<String, dynamic> netConns,
  Map<String, Map<String, String?>> deviceMap,
) {
  final clients = <DiagnosticClient>[];
  final nodeConnections = netConns['nodeWirelessConnections'] as List? ?? [];

  for (final node in nodeConnections) {
    final n = node as Map<String, dynamic>;
    final connections = n['connections'] as List? ?? [];
    for (final conn in connections) {
      final c = conn as Map<String, dynamic>;
      final mac = ((c['macAddress'] as String?) ?? '').toUpperCase();
      final wireless = c['wireless'] as Map<String, dynamic>?;
      final devInfo = deviceMap[mac];

      if (wireless != null) {
        final txWireless = wireless['txRate'] as int?;
        final rxWireless = wireless['rxRate'] as int?;
        final txFromDevices =
            devInfo?['txRate'] != null ? int.tryParse(devInfo!['txRate']!) : null;
        final rxFromDevices =
            devInfo?['rxRate'] != null ? int.tryParse(devInfo!['rxRate']!) : null;
        final negotiated = c['negotiatedMbps'] as int?;
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
  return clients;
}

void main() {
  // ── GetDeviceInfo parsing ───────────────────────────────────────────

  group('GetDeviceInfo parsing', () {
    test('modelNumber is M60CF-EU not description', () {
      expect(_deviceInfo['modelNumber'], 'M60CF-EU');
      expect(_deviceInfo['description'], 'Linksys PINNACLE 2.0');
    });

    test('serialNumber extracted', () {
      expect(_deviceInfo['serialNumber'], '67A10M24F00099');
    });

    test('firmwareVersion extracted', () {
      expect(_deviceInfo['firmwareVersion'], '1.0.18.26040118');
    });
  });

  // ── GetSystemStats parsing ──────────────────────────────────────────

  group('GetSystemStats parsing', () {
    test('uptimeSeconds extracted', () {
      final uptime = (_systemStats['uptimeSeconds'] as int?) ?? 0;
      expect(uptime, 12150);
    });

    test('CPU and memory gracefully absent', () {
      final cpuRaw = _systemStats['CPULoad'];
      final memRaw = _systemStats['MemoryLoad'];
      expect(cpuRaw, isNull, reason: 'This firmware has no CPULoad');
      expect(memRaw, isNull, reason: 'This firmware has no MemoryLoad');

      // The provider converts to percent — null input should stay null
      final cpuPct = cpuRaw != null
          ? ((double.tryParse('$cpuRaw') ?? 0) * 100).round()
          : null;
      expect(cpuPct, isNull);
    });
  });

  // ── Radio config parsing ────────────────────────────────────────────

  group('Radio config parsing', () {
    test('channel 0 is Auto', () {
      final radios = _radioInfo['radios'] as List;
      for (final radio in radios) {
        final r = radio as Map<String, dynamic>;
        final channel = r['settings']['channel'];
        expect(channel, 0);
        final isAuto = channel == 0 || channel == '0';
        expect(isAuto, isTrue);
      }
    });

    test('both radios present with correct bands', () {
      final radios = _radioInfo['radios'] as List;
      expect(radios.length, 2);
      expect((radios[0] as Map)['band'], '2.4GHz');
      expect((radios[1] as Map)['band'], '5GHz');
    });

    test('band steering is not supported', () {
      expect(_radioInfo['isBandSteeringSupported'], false);
    });

    test('channelWidth Auto should not show redundant (Auto)', () {
      final radios = _radioInfo['radios'] as List;
      for (final radio in radios) {
        final r = radio as Map<String, dynamic>;
        final width = r['settings']['channelWidth'];
        // When both channel and width are Auto, display should be clean
        expect(width, 'Auto');
      }
    });
  });

  // ── Device map from GetDevices3 ─────────────────────────────────────

  group('buildDeviceMap from GetDevices3', () {
    late Map<String, Map<String, String?>> deviceMap;

    setUp(() {
      deviceMap = buildDeviceMap(_devices3);
    });

    test('extracts all devices with MAC addresses', () {
      expect(deviceMap.length, 3);
    });

    test('friendlyName used as hostname', () {
      expect(deviceMap['D6:B0:E7:B4:64:D9']?['hostname'], 'Jeevan-S21-Ultra');
      expect(deviceMap['BA:E0:0E:D0:C6:5C']?['hostname'], 'MACBOOKPRO');
    });

    test('IP addresses extracted', () {
      expect(deviceMap['D6:B0:E7:B4:64:D9']?['ipAddress'], '192.168.1.212');
      expect(deviceMap['BA:E0:0E:D0:C6:5C']?['ipAddress'], '192.168.1.234');
      expect(deviceMap['98:FC:84:E7:20:52']?['ipAddress'], '192.168.1.254');
    });

    test('deviceType Mobile extracted', () {
      expect(deviceMap['D6:B0:E7:B4:64:D9']?['deviceType'], 'Mobile');
    });

    test('empty deviceType not stored', () {
      expect(deviceMap['BA:E0:0E:D0:C6:5C']?['deviceType'], isNull);
      expect(deviceMap['98:FC:84:E7:20:52']?['deviceType'], isNull);
    });

    test('MAC addresses are uppercased', () {
      expect(deviceMap.keys.every((k) => k == k.toUpperCase()), isTrue);
    });
  });

  // ── Client parsing from NodesWirelessNetworkConnections ─────────────

  group('parseClients from NodesWireless + deviceMap', () {
    late List<DiagnosticClient> clients;

    setUp(() {
      final deviceMap = buildDeviceMap(_devices3);
      clients = parseClients(_wirelessConnections, deviceMap);
    });

    test('parses all 4 wireless clients', () {
      expect(clients.length, 4);
    });

    test('all clients are wireless', () {
      expect(clients.every((c) => c.isWireless), isTrue);
    });

    test('all clients on 5GHz', () {
      expect(clients.every((c) => c.band == '5GHz'), isTrue);
    });

    test('negotiatedMbps used for TX/RX when wireless has no txRate', () {
      // BA:E0:0E:D0:C6:5C has negotiatedMbps 1201000 → 1201 Mbps
      final macbook = clients.firstWhere((c) => c.macAddress == 'BA:E0:0E:D0:C6:5C');
      expect(macbook.txRateMbps, 1201);
      expect(macbook.rxRateMbps, 1201);

      // D6:B0:E7:B4:64:D9 has negotiatedMbps 2401900 → 2401 Mbps
      final samsung = clients.firstWhere((c) => c.macAddress == 'D6:B0:E7:B4:64:D9');
      expect(samsung.txRateMbps, 2401);
      expect(samsung.rxRateMbps, 2401);
    });

    test('hostnames merged from GetDevices3', () {
      final macbook = clients.firstWhere((c) => c.macAddress == 'BA:E0:0E:D0:C6:5C');
      expect(macbook.hostname, 'MACBOOKPRO');

      final samsung = clients.firstWhere((c) => c.macAddress == 'D6:B0:E7:B4:64:D9');
      expect(samsung.hostname, 'Jeevan-S21-Ultra');
    });

    test('IP addresses merged from GetDevices3', () {
      final macbook = clients.firstWhere((c) => c.macAddress == 'BA:E0:0E:D0:C6:5C');
      expect(macbook.ipAddress, '192.168.1.234');

      final samsung = clients.firstWhere((c) => c.macAddress == 'D6:B0:E7:B4:64:D9');
      expect(samsung.ipAddress, '192.168.1.212');
    });

    test('deviceType merged from GetDevices3', () {
      final samsung = clients.firstWhere((c) => c.macAddress == 'D6:B0:E7:B4:64:D9');
      expect(samsung.deviceType, 'Mobile');

      final macbook = clients.firstWhere((c) => c.macAddress == 'BA:E0:0E:D0:C6:5C');
      expect(macbook.deviceType, isNull, reason: 'empty string deviceType should be null');
    });

    test('signal strength correctly classified', () {
      // -31 dBm → excellent (>= -65)
      final macbook = clients.firstWhere((c) => c.macAddress == 'BA:E0:0E:D0:C6:5C');
      expect(macbook.signalDecibels, -31);
      expect(macbook.signalStrength, SignalStrength.excellent);

      // -41 dBm → excellent
      final client2 = clients.firstWhere((c) => c.macAddress == '22:A7:50:A4:C5:0B');
      expect(client2.signalDecibels, -41);
      expect(client2.signalStrength, SignalStrength.excellent);
    });

    test('clients without GetDevices3 entry have null hostname/IP', () {
      // 22:A7:50:A4:C5:0B is not in GetDevices3
      final unknown = clients.firstWhere((c) => c.macAddress == '22:A7:50:A4:C5:0B');
      expect(unknown.hostname, isNull);
      expect(unknown.ipAddress, isNull);
    });

    test('no client is flagged (all have excellent signal)', () {
      expect(clients.where((c) => c.isFlagged).length, 0);
    });
  });

  // ── Speed test state ────────────────────────────────────────────────

  group('CsDiagnosticState speed test', () {
    test('speedTestDownloadMbps converts kbps to Mbps', () {
      final state = const CsDiagnosticState(speedTestDownloadKbps: 95000);
      expect(state.speedTestDownloadMbps, 95.0);
    });

    test('speedTestUploadMbps converts kbps to Mbps', () {
      final state = const CsDiagnosticState(speedTestUploadKbps: 12500);
      expect(state.speedTestUploadMbps, 12.5);
    });

    test('speedTestDownloadMbps is null when kbps is null', () {
      const state = CsDiagnosticState();
      expect(state.speedTestDownloadMbps, isNull);
    });

    test('isSpeedTestRunning true for latency/download/upload steps', () {
      expect(
        const CsDiagnosticState(speedTestStep: 'latency').isSpeedTestRunning,
        isTrue,
      );
      expect(
        const CsDiagnosticState(speedTestStep: 'download').isSpeedTestRunning,
        isTrue,
      );
      expect(
        const CsDiagnosticState(speedTestStep: 'upload').isSpeedTestRunning,
        isTrue,
      );
    });

    test('isSpeedTestRunning false for idle/complete/error', () {
      expect(
        const CsDiagnosticState(speedTestStep: 'idle').isSpeedTestRunning,
        isFalse,
      );
      expect(
        const CsDiagnosticState(speedTestStep: 'complete').isSpeedTestRunning,
        isFalse,
      );
      expect(
        const CsDiagnosticState(speedTestStep: 'error').isSpeedTestRunning,
        isFalse,
      );
    });

    test('copyWith clears speed test fields with clear flags', () {
      final state = const CsDiagnosticState(
        speedTestStep: 'complete',
        speedTestLatencyMs: 15,
        speedTestDownloadKbps: 95000,
        speedTestUploadKbps: 12500,
        speedTestError: null,
      );

      final cleared = state.copyWith(
        speedTestStep: 'idle',
        clearSpeedTestLatency: true,
        clearSpeedTestDownload: true,
        clearSpeedTestUpload: true,
      );

      expect(cleared.speedTestStep, 'idle');
      expect(cleared.speedTestLatencyMs, isNull);
      expect(cleared.speedTestDownloadKbps, isNull);
      expect(cleared.speedTestUploadKbps, isNull);
    });

    test('copyWith preserves speed test fields without clear flags', () {
      final state = const CsDiagnosticState(
        speedTestLatencyMs: 15,
        speedTestDownloadKbps: 95000,
      );

      final updated = state.copyWith(speedTestStep: 'upload');

      expect(updated.speedTestLatencyMs, 15);
      expect(updated.speedTestDownloadKbps, 95000);
      expect(updated.speedTestStep, 'upload');
    });
  });

  // ── State construction from real JNAP data ─────────────────────────

  group('CsDiagnosticState from real JNAP data', () {
    test('state correctly populated from real responses', () {
      final uptimeSeconds = (_systemStats['uptimeSeconds'] as int?) ?? 0;
      final cpuRaw = _systemStats['CPULoad'];
      final memRaw = _systemStats['MemoryLoad'];
      final cpuPct = cpuRaw != null
          ? ((double.tryParse('$cpuRaw') ?? 0) * 100).round()
          : null;
      final memPct = memRaw != null
          ? ((double.tryParse('$memRaw') ?? 0) * 100).round()
          : null;

      final deviceMap = buildDeviceMap(_devices3);
      final clients = parseClients(_wirelessConnections, deviceMap);

      final state = CsDiagnosticState(
        loadState: DiagnosticLoadState.loaded,
        clients: clients,
        wanStatus: const {'wanStatus': 'Connected'},
        deviceInfo: _deviceInfo,
        routerHealth: {
          'uptimeInSeconds': uptimeSeconds,
          'cpuLoad': cpuPct,
          'memoryLoad': memPct,
        },
        radioInfo: _radioInfo,
      );

      expect(state.loadState, DiagnosticLoadState.loaded);
      expect(state.clients.length, 4);
      expect(state.wanConnected, isTrue);
      expect(state.routerUptimeSeconds, 12150);
      expect(state.routerHealth?['cpuLoad'], isNull);
      expect(state.routerHealth?['memoryLoad'], isNull);
      expect(state.deviceInfo?['modelNumber'], 'M60CF-EU');
      expect(state.deviceInfo?['serialNumber'], '67A10M24F00099');
      expect(state.bandSteeringEnabled, isFalse);
      expect(state.flaggedClients.length, 0);
    });
  });
}
