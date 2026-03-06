import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';

/// Looks up a single device + its DHCP reservation by MAC address.
final uspDeviceDetailProvider =
    Provider.family<DeviceDetailState, String>((ref, mac) {
  final state = ref.watch(uspDashboardProvider).valueOrNull;
  if (state == null) return DeviceDetailState.empty();
  final device = state.deviceModels.firstWhereOrNull(
    (d) => d.mac.toUpperCase() == mac.toUpperCase(),
  );
  final reservation = state.dhcpReservationModels.firstWhereOrNull(
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
