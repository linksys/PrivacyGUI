// One row of the Troubleshooting page's device status list, as a map and as a
// value.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/troubleshooting/models/device_status.dart';

const _rowMap = <String, dynamic>{
  'name': 'Work Laptop',
  'mac': 'A4:BB:6D:00:00:10',
  'ipAddress': 'fd00::10',
  'connection': 'LAN',
  'type': 'ipv6',
};

void main() {
  test('reads each address type by name, and anything else as IPv4', () {
    expect(DeviceStatusType.reslove('ipv4'), DeviceStatusType.ipv4);
    expect(DeviceStatusType.reslove('ipv6'), DeviceStatusType.ipv6);
    expect(DeviceStatusType.reslove('IPv6'), DeviceStatusType.ipv4);
  });

  test('an IPv4 and an IPv6 row of one device differ by their type', () {
    final v4 = DeviceStatusModel.ipv4(
        name: 'Work Laptop',
        mac: 'A4:BB:6D:00:00:10',
        ipAddress: '192.168.1.100',
        connection: 'LAN');
    final v6 = DeviceStatusModel.ipv6(
        name: 'Work Laptop',
        mac: 'A4:BB:6D:00:00:10',
        ipAddress: 'fd00::10',
        connection: 'LAN');

    expect(v4.type, DeviceStatusType.ipv4);
    expect(v6.type, DeviceStatusType.ipv6);
    expect(v6.toMap(), _rowMap);
  });

  test('reads back from the map and the JSON it writes', () {
    final row = DeviceStatusModel.fromMap(_rowMap);

    expect(row.type, DeviceStatusType.ipv6);
    expect(row.toMap(), _rowMap);
    expect(DeviceStatusModel.fromJson(row.toJson()), row);
  });

  test('a row read twice is the same row; a change to any field is not', () {
    final row = DeviceStatusModel.fromMap(_rowMap);

    expect(DeviceStatusModel.fromMap(_rowMap), row);
    for (final edited in [
      row.copyWith(name: 'Other'),
      row.copyWith(mac: '00:00:00:00:00:01'),
      row.copyWith(ipAddress: '192.168.1.100'),
      row.copyWith(connection: 'Wireless'),
      row.copyWith(type: DeviceStatusType.ipv4),
    ]) {
      expect(edited, isNot(row));
    }
  });

  test('an edit keeps the fields it does not name', () {
    final row = DeviceStatusModel.fromMap(_rowMap);

    expect(row.copyWith(connection: 'Wireless').toMap(),
        {..._rowMap, 'connection': 'Wireless'});
  });
}
