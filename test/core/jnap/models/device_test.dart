import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';

/// A client from `GetDevices3` output, as JSON text arrives from the router,
/// with every optional field filled in. Shaped after
/// test/test_data/core_transaction.dart.
const _phoneText = '''
{
  "deviceID": "c5bb67a3-ad3a-4344-ade2-f487487af1f4",
  "lastChangeRevision": 6022,
  "model": {
    "deviceType": "Mobile",
    "manufacturer": "Samsung",
    "modelNumber": "SM-S9010",
    "hardwareVersion": "1",
    "modelDescription": "Galaxy S22"
  },
  "unit": {
    "serialNumber": "R5CT1234567",
    "firmwareVersion": "S9010ZCU2AWF1",
    "firmwareDate": "2023-06-01T00:00:00Z",
    "operatingSystem": "Android 13"
  },
  "isAuthority": false,
  "friendlyName": "Galaxy-S22",
  "knownInterfaces": [
    {"macAddress": "D2:60:CB:A0:3D:17", "interfaceType": "Wireless", "band": "5GHz"}
  ],
  "connections": [
    {
      "macAddress": "D2:60:CB:A0:3D:17",
      "ipAddress": "192.168.3.113",
      "ipv6Address": "fe80::d060:cbff:fea0:3d17",
      "parentDeviceID": "0b447477-5693-2b7e-8bbd-3023032eafee",
      "isGuest": true
    }
  ],
  "properties": [
    {"name": "userDeviceName", "value": "Hank's phone"}
  ],
  "maxAllowedProperties": 16
}
''';

/// The master node from the same output: a node type, and no optional field
/// it does not need.
const _masterText = '''
{
  "deviceID": "0b447477-5693-2b7e-8bbd-3023032eafee",
  "lastChangeRevision": 6022,
  "model": {"deviceType": "Infrastructure", "manufacturer": "Linksys", "modelNumber": "WHW03"},
  "unit": {"serialNumber": "20J2060A839173", "firmwareVersion": "2.1.20.213195"},
  "isAuthority": true,
  "nodeType": "Master",
  "connections": [{"macAddress": "30:23:03:2E:AF:EE", "ipAddress": "192.168.1.1"}],
  "properties": [],
  "maxAllowedProperties": 16
}
''';

