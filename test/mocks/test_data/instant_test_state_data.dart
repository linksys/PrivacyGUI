import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';
import 'package:privacy_gui/page/instant_test/models/verdict.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';
import 'package:privacy_gui/page/instant_test/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

/// Factory helpers for building [InstantTestState] variants in tests.
class InstantTestStateData {
  // ── Wan helpers ──────────────────────────────────────────────────────────

  static WanStatusUIModel connectedWan({String ip = '98.137.11.163'}) =>
      WanStatusUIModel(
        isUp: true,
        ipAddress: ip,
        subnetMask: '255.255.255.0',
        addressingType: 'DHCP',
        mtu: 1500,
        gateway: '98.137.11.1',
        ipv6Enabled: false,
        ipv6Addresses: const [],
      );

  static WanStatusUIModel disconnectedWan() => const WanStatusUIModel(
        isUp: false,
        ipAddress: '',
        subnetMask: '',
        addressingType: '',
        mtu: 0,
        gateway: '',
        ipv6Enabled: false,
        ipv6Addresses: [],
      );

  // ── Device helpers ───────────────────────────────────────────────────────

  static DeviceUIModel wifiDevice({
    String mac = 'AA:BB:CC:DD:EE:01',
    String hostName = 'test-device',
    String? band = '5GHz',
    int? signalStrength = -52,
    int? downlinkRate = 450000000, // 450 Mbps in bits/sec
  }) =>
      DeviceUIModel(
        mac: mac,
        ip: '192.168.1.100',
        hostName: hostName,
        isWifi: true,
        band: band,
        signalStrength: signalStrength,
        downlinkRate: downlinkRate,
        layer1Interface: 'Device.WiFi.AccessPoint.1.AssociatedDevice.1',
        isActive: true,
      );

  static DeviceUIModel wiredDevice({
    String mac = 'BB:CC:DD:EE:FF:01',
    String hostName = 'wired-device',
  }) =>
      DeviceUIModel(
        mac: mac,
        ip: '192.168.1.110',
        hostName: hostName,
        isWifi: false,
        layer1Interface: 'Device.Ethernet.Interface.1',
        isActive: true,
      );

  static DeviceUIModel weakWifiDevice({
    String mac = 'CC:DD:EE:FF:00:01',
    String hostName = 'weak-device',
  }) =>
      DeviceUIModel(
        mac: mac,
        ip: '192.168.1.120',
        hostName: hostName,
        isWifi: true,
        band: '2.4GHz',
        signalStrength: -82,
        downlinkRate: 5000000, // 5 Mbps
        layer1Interface: 'Device.WiFi.AccessPoint.2.AssociatedDevice.1',
        isActive: true,
      );

  // ── Node helpers ─────────────────────────────────────────────────────────

  static NodeUIModel masterNode() => const NodeUIModel(
        deviceId: 'AA:BB:CC:00:00:01',
        model: 'MX6200',
        isMaster: true,
      );

  static NodeUIModel satelliteNode({
    int? backhaulSignal = -55,
    String mediaType = 'IEEE 802.11ax',
  }) =>
      NodeUIModel(
        deviceId: 'AA:BB:CC:00:00:02',
        model: 'MX6200',
        isMaster: false,
        backhaulSignalStrength: backhaulSignal,
        backhaulMediaType: mediaType,
      );

  static NodeUIModel weakSatelliteNode() => satelliteNode(backhaulSignal: -78);

  // ── Full state factories ─────────────────────────────────────────────────

  static InstantTestState idleState() => const InstantTestState();

  static InstantTestState loadingState() => const InstantTestState(
        phase: InstantTestLoadPhase.loading,
      );

  static InstantTestState allClearState() {
    final device = wifiDevice();
    final score = DeviceScore.compute(device);
    final verdict = VerdictEngine.compute(
      gatewayReachable: true,
      wanConnected: true,
      wanIpAddress: '98.137.11.163',
      dnsWorking: true,
      downloadMbps: 150,
      latencyMs: 12,
      firmwareUpdateAvailable: false,
      firmwareVersion: '1.0.10',
      uptimeSeconds: 86400,
      deviceScores: [score],
      clients: [device],
      meshNodes: const [],
      planSpeedMbps: null,
    );
    return InstantTestState(
      phase: InstantTestLoadPhase.complete,
      wanStatus: connectedWan(),
      clients: [device],
      deviceScores: [score],
      firmwareVersion: '1.0.10',
      firmwareUpdateAvailable: false,
      uptimeSeconds: 86400,
      gatewayPing: const GatewayPingResult(reachable: true, latencyMs: 2),
      dnsCheck: const DnsCheckResult(resolved: true, latencyMs: 10),
      speedTest: const SpeedTestResult(
          downloadMbps: 150, uploadMbps: 50, latencyMs: 12, jitterMs: 2),
      browserTestStep: 'complete',
      verdict: verdict,
      verdictIsPreliminary: false,
    );
  }

  static InstantTestState wanDisconnectedState() {
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
      deviceScores: const [],
      clients: const [],
      meshNodes: const [],
      planSpeedMbps: null,
    );
    return InstantTestState(
      phase: InstantTestLoadPhase.complete,
      wanStatus: disconnectedWan(),
      gatewayPing: const GatewayPingResult(reachable: true, latencyMs: 2),
      browserTestStep: 'complete',
      verdict: verdict,
      verdictIsPreliminary: false,
    );
  }
}
