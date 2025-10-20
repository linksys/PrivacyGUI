import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';

import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

final dhcpReservationProvider = NotifierProvider.autoDispose<
    DHCPReservationsNotifier,
    DHCPReservationState>(() => DHCPReservationsNotifier());

class DHCPReservationsNotifier
    extends AutoDisposeNotifier<DHCPReservationState>
    with
        PreservableNotifierMixin<DHCPReservationsSettings,
            DHCPReservationsStatus, DHCPReservationState> {
  @override
  DHCPReservationState build() {
    return const DHCPReservationState(
      settings: DHCPReservationsSettings(
        reservations: [],
        additionalReservations: [],
      ),
      status: DHCPReservationsStatus(devices: []),
    );
  }

  @override
  Future<void> performFetch() async {
    final localNetworkSettings =
        await ref.read(localNetworkSettingProvider.notifier).fetch();
    final deviceList = ref.read(instantDeviceProvider).devices;

    state = state.copyWith(
      settings: state.settings.copyWith(
        reservations: localNetworkSettings.dhcpReservationList
            .map((e) => ReservedListItem(reserved: true, data: e))
            .toList(),
        additionalReservations: [],
      ),
      status: DHCPReservationsStatus(
        devices: deviceList
            .map((e) => ReservedListItem(
                  reserved: false,
                  data: DHCPReservation(
                    macAddress: e.macAddress,
                    ipAddress: e.ipv4Address,
                    description: e.name,
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  Future<void> performSave() async {
    final reservations = state.settings.reservations
        .where((e) => e.reserved)
        .map((e) => e.data)
        .toList();
    await ref
        .read(localNetworkSettingProvider.notifier)
        .saveReservations(reservations);
  }

  bool isConflict(ReservedListItem item) {
    return state.settings.reservations.any((e) =>
        e.reserved &&
        (e.data.macAddress == item.data.macAddress ||
            e.data.ipAddress == item.data.ipAddress));
  }

  void updateReservationItem(
      ReservedListItem editedItem, String? name, String? ip, String? mac) {
    final rList = state.settings.reservations;
    final index = rList.indexOf(editedItem);
    if (index >= 0) {
      final newRList = (List<ReservedListItem>.from(rList)
        ..replaceRange(
          index,
          index + 1,
          [
            editedItem.copyWith(
                data: editedItem.data.copyWith(
              macAddress: mac,
              ipAddress: ip,
              description: name,
            ))
          ],
        ));
      state = state.copyWith(
        settings: state.settings.copyWith(reservations: newRList),
      );
    }
  }

  void updateReservations(ReservedListItem item, [bool isNew = false]) {
    final rList = state.settings.reservations;
    final dList = state.status.devices;
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
        settings: state.settings.copyWith(reservations: newRList),
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
        settings: state.settings.copyWith(reservations: newRList),
      );
      return;
    }

    // new add
    final newRList = List<ReservedListItem>.from(rList)..add(item);
    state =
        state.copyWith(settings: state.settings.copyWith(reservations: newRList));
  }
}

final preservableDHCPReservationProvider = Provider.autoDispose<
    PreservableContract<DHCPReservationsSettings,
        DHCPReservationsStatus>>((ref) {
  return ref.watch(dhcpReservationProvider.notifier);
});
