import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

Verdict _compute({
  bool? gatewayReachable = true,
  bool? wanConnected = true,
  String? wanIpAddress = '98.137.11.163',
  bool? dnsWorking = true,
  double? downloadMbps = 100,
  int? latencyMs = 20,
  bool? firmwareUpdateAvailable = false,
  String? firmwareVersion,
  int? uptimeSeconds = 86400,
  List<DeviceScore> deviceScores = const [],
  List<DeviceUIModel> clients = const [],
  List<NodeUIModel> meshNodes = const [],
  double? planSpeedMbps,
  bool? isWifiScheduleBlocking,
  bool? isInstantPrivacyOn,
  bool? isInstantPauseActive,
  int? cpuLoadPct,
  int? cpuLoadPctStart,
  int? memoryLoadPct,
  int? wifiSnrDb,
  bool? isPmfRequired,
  bool? isBandSteeringMissteer,
  bool? hasEthernetNoLink,
  bool? hasZombieMeshNode,
  int? dhcpPoolUtilizationPct,
  bool? isDeviceInApMode,
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
  );
}

DeviceUIModel _client({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String? hostName,
  String? band = '5GHz',
  int? signal,
  int? downlinkBps,
  bool wireless = true,
}) {
  return DeviceUIModel(
    mac: mac,
    ip: '192.168.1.100',
    hostName: hostName ?? mac,
    isWifi: wireless,
    band: band,
    signalStrength: signal,
    downlinkRate: downlinkBps,
    layer1Interface: wireless
        ? 'Device.WiFi.AccessPoint.1.AssociatedDevice.1'
        : 'Device.Ethernet.Interface.1',
    isActive: true,
  );
}

DeviceScore _weakDevice({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String? hostName,
  int signal = -80,
  int downlinkMbps = 5,
}) {
  final device = _client(
    mac: mac,
    hostName: hostName,
    signal: signal,
    downlinkBps: downlinkMbps * 1000000,
  );
  return DeviceScore.compute(device);
}

DeviceScore _goodDevice({
  String mac = '11:22:33:44:55:66',
  String? hostName,
}) {
  final device = _client(
    mac: mac,
    hostName: hostName,
    signal: -50,
    downlinkBps: 866 * 1000000,
  );
  return DeviceScore.compute(device);
}

