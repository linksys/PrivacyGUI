import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/local_network_settings_state.dart';

void main() {
  testLocalizations('DHCP reservations edit view test - Add DHCP reservation',
      (tester, locale) async {
    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      locale: locale,
      child: const DHCPReservationsEditView(
        args: {'viewType': 'add'},
      ),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('DHCP reservations edit view test - Edit DHCP reservation',
      (tester, locale) async {
    final mockState =
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      locale: locale,
      child: DHCPReservationsEditView(
        args: {
          'viewType': 'edit',
          'item': mockState.dhcpReservationList[1],
        },
      ),
    );
    await tester.pumpWidget(widget);
  });
}
