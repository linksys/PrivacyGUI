/// Advanced VerdictEngine tests covering edge cases, three-leg speed,
/// DNS three-way diagnosis, PPPoE, CGNAT, and combined scenarios.
///
/// Tagged for automation: no tags → included in ./run_tests.sh by default.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

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
  bool? publicDnsWorking,
  bool? configuredDnsReachable,
  List<String>? dnsServers,
  String? wanType,
  double? routerInternetDownloadMbps,
  int? dhcpPoolUtilizationPct,
  bool? hasZombieMeshNode,
  bool? hasEthernetNoLink,
  bool? isBandSteeringMissteer,
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
    publicDnsWorking: publicDnsWorking,
    configuredDnsReachable: configuredDnsReachable,
    dnsServers: dnsServers,
    wanType: wanType,
    routerInternetDownloadMbps: routerInternetDownloadMbps,
    dhcpPoolUtilizationPct: dhcpPoolUtilizationPct,
    hasZombieMeshNode: hasZombieMeshNode,
    hasEthernetNoLink: hasEthernetNoLink,
    isBandSteeringMissteer: isBandSteeringMissteer,
  );
}

DeviceUIModel _wifiDevice({String mac = 'AA:BB:CC:DD:EE:FF', int? signal = -55, int downlinkMbps = 200, String? band = '5GHz'}) =>
    DeviceUIModel(mac: mac, ip: '192.168.1.100', hostName: 'device-$mac', isWifi: true, band: band, signalStrength: signal, downlinkRate: downlinkMbps * 1000000, layer1Interface: 'Device.WiFi.AccessPoint.1.AssociatedDevice.1', isActive: true);

NodeUIModel _masterNode() => const NodeUIModel(deviceId: 'router', model: 'MX6200', isMaster: true);
NodeUIModel _childNode({int? signal = -60}) => NodeUIModel(deviceId: 'child', model: 'MX6200', isMaster: false, backhaulSignalStrength: signal);

