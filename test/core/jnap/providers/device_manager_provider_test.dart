// The device manager as every device and node page meets it: what it builds
// from a poll, what it answers about a device, and the writes it sends.
//
// The input is the poll as polling hands it over, a map of each action to the
// router's answer, through RecordingPolling. It is never one of the parsed
// snapshots in test/test_data/, which skip createState (#1922 P0). The router
// below is a Velop (WHW03) mesh with one satellite, shaped after
// test/test_data/core_transaction.dart.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_device_category.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';

const _masterId = '0b447477-5693-2b7e-8bbd-3023032eafee';
const _satelliteId = '2fce469a-2d48-6cf2-8b86-3023032ea4ea';
const _farSatelliteId = '5391a1d4-12fa-95c6-0b68-30230335e007';
const _guestPhoneId = 'c5bb67a3-ad3a-4344-ade2-f487487af1f4';
const _iPhoneId = '4dfda198-47f4-4eea-9162-588b7beb0322';
const _desktopId = 'b33c8e19-b4a5-40e7-888d-b669d2a2d6fa';
const _laptopId = '667f4f5b-8b9a-4724-9171-97e01952a740';
const _tabletId = 'cca5422a-8390-4bfb-84de-f0993f866b4f';
const _printerId = 'ac77eb3f-10b5-41cb-bcb7-d2a506127ac4';

const _guestPhoneMac = 'D2:60:CB:A0:3D:17';
const _iPhoneMac = '4A:2D:59:25:67:D7';
const _desktopMac = '80:1F:02:73:C5:D4';
const _laptop5GMac = 'F2:B7:56:06:DD:D9';
const _laptop6GMac = 'F2:B7:56:06:DD:DA';
const _satelliteBackhaulMac = '3A:23:03:2E:A4:EC';

Map<String, dynamic> _device(
  String id, {
  String? nodeType,
  bool isAuthority = false,
  String deviceType = 'Mobile',
  String? friendlyName,
  List<Map<String, dynamic>> connections = const [],
  List<Map<String, dynamic>> knownInterfaces = const [],
  List<Map<String, dynamic>> properties = const [],
}) =>
    {
      'deviceID': id,
      'lastChangeRevision': 6022,
      'model': {'deviceType': deviceType},
      'unit': <String, dynamic>{},
      'isAuthority': isAuthority,
      if (nodeType != null) 'nodeType': nodeType,
      if (friendlyName != null) 'friendlyName': friendlyName,
      'knownInterfaces': knownInterfaces,
      'connections': connections,
      'properties': properties,
      'maxAllowedProperties': 16,
    };