NodeUIModel _satellite({
  String friendlyName = 'Living Room',
  int? backhaulSignal,
  String mediaType = 'IEEE 802.11ax',
}) {
  return NodeUIModel(
    deviceId: 'sat-${friendlyName.replaceAll(' ', '_')}',
    friendlyName: friendlyName,
    model: 'MX6200',
    isMaster: false,
    backhaulSignalStrength: backhaulSignal,
    backhaulMediaType: mediaType,
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
        VerdictFinding(priority: VerdictPriority.critical, headline: 'A', explanation: ''),
        VerdictFinding(priority: VerdictPriority.warning, headline: 'B', explanation: ''),
        VerdictFinding(priority: VerdictPriority.info, headline: 'C', explanation: ''),
      ];
      const v = Verdict(findings: findings);
      expect(v.visibleFindings.length, 2);
      expect(v.hiddenFindings.length, 1);
      expect(v.hiddenFindings.first.headline, 'C');
    });

    test('primaryFinding returns first finding', () {
      const v = Verdict(findings: [
        VerdictFinding(priority: VerdictPriority.warning, headline: 'First', explanation: ''),
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
      const f = VerdictFinding(priority: VerdictPriority.warning, headline: 'Test', explanation: '');
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
      expect(v.findings.first.postRestartEscalation, contains('Linksys support'));
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
      expect(v.checksRun, 2);
    });

    test('WAN null → skipped', () {
      final v = _compute(wanConnected: null);
      expect(v.findings.where((f) => f.headline.toLowerCase().contains('no internet')), isEmpty);
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
  });

  // ── Check 4: DNS / Internet reachable ─────────────────────────────────────

  group('VerdictEngine — Check 4: DNS/Internet reachable', () {
    test('DNS failing → critical with ISP escalation', () {
      final v = _compute(dnsWorking: false);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(finding.priority, VerdictPriority.critical);
      expect(finding.headline.toLowerCase(), anyOf(contains('website'), contains('internet')));
      expect(finding.explanation, contains('WAN IP assigned'));
      expect(finding.postRestartEscalation, isNotNull);
      expect(finding.postRestartEscalation, contains('websites'));
    });

    test('DNS failing with empty WAN IP → shows "WAN connected" text', () {
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

    test('speed null → skipped', () {
      final v = _compute(downloadMbps: null);
      expect(v.findings.where((f) => f.checkNumber == 5), isEmpty);
    });

    test('very slow speed has ISP escalation text', () {
      final v = _compute(downloadMbps: 2);
      final finding = v.findings.firstWhere((f) => f.checkNumber == 5);
      expect(finding.postRestartEscalation, isNotNull);
      expect(finding.postRestartEscalation, contains('2 Mbps'));
    });
  });

  // ── Weak-WiFi elevation (D-8) ─────────────────────────────────────────────

  group('VerdictEngine — D-8: Weak-WiFi elevation', () {
    test('weak device + slow speed → elevates WiFi finding as primary', () {
      final weak = _weakDevice();
      final v = _compute(downloadMbps: 15, deviceScores: [weak]);
      final findings = v.findings;
      final wifiIdx = findings.indexWhere((f) => f.checkNumber == 7);
      expect(wifiIdx, greaterThanOrEqualTo(0));
      expect(findings[wifiIdx].headline, contains('weak WiFi'));
    });

    test('no weak devices + slow speed → no WiFi elevation', () {
      final good = _goodDevice();
      final v = _compute(downloadMbps: 15, deviceScores: [good]);
      final elevatedWifi = v.findings
          .where((f) => f.checkNumber == 7 && f.headline.contains('weak WiFi connection'))
          .toList();
      expect(elevatedWifi, isEmpty);
    });
  });

  // ── Check 6: Latency ──────────────────────────────────────────────────────

  group('VerdictEngine — Check 6: Latency', () {
    test('high latency (>100ms) → warning', () {
      final v = _compute(latencyMs: 150);
      final finding = v.findings.firstWhere((f) => f.headline.contains('lag'));
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
  });

  // ── Check 7: Device WiFi quality ──────────────────────────────────────────

  group('VerdictEngine — Check 7: Device WiFi quality', () {
    test('devices with weak signal → warning with count', () {
      final devices = [
        _weakDevice(mac: 'AA:BB:CC:DD:EE:01', hostName: 'iPhone'),
        _weakDevice(mac: 'AA:BB:CC:DD:EE:02', hostName: 'Laptop'),
      ];
      final v = _compute(deviceScores: devices);
      final finding = v.findings.firstWhere((f) => f.headline.contains('weak WiFi'));
      expect(finding.priority, VerdictPriority.warning);
      expect(finding.headline, contains('2 devices'));
    });

    test('single weak device → singular "device"', () {
      final devices = [_weakDevice(hostName: 'iPhone')];
      final v = _compute(deviceScores: devices);
      final finding = v.findings.firstWhere((f) => f.headline.contains('weak WiFi'));
      expect(finding.headline, contains('1 device'));
    });

    test('3+ weak devices → shows first 2 names + "and X more"', () {
      final devices = [
        _weakDevice(mac: 'AA:BB:CC:DD:EE:01', hostName: 'iPhone'),
        _weakDevice(mac: 'AA:BB:CC:DD:EE:02', hostName: 'Laptop'),
        _weakDevice(mac: 'AA:BB:CC:DD:EE:03', hostName: 'iPad'),
        _weakDevice(mac: 'AA:BB:CC:DD:EE:04', hostName: 'TV'),
      ];
      final v = _compute(deviceScores: devices);
      final finding = v.findings.firstWhere((f) => f.headline.contains('weak WiFi'));
      expect(finding.explanation, contains('and 2 more'));
    });

    test('all good devices → no finding', () {
      final devices = [_goodDevice()];
      final v = _compute(deviceScores: devices);
      expect(v.findings.where((f) => f.headline.contains('weak WiFi')), isEmpty);
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
      final finding = v.findings.firstWhere((f) => f.headline.contains('2.4 GHz'));
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
      expect(v.findings.where((f) => f.headline.contains('2.4 GHz')), isEmpty);
    });

    test('wired clients excluded from count', () {
      final clients = [
        _client(mac: '01:00:00:00:00:01', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:02', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:03', band: '2.4GHz'),
        _client(mac: '01:00:00:00:00:04', band: null, wireless: false),
        _client(mac: '01:00:00:00:00:05', band: null, wireless: false),
      ];
      final v = _compute(clients: clients);
      expect(v.findings.where((f) => f.headline.contains('2.4 GHz')), isEmpty);
    });
  });

  // ── Check 9: Mesh backhaul health ─────────────────────────────────────────

  group('VerdictEngine — Check 9: Mesh backhaul health', () {
    test('weak satellite backhaul → warning', () {
      final nodes = [
        const NodeUIModel(deviceId: 'router', model: 'MX6200', isMaster: true),
        _satellite(friendlyName: 'Living Room', backhaulSignal: -75),
      ];
      final v = _compute(meshNodes: nodes);
      final finding = v.findings.firstWhere((f) => f.headline.contains('child'));
      expect(finding.priority, VerdictPriority.warning);
      expect(finding.headline, contains('1 child node'));
      expect(finding.explanation, contains('Living Room'));
      expect(finding.explanation, contains('-75 dBm'));
    });

    test('multiple weak satellites → plural', () {
      final nodes = [
        const NodeUIModel(deviceId: 'router', model: 'MX6200', isMaster: true),
        _satellite(friendlyName: 'Living Room', backhaulSignal: -75),
        _satellite(friendlyName: 'Bedroom', backhaulSignal: -80),
      ];
      final v = _compute(meshNodes: nodes);
      final finding = v.findings.firstWhere((f) => f.headline.contains('child'));
      expect(finding.headline, contains('2 child nodes'));
      expect(finding.headline, contains('have'));
    });

    test('strong backhaul → no finding', () {
      final nodes = [
        const NodeUIModel(deviceId: 'router', model: 'MX6200', isMaster: true),
        _satellite(friendlyName: 'Living Room', backhaulSignal: -55),
      ];
      final v = _compute(meshNodes: nodes);
      expect(v.findings.where((f) => f.headline.contains('child')), isEmpty);
    });

    test('single node (no mesh) → skipped', () {
      final nodes = [
        const NodeUIModel(deviceId: 'router', model: 'MX6200', isMaster: true),
      ];
      final v = _compute(meshNodes: nodes);
      expect(v.findings.where((f) => f.headline.contains('child')), isEmpty);
    });
  });

  // ── Check 10: Firmware update ─────────────────────────────────────────────

  group('VerdictEngine — Check 10: Firmware update', () {
    test('firmware available → info with version', () {
      final v = _compute(firmwareUpdateAvailable: true, firmwareVersion: '2.1.0');
      final finding = v.findings.firstWhere((f) => f.headline.contains('update'));
      expect(finding.priority, VerdictPriority.info);
      expect(finding.headline, contains('2.1.0'));
      expect(finding.actionKey, VerdictEngine.actionFirmwareUpdate);
      expect(finding.actionLabel, 'Update Now');
    });

    test('no update → no finding', () {
      final v = _compute(firmwareUpdateAvailable: false);
      expect(v.findings.where((f) => f.headline.contains('update')), isEmpty);
    });
  });

  // ── Check 11: Long uptime ────────────────────────────────────────────────

  group('VerdictEngine — Check 11: Long uptime', () {
    test('30+ days → info with restart action', () {
      final v = _compute(uptimeSeconds: 30 * 86400);
      final finding = v.findings.firstWhere((f) => f.headline.contains('running'));
      expect(finding.priority, VerdictPriority.info);
      expect(finding.headline, contains('30 days'));
      expect(finding.actionKey, VerdictEngine.actionRestartRouter);
    });

    test('29 days → no finding', () {
      final v = _compute(uptimeSeconds: 29 * 86400);
      expect(v.findings.where((f) => f.headline.contains('running')), isEmpty);
    });
  });

  // ── Checks 12-15: Access restrictions + CPU/memory ───────────────────────

  group('VerdictEngine — checks 12-15', () {
    test('WiFi schedule blocking → info', () {
      final v = _compute(isWifiScheduleBlocking: true);
      expect(v.findings.where((f) => f.headline.contains('schedule')), isNotEmpty);
    });

    test('Instant Privacy on → warning', () {
      final v = _compute(isInstantPrivacyOn: true);
      expect(v.findings.where((f) => f.headline.contains('Instant Privacy')), isNotEmpty);
    });

    test('Instant Pause active → warning', () {
      final v = _compute(isInstantPauseActive: true);
      expect(v.findings.where((f) => f.headline.contains('paused')), isNotEmpty);
    });

    test('high CPU (>80%) → warning', () {
      final v = _compute(cpuLoadPct: 90);
      expect(v.findings.where((f) => f.headline.contains('high load')), isNotEmpty);
    });

    test('high memory (>85%) → warning', () {
      final v = _compute(memoryLoadPct: 90);
      expect(v.findings.where((f) => f.headline.contains('memory')), isNotEmpty);
    });
  });

  // ── Checks 16-19: Advanced checks ────────────────────────────────────────

  group('VerdictEngine — checks 16-19', () {
    test('band steering missteer → warning', () {
      final v = _compute(isBandSteeringMissteer: true);
      final finding = v.findings.firstWhere(
          (f) => f.headline.toLowerCase().contains('stuck') ||
              f.headline.toLowerCase().contains('band'));
      expect(finding.priority, VerdictPriority.warning);
    });

    test('ethernet no link → warning', () {
      final v = _compute(hasEthernetNoLink: true);
      final finding = v.findings.firstWhere(
          (f) => f.headline.toLowerCase().contains('no network link'));
      expect(finding.priority, VerdictPriority.warning);
    });

    test('zombie mesh node → warning', () {
      final v = _compute(hasZombieMeshNode: true);
      final finding = v.findings.firstWhere((f) => f.headline.contains('not working well'));
      expect(finding.priority, VerdictPriority.warning);
    });

    test('DHCP 90%+ → warning', () {
      final v = _compute(dhcpPoolUtilizationPct: 95);
      final finding = v.findings.firstWhere(
          (f) => f.headline.toLowerCase().contains('address pool'));
      expect(finding.priority, VerdictPriority.warning);
    });

    test('DHCP 89% → no finding (boundary)', () {
      final v = _compute(dhcpPoolUtilizationPct: 89);
      expect(v.findings.where((f) => f.headline.toLowerCase().contains('address pool')), isEmpty);
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
        const NodeUIModel(deviceId: 'router', model: 'MX6200', isMaster: true),
        _satellite(friendlyName: 'Living Room', backhaulSignal: -55),
      ];
      final v = _compute(
        deviceScores: [_goodDevice()],
        clients: clients,
        meshNodes: nodes,
        firmwareUpdateAvailable: false,
      );
      expect(v.checksRun, 11);
    });

    test('early return at gateway → checksRun is 1', () {
      final v = _compute(gatewayReachable: false);
      expect(v.checksRun, 1);
    });
  });
}
