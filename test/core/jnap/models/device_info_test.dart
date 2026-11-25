import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';

/// `GetDeviceInfo` output as JSON text, from
/// test/test_data/core_transaction.dart with its services cut short.
const _velopText = '''
{
  "manufacturer": "Linksys",
  "modelNumber": "WHW03",
  "hardwareVersion": "2",
  "description": "Velop",
  "serialNumber": "20J2060A839173",
  "firmwareVersion": "2.1.20.213195",
  "firmwareDate": "2023-07-25T07:27:06Z",
  "services": [
    "http://linksys.com/jnap/core/Core",
    "http://linksys.com/jnap/devicelist/DeviceList4",
    "http://linksys.com/jnap/nodes/setup/Setup"
  ]
}
''';

Map<String, dynamic> _decode(String text) =>
    jsonDecode(text) as Map<String, dynamic>;

void main() {
  test('reads who the router is and the services it lists', () {
    final info = NodeDeviceInfo.fromJson(_decode(_velopText));

    expect(info.serialNumber, '20J2060A839173');
    expect(info.modelNumber, 'WHW03');
    expect(info.hardwareVersion, '2');
    expect(info.description, 'Velop');
    expect(info.manufacturer, 'Linksys');
    expect(info.firmwareVersion, '2.1.20.213195');
    expect(info.firmwareDate, '2023-07-25T07:27:06Z');
    expect(info.services, hasLength(3));
    expect(info.services.last, 'http://linksys.com/jnap/nodes/setup/Setup');
  });

  test('writes back what it read', () {
    final output = _decode(_velopText);

    expect(NodeDeviceInfo.fromJson(output).toJson(), output);
  });

  test('copyWith changes only what it names', () {
    final info = NodeDeviceInfo.fromJson(_decode(_velopText));

    final updated = info.copyWith(
      firmwareVersion: '2.1.21.215000',
      firmwareDate: '2024-01-10T00:00:00Z',
    );

    expect(updated.firmwareVersion, '2.1.21.215000');
    expect(updated.firmwareDate, '2024-01-10T00:00:00Z');
    expect(updated.serialNumber, info.serialNumber);
    expect(updated.services, info.services);
    expect(updated, isNot(info));
    expect(
        updated.copyWith(
            firmwareVersion: '2.1.20.213195',
            firmwareDate: '2023-07-25T07:27:06Z'),
        info);
  });
}
