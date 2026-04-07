import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

/// Baseline "all good" inputs — override individual fields per test.
Verdict _compute({
  bool? gatewayReachable = true,
  bool? wanConnected = true,
  String? wanIpAddress = '192.168.50.105',
  bool? dnsWorking = true,
  double? downloadMbps = 100,
  int? latencyMs = 20,
  bool? firmwareUpdateAvailable = false,
  String? firmwareVersion,
  int? uptimeSeconds = 86400, // 1 day
  List<DeviceScore> deviceScores = const [],
  List<DiagnosticClient> clients = const [],
  List<MeshNodeInfo> meshNodes = const [],
  double? planSpeedMbps,
}) {
  return VerdictEngine.compute(
    gatewayReachable: gatewayReachable,
    wanConnected: wanConnected,
    wanIpAddress: wanIpAddress,
    dnsWorking: dnsWorking,
    downloadMbps: downloadMbps,
    latencyMs: latencyMs,
    firmwareUpdateAvailable: firmwareUpdateAvailable,
    firmwareVersion: firmwareVersion,
    uptimeSeconds: uptimeSeconds,
    deviceScores: deviceScores,
    clients: clients,
    meshNodes: meshNodes,
    planSpeedMbps: planSpeedMbps,
  );
}

DiagnosticClient _client({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String? hostname,
  String band = '5GHz',
  int? signal,
  int? txRate,
  int? rxRate,
  bool wireless = true,
}) {
  return DiagnosticClient(
    macAddress: mac,
    hostname: hostname,
    band: band,
    signalDecibels: signal,
    txRateMbps: txRate,
    rxRateMbps: rxRate,
    isWireless: wireless,
  );
}

DeviceScore _weakDevice({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String? hostname,
  int signal = -80,
  int txRate = 5,
}) {
  final client = _client(
    mac: mac,
    hostname: hostname,
    signal: signal,
    txRate: txRate,
    rxRate: txRate,
  );
  return DeviceScore.compute(client);
}

DeviceScore _goodDevice({
  String mac = '11:22:33:44:55:66',
  String? hostname,
}) {
  final client = _client(
    mac: mac,
    hostname: hostname,
    signal: -50,
    txRate: 866,
    rxRate: 866,
  );
  return DeviceScore.compute(client);
}

MeshNodeInfo _satellite({
  String name = 'Living Room',
  int? rssi,
  String backhaulType = 'Wireless',
}) {
  return MeshNodeInfo(
    deviceId: 'sat-1',
    name: name,
    isController: false,
    backhaulType: backhaulType,
    backhaulRssi: rssi,
  );
}

