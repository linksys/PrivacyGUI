// One row of the Troubleshooting page's DHCP client list, as a map and as a
// value.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/troubleshooting/models/dhcp_client.dart';

const _rowMap = <String, dynamic>{
  'name': 'Work Laptop',
  'mac': 'A4:BB:6D:00:00:10',
  'interface': 'LAN',
  'ipAddress': '192.168.1.100',
  'expires': '23:59:30',
};

void main() {
  test('reads back from the map and the JSON it writes', () {
    final row = DhcpClientModel.fromMap(_rowMap);

    expect(row.interface, 'LAN');
    expect(row.expires, '23:59:30');
    expect(row.toMap(), _rowMap);
    expect(DhcpClientModel.fromJson(row.toJson()), row);
  });

  test('a row read twice is the same row; a change to any field is not', () {
    final row = DhcpClientModel.fromMap(_rowMap);

    expect(DhcpClientModel.fromMap(_rowMap), row);
    for (final edited in [
      row.copyWith(name: 'Other'),
      row.copyWith(mac: '00:00:00:00:00:01'),
      row.copyWith(interface: 'Offline'),
      row.copyWith(ipAddress: '192.168.1.101'),
      row.copyWith(expires: '00:00:01'),
    ]) {
      expect(edited, isNot(row));
    }
  });

  test('an edit keeps the fields it does not name', () {
    final row = DhcpClientModel.fromMap(_rowMap);

    expect(row.copyWith(interface: 'Offline').toMap(),
        {..._rowMap, 'interface': 'Offline'});
  });
}
