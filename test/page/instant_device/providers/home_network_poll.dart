// A small home network as one poll reports it, for the pages that read the
// device manager and the dashboard manager.
//
// The input is the poll itself, a Map<JNAPAction, JNAPResult> as
// RecordingPolling hands it out, so the managers' createState runs for real
// (#1922 decodes the poll in one place; tests fed by the poll survive that).
//
// The network: an MX4200 in the living room with an MX4200 node in the
// bedroom, backhauled over 5 GHz. On the main network a wired laptop on the
// router and an iPhone on the node's 5 GHz; on the guest network a tablet on
// the router's 2.4 GHz; and a printer that is offline.

import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

const masterMac = '80:69:1A:00:00:01';
const bedroomMac = '80:69:1A:00:00:02';
const laptopMac = 'A4:BB:6D:00:00:10';
const phoneMac = 'D2:60:CB:00:00:20';
const tabletMac = '3C:22:FB:00:00:30';
const printerMac = '00:1E:0B:00:00:40';

Map<String, dynamic> _property(String name, String value) =>
    {'name': name, 'value': value};

Map<String, dynamic> masterDevice() => {
      'deviceID': 'master',
      'lastChangeRevision': 10,
      'model': {
        'deviceType': 'Infrastructure',
        'manufacturer': 'Linksys',
        'modelNumber': 'MX4200',
        'hardwareVersion': '1',
        'description': 'Velop',
      },
      'unit': {
        'serialNumber': '59A10M21C00042',
        'firmwareVersion': '1.0.13.216019',
      },
      'isAuthority': true,
      'nodeType': 'Master',
      'knownInterfaces': [
        {'macAddress': masterMac, 'interfaceType': 'Wired'},
      ],
      'connections': [
        {'macAddress': masterMac, 'ipAddress': '192.168.1.1'},
      ],
      'properties': [_property('userDeviceLocation', 'Living Room')],
      'maxAllowedProperties': 16,
    };

Map<String, dynamic> bedroomNode({bool online = true}) => {
      'deviceID': 'bedroom',
      'lastChangeRevision': 11,
      'model': {
        'deviceType': 'Infrastructure',
        'manufacturer': 'Linksys',
        'modelNumber': 'MX4200',
        'hardwareVersion': '2',
        'description': 'Velop',
      },
      'unit': {
        'serialNumber': '59A10M21C00043',
        'firmwareVersion': '1.0.13.216020',
      },
      'isAuthority': false,
      'nodeType': 'Slave',
      'knownInterfaces': [
        {'macAddress': bedroomMac, 'interfaceType': 'Wireless', 'band': '5GHz'},
      ],
      'connections': [
        if (online)
          {
            'macAddress': bedroomMac,
            'ipAddress': '192.168.1.194',
            'parentDeviceID': 'master',
          },
      ],
      'properties': [_property('userDeviceLocation', 'Bedroom')],
      'maxAllowedProperties': 16,
    };

Map<String, dynamic> laptopDevice() => {
      'deviceID': 'laptop',
      'lastChangeRevision': 20,
      'model': {
        'deviceType': 'Computer',
        'manufacturer': 'Dell',
        'modelNumber': 'XPS 13',
      },
      'unit': {'operatingSystem': 'Windows'},
      'isAuthority': false,
      'knownInterfaces': [
        {'macAddress': laptopMac, 'interfaceType': 'Wired'},
      ],
      'connections': [
        {
          'macAddress': laptopMac,
          'ipAddress': '192.168.1.100',
          'ipv6Address': 'fd00::10',
          'parentDeviceID': 'master',
        },
      ],
      'properties': [_property('userDeviceName', 'Work Laptop')],
      'maxAllowedProperties': 16,
    };

