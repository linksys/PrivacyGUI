// The advanced settings routes (route_advanced_settings.dart): the page each
// one builds, and the arguments a push hands it.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/administration/views/administration_settings_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/port_range_forwarding_list_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/port_range_forwarding_rule_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/port_range_triggering_list_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/port_range_triggering_rule_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/single_port_forwarding_list_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/single_port_forwarding_rule_view.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/views/apps_and_gaming_view.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/views/dmz_settings_view.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/views/firewall_view.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/views/ipv6_port_service_list_view.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/views/ipv6_port_service_rule_view.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/views/dhcp_reservations_view.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_rule_view.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_view.dart';
import 'package:privacy_gui/route/constants.dart';

import 'app_route_builder.dart';

void main() {
  late AppRoutes routes;

  setUp(() => routes = AppRoutes());
  tearDown(() => routes.dispose());

  // dhcpReservationEdit and cardListEdit are left out: nothing navigates to
  // either (constitution 3.3's roster), so nothing in the app builds them.
  final pages = <String, TypeMatcher<Widget>>{
    RouteNamed.internetSettings: isA<InternetSettingsView>(),
    RouteNamed.settingsLocalNetwork: isA<LocalNetworkSettingsView>(),
    RouteNamed.settingsAppsGaming: isA<AppsGamingSettingsView>(),
  };

  final pagesWithArguments = <String, TypeMatcher<Widget>>{
    RouteNamed.dhcpReservation: isA<DHCPReservationsView>(),
    RouteNamed.singlePortForwardingList: isA<SinglePortForwardingListView>(),
    RouteNamed.singlePortForwardingRule: isA<SinglePortForwardingRuleView>(),
    RouteNamed.portRangeForwardingList: isA<PortRangeForwardingListView>(),
    RouteNamed.portRangeForwardingRule: isA<PortRangeForwardingRuleView>(),
    RouteNamed.portRangeTriggeringList: isA<PortRangeTriggeringListView>(),
    RouteNamed.portRangeTriggeringRule: isA<PortRangeTriggeringRuleView>(),
    RouteNamed.settingsFirewall: isA<FirewallView>(),
    RouteNamed.ipv6PortServiceList: isA<Ipv6PortServiceListView>(),
    RouteNamed.ipv6PortServiceRule: isA<Ipv6PortServiceRuleView>(),
    RouteNamed.settingsDMZ: isA<DMZSettingsView>(),
    RouteNamed.settingsAdministration: isA<AdministrationSettingsView>(),
    RouteNamed.settingsStaticRouting: isA<StaticRoutingView>(),
    RouteNamed.settingsStaticRoutingRule: isA<StaticRoutingRuleView>(),
  };

  for (final MapEntry(key: name, value: page) in pages.entries) {
    testWidgets('$name builds its page', (tester) async {
      expect(await routes.build(tester, name), page);
    });
  }

  for (final MapEntry(key: name, value: page) in pagesWithArguments.entries) {
    group(name, () {
      // A rule page is pushed with the rule to edit and the list's rules.
      testWidgets('hands its page the arguments it was pushed with',
          (tester) async {
        final extra = <String, dynamic>{
          'edit': {'description': 'NAS', 'externalPort': 8080},
          'items': <Map<String, dynamic>>[],
        };

        final built = await routes.build(tester, name, extra: extra);

        expect(built, page);
        expect(argsOf(built), extra);
      });

      testWidgets('opened by its URL, hands its page no arguments',
          (tester) async {
        final built = await routes.build(tester, name);

        expect(argsOf(built), isEmpty);
      });
    });
  }
}
