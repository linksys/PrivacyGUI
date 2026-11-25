// The Devices page's filter: which nodes, networks and bands it offers, and
// which clients each choice leaves on the list.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';

import '../../../common/recording_polling.dart';
import 'home_network_poll.dart';

/// The iPhone moved to the bedroom node's 6 GHz, a band the router's own
/// radios do not list.
Map<String, dynamic> _phoneOn6GHz() {
  final connections = nodesWirelessConnections();
  final bedroom = (connections['nodeWirelessConnections'] as List)[1]
      as Map<String, dynamic>;
  final phone = (bedroom['connections'] as List).single as Map<String, dynamic>;
  (phone['wireless'] as Map<String, dynamic>)
    ..['band'] = '6GHz'
    ..['radioID'] = 'RADIO_6GHz';
  return connections;
}

/// A client online under a node the router does not list.
Map<String, dynamic> _orphan() => {
      ...laptopDevice(),
      'deviceID': 'orphan',
      'knownInterfaces': [
        {'macAddress': '02:00:00:00:00:99', 'interfaceType': 'Wired'},
      ],
      'connections': [
        {
          'macAddress': '02:00:00:00:00:99',
          'ipAddress': '192.168.1.150',
          'parentDeviceID': 'gone',
        },
      ],
      'properties': <Object>[],
    };

void main() {
  late ProviderContainer container;

  void pollReports(Map<JNAPAction, dynamic> poll) {
    container = ProviderContainer(overrides: [
      pollingProvider.overrideWith(() => RecordingPolling(poll.cast())),
    ]);
    addTearDown(container.dispose);
  }

  DeviceFilterConfigNotifier filter() =>
      container.read(deviceFilterConfigProvider.notifier);
  DeviceFilterConfigState config() =>
      container.read(deviceFilterConfigProvider);
  List<String> shown() => [
        for (final device in container.read(filteredDeviceListProvider))
          device.deviceId
      ];

  setUp(() => pollReports(homeNetworkPoll()));

  group('initFilter', () {
    test('offers every node, both networks and every band in use', () {
      filter().initFilter();

      expect(config().connectionFilter, isTrue);
      expect(config().nodeFilter, ['master', 'bedroom']);
      expect(config().wifiFilter, ['Home', 'Home-Guest'],
          reason: 'each main network name once, then the guest network');
      expect(config().bandFilter, ['2.4GHz', '5GHz', 'Ethernet']);
      expect(config().showOrphanNodes, isFalse);
    });

    test('also offers a band only a client uses', () {
      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getNodesWirelessNetworkConnections: _phoneOn6GHz(),
      }));

      filter().initFilter();

      expect(config().bandFilter,
          unorderedEquals(['2.4GHz', '5GHz', '6GHz', 'Ethernet']));
    });

    test("on a node's page offers that node, and only its clients' bands", () {
      pollReports(homeNetworkPoll(extra: {
        JNAPAction.getNodesWirelessNetworkConnections: _phoneOn6GHz(),
      }));

      filter().initFilter(preselectedNodeId: ['master']);

      expect(config().nodeFilter, ['master']);
      expect(
          config().bandFilter, unorderedEquals(['2.4GHz', '5GHz', 'Ethernet']));

      filter().initFilter(preselectedNodeId: ['bedroom']);

      expect(config().nodeFilter, ['bedroom']);
      expect(config().bandFilter, contains('6GHz'));
    });

    test('offers a no-node entry while a client is online under no node', () {
      pollReports(homeNetworkPoll(devices: [
        masterDevice(),
        laptopDevice(),
        _orphan(),
      ]));

      filter().initFilter();

      expect(config().showOrphanNodes, isTrue);
      expect(config().nodeFilter, ['master', '']);
      expect(shown(), unorderedEquals(['laptop', 'orphan']));
    });
  });

  group('the filtered list', () {
    setUp(() => filter().initFilter());

    test('shows the online clients on every node, network and band', () {
      expect(shown(), unorderedEquals(['laptop', 'phone', 'tablet']));
    });

    test('the offline view shows the offline clients, whatever else is set',
        () {
      filter()
        ..updateConnectionFilter(false)
        ..updateNodeFilter([])
        ..updateWifiFilter([])
        ..updateBandFilter([]);

      expect(shown(), ['printer']);
    });

    test('leaves out the clients of a node left out', () {
      filter().updateNodeFilter(['master']);

      expect(shown(), unorderedEquals(['laptop', 'tablet']));
    });

    test('leaves out the Wi-Fi clients of a network left out, not wired ones',
        () {
      filter().updateWifiFilter(['Home']);

      expect(shown(), unorderedEquals(['laptop', 'phone']));
    });

    test('leaves out the clients on a band left out', () {
      filter().updateBandFilter(['5GHz', 'Ethernet']);

      expect(shown(), unorderedEquals(['laptop', 'phone']));
    });
  });
}
