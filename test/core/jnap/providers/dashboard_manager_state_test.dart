// The dashboard's state as a poll builds it, and as it is written out and read
// back.
//
// The input is the poll as polling hands it over, through RecordingPolling,
// so DashboardManagerNotifier.createState runs on it (#1922 P0). It is never
// the parsed snapshot in test/test_data/dashboard_manager_test_state.dart,
// which skips createState. The rest of dashboard_manager_provider.dart waits
// on #1941 and #1942 and is not tested here.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

import '../../../common/recording_polling.dart';

/// [output] as the router's answer, after a trip through JSON text.
JNAPSuccess _ok(Map<String, dynamic> output) => JNAPSuccess(
    result: 'OK',
    output: jsonDecode(jsonEncode(output)) as Map<String, dynamic>);

const _deviceInfo = {
  'manufacturer': 'Linksys',
  'modelNumber': 'WHW03',
  'hardwareVersion': '2',
  'description': 'Velop',
  'serialNumber': '20J2060A839173',
  'firmwareVersion': '2.1.20.213195',
  'firmwareDate': '2023-07-25T07:27:06Z',
  'services': [
    'http://linksys.com/jnap/core/Core',
    'http://linksys.com/jnap/healthcheck/HealthCheckManager',
  ],
};

Map<String, dynamic> _radio(String id, String band, String ssid) => {
      'radioID': id,
      'physicalRadioID': 'ath0',
      'bssid': '30:23:03:2E:AF:EF',
      'band': band,
      'supportedModes': ['802.11mixed'],
      'supportedChannelsForChannelWidths': [
        {
          'channelWidth': 'Auto',
          'channels': [0, 36, 40, 44, 48]
        },
      ],
      'supportedSecurityTypes': ['None', 'WPA2-Personal'],
      'maxRADIUSSharedKeyLength': 64,
      'settings': {
        'isEnabled': true,
        'mode': '802.11mixed',
        'ssid': ssid,
        'broadcastSSID': true,
        'channelWidth': 'Auto',
        'channel': 0,
        'security': 'WPA2-Personal',
        'wpaPersonalSettings': {'passphrase': 'TestWifi1!'},
      },
    };

Map<String, dynamic> _guestRadio(String id) => {
      'radioID': id,
      'isEnabled': true,
      'broadcastGuestSSID': true,
      'guestSSID': 'fee_guest_qa_velop',
      'guestWPAPassphrase': 'TestWifi1!',
      'canEnableRadio': true,
    };

Map<String, dynamic> _speedTest(int id, String timestamp, int download) => {
      'resultID': id,
      'timestamp': timestamp,
      'healthCheckModulesRequested': ['SpeedTest'],
      'speedTestResult': {
        'resultID': id,
        'exitCode': 'Success',
        'serverID': '38330',
        'latency': 2,
        'uploadBandwidth': 44559,
        'downloadBandwidth': download,
      },
    };

/// The poll of a WHW03, with the reads the dashboard takes from it.
Map<JNAPAction, JNAPResult> _poll() => {
      JNAPAction.getDeviceInfo: _ok(_deviceInfo),
      JNAPAction.getRadioInfo: _ok({
        'isBandSteeringSupported': true,
        'radios': [
          _radio('RADIO_2.4GHz', '2.4GHz', 'fee_qa_velop'),
          _radio('RADIO_5GHz', '5GHz', 'fee_qa_velop'),
        ],
      }),
      JNAPAction.getGuestRadioSettings: _ok({
        'isGuestNetworkACaptivePortal': false,
        'isGuestNetworkEnabled': true,
        'radios': [_guestRadio('RADIO_2.4GHz'), _guestRadio('RADIO_5GHz')],
      }),
      // The router lists its results in no particular order.
      JNAPAction.getHealthCheckResults: _ok({
        'healthCheckResults': [
          _speedTest(27479, '2023-08-04T06:36:19Z', 91690),
          _speedTest(16557, '2023-08-07T08:36:12Z', 93356),
          _speedTest(63397, '2023-08-04T06:35:43Z', 92401),
        ],
      }),
      JNAPAction.getSupportedHealthCheckModules: _ok({
        'supportedHealthCheckModules': ['SpeedTest'],
      }),
      JNAPAction.getSystemStats: _ok({
        'uptimeSeconds': 19555,
        'CPULoad': '0.23',
        'MemoryLoad': '0.79',
      }),
      JNAPAction.getEthernetPortConnections: _ok({
        'wanPortConnection': '1Gbps',
        'lanPortConnections': ['None', '1Gbps', 'None'],
      }),
      JNAPAction.getLocalTime: _ok({'currentTime': '2024-12-25T15:34:42+0800'}),
      JNAPAction.getSoftSKUSettings: _ok({'modelNumber': 'LN16-EU'}),
    };

