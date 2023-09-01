import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/dhcp_reservations/dhcp_reservations_state.dart';

final dhcpReservationsProvider =
    NotifierProvider<DHCPReservationsNotifier, DHCPReservationsState>(
        () => DHCPReservationsNotifier());

class DHCPReservationsNotifier extends Notifier<DHCPReservationsState> {
  @override
  DHCPReservationsState build() => DHCPReservationsState.init();
}
