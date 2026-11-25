import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';

const _nas = ReservedListItem(
  reserved: true,
  data: DHCPReservation(
    macAddress: 'AA:BB:CC:DD:EE:01',
    ipAddress: '192.168.1.120',
    description: 'NAS',
  ),
);

const _state = DHCPReservationState(
  reservations: [_nas],
  additionalReservations: [],
  devices: [
    ReservedListItem(
        reserved: false,
        data: DHCPReservation(
          macAddress: 'AA:BB:CC:DD:EE:03',
          ipAddress: '192.168.1.130',
          description: 'Laptop',
        ))
  ],
);

void main() {
  test('survives a trip through JSON text', () {
    expect(DHCPReservationState.fromJson(_state.toJson()), _state);
    expect(ReservedListItem.fromJson(_nas.toJson()), _nas);
  });

  test('reads an item with no reserved flag as unreserved', () {
    final item = ReservedListItem.fromMap({'data': _nas.data.toMap()});

    expect(item.reserved, isFalse);
  });

  test('copyWith changes only what it names', () {
    expect(_state.copyWith(reservations: []).reservations, isEmpty);
    expect(_state.copyWith(), _state);
    expect(_nas.copyWith(reserved: false).reserved, isFalse);
    expect(_nas.copyWith(), _nas);
  });

  test('describes itself by its fields', () {
    expect(_state.toString(), contains('reservations: [ReservedListItem('));
    expect(_nas.toString(), contains('reserved: true'));
  });
}
