import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/dhcp_reservations/dhcp_reservations_state.dart';
import 'package:linksys_app/provider/troubleshooting/troubleshooting_provider.dart';

final dhcpReservationsProvider =
    NotifierProvider<DHCPReservationsNotifier, DHCPReservationsState>(
        () => DHCPReservationsNotifier());

class DHCPReservationsNotifier extends Notifier<DHCPReservationsState> {
  @override
  DHCPReservationsState build() =>
      const DHCPReservationsState(dhcpReservationList: [], dhcpClientList: []);

  // TODO refactor after LAN settings finish
  Future fetch({bool force = false}) async {
    final troubleshooting = ref.read(troubleshootingProvider.notifier);
    final dhcpClinetList = await troubleshooting
        .fetch(force: force)
        .then((_) => troubleshooting.state.dhcpClientList);

    final routerLanSettings = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getLANSettings, auth: true, fetchRemote: force)
        .then((value) => RouterLANSettings.fromJson(value.output));

    state = state.copyWith(
        dhcpReservationList: routerLanSettings.dhcpSettings.reservations,
        dhcpClientList: dhcpClinetList);
  }
}
