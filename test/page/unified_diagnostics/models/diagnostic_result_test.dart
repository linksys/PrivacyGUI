import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';

void main() {
  group('DiagnosticSeverity', () {
    test('has all expected values', () {
      expect(DiagnosticSeverity.values.length, 4);
      expect(DiagnosticSeverity.ok, isNotNull);
      expect(DiagnosticSeverity.warning, isNotNull);
      expect(DiagnosticSeverity.error, isNotNull);
      expect(DiagnosticSeverity.skipped, isNotNull);
    });
  });

  group('DiagnosticStepUIModel', () {
    test('creates with required fields', () {
      final result = DiagnosticStepUIModel(
        step: DiagnosticStep.checkingWanStatus,
        severity: DiagnosticSeverity.ok,
        titleKey: 'test_title',
        descriptionKey: 'test_desc',
      );

      expect(result.step, DiagnosticStep.checkingWanStatus);
      expect(result.severity, DiagnosticSeverity.ok);
      expect(result.titleKey, 'test_title');
      expect(result.descriptionKey, 'test_desc');
      expect(result.rawData, isEmpty);
      expect(result.timestamp, isNotNull);
    });

    test('severity getters work correctly', () {
      final okResult = DiagnosticStepUIModel(
        step: DiagnosticStep.checkingWanStatus,
        severity: DiagnosticSeverity.ok,
        titleKey: 'title',
        descriptionKey: 'desc',
      );

      final warningResult = DiagnosticStepUIModel(
        step: DiagnosticStep.checkingWanStatus,
        severity: DiagnosticSeverity.warning,
        titleKey: 'title',
        descriptionKey: 'desc',
      );

      final errorResult = DiagnosticStepUIModel(
        step: DiagnosticStep.checkingWanStatus,
        severity: DiagnosticSeverity.error,
        titleKey: 'title',
        descriptionKey: 'desc',
      );

      final skippedResult = DiagnosticStepUIModel(
        step: DiagnosticStep.checkingWanStatus,
        severity: DiagnosticSeverity.skipped,
        titleKey: 'title',
        descriptionKey: 'desc',
      );

      expect(okResult.isOk, true);
      expect(okResult.isWarning, false);
      expect(okResult.isError, false);
      expect(okResult.isSkipped, false);

      expect(warningResult.isWarning, true);
      expect(errorResult.isError, true);
      expect(skippedResult.isSkipped, true);
    });
  });

  group('WanStatusCheckUIModel', () {
    test('creates with WAN data', () {
      final result = WanStatusCheckUIModel(
        status: 'Up',
        ipAddress: '192.168.1.100',
        addressingType: 'DHCP',
        severity: DiagnosticSeverity.ok,
        titleKey: 'wan_ok',
        descriptionKey: 'wan_ok_desc',
      );

      expect(result.step, DiagnosticStep.checkingWanStatus);
      expect(result.status, 'Up');
      expect(result.ipAddress, '192.168.1.100');
      expect(result.addressingType, 'DHCP');
      expect(result.isUp, true);
      expect(result.hasIp, true);
    });

    test('isUp returns false for down status', () {
      final result = WanStatusCheckUIModel(
        status: 'Down',
        ipAddress: '',
        addressingType: 'DHCP',
        severity: DiagnosticSeverity.error,
        titleKey: 'wan_down',
        descriptionKey: 'wan_down_desc',
      );

      expect(result.isUp, false);
      expect(result.hasIp, false);
    });
  });

  group('PingCheckUIModel', () {
    test('creates with ping data', () {
      final result = PingCheckUIModel(
        step: DiagnosticStep.pingGateway,
        host: '192.168.1.1',
        successCount: 3,
        failureCount: 0,
        avgResponseTime: 5,
        severity: DiagnosticSeverity.ok,
        titleKey: 'ping_ok',
        descriptionKey: 'ping_ok_desc',
      );

      expect(result.step, DiagnosticStep.pingGateway);
      expect(result.host, '192.168.1.1');
      expect(result.totalCount, 3);
      expect(result.successRate, 100.0);
      expect(result.allSucceeded, true);
      expect(result.allFailed, false);
    });

    test('calculates success rate correctly', () {
      final partial = PingCheckUIModel(
        step: DiagnosticStep.pingDns,
        host: '8.8.8.8',
        successCount: 2,
        failureCount: 1,
        avgResponseTime: 10,
        severity: DiagnosticSeverity.warning,
        titleKey: 'ping_partial',
        descriptionKey: 'ping_partial_desc',
      );

      expect(partial.totalCount, 3);
      expect(partial.successRate, closeTo(66.67, 0.01));
      expect(partial.allSucceeded, false);
      expect(partial.allFailed, false);
    });

    test('allFailed returns true when no success', () {
      final failed = PingCheckUIModel(
        step: DiagnosticStep.pingInternet,
        host: '8.8.8.8',
        successCount: 0,
        failureCount: 3,
        avgResponseTime: 0,
        severity: DiagnosticSeverity.error,
        titleKey: 'ping_fail',
        descriptionKey: 'ping_fail_desc',
      );

      expect(failed.allFailed, true);
      expect(failed.successRate, 0.0);
    });
  });

  group('WifiSignalCheckUIModel', () {
    test('creates with WiFi data', () {
      final result = WifiSignalCheckUIModel(
        rssi: -50,
        channel: 6,
        band: '2.4GHz',
        connectedDevices: 10,
        severity: DiagnosticSeverity.ok,
        titleKey: 'wifi_ok',
        descriptionKey: 'wifi_ok_desc',
      );

      expect(result.step, DiagnosticStep.checkingWifiSignal);
      expect(result.rssi, -50);
      expect(result.channel, 6);
      expect(result.band, '2.4GHz');
      expect(result.isStrongSignal, true);
      expect(result.isMediumSignal, false);
      expect(result.isWeakSignal, false);
    });

    test('signal strength thresholds', () {
      final weak = WifiSignalCheckUIModel(
        rssi: -80,
        channel: 1,
        band: '2.4GHz',
        connectedDevices: 5,
        severity: DiagnosticSeverity.warning,
        titleKey: 'wifi_weak',
        descriptionKey: 'wifi_weak_desc',
      );

      final medium = WifiSignalCheckUIModel(
        rssi: -60,
        channel: 36,
        band: '5GHz',
        connectedDevices: 5,
        severity: DiagnosticSeverity.ok,
        titleKey: 'wifi_ok',
        descriptionKey: 'wifi_ok_desc',
      );

      expect(weak.isWeakSignal, true);
      expect(weak.isMediumSignal, false);
      expect(weak.isStrongSignal, false);

      expect(medium.isWeakSignal, false);
      expect(medium.isMediumSignal, true);
      expect(medium.isStrongSignal, false);
    });
  });

  group('ConnectedDevicesCheckUIModel', () {
    test('creates with device data', () {
      final result = ConnectedDevicesCheckUIModel(
        totalDevices: 15,
        activeDevices: 10,
        highBandwidthDevices: const ['Device1', 'Device2'],
        severity: DiagnosticSeverity.warning,
        titleKey: 'devices_bandwidth',
        descriptionKey: 'devices_bandwidth_desc',
      );

      expect(result.step, DiagnosticStep.checkingConnectedDevices);
      expect(result.totalDevices, 15);
      expect(result.activeDevices, 10);
      expect(result.highBandwidthDevices.length, 2);
      expect(result.hasManyDevices, false);
      expect(result.hasHighBandwidthDevices, true);
    });

    test('hasManyDevices threshold at 20', () {
      final many = ConnectedDevicesCheckUIModel(
        totalDevices: 25,
        activeDevices: 20,
        highBandwidthDevices: const [],
        severity: DiagnosticSeverity.warning,
        titleKey: 'devices_many',
        descriptionKey: 'devices_many_desc',
      );

      final few = ConnectedDevicesCheckUIModel(
        totalDevices: 10,
        activeDevices: 8,
        highBandwidthDevices: const [],
        severity: DiagnosticSeverity.ok,
        titleKey: 'devices_ok',
        descriptionKey: 'devices_ok_desc',
      );

      expect(many.hasManyDevices, true);
      expect(few.hasManyDevices, false);
    });
  });

  group('TracerouteHopUIModel', () {
    test('creates with hop data', () {
      const hop = TracerouteHopUIModel(
        hopNumber: 1,
        host: 'gateway.local',
        hostAddress: '192.168.1.1',
        avgRoundTrip: 5,
      );

      expect(hop.hopNumber, 1);
      expect(hop.host, 'gateway.local');
      expect(hop.hostAddress, '192.168.1.1');
      expect(hop.avgRoundTrip, 5);
      expect(hop.isSlow, false);
      expect(hop.isUnreachable, false);
    });

    test('isSlow returns true for RTT > 200ms', () {
      const slowHop = TracerouteHopUIModel(
        hopNumber: 5,
        host: 'slow-router.isp.net',
        hostAddress: '10.0.0.1',
        avgRoundTrip: 250,
      );

      const normalHop = TracerouteHopUIModel(
        hopNumber: 3,
        host: 'fast-router.net',
        hostAddress: '10.0.0.2',
        avgRoundTrip: 50,
      );

      expect(slowHop.isSlow, true);
      expect(normalHop.isSlow, false);
    });

    test('isUnreachable returns true for empty address or zero RTT', () {
      const unreachableNoAddress = TracerouteHopUIModel(
        hopNumber: 2,
        host: '',
        hostAddress: '',
        avgRoundTrip: 0,
      );

      const unreachableZeroRtt = TracerouteHopUIModel(
        hopNumber: 3,
        host: 'some.host',
        hostAddress: '10.0.0.1',
        avgRoundTrip: 0,
      );

      const reachable = TracerouteHopUIModel(
        hopNumber: 1,
        host: 'gateway',
        hostAddress: '192.168.1.1',
        avgRoundTrip: 5,
      );

      expect(unreachableNoAddress.isUnreachable, true);
      expect(unreachableZeroRtt.isUnreachable, true);
      expect(reachable.isUnreachable, false);
    });
  });

  group('TracerouteCheckUIModel', () {
    test('creates with traceroute data', () {
      final hops = [
        const TracerouteHopUIModel(
          hopNumber: 1,
          host: 'gateway.local',
          hostAddress: '192.168.1.1',
          avgRoundTrip: 1,
        ),
        const TracerouteHopUIModel(
          hopNumber: 2,
          host: 'isp.net',
          hostAddress: '10.0.0.1',
          avgRoundTrip: 15,
        ),
        const TracerouteHopUIModel(
          hopNumber: 3,
          host: 'target.com',
          hostAddress: '8.8.8.8',
          avgRoundTrip: 25,
        ),
      ];

      final result = TracerouteCheckUIModel(
        hops: hops,
        targetHost: '8.8.8.8',
        severity: DiagnosticSeverity.ok,
        titleKey: 'traceroute_ok',
        descriptionKey: 'traceroute_ok_desc',
      );

      expect(result.step, DiagnosticStep.runningTraceroute);
      expect(result.hops.length, 3);
      expect(result.targetHost, '8.8.8.8');
      expect(result.slowHops, isEmpty);
      expect(result.rawData['hopCount'], 3);
      expect(result.rawData['slowHopCount'], 0);
    });

    test('slowHops returns hops with RTT > 200ms', () {
      final hops = [
        const TracerouteHopUIModel(
          hopNumber: 1,
          host: 'gateway',
          hostAddress: '192.168.1.1',
          avgRoundTrip: 5,
        ),
        const TracerouteHopUIModel(
          hopNumber: 2,
          host: 'slow-node',
          hostAddress: '10.0.0.1',
          avgRoundTrip: 300, // slow
        ),
        const TracerouteHopUIModel(
          hopNumber: 3,
          host: 'another-slow',
          hostAddress: '10.0.0.2',
          avgRoundTrip: 250, // slow
        ),
        const TracerouteHopUIModel(
          hopNumber: 4,
          host: 'fast-node',
          hostAddress: '10.0.0.3',
          avgRoundTrip: 50,
        ),
      ];

      final result = TracerouteCheckUIModel(
        hops: hops,
        targetHost: '8.8.8.8',
        severity: DiagnosticSeverity.warning,
        titleKey: 'traceroute_slow',
        descriptionKey: 'traceroute_slow_desc',
      );

      expect(result.slowHops.length, 2);
      expect(result.slowHops[0].hopNumber, 2);
      expect(result.slowHops[1].hopNumber, 3);
      expect(result.rawData['slowHopCount'], 2);
    });

    test('rawData contains hop and slow hop counts', () {
      final hops = [
        const TracerouteHopUIModel(
          hopNumber: 1,
          host: 'gateway',
          hostAddress: '192.168.1.1',
          avgRoundTrip: 5,
        ),
        const TracerouteHopUIModel(
          hopNumber: 2,
          host: 'slow',
          hostAddress: '10.0.0.1',
          avgRoundTrip: 500,
        ),
      ];

      final result = TracerouteCheckUIModel(
        hops: hops,
        targetHost: 'google.com',
        severity: DiagnosticSeverity.warning,
        titleKey: 'title',
        descriptionKey: 'desc',
      );

      expect(result.rawData['hopCount'], 2);
      expect(result.rawData['slowHopCount'], 1);
      expect(result.rawData['targetHost'], 'google.com');
    });
  });
}
