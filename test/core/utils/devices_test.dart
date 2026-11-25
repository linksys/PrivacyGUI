// The names, addresses and connection types the device lists, the topology
// and the dashboard show for a device (DeviceUtil, LinksysDeviceExt).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';

/// A client device as GetDevices3 lists it, with [overrides] merged in.
Map<String, dynamic> _deviceJson([Map<String, dynamic> overrides = const {}]) =>
    {
      ...jsonDecode('''
{
  "deviceID": "7f2a1c34-0000-4000-8000-a1b2c3d4e5f6",
  "lastChangeRevision": 812,
  "model": {"deviceType": "Mobile"},
  "unit": {},
  "isAuthority": false,
  "knownInterfaces": [
    {"macAddress": "A1:B2:C3:D4:E5:F6", "interfaceType": "Wireless", "band": "5GHz"}
  ],
  "connections": [
    {"macAddress": "A1:B2:C3:D4:E5:F6", "ipAddress": "192.168.1.120",
     "ipv6Address": "fe80::a3b2:c3ff:fed4:e5f6", "parentDeviceID": null}
  ],
  "properties": [],
  "maxAllowedProperties": 16
}
''') as Map<String, dynamic>,
      ...overrides,
    };

RawDevice _device([Map<String, dynamic> overrides = const {}]) =>
    RawDevice.fromMap(_deviceJson(overrides));

LinksysDevice _linksysDevice([Map<String, dynamic> overrides = const {}]) =>
    LinksysDevice.fromMap(_deviceJson(overrides));

List<Map<String, String>> _properties(Map<String, String> values) => [
      for (final MapEntry(:key, :value) in values.entries)
        {'name': key, 'value': value},
    ];