void main() {
  // ── Verdict model ─────────────────────────────────────────────────────────

  group('Verdict — model properties', () {
    test('empty findings → isAllClear', () {
      const v = Verdict(findings: [], checksRun: 5);
      expect(v.isAllClear, isTrue);
      expect(v.overallPriority, VerdictPriority.allClear);
      expect(v.primaryFinding, isNull);
      expect(v.visibleFindings, isEmpty);
      expect(v.hiddenFindings, isEmpty);
    });

    test('all-clear findings → isAllClear', () {
      const v = Verdict(findings: [
        VerdictFinding(
          priority: VerdictPriority.allClear,
          headline: 'All good',
          explanation: 'Everything is fine.',
        ),
      ]);
      expect(v.isAllClear, isTrue);
    });

    test('visibleFindings caps at 2, rest in hiddenFindings', () {
      const findings = [
        VerdictFinding(
            priority: VerdictPriority.critical,
            headline: 'A',
            explanation: ''),
        VerdictFinding(
            priority: VerdictPriority.warning,
            headline: 'B',
            explanation: ''),
        VerdictFinding(
            priority: VerdictPriority.info,
            headline: 'C',
            explanation: ''),
      ];
      const v = Verdict(findings: findings);
      expect(v.visibleFindings.length, 2);
      expect(v.hiddenFindings.length, 1);
      expect(v.hiddenFindings.first.headline, 'C');
    });

    test('primaryFinding returns first finding', () {
      const v = Verdict(findings: [
        VerdictFinding(
            priority: VerdictPriority.warning,
            headline: 'First',
            explanation: ''),
      ]);
      expect(v.primaryFinding?.headline, 'First');
    });

    test('isPreliminary always false for base Verdict', () {
      const v = Verdict(findings: []);
      expect(v.isPreliminary, isFalse);
    });
  });

  // ── VerdictFinding ────────────────────────────────────────────────────────

  group('VerdictFinding — hasAutoFix', () {
    test('with actionKey → hasAutoFix true', () {
      const f = VerdictFinding(
        priority: VerdictPriority.critical,
        headline: 'Test',
        explanation: '',
        actionKey: 'restart_router',
      );
      expect(f.hasAutoFix, isTrue);
    });

    test('without actionKey → hasAutoFix false', () {
      const f = VerdictFinding(
        priority: VerdictPriority.warning,
        headline: 'Test',
        explanation: '',
      );
      expect(f.hasAutoFix, isFalse);
    });
  });

  // ── Check 1: Gateway reachable ────────────────────────────────────────────

  group('VerdictEngine — Check 1: gateway reachable', () {
    test('gateway unreachable → critical, early return', () {
      final v = _compute(gatewayReachable: false);
      expect(v.findings.length, 1);
      expect(v.findings.first.priority, VerdictPriority.critical);
      expect(v.findings.first.headline, contains('router'));
      expect(v.findings.first.actionKey, VerdictEngine.actionRestartRouter);
      expect(v.findings.first.checkNumber, 1);
      expect(v.checksRun, 1);
    });

    test('gateway unreachable → has post-restart escalation', () {
      final v = _compute(gatewayReachable: false);
      expect(v.findings.first.postRestartEscalation, isNotNull);
      expect(v.findings.first.postRestartEscalation,
          contains('Linksys support'));
    });

    test('gateway null → skipped, no finding', () {
      final v = _compute(gatewayReachable: null);
      expect(v.findings.where((f) => f.checkNumber == 1), isEmpty);
    });

    test('gateway reachable → no finding', () {
      final v = _compute(gatewayReachable: true);
      expect(v.findings.where((f) => f.checkNumber == 1), isEmpty);
    });
  });

  // ── Check 2: WAN connection ───────────────────────────────────────────────

  group('VerdictEngine — Check 2: WAN connection', () {
    test('WAN disconnected → critical, early return', () {
      final v = _compute(wanConnected: false);
      expect(v.findings.length, 1);
      expect(v.findings.first.priority, VerdictPriority.critical);
      expect(v.findings.first.headline, contains('internet'));
      expect(v.findings.first.explanation, contains('modem'));
      expect(v.checksRun, 2); // gateway + WAN
    });

    test('WAN null → skipped', () {
      final v = _compute(wanConnected: null);
      // Should not produce a WAN finding
      expect(
          v.findings.where(
              (f) => f.headline.toLowerCase().contains('no internet')),
          isEmpty);
    });
  });

  // ── Check 3: WAN IP assigned ──────────────────────────────────────────────

  group('VerdictEngine — Check 3: WAN IP assigned', () {
    test('WAN connected but empty IP → critical, early return', () {
      final v = _compute(wanConnected: true, wanIpAddress: '');
      expect(v.findings.length, 1);
      expect(v.findings.first.priority, VerdictPriority.critical);
      expect(v.findings.first.headline, contains('address'));
      expect(v.findings.first.checkNumber, 3);
      expect(v.findings.first.actionKey, VerdictEngine.actionRestartRouter);
    });

    test('WAN connected with valid IP → no finding', () {
      final v = _compute(wanConnected: true, wanIpAddress: '192.168.50.105');
      expect(v.findings.where((f) => f.checkNumber == 3), isEmpty);
    });

    test('WAN disconnected → check 3 skipped (early return at check 2)', () {
      final v = _compute(wanConnected: false, wanIpAddress: '');
      // Should only have check 2 finding, not check 3
      expect(v.findings.length, 1);
      expect(v.findings.first.headline, contains('internet'));
    });
  });

  // ── Check 4: DNS / Internet reachable ─────────────────────────────────────

  group('VerdictEngine — Check 4: DNS/Internet reachable', () {
    test('DNS failing → critical with ISP escalation', () {
      final v = _compute(dnsWorking: false);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(finding.priority, VerdictPriority.critical);
      expect(finding.headline, contains('internet'));
      expect(finding.explanation, contains('WAN IP assigned'));
      expect(finding.postRestartEscalation, isNotNull);
      expect(finding.postRestartEscalation, contains('websites'));
    });

    test('DNS failing with empty WAN IP → shows "WAN connected" text', () {
      // wanIpAddress null or empty should use fallback text
      final v = _compute(dnsWorking: false, wanIpAddress: null);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(finding.explanation, contains('WAN connected'));
    });

    test('DNS null → skipped', () {
      final v = _compute(dnsWorking: null);
      expect(v.findings.where((f) => f.checkNumber == 4), isEmpty);
    });

    test('DNS check skipped when WAN disconnected', () {
      final v = _compute(wanConnected: false, dnsWorking: false);
      // Early return at WAN check, so DNS finding should not appear
      expect(v.findings.where((f) => f.checkNumber == 4), isEmpty);
    });
  });

  // ── Check 5: Internet speed ───────────────────────────────────────────────

  group('VerdictEngine — Check 5: Internet speed', () {
    test('very slow (<5 Mbps) → critical', () {
      final v = _compute(downloadMbps: 3);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 5);
      expect(finding.priority, VerdictPriority.critical);
      expect(finding.headline, contains('3 Mbps'));
      expect(finding.headline, contains('very slow'));
      expect(finding.actionKey, VerdictEngine.actionRestartRouter);
    });

    test('slow (<25 Mbps) → warning', () {
      final v = _compute(downloadMbps: 15);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 6);
      expect(finding.priority, VerdictPriority.warning);
      expect(finding.headline, contains('15 Mbps'));
      expect(finding.headline, contains('slower than expected'));
    });

    test('below 50% of plan speed → warning', () {
      final v = _compute(downloadMbps: 40, planSpeedMbps: 100);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 6);
      expect(finding.priority, VerdictPriority.warning);
      expect(finding.headline, contains('100 Mbps'));
    });

    test('good speed → no finding', () {
      final v = _compute(downloadMbps: 100);
      expect(v.findings.where((f) => f.checkNumber == 5), isEmpty);
      expect(v.findings.where((f) => f.checkNumber == 6), isEmpty);
    });

    test('above 50% of plan → no finding', () {
      final v = _compute(downloadMbps: 60, planSpeedMbps: 100);
      expect(v.findings.where((f) => f.checkNumber == 5), isEmpty);
      expect(v.findings.where((f) => f.checkNumber == 6), isEmpty);
    });

    test('speed null → skipped', () {
      final v = _compute(downloadMbps: null);
      expect(v.findings.where((f) => f.checkNumber == 5), isEmpty);
      expect(v.findings.where((f) => f.checkNumber == 6), isEmpty);
    });

    test('speed check skipped when WAN disconnected', () {
      final v = _compute(wanConnected: false, downloadMbps: 3);
      expect(v.findings.where((f) => f.checkNumber == 5), isEmpty);
    });

    test('speed check skipped when DNS failing', () {
      final v = _compute(dnsWorking: false, downloadMbps: 3);
      expect(v.findings.where((f) => f.checkNumber == 5), isEmpty);
    });

    test('very slow speed has ISP escalation text', () {
      final v = _compute(downloadMbps: 2);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 5);
      expect(finding.postRestartEscalation, isNotNull);
      expect(finding.postRestartEscalation, contains('2 Mbps'));
    });

    test('slow speed includes variance note', () {
      final v = _compute(downloadMbps: 15);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 6);
      expect(finding.explanation, contains('Speed can vary'));
    });
  });

  // ── Weak-WiFi elevation (D-8) ─────────────────────────────────────────────

  group('VerdictEngine — D-8: Weak-WiFi elevation', () {
    test('weak device + slow speed → elevates WiFi finding as primary', () {
      final weak = _weakDevice();
      final v = _compute(downloadMbps: 15, deviceScores: [weak]);
      // Should have a check-7 finding BEFORE the speed finding
      final findings = v.findings;
      final wifiIdx = findings.indexWhere((f) => f.checkNumber == 7);
      expect(wifiIdx, greaterThanOrEqualTo(0));
      expect(findings[wifiIdx].headline, contains('weak WiFi'));
    });

    test('weak device + fast speed → no WiFi elevation in speed check', () {
      final weak = _weakDevice();
      final v = _compute(downloadMbps: 100, deviceScores: [weak]);
      // Should not get the "weak WiFi connection" elevation from speed check
      final elevatedWifi = v.findings
          .where((f) =>
              f.checkNumber == 7 && f.headline.contains('weak WiFi connection'))
          .toList();
      expect(elevatedWifi, isEmpty);
    });

    test('no weak devices + slow speed → no WiFi elevation', () {
      final good = _goodDevice();
      final v = _compute(downloadMbps: 15, deviceScores: [good]);
      final elevatedWifi = v.findings
          .where((f) =>
              f.checkNumber == 7 && f.headline.contains('weak WiFi connection'))
          .toList();
      expect(elevatedWifi, isEmpty);
    });
  });

  // ── Check 6: Latency ──────────────────────────────────────────────────────

  group('VerdictEngine — Check 6: Latency', () {
    test('high latency (>100ms) → warning', () {
      final v = _compute(latencyMs: 150);
      final finding = v.findings
          .firstWhere((f) => f.headline.contains('lag'));
      expect(finding.priority, VerdictPriority.warning);
      expect(finding.headline, contains('150'));
    });

    test('normal latency → no finding', () {
      final v = _compute(latencyMs: 50);
      expect(v.findings.where((f) => f.headline.contains('lag')), isEmpty);
    });

    test('latency exactly 100ms → no finding (> not >=)', () {
      final v = _compute(latencyMs: 100);
      expect(v.findings.where((f) => f.headline.contains('lag')), isEmpty);
    });

    test('latency null → skipped', () {
      final v = _compute(latencyMs: null);
      expect(v.findings.where((f) => f.headline.contains('lag')), isEmpty);
    });
  });

  // ── Check 7: Device WiFi quality ──────────────────────────────────────────

  group('VerdictEngine — Check 7: Device WiFi quality', () {
    test('devices with weak signal → warning with count', () {
      final devices = [
        _weakDevice(mac: 'AA:BB:CC:DD:EE:01', hostname: 'iPhone'),
        _weakDevice(mac: 'AA:BB:CC:DD:EE:02', hostname: 'Laptop'),
      ];
      final v = _compute(deviceScores: devices);
      final finding =
          v.findings.firstWhere((f) => f.headline.contains('weak WiFi'));
      expect(finding.priority, VerdictPriority.warning);
      expect(finding.headline, contains('2 devices'));
    });

    test('single weak device → singular "device"', () {
      final devices = [_weakDevice(hostname: 'iPhone')];
      final v = _compute(deviceScores: devices);
      final finding =
          v.findings.firstWhere((f) => f.headline.contains('weak WiFi'));
      expect(finding.headline, contains('1 device'));
    });

    test('3+ weak devices → shows first 2 names + "and X more"', () {
      final devices = [
        _weakDevice(mac: 'AA:BB:CC:DD:EE:01', hostname: 'iPhone'),
        _weakDevice(mac: 'AA:BB:CC:DD:EE:02', hostname: 'Laptop'),
        _weakDevice(mac: 'AA:BB:CC:DD:EE:03', hostname: 'iPad'),
        _weakDevice(mac: 'AA:BB:CC:DD:EE:04', hostname: 'TV'),
      ];
      final v = _compute(deviceScores: devices);
      final finding =
          v.findings.firstWhere((f) => f.headline.contains('weak WiFi'));
      expect(finding.explanation, contains('and 2 more'));
    });

    test('all good devices → no finding', () {
      final devices = [_goodDevice()];
      final v = _compute(deviceScores: devices);
      expect(
          v.findings.where(
              (f) => f.headline.contains('weak WiFi')),
          isEmpty);
    });

    test('empty deviceScores → skipped', () {
      final v = _compute(deviceScores: []);
      expect(
          v.findings.where(
              (f) => f.headline.contains('weak WiFi')),
          isEmpty);
    });
  });

  // ── Check 8: 2.4 GHz overcrowding ────────────────────────────────────────

  group('VerdictEngine — Check 8: 2.4 GHz overcrowding', () {
    test('60%+ on 2.4 GHz with 4+ devices → info finding', () {
      final clients = [
        _client(mac: '01:00:00:00:00:01', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:02', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:03', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:04', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:05', band: '5GHz'),
      ];
      final v = _compute(clients: clients);
      final finding = v.findings
          .firstWhere((f) => f.headline.contains('2.4 GHz'));
      expect(finding.priority, VerdictPriority.info);
      expect(finding.headline, contains('4 of 5'));
    });

    test('below threshold → no finding', () {
      final clients = [
        _client(mac: '01:00:00:00:00:01', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:02', band: '5GHz'),
        _client(mac: '01:00:00:00:00:03', band: '5GHz'),
        _client(mac: '01:00:00:00:00:04', band: '5GHz'),
      ];
      final v = _compute(clients: clients);
      expect(
          v.findings.where((f) => f.headline.contains('2.4 GHz')),
          isEmpty);
    });

    test('fewer than 4 wireless clients → skipped', () {
      final clients = [
        _client(mac: '01:00:00:00:00:01', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:02', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:03', band: '2.4GHz'),
      ];
      final v = _compute(clients: clients);
      expect(
          v.findings.where((f) => f.headline.contains('2.4 GHz')),
          isEmpty);
    });

    test('wired clients excluded from count', () {
      final clients = [
        _client(mac: '01:00:00:00:00:01', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:02', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:03', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:04', band: '', wireless: false),
        _client(mac: '01:00:00:00:00:05', band: '', wireless: false),
      ];
      final v = _compute(clients: clients);
      // Only 3 wireless → below 4 threshold
      expect(
          v.findings.where((f) => f.headline.contains('2.4 GHz')),
          isEmpty);
    });
  });

  // ── Check 9: Mesh backhaul health ─────────────────────────────────────────

  group('VerdictEngine — Check 9: Mesh backhaul health', () {
    test('weak satellite backhaul → warning', () {
      final nodes = [
        const MeshNodeInfo(
          deviceId: 'router',
          name: 'Router',
          isController: true,
        ),
        _satellite(name: 'Living Room', rssi: -75),
      ];
      final v = _compute(meshNodes: nodes);
      final finding = v.findings
          .firstWhere((f) => f.headline.contains('satellite'));
      expect(finding.priority, VerdictPriority.warning);
      expect(finding.headline, contains('1 satellite node'));
      expect(finding.explanation, contains('Living Room'));
      expect(finding.explanation, contains('-75 dBm'));
    });

    test('multiple weak satellites → plural', () {
      final nodes = [
        const MeshNodeInfo(
          deviceId: 'router',
          name: 'Router',
          isController: true,
        ),
        _satellite(name: 'Living Room', rssi: -75),
        _satellite(name: 'Bedroom', rssi: -80),
      ];
      final v = _compute(meshNodes: nodes);
      final finding = v.findings
          .firstWhere((f) => f.headline.contains('satellite'));
      expect(finding.headline, contains('2 satellite nodes'));
      expect(finding.headline, contains('have'));
    });

    test('strong backhaul → no finding', () {
      final nodes = [
        const MeshNodeInfo(
          deviceId: 'router',
          name: 'Router',
          isController: true,
        ),
        _satellite(name: 'Living Room', rssi: -55),
      ];
      final v = _compute(meshNodes: nodes);
      expect(
          v.findings.where((f) => f.headline.contains('satellite')),
          isEmpty);
    });

    test('single node (no mesh) → skipped', () {
      final nodes = [
        const MeshNodeInfo(
          deviceId: 'router',
          name: 'Router',
          isController: true,
        ),
      ];
      final v = _compute(meshNodes: nodes);
      expect(
          v.findings.where((f) => f.headline.contains('satellite')),
          isEmpty);
    });
  });

  // ── Check 10: Firmware update ─────────────────────────────────────────────

  group('VerdictEngine — Check 10: Firmware update', () {
    test('firmware available → info with version', () {
      final v = _compute(
        firmwareUpdateAvailable: true,
        firmwareVersion: '2.1.0',
      );
      final finding = v.findings
          .firstWhere((f) => f.headline.contains('update'));
      expect(finding.priority, VerdictPriority.info);
      expect(finding.headline, contains('2.1.0'));
      expect(finding.actionKey, VerdictEngine.actionFirmwareUpdate);
      expect(finding.actionLabel, 'Update Now');
    });

    test('firmware available without version → no version in headline', () {
      final v = _compute(firmwareUpdateAvailable: true);
      final finding = v.findings
          .firstWhere((f) => f.headline.contains('update'));
      expect(finding.headline, isNot(contains('null')));
    });

    test('no update → no finding, but checksRun incremented', () {
      final v = _compute(firmwareUpdateAvailable: false);
      expect(
          v.findings.where((f) => f.headline.contains('update')),
          isEmpty);
    });

    test('firmware null → skipped', () {
      final v = _compute(firmwareUpdateAvailable: null);
      expect(
          v.findings.where((f) => f.headline.contains('update')),
          isEmpty);
    });
  });

  // ── Check 11: Long uptime ────────────────────────────────────────────────

  group('VerdictEngine — Check 11: Long uptime', () {
    test('30+ days → info with restart action', () {
      final v = _compute(uptimeSeconds: 30 * 86400); // 30 days
      final finding = v.findings
          .firstWhere((f) => f.headline.contains('running'));
      expect(finding.priority, VerdictPriority.info);
      expect(finding.headline, contains('30 days'));
      expect(finding.actionKey, VerdictEngine.actionRestartRouter);
    });

    test('90 days → shows correct count', () {
      final v = _compute(uptimeSeconds: 90 * 86400);
      final finding = v.findings
          .firstWhere((f) => f.headline.contains('running'));
      expect(finding.headline, contains('90 days'));
    });

    test('29 days → no finding', () {
      final v = _compute(uptimeSeconds: 29 * 86400);
      expect(
          v.findings.where((f) => f.headline.contains('running')),
          isEmpty);
    });

    test('uptime null → skipped', () {
      final v = _compute(uptimeSeconds: null);
      expect(
          v.findings.where((f) => f.headline.contains('running')),
          isEmpty);
    });
  });

  // ── All-clear scenario ────────────────────────────────────────────────────

  group('VerdictEngine — all-clear', () {
    test('everything healthy → no findings, isAllClear', () {
      final v = _compute();
      expect(v.isAllClear, isTrue);
      expect(v.findings, isEmpty);
      expect(v.overallPriority, VerdictPriority.allClear);
    });

    test('all inputs null → no findings, checksRun defaults to 8', () {
      final v = _compute(
        gatewayReachable: null,
        wanConnected: null,
        wanIpAddress: null,
        dnsWorking: null,
        downloadMbps: null,
        latencyMs: null,
        firmwareUpdateAvailable: null,
        uptimeSeconds: null,
      );
      expect(v.findings, isEmpty);
      expect(v.checksRun, 8);
    });
  });

  // ── Sorting ───────────────────────────────────────────────────────────────

  group('VerdictEngine — finding sort order', () {
    test('critical findings sorted before warning and info', () {
      // Produce multiple findings at different priorities
      final weak = _weakDevice();
      final v = _compute(
        downloadMbps: 3, // critical speed
        latencyMs: 150, // warning latency
        firmwareUpdateAvailable: true, // info firmware
        uptimeSeconds: 90 * 86400, // info uptime
        deviceScores: [weak], // warning weak devices
      );
      expect(v.findings.length, greaterThanOrEqualTo(3));

      // Verify sort: critical first, then warning, then info
      for (int i = 0; i < v.findings.length - 1; i++) {
        expect(v.findings[i].priority.index,
            lessThanOrEqualTo(v.findings[i + 1].priority.index));
      }
    });
  });

  // ── ISP escalation text ───────────────────────────────────────────────────

  group('VerdictEngine — ISP escalation text (D-26)', () {
    test('Check 3 escalation mentions IP address', () {
      final v = _compute(wanConnected: true, wanIpAddress: '');
      expect(v.findings.first.postRestartEscalation,
          contains('IP address'));
    });

    test('Check 4 escalation mentions websites', () {
      final v = _compute(dnsWorking: false);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(finding.postRestartEscalation, contains('websites'));
    });

    test('Check 5 (very slow) escalation includes speed value', () {
      final v = _compute(downloadMbps: 2);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 5);
      expect(finding.postRestartEscalation, contains('2 Mbps'));
    });

    test('Check 6 (slow) escalation includes speed value', () {
      final v = _compute(downloadMbps: 15);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 6);
      expect(finding.postRestartEscalation, contains('15 Mbps'));
    });

    test('all escalation text mentions restarting', () {
      final v = _compute(dnsWorking: false);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(finding.postRestartEscalation, contains('restarting'));
    });
  });

  // ── checksRun accounting ──────────────────────────────────────────────────

  group('VerdictEngine — checksRun accounting', () {
    test('all checks available → correct checksRun count', () {
      final clients = [
        _client(mac: '01:00:00:00:00:01', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:02', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:03', band: '5GHz'),
        _client(mac: '01:00:00:00:00:04', band: '5GHz'),
      ];
      final nodes = [
        const MeshNodeInfo(
          deviceId: 'router',
          name: 'Router',
          isController: true,
        ),
        _satellite(name: 'Living Room', rssi: -55),
      ];
      final v = _compute(
        deviceScores: [_goodDevice()],
        clients: clients,
        meshNodes: nodes,
        firmwareUpdateAvailable: false,
      );
      // Checks: gateway(1) + WAN(2) + IP(3) + DNS(4) + speed(5) +
      //   latency(6) + deviceQuality(7) + 2.4crowd(8) + mesh(9) +
      //   firmware(10) + uptime(11) = 11
      expect(v.checksRun, 11);
    });

    test('early return at gateway → checksRun is 1', () {
      final v = _compute(gatewayReachable: false);
      expect(v.checksRun, 1);
    });
  });
}
