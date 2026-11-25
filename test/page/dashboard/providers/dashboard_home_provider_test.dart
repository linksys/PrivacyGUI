// The dashboard home: its Wi-Fi cards, the network's health, the WAN and the
// last speed test, built from what the router reports in a poll.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';

import '../../../common/recording_polling.dart';
import '../../instant_device/providers/home_network_poll.dart';

/// One `GetHealthCheckResults` entry: a speed test, in kilobits a second.
Map<String, dynamic> _speedTest(String timestamp,
        {required int upload, required int download}) =>
    {
      'resultID': timestamp.hashCode,
      'timestamp': timestamp,
      'healthCheckModulesRequested': ['SpeedTest'],
      'speedTestResult': {
        'resultID': timestamp.hashCode,
        'exitCode': 'Success',
        'serverID': '38330',
        'latency': 2,
        'uploadBandwidth': upload,
        'downloadBandwidth': download,
      },
    };

void main() {
  late ProviderContainer container;

  DashboardHomeState home() => container.read(dashboardHomeProvider);

  void pollReports(Map<JNAPAction, JNAPResult> poll) {
    container = ProviderContainer(overrides: [
      pollingProvider.overrideWith(() => RecordingPolling(poll)),
    ]);
    addTearDown(container.dispose);
  }

  setUp(() => pollReports(homeNetworkPoll()));

  group('the Wi-Fi cards', () {
    test('one card a band, then the guest network', () {
      expect(
        [
          for (final wifi in home().wifis)
            [wifi.ssid, wifi.radios, wifi.isGuest]
        ],
        [
          [
            'Home',
            ['RADIO_2.4GHz'],
            false
          ],
          [
            'Home',
            ['RADIO_5GHz'],
            false
          ],
          [
            'Home-Guest',
            ['RADIO_2.4GHz', 'RADIO_5GHz'],
            true
          ],
        ],
      );
    });

    test(
        'each card counts the online Wi-Fi clients on it, not nodes or wired '
        'ones', () {
      expect([for (final wifi in home().wifis) wifi.numOfConnectedDevices],
          [0, 1, 1]);
    });

    test('the guest card shows the guest network as on or off', () {
      expect(home().wifis.last.isEnabled, isTrue);

      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getGuestRadioSettings: guestRadioSettings(enabled: false),
      }));

      expect(home().wifis.last.isGuest, isTrue);
      expect(home().wifis.last.isEnabled, isFalse);
    });

    test('a router without a guest network has no guest card', () {
      pollReports(homeNetworkPoll()..remove(JNAPAction.getGuestRadioSettings));

      expect(home().wifis.where((wifi) => wifi.isGuest), isEmpty);
    });
  });

  group('the network', () {
    test('shows the router by its model', () {
      expect(home().masterIcon, 'routerMx5300');
    });

    test('flags a node that is offline', () {
      expect(home().isAnyNodesOffline, isFalse);

      pollReports(homeNetworkPoll(devices: [
        masterDevice(),
        bedroomNode(online: false),
      ]));

      expect(home().isAnyNodesOffline, isTrue);
    });

    test('shows the WAN type the router uses and the one it detected', () {
      expect(home().wanType, 'DHCP');
      expect(home().detectedWANType, 'DHCP');
    });

    test('shows the uptime and which ports are connected', () {
      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getSystemStats: {
          'uptimeSeconds': 86400,
          'CPULoad': '12%',
          'MemoryLoad': '40%',
        },
        JNAPAction.getEthernetPortConnections: {
          'wanPortConnection': '1Gbps',
          'lanPortConnections': ['1Gbps', 'None', '100Mbps', 'None'],
        },
      }));

      expect(home().uptime, 86400);
      expect(home().wanPortConnection, '1Gbps');
      expect(home().lanPortConnections, ['1Gbps', 'None', '100Mbps', 'None']);
    });

    test('lays the ports out side by side on a router built that way', () {
      expect(home().isHorizontalLayout, isFalse);

      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getDeviceInfo: deviceInfo(modelNumber: 'LN11'),
      }));

      expect(home().isHorizontalLayout, isTrue);
    });

    test('a poll the router has answered is not the first one', () {
      expect(home().isFirstPolling, isFalse);
    });

    test('a poll seeded from the cache, before any answer, is the first one',
        () {
      container.read(pollingProvider.notifier).state = AsyncData(
          CoreTransactionData(
              lastUpdate: 0, isReady: false, data: homeNetworkPoll()));

      expect(home().isFirstPolling, isTrue);
    });
  });

  group('the speed test', () {
    test('shows the latest result, in megabits', () {
      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getHealthCheckResults: {
          'healthCheckResults': [
            _speedTest('2026-01-04T21:00:00Z', upload: 5000, download: 9000),
            _speedTest('2026-01-05T09:15:00Z', upload: 44559, download: 93356),
          ],
        },
        JNAPAction.getSupportedHealthCheckModules: {
          'supportedHealthCheckModules': ['SpeedTest'],
        },
      }));

      expect(home().uploadResult,
          const DashboardSpeedItem(value: '45', unit: 'Mb'));
      expect(home().downloadResult,
          const DashboardSpeedItem(value: '93', unit: 'Mb'));
      expect(home().speedCheckTimestamp, 1767604500000);
    });

    // The router's timestamps are ISO 8601, on a 24-hour clock. Read on a
    // 12-hour one, a test run at 12:30 UTC showed as run at 00:30.
    test('reads a test run in the 12 o\'clock hour at the time it ran', () {
      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getHealthCheckResults: {
          'healthCheckResults': [
            _speedTest('2026-01-05T12:30:00Z', upload: 44559, download: 93356),
          ],
        },
      }));

      expect(home().speedCheckTimestamp, 1767616200000);
    });

    test('shows dashes before any test has run', () {
      expect(
          home().uploadResult, const DashboardSpeedItem(value: '--', unit: ''));
      expect(home().downloadResult,
          const DashboardSpeedItem(value: '--', unit: ''));
      expect(home().speedCheckTimestamp, isNull);
    });

    test('runs Ookla, or SamKnows where the router has it', () {
      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getSupportedHealthCheckModules: {
          'supportedHealthCheckModules': ['SpeedTest'],
        },
      }));
      expect(home().isHealthCheckSupported, isTrue);
      expect(home().healthCheckModule, 'Ookla');

      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getSupportedHealthCheckModules: {
          'supportedHealthCheckModules': ['SpeedTest', 'SpeedTestSamKnows'],
        },
      }));
      expect(home().healthCheckModule, 'SamKnows');
    });

    test('offers no speed test on a router without one', () {
      expect(home().isHealthCheckSupported, isFalse);
      expect(home().healthCheckModule, isNull);
    });
  });
}