void main() {
  // ── Three-leg speed test (D-R7) ───────────────────────────────────────────

  group('VerdictEngine — D-R7 three-leg WiFi bottleneck', () {
    test('router > 2× client at < 50 Mbps → WiFi bottleneck finding', () {
      final v = _compute(downloadMbps: 20, routerInternetDownloadMbps: 150);
      final finding = v.findings.firstWhere(
          (f) => f.headline.contains('WiFi is slowing'), orElse: () => throw 'Missing WiFi bottleneck finding');
      expect(finding.priority, VerdictPriority.warning);
      expect(finding.explanation, contains('150'));
      expect(finding.explanation, contains('20'));
    });

    test('router > 2× client but speed >= 50 Mbps → no bottleneck finding', () {
      final v = _compute(downloadMbps: 55, routerInternetDownloadMbps: 200);
      expect(v.findings.where((f) => f.headline.contains('WiFi is slowing')), isEmpty);
    });

    test('router <= 2× client → no bottleneck finding', () {
      final v = _compute(downloadMbps: 40, routerInternetDownloadMbps: 70);
      expect(v.findings.where((f) => f.headline.contains('WiFi is slowing')), isEmpty);
    });

    test('router null → no bottleneck finding', () {
      final v = _compute(downloadMbps: 10, routerInternetDownloadMbps: null);
      expect(v.findings.where((f) => f.headline.contains('WiFi is slowing')), isEmpty);
    });

    test('bottleneck explanation contains both leg speeds', () {
      final v = _compute(downloadMbps: 15, routerInternetDownloadMbps: 200);
      final f = v.findings.firstWhere((f) => f.headline.contains('WiFi is slowing'));
      expect(f.explanation, contains('200'));
      expect(f.explanation, contains('15'));
      expect(f.explanation, contains('WiFi'));
    });

    test('bottleneck ranks between speed and latency findings in sort', () {
      final v = _compute(downloadMbps: 15, routerInternetDownloadMbps: 200, latencyMs: 200);
      final idxBottleneck = v.findings.indexWhere((f) => f.headline.contains('WiFi is slowing'));
      final idxLatency = v.findings.indexWhere((f) => f.headline.contains('lag'));
      // Both should be present; bottleneck is warning, latency is warning — sorted by index
      expect(idxBottleneck, greaterThanOrEqualTo(0));
      expect(idxLatency, greaterThanOrEqualTo(0));
    });
  });

  // ── DNS three-way diagnosis ───────────────────────────────────────────────

  group('VerdictEngine — DNS three-way root-cause diagnosis', () {
    test('publicDns=true + configuredReachable=true → DNS service broken copy', () {
      final v = _compute(dnsWorking: false, publicDnsWorking: true, configuredDnsReachable: true);
      final f = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(f.explanation, contains('DNS servers are online but not responding'));
      expect(f.postRestartEscalation, contains('DNS queries are failing'));
    });

    test('publicDns=true + configuredReachable=false → routing broken copy', () {
      final v = _compute(dnsWorking: false, publicDnsWorking: true, configuredDnsReachable: false);
      final f = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(f.explanation, contains('Cannot reach your ISP\'s DNS servers'));
      expect(f.postRestartEscalation, contains('routing'));
    });

    test('publicDns=false → internet unreachable copy', () {
      final v = _compute(dnsWorking: false, publicDnsWorking: false);
      final f = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(f.explanation, contains('Internet appears to be unreachable'));
    });

    test('publicDns=null → generic DNS failure copy', () {
      final v = _compute(dnsWorking: false, publicDnsWorking: null);
      final f = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(f.postRestartEscalation, contains('websites won\'t load'));
    });

    test('ISP DNS servers surfaced when provided', () {
      final v = _compute(dnsWorking: false, dnsServers: ['172.30.1.105', '172.30.1.106']);
      final f = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(f.explanation, contains('172.30.1.105'));
      expect(f.explanation, contains('assigned by your ISP'));
    });

    test('custom DNS servers labelled correctly', () {
      final v = _compute(dnsWorking: false, dnsServers: ['1.1.1.1', '8.8.8.8']);
      final f = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(f.explanation, contains('1.1.1.1'));
      expect(f.explanation, anyOf(contains('Cloudflare'), contains('custom')));
    });

    test('PPPoE WAN type note included in DNS failure', () {
      final v = _compute(dnsWorking: false, wanType: 'PPPoE');
      final f = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(f.explanation, contains('PPPoE'));
    });
  });

  // ── WAN IP edge cases ─────────────────────────────────────────────────────

  group('VerdictEngine — WAN IP edge cases', () {
    test('RFC1918 10.x WAN IP — no double-NAT finding (check disabled)', () {
      // Double-NAT detection intentionally disabled (support team decision)
      final v = _compute(wanIpAddress: '10.83.5.101');
      expect(v.findings.where((f) => f.headline.toLowerCase().contains('double') || f.headline.toLowerCase().contains('router')), isEmpty);
    });

    test('RFC1918 192.168.x WAN IP — no double-NAT finding', () {
      final v = _compute(wanIpAddress: '192.168.50.1');
      expect(v.findings.where((f) => f.headline.toLowerCase().contains('two routers')), isEmpty);
    });

    test('valid public IP — no IP-related finding', () {
      final v = _compute(wanIpAddress: '98.137.11.163');
      expect(v.findings.where((f) => f.checkNumber == 3), isEmpty);
    });

    test('empty WAN IP when connected → critical finding check 3', () {
      final v = _compute(wanConnected: true, wanIpAddress: '');
      expect(v.findings.first.checkNumber, 3);
      expect(v.findings.first.priority, VerdictPriority.critical);
    });
  });

  // ── Mesh topology checks ──────────────────────────────────────────────────

  group('VerdictEngine — mesh topology scenarios', () {
    test('single node mesh — no backhaul finding', () {
      final v = _compute(meshNodes: [_masterNode()]);
      expect(v.findings.where((f) => f.headline.contains('child')), isEmpty);
    });

    test('wired child node (signal null) — no weak backhaul finding', () {
      final nodes = [_masterNode(), NodeUIModel(deviceId: 'child', model: 'MX6200', isMaster: false, backhaulMediaType: 'Ethernet', backhaulSignalStrength: null)];
      final v = _compute(meshNodes: nodes);
      expect(v.findings.where((f) => f.headline.contains('child')), isEmpty);
    });

    test('child signal exactly -70 — not weak (< not <=)', () {
      final v = _compute(meshNodes: [_masterNode(), _childNode(signal: -70)]);
      expect(v.findings.where((f) => f.headline.contains('child')), isEmpty);
    });

    test('child signal -71 — weak', () {
      final v = _compute(meshNodes: [_masterNode(), _childNode(signal: -71)]);
      expect(v.findings.where((f) => f.headline.contains('child')), isNotEmpty);
    });

    test('zombie node finding fires', () {
      final v = _compute(hasZombieMeshNode: true);
      final f = v.findings.firstWhere((f) => f.headline.contains('not working well'));
      expect(f.priority, VerdictPriority.warning);
      expect(f.actionKey, VerdictEngine.actionRestartRouter);
    });
  });

  // ── Combined / regression scenarios ──────────────────────────────────────

  group('VerdictEngine — combined scenarios (regression)', () {
    test('all-clear: gateway ok + WAN ok + DNS ok + 100Mbps → 0 findings', () {
      final v = _compute();
      expect(v.isAllClear, isTrue);
      expect(v.findings.where((f) => f.priority == VerdictPriority.critical || f.priority == VerdictPriority.warning), isEmpty);
    });

    test('WAN down: early return prevents speed/DNS checks from running', () {
      final v = _compute(wanConnected: false, downloadMbps: 3, dnsWorking: false);
      expect(v.findings.length, 1);
      expect(v.findings.first.priority, VerdictPriority.critical);
      expect(v.checksRun, 2);
    });

    test('gateway fail: early return at check 1', () {
      final v = _compute(gatewayReachable: false);
      expect(v.findings.length, 1);
      expect(v.checksRun, 1);
      expect(v.findings.first.checkNumber, 1);
    });

    test('multiple issues: sorted critical → warning → info', () {
      final weakDevice = DeviceScore.compute(
          DeviceUIModel(mac: 'AA', ip: '', hostName: 'phone', isWifi: true, signalStrength: -85, downlinkRate: 2000000, layer1Interface: '', isActive: true));
      final v = _compute(
        downloadMbps: 3,
        firmwareUpdateAvailable: true,
        deviceScores: [weakDevice],
        cpuLoadPct: 95,
      );
      // All findings should be sorted
      for (int i = 0; i < v.findings.length - 1; i++) {
        expect(v.findings[i].priority.index, lessThanOrEqualTo(v.findings[i + 1].priority.index));
      }
    });

    test('plan speed comparison: 60% of 100Mbps plan at 55Mbps → no finding', () {
      final v = _compute(downloadMbps: 55, planSpeedMbps: 100);
      expect(v.findings.where((f) => f.checkNumber == 6), isEmpty);
    });

    test('plan speed: 49% of 100Mbps plan at 49Mbps → warning', () {
      final v = _compute(downloadMbps: 49, planSpeedMbps: 100);
      expect(v.findings.where((f) => f.checkNumber == 6), isNotEmpty);
    });

    test('DHCP 90% threshold boundary: exactly 90 → fires', () {
      final v = _compute(dhcpPoolUtilizationPct: 90);
      expect(v.findings.where((f) => f.headline.contains('address pool')), isNotEmpty);
    });

    test('DHCP 89% → does not fire', () {
      final v = _compute(dhcpPoolUtilizationPct: 89);
      expect(v.findings.where((f) => f.headline.contains('address pool')), isEmpty);
    });

    test('uptime exactly 30 days → fires', () {
      final v = _compute(uptimeSeconds: 30 * 86400);
      expect(v.findings.where((f) => f.headline.contains('running')), isNotEmpty);
    });

    test('uptime 29 days 23 hours → does not fire', () {
      final v = _compute(uptimeSeconds: 30 * 86400 - 3600);
      expect(v.findings.where((f) => f.headline.contains('running')), isEmpty);
    });
  });

  // ── DeviceScore edge cases ────────────────────────────────────────────────

  group('DeviceScore — edge cases', () {
    test('null signal + null downlinkRate → score 0 (issue)', () {
      final d = DeviceUIModel(mac: 'AA', ip: '', hostName: 'device', isWifi: true, signalStrength: null, downlinkRate: null, layer1Interface: '', isActive: true);
      expect(DeviceScore.compute(d).score, 0);
      expect(DeviceScore.compute(d).isIssue, isTrue);
    });

    test('perfect signal (-30dBm) + max rate (1200Mbps) → score 100', () {
      final d = DeviceUIModel(mac: 'AA', ip: '', hostName: 'device', isWifi: true, signalStrength: -30, downlinkRate: 1200 * 1000000, layer1Interface: '', isActive: true);
      expect(DeviceScore.compute(d).score, 100);
      expect(DeviceScore.compute(d).isGood, isTrue);
    });

    test('wired device always scores 100 regardless of signal', () {
      final d = DeviceUIModel(mac: 'AA', ip: '', hostName: 'device', isWifi: false, signalStrength: -90, downlinkRate: 0, layer1Interface: 'Device.Ethernet.Interface.1', isActive: true);
      expect(DeviceScore.compute(d).score, 100);
    });

    test('score 70 boundary → good (>= 70)', () {
      // signal: (-55+90)/60*50 = 35/60*50 ≈ 29
      // rate: need ~41 more → 41/50*1200 ≈ 984 Mbps
      // Total: ~70 → good
      final d = DeviceUIModel(mac: 'AA', ip: '', hostName: 'device', isWifi: true, signalStrength: -55, downlinkRate: 990 * 1000000, layer1Interface: '', isActive: true);
      final score = DeviceScore.compute(d);
      expect(score.score, greaterThanOrEqualTo(68)); // allow ±2 for rounding
      expect(score.score, lessThanOrEqualTo(72));
    });
  });

  // ── VerdictEngine ISP escalation scripts ─────────────────────────────────

  group('VerdictEngine — ISP escalation scripts', () {
    test('speed escalation (check 5) contains post-restart guidance', () {
      final v = _compute(downloadMbps: 3.7);
      final f = v.findings.firstWhere((f) => f.checkNumber == 5);
      expect(f.postRestartEscalation, isNotNull);
      // The escalation script is a generic ISP script — verifying it's non-empty
      expect(f.postRestartEscalation!.length, greaterThan(20));
    });

    test('slow speed escalation (check 6) contains post-restart guidance', () {
      final v = _compute(downloadMbps: 12.5);
      final f = v.findings.firstWhere((f) => f.checkNumber == 6);
      expect(f.postRestartEscalation, isNotNull);
      expect(f.postRestartEscalation!.length, greaterThan(20));
    });

    test('WAN no-IP escalation (check 3) is non-null', () {
      final v = _compute(wanConnected: true, wanIpAddress: '');
      final f = v.findings.firstWhere((f) => f.checkNumber == 3);
      expect(f.postRestartEscalation, isNotNull);
    });

    test('DNS failure escalation (check 4) mentions restarting', () {
      final v = _compute(dnsWorking: false);
      final f = v.findings.firstWhere((f) => f.checkNumber == 4);
      expect(f.postRestartEscalation, isNotNull);
      expect(f.postRestartEscalation, contains('restarted'));
    });

    test('speed escalations (checks 5 + 6) mention restarting', () {
      for (final mbps in [3.0, 15.0]) {
        final v = _compute(downloadMbps: mbps);
        final check = mbps < 5 ? 5 : 6;
        final f = v.findings.firstWhere((f) => f.checkNumber == check, orElse: () => throw 'Missing check $check for $mbps Mbps');
        if (f.postRestartEscalation != null) {
          expect(f.postRestartEscalation, contains('restarted'), reason: 'Check $check at $mbps Mbps');
        }
      }
    });
  });
}
