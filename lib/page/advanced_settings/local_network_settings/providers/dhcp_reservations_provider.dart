import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';

import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';

final dhcpReservationProvider = NotifierProvider.autoDispose<
    DHCPReservationsNotifier,
    DHCPReservationState>(() => DHCPReservationsNotifier());

class DHCPReservationsNotifier
    extends AutoDisposeNotifier<DHCPReservationState> {
  @override
  build() => init();

  DHCPReservationState init() {
    final List<DHCPReservation> reservedList = ref.read(
        localNetworkSettingProvider
            .select((state) => state.dhcpReservationList));
    final List<DeviceListItem> deviceList =
        ref.watch(filteredDeviceListProvider);
    state = DHCPReservationState(
        reservations: reservedList
            .map((e) => ReservedListItem(reserved: true, data: e))
            .toList(),
        devices: deviceList
            .where(
                (e) => !reservedList.any((r) => r.macAddress == e.macAddress))
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

  void updateReservations(ReservedListItem item) {
    final rList = state.reservations;
    final dList = state.devices;
    var hit = rList
        .firstWhereOrNull((e) => e.data.macAddress == item.data.macAddress);
    if (hit != null) {
      // This item is found on reservations list, so it is reserved.
      final index = rList.indexOf(item);
      state = state.copyWith(
          reservations: List.from(rList)
            ..replaceRange(
                index, index, [item.copyWith(reserved: !item.reserved)]));
      return;
    }
    hit = dList
        .firstWhereOrNull((e) => e.data.macAddress == item.data.macAddress);

    if (hit != null) {
      // This item is found on device list, add into reserveation list
      state = state.copyWith(
          reservations: List.from(rList)
            ..add(item.copyWith(reserved: !item.reserved)));
      return;
    }
  }
}
