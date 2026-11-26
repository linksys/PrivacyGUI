// The PnP routes (route_pnp.dart): the setup flow and its troubleshooter,
// the page each one builds, and the arguments it passes on.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/pnp_admin_view.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_ipoe_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_auth_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_save_settings_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_pppoe_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_static_ip_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/route/constants.dart';

import 'app_route_builder.dart';

void main() {
  late AppRoutes routes;

  setUp(() => routes = AppRoutes());
  tearDown(() => routes.dispose());

  group('pnp', () {
    // The router's setup link opens PnP with its query, such as the
    // password printed on the router's label.
    testWidgets('hands the admin page its URL query and what it was pushed '
        'with', (tester) async {
      final built = await routes.build(tester, RouteNamed.pnp,
          extra: {'p': 'from-push', 'forceLogin': true},
          query: {'p': 'from-url'});

      expect(built, isA<PnpAdminView>());
      expect(argsOf(built), {'p': 'from-url', 'forceLogin': true});
    });

    testWidgets('opened by its URL alone, hands it the query', (tester) async {
      final built =
          await routes.build(tester, RouteNamed.pnp, query: {'p': 'label'});

      expect(argsOf(built), {'p': 'label'});
    });
  });

  final pages = <String, TypeMatcher<Widget>>{
    RouteNamed.pnpConfig: isA<PnpSetupView>(),
    RouteNamed.pnpUnplugModem: isA<PnpUnplugModemView>(),
    RouteNamed.pnpModemLightsOff: isA<PnpModemLightsOffView>(),
    RouteNamed.pnpWaitingModem: isA<PnpWaitingModemView>(),
    RouteNamed.pnpIspTypeSelection: isA<PnpIspTypeSelectionView>(),
    RouteNamed.pnpStaticIp: isA<PnpStaticIpView>(),
    RouteNamed.pnpIPoE: isA<PnpIpoeView>(),
  };

  final pagesWithArguments = <String, TypeMatcher<Widget>>{
    RouteNamed.pnpNoInternetConnection: isA<PnpNoInternetConnectionView>(),
    RouteNamed.pnpIspAuth: isA<PnpIspAuthView>(),
    RouteNamed.pnpIspSaveSettings: isA<PnpIspSaveSettingsView>(),
    RouteNamed.pnpPPPOE: isA<PnpPPPOEView>(),
  };

  for (final MapEntry(key: name, value: page) in pages.entries) {
    testWidgets('$name builds its page', (tester) async {
      expect(await routes.build(tester, name), page);
    });
  }

  for (final MapEntry(key: name, value: page) in pagesWithArguments.entries) {
    testWidgets('$name hands its page the arguments it was pushed with',
        (tester) async {
      final extra = <String, dynamic>{'ssid': 'Linksys00042'};

      final built = await routes.build(tester, name, extra: extra);

      expect(built, page);
      expect(argsOf(built), extra);
    });

    testWidgets('$name, opened by its URL, hands its page no arguments',
        (tester) async {
      expect(argsOf(await routes.build(tester, name)), isEmpty);
    });
  }
}