/// `GetDevices3` output. The router lists the nodes among the clients, in no
/// particular order.
final _devices = {
  'revision': 6022,
  'devices': [
    _device(_guestPhoneId, connections: [
      {
        'macAddress': _guestPhoneMac,
        'ipAddress': '192.168.3.113',
        'parentDeviceID': _masterId,
      }
    ], knownInterfaces: [
      {
        'macAddress': _guestPhoneMac,
        'interfaceType': 'Wireless',
        'band': '5GHz'
      }
    ]),
    _device(_satelliteId,
        nodeType: 'Slave',
        deviceType: 'Infrastructure',
        friendlyName: 'LINKSYS38609',
        // A stale address: the backhaul has the one in use.
        connections: [
          {'macAddress': '30:23:03:2E:A4:EA', 'ipAddress': '192.168.1.110'}
        ],
        knownInterfaces: [
          {'macAddress': '36:23:03:2E:A4:ED', 'interfaceType': 'Unknown'},
          {'macAddress': '30:23:03:2E:A4:EA', 'interfaceType': 'Unknown'},
          {
            'macAddress': _satelliteBackhaulMac,
            'interfaceType': 'Wireless',
            'band': '5GHz'
          },
        ],
        properties: [
          {'name': 'userDeviceLocation', 'value': 'Behind Hank'},
          {'name': 'userDeviceName', 'value': 'Behind Hank'},
        ]),
    _device(_desktopId, deviceType: 'Computer', connections: [
      {
        'macAddress': _desktopMac,
        'ipAddress': '192.168.1.50',
        'parentDeviceID': _masterId,
      }
    ], knownInterfaces: [
      {'macAddress': _desktopMac, 'interfaceType': 'Wired'}
    ]),
    _device(_masterId,
        nodeType: 'Master',
        isAuthority: true,
        deviceType: 'Infrastructure',
        friendlyName: 'Linksys39173',
        connections: [
          {'macAddress': '30:23:03:2E:AF:EE', 'ipAddress': '192.168.1.1'}
        ],
        knownInterfaces: [
          {'macAddress': '30:23:03:2E:AF:EE', 'interfaceType': 'Wired'}
        ],
        properties: [
          {'name': 'userDeviceLocation', 'value': 'Hank Table Test'},
          {'name': 'userDeviceName', 'value': 'Hank Table Test'},
        ]),
    // Out of the master's reach: it backhauls through the first satellite.
    _device(_farSatelliteId,
        nodeType: 'Slave',
        deviceType: 'Infrastructure',
        friendlyName: 'LINKSYS35E00',
        connections: [
          {'macAddress': '30:23:03:35:E0:07', 'ipAddress': '192.168.1.195'}
        ],
        knownInterfaces: [
          {
            'macAddress': '3A:23:03:35:E0:09',
            'interfaceType': 'Wireless',
            'band': '5GHz'
          },
        ]),
    _device(_tabletId, friendlyName: '192-168-1-249', knownInterfaces: [
      {
        'macAddress': '0E:A9:5B:A3:C0:72',
        'interfaceType': 'Wireless',
        'band': '5GHz'
      }
    ], properties: [
      {'name': 'userDeviceOS', 'value': 'Android 13'},
      {'name': 'userDeviceManufacturer', 'value': 'Samsung'},
    ]),
    _device(_iPhoneId,
        friendlyName: 'Taiwan-Linksys-Peter-iPhone 8 Plus-7B5C8',
        connections: [
          {
            'macAddress': _iPhoneMac,
            'ipAddress': '192.168.1.120',
            'parentDeviceID': _satelliteId,
          }
        ],
        knownInterfaces: [
          {
            'macAddress': _iPhoneMac,
            'interfaceType': 'Wireless',
            'band': '5GHz'
          }
        ]),
    _device(_laptopId, deviceType: 'Computer', connections: [
      {
        'macAddress': _laptop5GMac,
        'ipAddress': '192.168.1.130',
        'parentDeviceID': _masterId,
      }
    ], knownInterfaces: [
      {'macAddress': _laptop5GMac, 'interfaceType': 'Wireless', 'band': '5GHz'},
      {'macAddress': _laptop6GMac, 'interfaceType': 'Wireless', 'band': '6GHz'},
    ]),
    _device(_printerId, deviceType: 'Printer', knownInterfaces: [
      {'macAddress': '16:0F:B6:EE:17:B3', 'interfaceType': 'Wired'}
    ]),
  ],
};

Map<String, dynamic> _wireless(
  String bssid, {
  required String radioID,
  required String band,
  required int signal,
  bool isGuest = false,
  bool? isMLOCapable,
}) =>
    {
      'bssid': bssid,
      'isGuest': isGuest,
      'radioID': radioID,
      'band': band,
      'signalDecibels': signal,
      if (isMLOCapable != null) 'isMLOCapable': isMLOCapable,
    };

/// `GetNetworkConnections2` output: the link each client is on.
final _networkConnections = {
  'connections': [
    {
      'macAddress': _guestPhoneMac,
      'negotiatedMbps': 780,
      'wireless': _wireless('36:23:03:2E:AF:F0',
          radioID: 'RADIO_5GHz', band: '5GHz', signal: -47, isGuest: true),
    },
    {
      'macAddress': _iPhoneMac,
      'negotiatedMbps': 866,
      'wireless': _wireless('30:23:03:35:E0:09',
          radioID: 'RADIO_5GHz', band: '5GHz', signal: -62),
    },
    {'macAddress': _desktopMac, 'negotiatedMbps': 100},
    {
      'macAddress': _laptop5GMac,
      'negotiatedMbps': 1201,
      'wireless': _wireless('30:23:03:2E:AF:F0',
          radioID: 'RADIO_5GHz', band: '5GHz', signal: -51, isMLOCapable: true),
    },
    {
      'macAddress': _laptop6GMac,
      'negotiatedMbps': 2402,
      'wireless': _wireless('30:23:03:2E:AF:F4',
          radioID: 'RADIO_6GHz', band: '6GHz', signal: -58, isMLOCapable: true),
    },
  ],
};

