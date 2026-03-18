import 'package:equatable/equatable.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_reservation_ui_model.dart';

/// Equatable wrapper for the list of DHCP reservations.
class DhcpReservationList extends Equatable {
  final List<DhcpReservationUIModel> reservations;

  const DhcpReservationList({this.reservations = const []});

  @override
  List<Object?> get props => [reservations];
}
