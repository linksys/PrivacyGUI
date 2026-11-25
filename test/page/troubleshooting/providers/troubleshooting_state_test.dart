// The Troubleshooting page's state as a map and as a value.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/troubleshooting/models/device_status.dart';
import 'package:privacy_gui/page/troubleshooting/models/dhcp_client.dart';
import 'package:privacy_gui/page/troubleshooting/providers/troubleshooting_state.dart';

const _statusRow = <String, dynamic>{
  'name': 'Work Laptop',
  'mac': 'A4:BB:6D:00:00:10',
  'ipAddress': '192.168.1.100',
  'connection': 'LAN',
  'type': 'ipv4',
};

const _dhcpRow = <String, dynamic>{
  'name': 'Work Laptop',
  'mac': 'A4:BB:6D:00:00:10',
  'interface': 'LAN',
  'ipAddress': '192.168.1.100',
  'expires': '23:59:30',
};

TroubleshootingState _state() => TroubleshootingState(
      deviceStatusList: [DeviceStatusModel.fromMap(_statusRow)],
      dhcpClientList: [DhcpClientModel.fromMap(_dhcpRow)],
    );

void main() {
  test('writes both lists as rows of maps', () {
    expect(_state().toMap(), {
      'deviceStatusList': [_statusRow],
      'dhchClientList': [_dhcpRow],
    });
  });

  test('a state read twice is the same state; a changed list is not', () {
    final state = _state();

    expect(_state(), state);
    expect(state.copyWith(deviceStatusList: []), isNot(state));
    expect(state.copyWith(dhchClientList: []), isNot(state));
  });

  test('an edit to one list keeps the other', () {
    final state = _state();

    expect(state.copyWith(deviceStatusList: []).dhcpClientList,
        same(state.dhcpClientList));
    expect(state.copyWith(dhchClientList: []).deviceStatusList,
        same(state.deviceStatusList));
  });
}
