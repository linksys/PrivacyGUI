import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

final dhcpReservationProvider =
    NotifierProvider.autoDispose<DHCPReservationsNotifier, DHCPReservationState>(
        () => DHCPReservationsNotifier());

// The provider now needs to be generic to match the contract.
final preservableDHCPReservationsProvider =
    Provider.autoDispose<PreservableContract<DHCPReservationsSettings, DHCPReservationsStatus>>(
        (ref) {
  return ref.watch(dhcpReservationProvider.notifier);
});

class DHCPReservationsNotifier extends AutoDisposeNotifier<DHCPReservationState>
    with
        PreservableAutoDisposeNotifierMixin<DHCPReservationsSettings,
            DHCPReservationsStatus, DHCPReservationState> {
  @override
  DHCPReservationState build() => DHCPReservationState.init();

  @override
  bool updateShouldNotify(DHCPReservationState previous, DHCPReservationState next) {
    return previous != next;
  }

  @override
  set state(DHCPReservationState newState) {
    super.state = newState;
  }

  @override
  Future<(DHCPReservationsSettings?, DHCPReservationsStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    // The initial state is set from the LocalNetworkSettingsNotifier, so this should not be called directly.
    // However, to comply with the mixin, we must implement it.
    return (state.settings.current, null);
  }

  @override
  Future<void> performSave() async {
    final settings = state.settings.current;
    final reservations =
        settings.reservations.where((e) => e.reserved).map((e) => e.data).toList();
    await ref
        .read(localNetworkSettingProvider.notifier)
        .saveReservations(reservations);
  }

  void setInitialReservations(List<DHCPReservation> reservedList) {
    final initialSettings = DHCPReservationsSettings(
        reservations: reservedList
            .map((e) => ReservedListItem(reserved: true, data: e))
            .toList());
    state = state.copyWith(
        settings: Preservable(
            original: initialSettings, current: initialSettings));
  }

  void updateSettings(DHCPReservationsSettings newSettings) {
    state = state.copyWith(
      settings: state.settings.copyWith(current: newSettings),
    );
  }

  void updateDevices([List<DeviceListItem> deviceList = const []]) {
    state = state.copyWith(
        status: state.status.copyWith(
            devices: deviceList
                .map((e) => ReservedListItem(
                    reserved: false,
                    data: DHCPReservation(
                        macAddress: e.macAddress,
                        ipAddress: e.ipv4Address,
                        description: e.name)))
                .toList(),
            additionalReservations: []));
  }

  bool isConflict(ReservedListItem item) {
    return state.settings.current.reservations.any((e) =>
        e.reserved &&
        (e.data.macAddress == item.data.macAddress ||
            e.data.ipAddress == item.data.ipAddress));
  }

  void updateReservationItem(
      ReservedListItem editedItem, String? name, String? ip, String? mac) {
    final rList = state.settings.current.reservations;
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
      updateSettings(state.settings.current.copyWith(reservations: newRList));
    }
  }

  void updateReservations(ReservedListItem item, [bool isNew = false]) {
    final rList = state.settings.current.reservations;
    final dList = state.status.devices;
    var hit =
        rList.firstWhereOrNull((e) => e.data.macAddress == item.data.macAddress);
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
      updateSettings(state.settings.current.copyWith(reservations: newRList));
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
      updateSettings(state.settings.current.copyWith(reservations: newRList));
      return;
    }

    // new add
    final newRList = List<ReservedListItem>.from(rList)..add(item);
    updateSettings(state.settings.current.copyWith(reservations: newRList));
  }
}