Map<String, dynamic> phoneDevice({String? userDeviceType}) => {
      'deviceID': 'phone',
      'lastChangeRevision': 21,
      'model': {
        'deviceType': 'Phone',
        'manufacturer': 'Apple Inc.',
        'modelNumber': 'iPhone XR',
      },
      'unit': {'operatingSystem': 'iOS'},
      'isAuthority': false,
      'knownInterfaces': [
        {'macAddress': phoneMac, 'interfaceType': 'Wireless', 'band': '5GHz'},
      ],
      'connections': [
        {
          'macAddress': phoneMac,
          'ipAddress': '192.168.1.120',
          'parentDeviceID': 'bedroom',
        },
      ],
      'properties': [
        _property('userDeviceName', 'Alice iPhone'),
        if (userDeviceType != null) _property('userDeviceType', userDeviceType),
      ],
      'maxAllowedProperties': 16,
    };

Map<String, dynamic> tabletDevice() => {
      'deviceID': 'tablet',
      'lastChangeRevision': 22,
      'model': {'deviceType': 'Tablet', 'manufacturer': 'Samsung'},
      'unit': <String, dynamic>{},
      'isAuthority': false,
      'knownInterfaces': [
        {
          'macAddress': tabletMac,
          'interfaceType': 'Wireless',
          'band': '2.4GHz',
        },
      ],
      'connections': [
        {
          'macAddress': tabletMac,
          'ipAddress': '192.168.3.110',
          'parentDeviceID': 'master',
          'isGuest': true,
        },
      ],
      'properties': [_property('userDeviceName', 'Guest Tablet')],
      'maxAllowedProperties': 16,
    };

Map<String, dynamic> printerDevice() => {
      'deviceID': 'printer',
      'lastChangeRevision': 23,
      'model': {'deviceType': 'Printer', 'manufacturer': 'HP'},
      'unit': <String, dynamic>{},
      'isAuthority': false,
      'knownInterfaces': [
        {'macAddress': printerMac, 'interfaceType': 'Wired'},
      ],
      'connections': <Map<String, dynamic>>[],
      'properties': [_property('userDeviceName', 'Printer')],
      'maxAllowedProperties': 16,
    };

