import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/has_unconfirmed_rows.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';

/// Equatable wrapper for the list of DHCP reservations.
class DhcpReservationList extends Equatable implements HasUnconfirmedRows {
  final List<DhcpReservationUIModel> reservations;

  const DhcpReservationList({this.reservations = const []});

  /// A row added on the page has no path until the router creates it (#1212):
  /// while one is here and the read after a save failed, the next save reads
  /// the router before it writes.
  @override
  bool get hasUnconfirmedRows =>
      reservations.any((r) => r.instancePath == null);

  @override
  List<Object?> get props => [reservations];
}
