import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

/// Looks up a single device + its DHCP reservation by MAC address.
final uspDeviceDetailProvider =
    Provider.family<DeviceDetailState, String>((ref, mac) {
  final data = ref.watch(devicesDataProvider).valueOrNull;
  if (data == null) return DeviceDetailState.empty();
  final device = data.deviceModels.firstWhereOrNull(
    (d) => d.mac.toUpperCase() == mac.toUpperCase(),
  );
  final dhcpData = ref.watch(dhcpDataProvider).valueOrNull;
  final reservation = dhcpData?.reservationModels.firstWhereOrNull(
    (r) => r.mac.toUpperCase() == mac.toUpperCase(),
  );
  return DeviceDetailState(device: device, reservation: reservation);
});

/// Aggregated state for a single device's detail page.
class DeviceDetailState extends Equatable {
  final DeviceUIModel? device;
  final DhcpReservationUIModel? reservation;

  const DeviceDetailState({this.device, this.reservation});

  factory DeviceDetailState.empty() => const DeviceDetailState();

  bool get hasReservation => reservation != null;

  @override
  List<Object?> get props => [device, reservation];
}