void main() {
  group('getDeviceLocation', () {
    test('is the location the user gave', () {
      final device = _device({
        'friendlyName': 'Pixel-7',
        'properties': _properties({
          'userDeviceLocation': 'Kitchen',
          'userDeviceName': 'My phone',
        }),
      });

      expect(device.getDeviceLocation(), 'Kitchen');
    });

    test('falls back to the device name when the location is empty', () {
      final device = _device({
        'friendlyName': 'Pixel-7',
        'properties': _properties({
          'userDeviceLocation': '',
          'userDeviceName': 'My phone',
        }),
      });

      expect(device.getDeviceLocation(), 'My phone');
    });
  });

  group('getDeviceName', () {
    test('is the name the user gave, above the host name', () {
      final device = _device({
        'friendlyName': 'Pixel-7',
        'properties': _properties({'userDeviceName': 'My phone'}),
      });

      expect(device.getDeviceName(), 'My phone');
    });

    test('skips an empty name the user gave', () {
      final device = _device({
        'friendlyName': 'Pixel-7',
        'properties': _properties({'userDeviceName': ''}),
      });

      expect(device.getDeviceName(), 'Pixel-7');
    });

    group('of an Android phone with a generic host name', () {
      for (final hostName in [
        'android-0123456789abcdef',
        'android-0123456789ABCDEF-extra',
        'Android',
        'Android-12',
      ]) {
        test('$hostName is its maker and model', () {
          final device = _device({
            'friendlyName': hostName,
            'model': {
              'deviceType': 'Mobile',
              'manufacturer': 'Samsung',
              'modelNumber': 'Galaxy S8',
            },
          });

          expect(device.getDeviceName(), 'Samsung Galaxy S8');
        });
      }

      test('reads the maker and model the user gave', () {
        final device = _device({
          'friendlyName': 'android-0123456789abcdef',
          'model': {'deviceType': 'Tablet'},
          'properties': _properties({
            'userDeviceManufacturer': 'Lenovo',
            'userDeviceModelNumber': 'Tab M10',
          }),
        });

        expect(device.getDeviceName(), 'Lenovo Tab M10');
      });

      test('without a maker or model is its system and type', () {
        final device = _device({
          'friendlyName': 'android-0123456789abcdef',
          'model': {'deviceType': 'Phone'},
          'unit': {'operatingSystem': 'Android Oreo'},
        });

        expect(device.getDeviceName(), 'Android Oreo Phone');
      });

      test('without a model or system keeps its host name', () {
        final device = _device({
          'friendlyName': 'android-0123456789abcdef',
          'model': {'deviceType': 'Mobile', 'manufacturer': 'Samsung'},
        });

        expect(device.getDeviceName(), 'android-0123456789abcdef');
      });
    });

    test('of an Android computer keeps its host name', () {
      final device = _device({
        'friendlyName': 'android-0123456789abcdef',
        'model': {
          'deviceType': 'Computer',
          'manufacturer': 'Samsung',
          'modelNumber': 'Galaxy Book',
        },
      });

      expect(device.getDeviceName(), 'android-0123456789abcdef');
    });

    test('of a host name that only looks like Android keeps it', () {
      final device = _device({
        'friendlyName': 'my-android-phone',
        'model': {
          'deviceType': 'Mobile',
          'manufacturer': 'Samsung',
          'modelNumber': 'Galaxy S8',
        },
      });

      expect(device.getDeviceName(), 'my-android-phone');
    });

    test('without a host name is its model number', () {
      final device = _device({
        'model': {'deviceType': 'Infrastructure', 'modelNumber': 'LN16'},
      });

      expect(device.getDeviceName(), 'LN16');
    });

    test('with nothing to go by is a network device', () {
      expect(_device().getDeviceName(), 'Network Device');
    });

    test('with nothing to go by, on the guest network, says so', () {
      final device = _device({
        'connections': [
          {'macAddress': 'A1:B2:C3:D4:E5:F6', 'isGuest': true},
        ],
      });

      expect(device.getDeviceName(), 'Guest Network Device');
    });
  });

  group('getMacAddress', () {
    test('is the first interface with a band or a known type', () {
      final device = _device({
        'knownInterfaces': [
          {'macAddress': '00:00:00:00:00:01', 'interfaceType': 'Unknown'},
          {'macAddress': '00:00:00:00:00:02', 'interfaceType': 'Wired'},
          {'macAddress': '00:00:00:00:00:03', 'interfaceType': 'Wireless'},
        ],
      });

      expect(device.getMacAddress(), '00:00:00:00:00:02');
    });

    test('takes an unknown interface that has a band', () {
      final device = _device({
        'knownInterfaces': [
          {
            'macAddress': '00:00:00:00:00:01',
            'interfaceType': 'Unknown',
            'band': '2.4GHz',
          },
        ],
      });

      expect(device.getMacAddress(), '00:00:00:00:00:01');
    });

    test('is the first interface when none is known', () {
      final device = _device({
        'knownInterfaces': [
          {'macAddress': '00:00:00:00:00:01', 'interfaceType': 'Unknown'},
          {'macAddress': '00:00:00:00:00:02', 'interfaceType': 'Unknown'},
        ],
      });

      expect(device.getMacAddress(), '00:00:00:00:00:01');
    });

    // A router without GetDevices3 lists MAC addresses, not interfaces.
    // Built directly: RawDevice.fromMap casts the list to List<String>, which
    // a decoded JSON list is not (see the report).
    test('on an older router, is the first MAC address it lists', () {
      final older = _device({'knownInterfaces': null}).copyWith(
          knownMACAddresses: ['00:00:00:00:00:0A', '00:00:00:00:00:0B']);

      expect(older.getMacAddress(), '00:00:00:00:00:0A');
      expect(older.copyWith(knownMACAddresses: []).getMacAddress(), '');
    });

    test('is empty when the router names neither', () {
      expect(_device({'knownInterfaces': null}).getMacAddress(), '');
    });
  });

  group('containsMacAddress', () {
    test('looks through the interfaces', () {
      final device = _device();

      expect(device.containsMacAddress('A1:B2:C3:D4:E5:F6'), isTrue);
      expect(device.containsMacAddress('00:00:00:00:00:01'), isFalse);
    });

    test('on an older router, looks through its MAC addresses', () {
      final older = _device({'knownInterfaces': null})
          .copyWith(knownMACAddresses: ['00:00:00:00:00:0A']);

      expect(older.containsMacAddress('00:00:00:00:00:0A'), isTrue);
      expect(older.containsMacAddress('00:00:00:00:00:0B'), isFalse);
    });

    test('finds nothing when the router names neither', () {
      expect(_device({'knownInterfaces': null}).containsMacAddress('A1'),
          isFalse);
    });
  });

  test('containsIpAddress and containsIpv6Address look through connections',
      () {
    final device = _device();

    expect(device.containsIpAddress('192.168.1.120'), isTrue);
    expect(device.containsIpAddress('192.168.1.121'), isFalse);
    expect(device.containsIpv6Address('fe80::a3b2:c3ff:fed4:e5f6'), isTrue);
    expect(device.containsIpv6Address('fe80::1'), isFalse);
  });

  group('getConnectionType', () {
    test('of a device with no connection is none', () {
      final device = _linksysDevice({'connections': []});

      expect(device.isOnline(), isFalse);
      expect(device.getConnectionType(), DeviceConnectionType.none);
    });

    test('of a client with a wireless interface is wireless', () {
      final device = _linksysDevice();

      expect(device.isOnline(), isTrue);
      expect(device.getConnectionType(), DeviceConnectionType.wireless);
    });

    test('of a client with only wired interfaces is wired', () {
      final device = _linksysDevice({
        'knownInterfaces': [
          {'macAddress': 'A1:B2:C3:D4:E5:F6', 'interfaceType': 'Wired'},
        ],
      });

      expect(device.getConnectionType(), DeviceConnectionType.wired);
    });

    group('of a node', () {
      test('on a wireless backhaul is wireless', () {
        final node = _linksysDevice({
          'nodeType': 'Slave',
          'connectionType': 'Wireless',
          'wirelessConnectionInfo': {
            'radioID': '5GL',
            'channel': 40,
            'apRSSI': -67,
            'stationRSSI': -18,
            'apBSSID': '80:69:1A:BB:46:CE',
            'stationBSSID': '80:69:1A:BB:46:CC',
          },
        });

        expect(node.getConnectionType(), DeviceConnectionType.wireless);
      });

      test('that says wireless but has no wireless backhaul is wired', () {
        final node = _linksysDevice(
            {'nodeType': 'Slave', 'connectionType': 'Wireless'});

        expect(node.getConnectionType(), DeviceConnectionType.wired);
      });

      test('on a wired backhaul is wired, whatever its interfaces', () {
        final node =
            _linksysDevice({'nodeType': 'Slave', 'connectionType': 'Wired'});

        expect(node.getConnectionType(), DeviceConnectionType.wired);
      });
    });
  });
}
