import 'package:privacy_gui/page/_framework/feature_state.dart';
import 'package:privacy_gui/page/_framework/preservable.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservation_list.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservations_status.dart';

/// Composed FeatureState for DHCP reservations.
class DhcpReservationsFeatureState
    extends FeatureState<DhcpReservationList, DhcpReservationsStatus> {
  const DhcpReservationsFeatureState({
    required super.settings,
    required super.status,
  });

  factory DhcpReservationsFeatureState.initial() {
    return DhcpReservationsFeatureState(
      settings: Preservable(
        original: const DhcpReservationList(),
        current: const DhcpReservationList(),
      ),
      status: const DhcpReservationsStatus(isLoading: true),
    );
  }

  @override
  DhcpReservationsFeatureState copyWith({
    Preservable<DhcpReservationList>? settings,
    DhcpReservationsStatus? status,
  }) {
    return DhcpReservationsFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
