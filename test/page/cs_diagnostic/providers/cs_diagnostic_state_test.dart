import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';

void main() {
  group('CsDiagnosticState — wanConnected', () {
    test('returns true when wanStatus is Connected', () {
      const state = CsDiagnosticState(
        wanStatus: {'wanStatus': 'Connected'},
      );
      expect(state.wanConnected, true);
    });

    test('returns true when wanStatus is connected (lowercase)', () {
      const state = CsDiagnosticState(
        wanStatus: {'wanStatus': 'connected'},
      );
      expect(state.wanConnected, true);
    });

    test('returns false when wanStatus is Disconnected', () {
      const state = CsDiagnosticState(
        wanStatus: {'wanStatus': 'Disconnected'},
      );
      expect(state.wanConnected, false);
    });

    test('returns false when wanStatus map is null', () {
      const state = CsDiagnosticState();
      expect(state.wanConnected, false);
    });

    test('returns false when wanStatus key is missing from map', () {
      const state = CsDiagnosticState(
        wanStatus: {'otherKey': 'value'},
      );
      expect(state.wanConnected, false);
    });
  });

  group('CsDiagnosticState — dhcpUtilization', () {
    test('calculates correct utilization ratio', () {
      const state = CsDiagnosticState(
        dhcpLeasesCount: 75,
        dhcpPoolLimit: 150,
      );
      expect(state.dhcpUtilization, 0.5);
    });

    test('returns 0 when pool limit is 0 (avoid division by zero)', () {
      const state = CsDiagnosticState(
        dhcpLeasesCount: 10,
        dhcpPoolLimit: 0,
      );
      expect(state.dhcpUtilization, 0);
    });

    test('returns 0 with default values', () {
      const state = CsDiagnosticState();
      expect(state.dhcpUtilization, 0);
    });

    test('returns high utilization for near-full pool', () {
      const state = CsDiagnosticState(
        dhcpLeasesCount: 128,
        dhcpPoolLimit: 150,
      );
      expect(state.dhcpUtilization, closeTo(0.853, 0.001));
    });
  });

  group('CsDiagnosticState — routerUptimeSeconds', () {
    test('returns uptime from routerHealth map', () {
      const state = CsDiagnosticState(
        routerHealth: {'uptimeInSeconds': 345600},
      );
      expect(state.routerUptimeSeconds, 345600);
    });

    test('returns 0 when routerHealth is null', () {
      const state = CsDiagnosticState();
      expect(state.routerUptimeSeconds, 0);
    });

    test('returns 0 when uptimeInSeconds key is missing', () {
      const state = CsDiagnosticState(
        routerHealth: {'cpuLoad': 12},
      );
      expect(state.routerUptimeSeconds, 0);
    });
  });

  group('CsDiagnosticState — flaggedClients', () {
    test('returns empty list when no clients are flagged', () {
      const state = CsDiagnosticState(
        clients: [
          DiagnosticClient(
            macAddress: 'AA:BB:CC:11:22:01',
            band: '5GHz',
            signalDecibels: -40,
            txRateMbps: 866,
            rxRateMbps: 780,
            isWireless: true,
          ),
        ],
      );
      expect(state.flaggedClients, isEmpty);
    });

    test('returns flagged clients with weak signal', () {
      const state = CsDiagnosticState(
        clients: [
          DiagnosticClient(
            macAddress: 'AA:BB:CC:11:22:01',
            band: '5GHz',
            signalDecibels: -40,
            txRateMbps: 866,
            rxRateMbps: 780,
            isWireless: true,
          ),
          DiagnosticClient(
            macAddress: 'AA:BB:CC:11:22:02',
            band: '2.4GHz',
            signalDecibels: -82,
            txRateMbps: 11,
            rxRateMbps: 8,
            isWireless: true,
          ),
        ],
      );
      expect(state.flaggedClients.length, 1);
      expect(state.flaggedClients.first.macAddress, 'AA:BB:CC:11:22:02');
    });

    test('excludes wired clients from flagged list', () {
      const state = CsDiagnosticState(
        clients: [
          DiagnosticClient(
            macAddress: 'AA:BB:CC:11:22:01',
            band: 'Wired',
            txRateMbps: 1,
            rxRateMbps: 1,
            isWireless: false,
          ),
        ],
      );
      expect(state.flaggedClients, isEmpty);
    });
  });

  group('CsDiagnosticState — complexityScore', () {
    test('returns 0 for minimal healthy state', () {
      const state = CsDiagnosticState(
        wanStatus: {'wanStatus': 'Connected'},
        routerHealth: {'uptimeInSeconds': 86400},
        dhcpLeasesCount: 5,
        dhcpPoolLimit: 150,
      );
      expect(state.complexityScore, 0);
    });

    test('increases score for many clients', () {
      final clients = List.generate(
        30,
        (i) => DiagnosticClient(
          macAddress: 'AA:BB:CC:11:22:${i.toRadixString(16).padLeft(2, '0')}',
          band: '5GHz',
          signalDecibels: -50,
          isWireless: true,
        ),
      );
      final state = CsDiagnosticState(
        clients: clients,
        wanStatus: {'wanStatus': 'Connected'},
        routerHealth: {'uptimeInSeconds': 86400},
      );
      // 30 clients / 10 = 3, clamped to [0,4]
      expect(state.complexityScore, 3);
    });

    test('increases score for high DHCP utilization', () {
      const state = CsDiagnosticState(
        dhcpLeasesCount: 120,
        dhcpPoolLimit: 150,
        wanStatus: {'wanStatus': 'Connected'},
        routerHealth: {'uptimeInSeconds': 86400},
      );
      // 0 clients score + 2 dhcp > 0.7 = 2
      expect(state.complexityScore, 2);
    });

    test('increases score when WAN is disconnected', () {
      const state = CsDiagnosticState(
        wanStatus: {'wanStatus': 'Disconnected'},
        routerHealth: {'uptimeInSeconds': 86400},
      );
      // 0 clients + 0 dhcp + 1 wan down = 1
      expect(state.complexityScore, 1);
    });

    test('increases score for recent reboot (uptime < 3600s)', () {
      const state = CsDiagnosticState(
        wanStatus: {'wanStatus': 'Connected'},
        routerHealth: {'uptimeInSeconds': 1200},
      );
      // 0 clients + 0 dhcp + 0 wan + 2 recent reboot = 2
      expect(state.complexityScore, 2);
    });

    test('clamps to max 10', () {
      final clients = List.generate(
        50,
        (i) => DiagnosticClient(
          macAddress: 'AA:BB:CC:11:22:${i.toRadixString(16).padLeft(2, '0')}',
          band: '5GHz',
          signalDecibels: -50,
          isWireless: true,
        ),
      );
      final state = CsDiagnosticState(
        clients: clients,
        wanStatus: {'wanStatus': 'Disconnected'},
        routerHealth: {'uptimeInSeconds': 500},
        dhcpLeasesCount: 140,
        dhcpPoolLimit: 150,
      );
      // 4 (clients capped) + 2 (dhcp) + 1 (wan) + 2 (reboot) = 9, clamped to 10
      expect(state.complexityScore, lessThanOrEqualTo(10));
    });
  });

  group('CsDiagnosticState — bandSteeringEnabled', () {
    test('returns true when supported', () {
      const state = CsDiagnosticState(
        radioInfo: {'isBandSteeringSupported': true},
      );
      expect(state.bandSteeringEnabled, true);
    });

    test('returns false when not supported', () {
      const state = CsDiagnosticState(
        radioInfo: {'isBandSteeringSupported': false},
      );
      expect(state.bandSteeringEnabled, false);
    });

    test('returns false when radioInfo is null', () {
      const state = CsDiagnosticState();
      expect(state.bandSteeringEnabled, false);
    });
  });

  group('CsDiagnosticState — guestNetworkEnabled', () {
    test('returns true when enabled', () {
      const state = CsDiagnosticState(
        guestNetwork: {'isGuestNetworkEnabled': true},
      );
      expect(state.guestNetworkEnabled, true);
    });

    test('returns false when disabled', () {
      const state = CsDiagnosticState(
        guestNetwork: {'isGuestNetworkEnabled': false},
      );
      expect(state.guestNetworkEnabled, false);
    });

    test('returns false when null', () {
      const state = CsDiagnosticState();
      expect(state.guestNetworkEnabled, false);
    });
  });

  group('CsDiagnosticState — firmwareUpdateAvailable', () {
    test('returns true when update is available', () {
      const state = CsDiagnosticState(
        firmwareUpdate: {
          'firmwareUpdateStatus': 'UpdateAvailable',
          'availableUpdate': {'firmwareVersion': '1.0.17.26032012'},
        },
      );
      expect(state.firmwareUpdateAvailable, true);
      expect(state.availableFirmwareVersion, '1.0.17.26032012');
    });

    test('returns false when no update available', () {
      const state = CsDiagnosticState(
        firmwareUpdate: {'firmwareUpdateStatus': 'NoUpdateAvailable'},
      );
      expect(state.firmwareUpdateAvailable, false);
    });

    test('returns false when firmwareUpdate is null', () {
      const state = CsDiagnosticState();
      expect(state.firmwareUpdateAvailable, false);
      expect(state.availableFirmwareVersion, null);
    });
  });

  group('CsDiagnosticState — macFilterMode', () {
    test('returns Allow when set and enabled', () {
      const state = CsDiagnosticState(
        macFilter: {'macFilterMode': 'Allow', 'isEnabled': true},
      );
      expect(state.macFilterMode, 'Allow');
    });

    test('returns Deny when set and enabled', () {
      const state = CsDiagnosticState(
        macFilter: {'macFilterMode': 'Deny', 'isEnabled': true},
      );
      expect(state.macFilterMode, 'Deny');
    });

    test('returns null when mode is Disabled', () {
      const state = CsDiagnosticState(
        macFilter: {'macFilterMode': 'Disabled'},
      );
      expect(state.macFilterMode, null);
    });

    test('returns null when isEnabled is false', () {
      const state = CsDiagnosticState(
        macFilter: {'macFilterMode': 'Allow', 'isEnabled': false},
      );
      expect(state.macFilterMode, null);
    });

    test('returns null when macFilter is null', () {
      const state = CsDiagnosticState();
      expect(state.macFilterMode, null);
    });

    test('returns mode when isEnabled key is absent (defaults true)', () {
      const state = CsDiagnosticState(
        macFilter: {'macFilterMode': 'Deny'},
      );
      expect(state.macFilterMode, 'Deny');
    });
  });

  group('CsDiagnosticState — parentalControlsEnabled', () {
    test('returns true when enabled', () {
      const state = CsDiagnosticState(
        parentalControls: {'isParentalControlEnabled': true},
      );
      expect(state.parentalControlsEnabled, true);
    });

    test('returns false when disabled', () {
      const state = CsDiagnosticState(
        parentalControls: {'isParentalControlEnabled': false},
      );
      expect(state.parentalControlsEnabled, false);
    });

    test('returns false when null', () {
      const state = CsDiagnosticState();
      expect(state.parentalControlsEnabled, false);
    });
  });

  group('CsDiagnosticState — wirelessScheduleEnabled', () {
    test('returns true when enabled', () {
      const state = CsDiagnosticState(
        wirelessSchedule: {'isWirelessSchedulerEnabled': true},
      );
      expect(state.wirelessScheduleEnabled, true);
    });

    test('returns false when disabled', () {
      const state = CsDiagnosticState(
        wirelessSchedule: {'isWirelessSchedulerEnabled': false},
      );
      expect(state.wirelessScheduleEnabled, false);
    });

    test('returns false when null', () {
      const state = CsDiagnosticState();
      expect(state.wirelessScheduleEnabled, false);
    });
  });

  group('CsDiagnosticState — securityMode', () {
    test('returns top-level securityMode when present', () {
      const state = CsDiagnosticState(
        networkSecurity: {'securityMode': 'WPA3-Personal'},
      );
      expect(state.securityMode, 'WPA3-Personal');
    });

    test('falls back to wpaPersonalSettings securityMode', () {
      const state = CsDiagnosticState(
        networkSecurity: {
          'wpaPersonalSettings': {'securityMode': 'WPA2-Personal'},
        },
      );
      expect(state.securityMode, 'WPA2-Personal');
    });

    test('returns null when networkSecurity is null', () {
      const state = CsDiagnosticState();
      expect(state.securityMode, null);
    });
  });

  group('CsDiagnosticState — copyWith', () {
    test('copies with changed loadState', () {
      const original = CsDiagnosticState(loadState: DiagnosticLoadState.idle);
      final copied = original.copyWith(loadState: DiagnosticLoadState.loaded);
      expect(copied.loadState, DiagnosticLoadState.loaded);
      expect(original.loadState, DiagnosticLoadState.idle);
    });

    test('clears errorMessage when copyWith passes null explicitly', () {
      const original = CsDiagnosticState(errorMessage: 'something broke');
      // copyWith always sets errorMessage to the passed value (not null-coalesced)
      final copied = original.copyWith();
      expect(copied.errorMessage, null);
    });

    test('preserves other fields when changing one', () {
      const original = CsDiagnosticState(
        dhcpLeasesCount: 42,
        dhcpPoolLimit: 200,
        wanStatus: {'wanStatus': 'Connected'},
      );
      final copied = original.copyWith(dhcpLeasesCount: 50);
      expect(copied.dhcpLeasesCount, 50);
      expect(copied.dhcpPoolLimit, 200);
      expect(copied.wanConnected, true);
    });
  });
}