void main() {
  late ProviderContainer container;

  DashboardManagerState dashboard() => container.read(dashboardManagerProvider);

  void start(Map<JNAPAction, JNAPResult> poll) {
    container = ProviderContainer(overrides: [
      pollingProvider.overrideWith(() => RecordingPolling(poll)),
    ]);
  }

  tearDown(() {
    container.dispose();
  });

  group('the state a poll builds', () {
    test('holds nothing from the router before it has answered a poll', () {
      start({});

      final state = dashboard();
      expect(state.deviceInfo, isNull);
      expect(state.mainRadios, isEmpty);
      expect(state.guestRadios, isEmpty);
      expect(state.isGuestNetworkEnabled, isFalse);
      expect(state.latestSpeedTest, isNull);
      expect(state.uptimes, 0);
      expect(state.wanConnection, isNull);
      expect(state.skuModelNumber, isNull);
      // Without the router's clock, the app's own stands in.
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(state.localTime, inInclusiveRange(now - 60000, now));
    });

    test('reads the router, its Wi-Fi and its guest network', () {
      start(_poll());

      final state = dashboard();
      expect(state.deviceInfo?.serialNumber, '20J2060A839173');
      expect(state.deviceInfo?.modelNumber, 'WHW03');
      expect(state.mainRadios.map((radio) => radio.radioID),
          ['RADIO_2.4GHz', 'RADIO_5GHz']);
      expect(state.mainRadios.first.settings.ssid, 'fee_qa_velop');
      expect(state.guestRadios.map((radio) => radio.guestSSID),
          ['fee_guest_qa_velop', 'fee_guest_qa_velop']);
      expect(state.isGuestNetworkEnabled, isTrue);
    });

    test('shows the newest speed test, wherever the router lists it', () {
      start(_poll());

      final latest = dashboard().latestSpeedTest;
      expect(latest?.resultID, 16557);
      expect(latest?.timestamp, '2023-08-07T08:36:12Z');
      expect(latest?.speedTestResult?.downloadBandwidth, 93356);
      expect(dashboard().healthCheckModules, ['SpeedTest']);
    });

    test('reads the uptime, the load and the port links', () {
      start(_poll());

      final state = dashboard();
      expect(state.uptimes, 19555);
      expect(state.cpuLoad, '0.23');
      expect(state.memoryLoad, '0.79');
      expect(state.wanConnection, '1Gbps');
      expect(state.lanConnections, ['None', '1Gbps', 'None']);
    });

    test('reads the router\'s wall-clock time and its SKU', () {
      start(_poll());

      final time = DateTime.fromMillisecondsSinceEpoch(dashboard().localTime);
      expect([time.year, time.month, time.day], [2024, 12, 25]);
      expect([time.hour, time.minute, time.second], [15, 34, 42]);
      expect(dashboard().skuModelNumber, 'LN16-EU');
    });
  });

  group('written out and read back', () {
    test('survives a trip through JSON text', () {
      start(_poll());
      final state = dashboard();

      final restored = DashboardManagerState.fromJson(state.toJson());

      expect(restored, state);
      expect(
          restored.latestSpeedTest?.speedTestResult?.downloadBandwidth, 93356);
      expect(restored.deviceInfo?.services, _deviceInfo['services']);
    });

    test('writes what the router said under the state\'s own names', () {
      start(_poll());

      final map = dashboard().toMap();

      expect(map['uptimes'], 19555);
      expect(map['wanConnection'], '1Gbps');
      expect(map['lanConnections'], ['None', '1Gbps', 'None']);
      expect(map['skuModelNumber'], 'LN16-EU');
      expect(map['isGuestNetworkEnabled'], isTrue);
      expect((map['deviceInfo'] as Map)['serialNumber'], '20J2060A839173');
      expect((map['latestSpeedTest'] as Map)['resultID'], 16557);
      expect(map['healthCheckModules'], ['SpeedTest']);
    });

    test('leaves out what the router has not said', () {
      start({});

      final map = dashboard().toMap();

      expect(
          map.keys,
          isNot(anyOf(
              contains('deviceInfo'),
              contains('latestSpeedTest'),
              contains('wanConnection'),
              contains('skuModelNumber'),
              contains('cpuLoad'),
              contains('memoryLoad'))));
      expect(DashboardManagerState.fromJson(dashboard().toJson()), dashboard());
    });

    test('reads a map that lists no radios as having none', () {
      final state = DashboardManagerState.fromMap(const {
        'isGuestNetworkEnabled': false,
        'healthCheckModules': <String>[],
        'uptimes': 19555,
        'lanConnections': <String>[],
        'localTime': 1735083282000,
      });

      expect(state.mainRadios, isEmpty);
      expect(state.guestRadios, isEmpty);
      expect(state.uptimes, 19555);
      expect(
          state,
          const DashboardManagerState(
              uptimes: 19555, localTime: 1735083282000));
    });

    test('copyWith changes only what it names', () {
      start(_poll());
      final state = dashboard();

      final busier = state.copyWith(memoryLoad: '0.95');

      expect(busier.memoryLoad, '0.95');
      expect(busier.cpuLoad, '0.23');
      expect(busier, isNot(state));
      expect(busier.copyWith(memoryLoad: '0.79'), state);
    });
  });
}
