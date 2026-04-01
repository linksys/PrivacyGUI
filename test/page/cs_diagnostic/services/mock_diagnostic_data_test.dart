import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';
import 'package:privacy_gui/page/cs_diagnostic/services/mock_diagnostic_data.dart';

void main() {
  group('MockDiagnosticData — healthy()', () {
    late CsDiagnosticState state;

    setUp(() {
      state = MockDiagnosticData.healthy();
    });

    test('is in loaded state', () {
      expect(state.loadState, DiagnosticLoadState.loaded);
    });

    test('has WAN connected', () {
      expect(state.wanConnected, true);
    });

    test('has reasonable uptime (> 1 day)', () {
      expect(state.routerUptimeSeconds, greaterThan(86400));
    });

    test('has clients', () {
      expect(state.clients, isNotEmpty);
      expect(state.clients.length, 14);
    });

    test('has both wired and wireless clients', () {
      final wireless = state.clients.where((c) => c.isWireless).length;
      final wired = state.clients.where((c) => !c.isWireless).length;
      expect(wireless, greaterThan(0));
      expect(wired, greaterThan(0));
    });

    test('has low DHCP utilization', () {
      expect(state.dhcpUtilization, lessThan(0.5));
    });

    test('has no firmware update available', () {
      expect(state.firmwareUpdateAvailable, false);
    });

    test('has band steering enabled', () {
      expect(state.bandSteeringEnabled, true);
    });

    test('has guest network enabled', () {
      expect(state.guestNetworkEnabled, true);
    });

    test('has low complexity score', () {
      expect(state.complexityScore, lessThanOrEqualTo(2));
    });

    test('has device info populated', () {
      expect(state.deviceInfo, isNotNull);
      expect(state.deviceInfo!['modelNumber'], 'M60');
    });

    test('all wireless clients have signal data', () {
      final wireless = state.clients.where((c) => c.isWireless);
      for (final client in wireless) {
        expect(client.signalDecibels, isNotNull,
            reason: '${client.displayName} should have signal data');
      }
    });
  });

  group('MockDiagnosticData — degraded()', () {
    late CsDiagnosticState state;

    setUp(() {
      state = MockDiagnosticData.degraded();
    });

    test('is in loaded state', () {
      expect(state.loadState, DiagnosticLoadState.loaded);
    });

    test('has WAN disconnected', () {
      expect(state.wanConnected, false);
    });

    test('has recent reboot (uptime < 2 hours)', () {
      expect(state.routerUptimeSeconds, lessThan(7200));
    });

    test('has high DHCP utilization (> 80%)', () {
      expect(state.dhcpUtilization, greaterThan(0.8));
    });

    test('has firmware update available', () {
      expect(state.firmwareUpdateAvailable, true);
      expect(state.availableFirmwareVersion, isNotNull);
    });

    test('has flagged clients', () {
      expect(state.flaggedClients, isNotEmpty);
    });

    test('has higher complexity score than healthy', () {
      final healthy = MockDiagnosticData.healthy();
      expect(state.complexityScore, greaterThan(healthy.complexityScore));
    });

    test('has backhaul info for mesh topology', () {
      expect(state.backhaulInfo, isNotNull);
      final devices = state.backhaulInfo!['backhaulDevices'] as List;
      expect(devices, isNotEmpty);
    });

    test('has clients', () {
      expect(state.clients, isNotEmpty);
    });

    test('has wireless clients with varying signal quality', () {
      final wireless = state.clients.where((c) => c.isWireless).toList();
      final signals = wireless
          .where((c) => c.signalDecibels != null)
          .map((c) => c.signalDecibels!)
          .toList();
      // Should have a range of signal strengths
      final hasGood = signals.any((s) => s > -65);
      final hasBad = signals.any((s) => s < -75);
      expect(hasGood, true, reason: 'Degraded scenario should have some good signals');
      expect(hasBad, true, reason: 'Degraded scenario should have some bad signals');
    });
  });

  group('MockDiagnosticData — data consistency', () {
    test('healthy client count matches DHCP lease count', () {
      final state = MockDiagnosticData.healthy();
      expect(state.dhcpLeasesCount, state.clients.length);
    });

    test('all clients have valid band values', () {
      final allClients = [
        ...MockDiagnosticData.healthy().clients,
        ...MockDiagnosticData.degraded().clients,
      ];
      const validBands = {'2.4GHz', '5GHz', '6GHz', 'Wired'};
      for (final client in allClients) {
        expect(validBands.contains(client.band), true,
            reason: '${client.displayName} has invalid band: ${client.band}');
      }
    });

    test('wired clients have no signal data', () {
      final allClients = [
        ...MockDiagnosticData.healthy().clients,
        ...MockDiagnosticData.degraded().clients,
      ];
      final wired = allClients.where((c) => !c.isWireless);
      for (final client in wired) {
        expect(client.signalDecibels, isNull,
            reason: 'Wired client ${client.displayName} should not have signal');
      }
    });

    test('all clients have MAC addresses', () {
      final allClients = [
        ...MockDiagnosticData.healthy().clients,
        ...MockDiagnosticData.degraded().clients,
      ];
      for (final client in allClients) {
        expect(client.macAddress, isNotEmpty);
        expect(client.macAddress.length, 17); // XX:XX:XX:XX:XX:XX
      }
    });
  });
}