/// `GetBackhaulInfo2` output: the satellite reaches the master over 5 GHz, and
/// the far satellite reaches the satellite over a cable.
final _backhaul = {
  'backhaulDevices': [
    {
      'deviceUUID': _satelliteId,
      'ipAddress': '192.168.1.194',
      'parentIPAddress': '192.168.1.1',
      'connectionType': 'Wireless',
      'wirelessConnectionInfo': {
        'radioID': '5GL',
        'channel': 44,
        'apRSSI': -23,
        'stationRSSI': -14,
        'apBSSID': '30:23:03:2E:AF:F0',
        'stationBSSID': _satelliteBackhaulMac,
      },
      'speedMbps': '143.553',
      'timestamp': '2023-09-23T05:13:09Z',
    },
    {
      'deviceUUID': _farSatelliteId,
      'ipAddress': '192.168.1.195',
      'parentIPAddress': '192.168.1.194',
      'connectionType': 'Wired',
      'speedMbps': '940.112',
      'timestamp': '2023-09-23T05:13:09Z',
    },
  ],
};

final _wanStatus = {
  'supportedWANTypes': ['DHCP', 'Static', 'PPPoE', 'PPTP', 'L2TP', 'Bridge'],
  'supportedIPv6WANTypes': ['Automatic', 'PPPoE', 'Pass-through'],
  'supportedWANCombinations': [
    {'wanType': 'DHCP', 'wanIPv6Type': 'Automatic'},
  ],
  'isDetectingWANType': false,
  'detectedWANType': 'DHCP',
  'wanStatus': 'Connected',
  'wanConnection': {
    'wanType': 'DHCP',
    'ipAddress': '192.168.2.101',
    'networkPrefixLength': 24,
    'gateway': '192.168.2.1',
    'mtu': 0,
    'dhcpLeaseMinutes': 5256000,
    'dnsServer1': '192.168.2.1',
  },
  'wanIPv6Status': 'Connecting',
  'macAddress': '30:23:03:2E:AF:EE',
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

final _radioInfo = {
  'isBandSteeringSupported': true,
  'radios': [
    _radio('RADIO_2.4GHz', '2.4GHz', 'fee_qa_velop'),
    _radio('RADIO_5GHz', '5GHz', 'fee_qa_velop_5G'),
  ],
};

Map<String, dynamic> _guestRadio(String id) => {
      'radioID': id,
      'isEnabled': true,
      'broadcastGuestSSID': true,
      'guestSSID': 'fee_guest_qa_velop',
      'guestWPAPassphrase': 'TestWifi1!',
      'canEnableRadio': true,
    };

final _guestRadioSettings = {
  'isGuestNetworkACaptivePortal': false,
  'isGuestNetworkEnabled': true,
  'radios': [_guestRadio('RADIO_2.4GHz'), _guestRadio('RADIO_5GHz')],
};

/// [output] as the router's answer, after a trip through JSON text, as it
/// reaches the app: every list in it is a `List<dynamic>`.
JNAPSuccess _ok(Map<String, dynamic> output) => JNAPSuccess(
    result: 'OK',
    output: jsonDecode(jsonEncode(output)) as Map<String, dynamic>);

/// The core poll of a master with its mesh, as polling hands it over.
Map<JNAPAction, JNAPResult> _poll() => {
      JNAPAction.getNetworkConnections: _ok(_networkConnections),
      JNAPAction.getRadioInfo: _ok(_radioInfo),
      JNAPAction.getGuestRadioSettings: _ok(_guestRadioSettings),
      JNAPAction.getDevices: _ok(_devices),
      JNAPAction.getBackhaulInfo: _ok(_backhaul),
      JNAPAction.getWANStatus: _ok(_wanStatus),
    };

void main() {
  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;

  DeviceManagerNotifier notifier() =>
      container.read(deviceManagerProvider.notifier);
  DeviceManagerState devices() => container.read(deviceManagerProvider);
  LinksysDevice device(String id) =>
      devices().deviceList.firstWhere((device) => device.deviceID == id);
  Set<String> ids(Iterable<LinksysDevice> devices) =>
      {for (final device in devices) device.deviceID};

  void start(Map<JNAPAction, JNAPResult> poll) {
    polling = RecordingPolling(poll);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
  }

  setUp(() {
    router = RouterBoundary();
  });

  tearDown(() {
    container.dispose();
  });

  group('the state a poll builds', () {
    test('is empty before the router has answered a poll', () {
      start({});

      expect(devices().deviceList, isEmpty);
      expect(devices().wanStatus, isNull);
      expect(devices().guestRadioSettings, isNull);
      expect(devices().radioInfos, isEmpty);
      expect(notifier().isEmptyState(), isTrue);
    });

    test('lists the nodes first, the master ahead of its satellites', () {
      start(_poll());

      final list = devices().deviceList;
      expect(list.first.deviceID, _masterId);
      expect(ids(list.skip(1).take(2)), {_satelliteId, _farSatelliteId});
      expect(ids(list.skip(3)), {
        _guestPhoneId,
        _iPhoneId,
        _desktopId,
        _laptopId,
        _tabletId,
        _printerId,
      });
      expect(devices().masterDevice.deviceID, _masterId);
      expect(ids(devices().slaveDevices), {_satelliteId, _farSatelliteId});
      expect(notifier().isEmptyState(), isFalse);
    });

    test('gives each node the online clients that name it as their parent', () {
      start(_poll());

      expect(ids(device(_masterId).connectedDevices),
          {_guestPhoneId, _desktopId, _laptopId});
      expect(ids(device(_satelliteId).connectedDevices), {_iPhoneId});
      expect(device(_farSatelliteId).connectedDevices, isEmpty);
    });

    test('marks a client on the guest network as a guest device', () {
      start(_poll());

      expect(device(_guestPhoneId).connectedWifiType, WifiConnectionType.guest);
      expect(device(_iPhoneId).connectedWifiType, WifiConnectionType.main);
      expect(device(_desktopId).connectedWifiType, WifiConnectionType.main);
      expect(ids(devices().guestWifiDevices), {_guestPhoneId});
    });

    test('reads a wireless client\'s signal from its network connection', () {
      start(_poll());

      expect(device(_iPhoneId).signalDecibels, -62);
      expect(device(_guestPhoneId).signalDecibels, -47);
      expect(device(_desktopId).signalDecibels, isNull);
      // A node's own list of clients carries the same signal.
      final onSatellite = device(_satelliteId).connectedDevices.single;
      expect(onSatellite.signalDecibels, -62);
    });

    test('lists the radios a client can use at once (MLO)', () {
      start(_poll());

      expect(device(_laptopId).mloList, ['RADIO_5GHz', 'RADIO_6GHz']);
      expect(device(_iPhoneId).mloList, isEmpty);
    });

    test('takes a satellite\'s address, link and signal from its backhaul', () {
      start(_poll());

      final satellite = device(_satelliteId);
      expect(satellite.connections.single.ipAddress, '192.168.1.194');
      expect(satellite.connectionType, 'Wireless');
      expect(satellite.speedMbps, '143.553');
      expect(satellite.wirelessConnectionInfo?.channel, 44);
      expect(satellite.wirelessConnectionInfo?.apBSSID, '30:23:03:2E:AF:F0');
      expect(satellite.signalDecibels, -14);
      expect(satellite.getConnectionType(), DeviceConnectionType.wireless);
      expect(devices().backhaulInfoData.first.parentIPAddress, '192.168.1.1');
      // A wired backhaul has no radio link.
      final farSatellite = device(_farSatelliteId);
      expect(farSatellite.connectionType, 'Wired');
      expect(farSatellite.speedMbps, '940.112');
      expect(farSatellite.getConnectionType(), DeviceConnectionType.wired);
    });

    test('leaves a node with no backhaul entry as the router listed it', () {
      start(_poll()..remove(JNAPAction.getBackhaulInfo));

      final satellite = device(_satelliteId);
      expect(satellite.connections.single.ipAddress, '192.168.1.110');
      expect(satellite.speedMbps, '--');
      expect(satellite.wirelessConnectionInfo, isNull);
      expect(devices().backhaulInfoData, isEmpty);
    });

    test('links each device to the one upstream of it', () {
      start(_poll());

      // A satellite through its backhaul's parent address, a client through
      // the node it names.
      expect(device(_satelliteId).upstream?.deviceID, _masterId);
      expect(device(_farSatelliteId).upstream?.deviceID, _satelliteId);
      expect(device(_iPhoneId).upstream?.deviceID, _satelliteId);
      expect(device(_guestPhoneId).upstream?.deviceID, _masterId);
      expect(device(_masterId).upstream, isNull);
      // An offline client has no upstream.
      expect(device(_tabletId).upstream, isNull);
    });

    test('reads wireless links from the nodes\' own list when the poll has it',
        () {
      start(_poll()
        ..[JNAPAction.getNodesWirelessNetworkConnections] = _ok({
          'lastTriggered': '2023-09-22T05:02:15Z',
          'nodeWirelessConnections': [
            {
              'deviceID': _satelliteId,
              'connections': [
                {
                  'macAddress': _iPhoneMac,
                  'negotiatedMbps': 6,
                  'timestamp': '2023-09-04T02:34:37Z',
                  'wireless': _wireless('30:23:03:35:E0:09',
                      radioID: 'RADIO_5GHz', band: '5GHz', signal: -84),
                },
              ],
            },
          ],
        }));

      expect(device(_iPhoneId).signalDecibels, -84);
      // The plain network connections are not read at all then.
      expect(device(_guestPhoneId).signalDecibels, isNull);
      expect(device(_guestPhoneId).connectedWifiType, WifiConnectionType.main);
    });

    test('reads a router that lists MAC addresses, not interfaces (GetDevices)',
        () {
      // Routers without DeviceList4 answer GetDevices, which names each
      // device's MAC addresses instead of its interfaces.
      Map<String, dynamic> legacy(Map<String, dynamic> device) => Map.of(device)
        ..remove('knownInterfaces')
        ..['knownMACAddresses'] = [
          for (final connection in device['connections'] as List)
            (connection as Map)['macAddress'],
        ];
      final listed = _devices['devices'] as List<Map<String, dynamic>>;
      start(_poll()
        ..[JNAPAction.getDevices] = _ok({
          'revision': 6022,
          'devices': [
            legacy(
                listed.firstWhere((device) => device['deviceID'] == _masterId)),
            legacy(
                listed.firstWhere((device) => device['deviceID'] == _iPhoneId)),
          ],
        }));

      expect(device(_iPhoneId).knownMACAddresses, [_iPhoneMac]);
      expect(device(_iPhoneId).getMacAddress(), _iPhoneMac);
      expect(device(_iPhoneId).signalDecibels, -62);
    });

    test('reads the WAN status, the radios and the guest network', () {
      start(_poll());

      expect(devices().wanStatus?.wanStatus, 'Connected');
      expect(devices().wanStatus?.wanConnection?.ipAddress, '192.168.2.101');
      expect(devices().radioInfos.keys, {'RADIO_2.4GHz', 'RADIO_5GHz'});
      expect(devices().guestRadioSettings?.isGuestNetworkEnabled, isTrue);
      expect(devices().lastUpdateTime, 1);
    });
  });

  group('what it answers about a device', () {
    test('names the Wi-Fi network a client is on', () {
      start(_poll());

      expect(
          notifier().getSsidConnectedBy(device(_iPhoneId)), 'fee_qa_velop_5G');
      expect(notifier().getSsidConnectedBy(device(_guestPhoneId)),
          'fee_guest_qa_velop');
      expect(notifier().getSsidConnectedBy(device(_desktopId)), isNull);
    });

    test('names the band a client is on, or Ethernet for a wired one', () {
      start(_poll());

      expect(notifier().getBandConnectedBy(device(_iPhoneId)), '5GHz');
      expect(notifier().getBandConnectedBy(device(_desktopId)), 'Ethernet');
      // Offline, a client keeps the band of the interface the router knows.
      expect(notifier().getBandConnectedBy(device(_tabletId)), '5GHz');
      // Offline and wired, it has none.
      expect(notifier().getBandConnectedBy(device(_printerId)), '');
    });

    test('finds no parent for a device it does not know or that is offline',
        () {
      start(_poll());

      expect(notifier().findParent('not-a-device'), isNull);
      expect(notifier().findParent(_tabletId), isNull);
      expect(notifier().findParent(_iPhoneId)?.deviceID, _satelliteId);
    });

    test('init empties the list until the next poll', () {
      start(_poll());

      notifier().init();

      expect(notifier().isEmptyState(), isTrue);
    });
  });

  group('renaming a device', () {
    setUp(() {
      router.holds(JNAPAction.getDevices, _devices);
    });

    test('writes the name and, for a node, its location, then rereads devices',
        () async {
      start(_poll());

      await notifier().updateDeviceNameAndIcon(
          targetId: _satelliteId, newName: 'Kitchen', isLocation: true);

      expect(router.payloadsOf(JNAPAction.setDeviceProperties), [
        {
          'deviceID': _satelliteId,
          'propertiesToModify': [
            {'name': 'userDeviceName', 'value': 'Kitchen'},
            {'name': 'userDeviceLocation', 'value': 'Kitchen'},
          ],
        }
      ]);
      expect(router.actions,
          [JNAPAction.setDeviceProperties, JNAPAction.getDevices]);
      expect(device(_satelliteId).getDeviceLocation(), 'Kitchen');
      expect(device(_masterId).getDeviceLocation(), 'Hank Table Test');
    });

    test('writes the icon a user picks for a client', () async {
      start(_poll());

      await notifier().updateDeviceNameAndIcon(
        targetId: _iPhoneId,
        newName: 'Peter\'s phone',
        isLocation: false,
        icon: IconDeviceCategory.phone,
      );

      expect(
          router
              .payloadsOf(JNAPAction.setDeviceProperties)
              .single['propertiesToModify'],
          [
            {'name': 'userDeviceName', 'value': 'Peter\'s phone'},
            {'name': 'userDeviceType', 'value': 'phone'},
          ]);
      expect(device(_iPhoneId).getDeviceName(), 'Peter\'s phone');
    });

    test('keeps the old name when the router refuses the new one', () async {
      router.refuses(JNAPAction.setDeviceProperties);
      start(_poll());

      await expectLater(
          notifier().updateDeviceNameAndIcon(
              targetId: _satelliteId, newName: 'Kitchen', isLocation: true),
          throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setDeviceProperties]);
      expect(device(_satelliteId).getDeviceLocation(), 'Behind Hank');
    });
  });

  group('deleting devices', () {
    test('deletes them in one transaction, drops them, then polls', () async {
      router.holds(JNAPAction.deleteDevice, const {});
      start(_poll());

      await notifier().deleteDevices(deviceIds: [_tabletId, _printerId]);

      expect(router.transactions.single.map((command) => command.key),
          [JNAPAction.deleteDevice, JNAPAction.deleteDevice]);
      expect(router.payloadsOf(JNAPAction.deleteDevice), [
        {'deviceID': _tabletId},
        {'deviceID': _printerId},
      ]);
      expect(ids(devices().deviceList).intersection({_tabletId, _printerId}),
          isEmpty);
      expect(devices().deviceList, hasLength(7));
      expect(polling.forced, 1);
    });

    test('keeps every device when the router refuses', () async {
      router.failsTransactions(const JNAPError(result: 'ErrorUnknown'));
      start(_poll());

      await expectLater(notifier().deleteDevices(deviceIds: [_tabletId]),
          throwsA(isA<JNAPError>()));

      expect(ids(devices().deviceList), contains(_tabletId));
      expect(polling.forced, 0);
    });
  });

  group('disconnecting a client', () {
    test('sends the client\'s MAC address, then polls', () async {
      router.holds(JNAPAction.clientDeauth, const {});
      start(_poll());

      await notifier().deauthClient(macAddress: _iPhoneMac);

      expect(router.payloadsOf(JNAPAction.clientDeauth), [
        {'macAddress': _iPhoneMac}
      ]);
      expect(polling.forced, 1);
    });

    test('does not poll when the router refuses', () async {
      router.refuses(JNAPAction.clientDeauth);
      start(_poll());

      await expectLater(notifier().deauthClient(macAddress: _iPhoneMac),
          throwsA(isA<JNAPError>()));

      expect(polling.forced, 0);
    });
  });
}
