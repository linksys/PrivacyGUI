import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';

import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

final dhcpReservationProvider = NotifierProvider.autoDispose<
    DHCPReservationsNotifier,
    DHCPReservationState>(() => DHCPReservationsNotifier());

class DHCPReservationsNotifier
    extends AutoDisposeNotifier<DHCPReservationState> {
  @override
  build() => DHCPReservationState(
      reservations: const [],
      additionalReservations: const [],
      devices: const []);

  DHCPReservationState setReservations(List<DHCPReservation> reservedList) {
    state = state.copyWith(
      reservations: reservedList
          .map((e) => ReservedListItem(
              reserved: state.reservations
                      .firstWhereOrNull(
                          (r) => r.data.macAddress == e.macAddress)
                      ?.reserved ??
                  true,
              data: e))
          .toList(),
    );
    return state;
  }

  DHCPReservationState updateDevices(
      [List<DeviceListItem> deviceList = const []]) {
    state = state.copyWith(
        devices: deviceList
            .map((e) => ReservedListItem(
                reserved: false,
                data: DHCPReservation(
                    macAddress: e.macAddress,
                    ipAddress: e.ipv4Address,
                    description: e.name)))
            .toList(),
        additionalReservations: []);
    return state;
  }

  void updateReservations(ReservedListItem item, [bool isNew = false]) {
    final rList = state.reservations;
    final dList = state.devices;
    var hit = rList
        .firstWhereOrNull((e) => e.data.macAddress == item.data.macAddress);
    final index = rList.indexOf(item);
    if (hit != null && index >= 0) {
      // This item is found on reservations list, so it is reserved.
      final isInDevice =
          dList.any((e) => e.data.macAddress == hit?.data.macAddress);
      final newRList = isInDevice
          ? (List<ReservedListItem>.from(rList)..removeAt(index))
          : (List<ReservedListItem>.from(rList)
            ..replaceRange(
              index,
              index + 1,
              [item.copyWith(reserved: !item.reserved)],
            ));
      state = state.copyWith(
        reservations: newRList,
        // devices: dList
        //     .where((e) =>
        //         !newRList.any((r) => r.data.macAddress == e.data.macAddress))
        //     .toList(),
      );
      return;
    }
    hit = dList.firstWhereOrNull((e) =>
        e.data.macAddress == item.data.macAddress &&
        e.data.ipAddress == item.data.ipAddress);

    if (hit != null) {
      // This item is found on device list, add into reserveation list
      final newRList = List<ReservedListItem>.from(rList)
        ..add(item.copyWith(
            reserved: isNew ? true : !item.reserved,
            data: item.data.copyWith(
                description: item.data.description
                    .replaceAll(HostNameRule().rule, ''))));
      state = state.copyWith(
        reservations: newRList,
        // devices: dList
        //     .where((e) =>
        //         !newRList.any((r) => r.data.macAddress == e.data.macAddress))
        //     .toList(),
      );
      return;
    }

    // new add
    final newRList = List<ReservedListItem>.from(rList)..add(item);
    state = state.copyWith(reservations: newRList);
  }
}