Map<String, dynamic> routerRadio(String radioID, {String ssid = 'Home'}) => {
      'radioID': radioID,
      'physicalRadioID': radioID == 'RADIO_2.4GHz' ? 'ath0' : 'ath1',
      'bssid':
          radioID == 'RADIO_2.4GHz' ? '80:69:1A:00:01:24' : '80:69:1A:00:01:50',
      'band': radioID == 'RADIO_2.4GHz' ? '2.4GHz' : '5GHz',
      'supportedModes': ['802.11mixed'],
      'supportedChannelsForChannelWidths': [
        {
          'channelWidth': 'Auto',
          'channels': [0, 1, 6, 11],
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
        'wpaPersonalSettings': {'passphrase': 'HomePass1!'},
      },
    };

Map<String, dynamic> guestRadioSettings({bool enabled = true}) => {
      'isGuestNetworkACaptivePortal': false,
      'isGuestNetworkEnabled': enabled,
      'radios': [
        for (final radioID in ['RADIO_2.4GHz', 'RADIO_5GHz'])
          {
            'radioID': radioID,
            'isEnabled': true,
            'broadcastGuestSSID': true,
            'guestSSID': 'Home-Guest',
            'guestWPAPassphrase': 'GuestPass1!',
            'canEnableRadio': true,
          },
      ],
    };

/// `GetNodesWirelessNetworkConnections`: the iPhone on the bedroom node's
/// 5 GHz, the tablet on the router's guest 2.4 GHz.
Map<String, dynamic> nodesWirelessConnections() => {
      'nodeWirelessConnections': [
        {
          'deviceID': 'master',
          'connections': [
            {
              'macAddress': tabletMac,
              'negotiatedMbps': 144,
              'timestamp': '2026-01-05T09:00:00Z',
              'wireless': {
                'bssid': '80:69:1A:00:01:25',
                'isGuest': true,
                'radioID': 'RADIO_2.4GHz',
                'band': '2.4GHz',
                'signalDecibels': -61,
              },
            },
          ],
        },
        {
          'deviceID': 'bedroom',
          'connections': [
            {
              'macAddress': phoneMac,
              'negotiatedMbps': 780,
              'timestamp': '2026-01-05T09:00:00Z',
              'wireless': {
                'bssid': '80:69:1A:00:02:50',
                'isGuest': false,
                'radioID': 'RADIO_5GHz',
                'band': '5GHz',
                'signalDecibels': -48,
                'isMLOCapable': true,
              },
            },
          ],
        },
      ],
    };

/// `GetBackhaulInfo`: the bedroom node on the router's 5 GHz.
Map<String, dynamic> backhaulInfo() => {
      'backhaulDevices': [
        {
          'deviceUUID': 'bedroom',
          'ipAddress': '192.168.1.194',
          'parentIPAddress': '192.168.1.1',
          'connectionType': 'Wireless',
          'wirelessConnectionInfo': {
            'radioID': '5GL',
            'channel': 44,
            'apRSSI': -40,
            'stationRSSI': -42,
            'apBSSID': '80:69:1A:00:01:50',
            'stationBSSID': bedroomMac,
          },
          'speedMbps': '866.7',
          'timestamp': '2026-01-05T09:00:00Z',
        },
      ],
    };

Map<String, dynamic> wanStatus() => {
      'macAddress': '80:69:1A:00:00:00',
      'detectedWANType': 'DHCP',
      'wanStatus': 'Connected',
      'wanIPv6Status': 'Connecting',
      'wanConnection': {
        'wanType': 'DHCP',
        'ipAddress': '203.0.113.7',
        'networkPrefixLength': 24,
        'gateway': '203.0.113.1',
        'mtu': 1500,
        'dhcpLeaseMinutes': 1440,
        'dnsServer1': '203.0.113.53',
      },
      'supportedWANTypes': ['DHCP', 'Static', 'PPPoE'],
    };

Map<String, dynamic> deviceInfo({String modelNumber = 'MX4200'}) => {
      'manufacturer': 'Linksys',
      'modelNumber': modelNumber,
      'hardwareVersion': '1',
      'description': 'Velop',
      'serialNumber': '59A10M21C00042',
      'firmwareVersion': '1.0.13.216019',
      'firmwareDate': '2026-01-01T00:00:00Z',
      'services': ['http://linksys.com/jnap/core/Core'],
    };

JNAPSuccess _ok(Map<String, dynamic> output) =>
    JNAPSuccess(result: 'OK', output: output);

/// The poll, with [devices] in place of the whole network when given.
Map<JNAPAction, JNAPResult> homeNetworkPoll({
  List<Map<String, dynamic>>? devices,
  Map<JNAPAction, Map<String, dynamic>> extra = const {},
}) =>
    {
      JNAPAction.getDeviceInfo: _ok(deviceInfo()),
      JNAPAction.getDevices: _ok({
        'revision': 30,
        'devices': devices ??
            [
              masterDevice(),
              bedroomNode(),
              laptopDevice(),
              phoneDevice(),
              tabletDevice(),
              printerDevice(),
            ],
      }),
      JNAPAction.getNodesWirelessNetworkConnections:
          _ok(nodesWirelessConnections()),
      JNAPAction.getRadioInfo: _ok({
        'isBandSteeringSupported': false,
        'radios': [routerRadio('RADIO_2.4GHz'), routerRadio('RADIO_5GHz')],
      }),
      JNAPAction.getGuestRadioSettings: _ok(guestRadioSettings()),
      JNAPAction.getBackhaulInfo: _ok(backhaulInfo()),
      JNAPAction.getWANStatus: _ok(wanStatus()),
      for (final entry in extra.entries) entry.key: _ok(entry.value),
    };