Map<String, dynamic> _decode(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

void main() {
  group('RawDevice', () {
    test('reads the fields the device pages show', () {
      final phone = RawDevice.fromMap(_decode(_phoneText));

      expect(phone.deviceID, 'c5bb67a3-ad3a-4344-ade2-f487487af1f4');
      expect(phone.isAuthority, isFalse);
      expect(phone.nodeType, isNull);
      expect(phone.friendlyName, 'Galaxy-S22');
      expect(phone.model.deviceType, 'Mobile');
      expect(phone.unit.serialNumber, 'R5CT1234567');
      expect(phone.connections.single.ipAddress, '192.168.3.113');
      expect(phone.connections.single.isGuest, isTrue);
      expect(phone.knownInterfaces?.single.band, '5GHz');
      expect(phone.properties.single.value, 'Hank\'s phone');
      expect(phone.maxAllowedProperties, 16);
    });

    test('writes back what it read, naming the fields the router left out', () {
      final master = RawDevice.fromMap(_decode(_masterText));

      expect(master.toMap(), {
        'connections': [
          {
            'macAddress': '30:23:03:2E:AF:EE',
            'ipAddress': '192.168.1.1',
            'ipv6Address': null,
            'parentDeviceID': null,
            'isGuest': null,
          }
        ],
        'properties': <Object>[],
        'unit': {
          'serialNumber': '20J2060A839173',
          'firmwareVersion': '2.1.20.213195',
          'firmwareDate': null,
          'operatingSystem': null,
        },
        'deviceID': '0b447477-5693-2b7e-8bbd-3023032eafee',
        'maxAllowedProperties': 16,
        'model': {
          'deviceType': 'Infrastructure',
          'manufacturer': 'Linksys',
          'modelNumber': 'WHW03',
          'hardwareVersion': null,
          'modelDescription': null,
        },
        'isAuthority': true,
        'lastChangeRevision': 6022,
        'friendlyName': null,
        'knownInterfaces': null,
        'knownMACAddresses': null,
        'nodeType': 'Master',
      });
    });

    test('survives a trip through JSON text', () {
      final phone = RawDevice.fromJson(_phoneText);

      expect(RawDevice.fromJson(phone.toJson()), phone);
      expect(phone, isNot(RawDevice.fromJson(_masterText)));
    });

    test('reads a GetDevices device, which lists its MAC addresses', () {
      // Routers without DeviceList4 answer GetDevices: MAC addresses in
      // place of interfaces.
      final legacy = _decode(_masterText.replaceFirst(
          '"properties"',
          '"knownMACAddresses": ["30:23:03:2E:AF:EE", "30:23:03:2E:AF:EF"], '
              '"properties"'));

      final master = RawDevice.fromMap(legacy);

      expect(
          master.knownMACAddresses, ['30:23:03:2E:AF:EE', '30:23:03:2E:AF:EF']);
      expect(master.knownInterfaces, isNull);
    });

    test('names the OS, maker and model from the unit, or the user\'s own', () {
      final phone = RawDevice.fromMap(_decode(_phoneText));
      expect(phone.operatingSystem, 'Android 13');
      expect(phone.manufacturer, 'Samsung');
      expect(phone.modelNumber, 'SM-S9010');

      final unnamed = phone.copyWith(
        unit: const RawDeviceUnit(),
        model: const RawDeviceModel(deviceType: 'Mobile'),
        properties: const [
          RawDeviceProperty(name: 'userDeviceOS', value: 'iOS 15.1'),
          RawDeviceProperty(name: 'userDeviceManufacturer', value: 'Apple'),
          RawDeviceProperty(
              name: 'userDeviceModelNumber', value: 'iPhone 8 Plus'),
        ],
      );
      expect(unnamed.operatingSystem, 'iOS 15.1');
      expect(unnamed.manufacturer, 'Apple');
      expect(unnamed.modelNumber, 'iPhone 8 Plus');
    });

    test('copyWith changes only what it names', () {
      final master = RawDevice.fromMap(_decode(_masterText));

      final moved = master.copyWith(
        nodeType: 'Slave',
        isAuthority: false,
        friendlyName: 'Den',
        lastChangeRevision: 6023,
      );

      expect((moved.nodeType, moved.isAuthority, moved.friendlyName),
          ('Slave', false, 'Den'));
      expect(moved.deviceID, master.deviceID);
      expect(moved.connections, master.connections);
      expect(moved, isNot(master));
    });
  });

  group('the parts of a device', () {
    final phone = _decode(_phoneText);

    test('a connection reads what the router gives, and nothing it does not',
        () {
      final full = RawDeviceConnection.fromMap(
          (phone['connections'] as List).single as Map<String, dynamic>);
      final bare = RawDeviceConnection.fromMap(
          const {'macAddress': '80:1F:02:73:C5:D4'});

      expect(full.parentDeviceID, '0b447477-5693-2b7e-8bbd-3023032eafee');
      expect(full.ipv6Address, 'fe80::d060:cbff:fea0:3d17');
      expect((bare.ipAddress, bare.parentDeviceID, bare.isGuest),
          (null, null, null));
      expect(RawDeviceConnection.fromJson(full.toJson()), full);
      final moved = full.copyWith(ipAddress: '192.168.1.194');
      expect(full.copyWith(), full);
      expect(full.copyWith(ipAddress: '192.168.1.194'), isNot(full));
      expect(moved.ipAddress, '192.168.1.194');
      expect(moved.macAddress, full.macAddress);
    });

    test('a property', () {
      const property = RawDeviceProperty(name: 'userDeviceName', value: 'Den');

      expect(property.toMap(), {'name': 'userDeviceName', 'value': 'Den'});
      expect(RawDeviceProperty.fromJson(property.toJson()), property);
      expect(property.copyWith(value: 'Kitchen').value, 'Kitchen');
      expect(property.copyWith(value: 'Kitchen').name, 'userDeviceName');
      expect(property.copyWith(), property);
      expect(property.copyWith(value: 'Kitchen'), isNot(property));
    });

    test('a unit', () {
      final unit = RawDeviceUnit.fromMap(phone['unit'] as Map<String, dynamic>);

      expect(unit.firmwareDate, '2023-06-01T00:00:00Z');
      expect(RawDeviceUnit.fromJson(unit.toJson()), unit);
      final updated = unit.copyWith(firmwareVersion: 'S9010ZCU3AWG1');
      expect(unit.copyWith(), unit);
      expect(unit.copyWith(firmwareVersion: 'S9010ZCU3AWG1'), isNot(unit));
      expect(updated.firmwareVersion, 'S9010ZCU3AWG1');
      expect(updated.serialNumber, 'R5CT1234567');
    });

    test('a model', () {
      final model =
          RawDeviceModel.fromMap(phone['model'] as Map<String, dynamic>);

      expect(model.modelDescription, 'Galaxy S22');
      expect(model.hardwareVersion, '1');
      expect(RawDeviceModel.fromJson(model.toJson()), model);
      final retyped = model.copyWith(deviceType: 'Phone');
      expect(model.copyWith(), model);
      expect(model.copyWith(deviceType: 'Phone'), isNot(model));
      expect(retyped.deviceType, 'Phone');
      expect(retyped.manufacturer, 'Samsung');
    });

    test('a known interface', () {
      final known = RawDeviceKnownInterface.fromMap(
          (phone['knownInterfaces'] as List).single as Map<String, dynamic>);
      final unknown = RawDeviceKnownInterface.fromMap(const {
        'macAddress': '1E:40:07:7A:EF:F1',
        'interfaceType': 'Unknown',
      });

      expect((known.interfaceType, known.band), ('Wireless', '5GHz'));
      expect(unknown.band, isNull);
      expect(RawDeviceKnownInterface.fromJson(known.toJson()), known);
      expect(known.copyWith(band: '6GHz').band, '6GHz');
      expect(known.copyWith(band: '6GHz').macAddress, 'D2:60:CB:A0:3D:17');
      expect(known.copyWith(), known);
      expect(known.copyWith(band: '6GHz'), isNot(known));
    });
  });
}
