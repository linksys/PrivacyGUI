import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/account/_account.dart';
import 'package:linksys_app/page/administration/firewall/_firewall.dart';
import 'package:linksys_app/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:linksys_app/page/administration/ip_details/_ip_details.dart';
import 'package:linksys_app/page/administration/port_forwarding/_port_forwarding.dart';
import 'package:linksys_app/page/administration/router_password/_router_password.dart';
import 'package:linksys_app/page/administration/timezone/_timezone.dart';
import 'package:linksys_app/page/components/picker/region_picker_view.dart';
import 'package:linksys_app/page/components/picker/simple_item_picker.dart';
import 'package:linksys_app/page/dashboard/_dashboard.dart';
import 'package:linksys_app/page/ddns/_ddns.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/health_check/_health_check.dart';
import 'package:linksys_app/page/landing/_landing.dart';

import 'package:linksys_app/page/linkup/views/linkup_view.dart';
import 'package:linksys_app/page/login/views/_views.dart';
import 'package:linksys_app/page/login/views/local_reset_router_password_view.dart';
import 'package:linksys_app/page/nodes/_nodes.dart';
import 'package:linksys_app/page/nodes/views/add_nodes_view.dart';
import 'package:linksys_app/page/notifications/notification_settings_page.dart';
import 'package:linksys_app/page/otp_flow/providers/_providers.dart';
import 'package:linksys_app/page/otp_flow/views/_views.dart';
import 'package:linksys_app/page/pnp/pnp_admin_view.dart';
import 'package:linksys_app/page/pnp/pnp_setup_view.dart';
import 'package:linksys_app/page/pnp/troubleshooter/pnp_lights_off.dart';
import 'package:linksys_app/page/pnp/troubleshooter/pnp_unplug_modem.dart';
import 'package:linksys_app/page/pnp/troubleshooter/pnp_waiting_modem.dart';
import 'package:linksys_app/page/safe_browsing/views/safe_browsing_view.dart';
import 'package:linksys_app/page/pnp/troubleshooter/pnp_no_internet_connection.dart';
import 'package:linksys_app/page/select_network/_select_network.dart';
import 'package:linksys_app/page/topology/_topology.dart';
import 'package:linksys_app/page/troubleshooting/_troubleshooting.dart';
import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';
import 'package:linksys_app/providers/auth/_auth.dart';
import 'package:linksys_app/route/route_model.dart';
import 'package:linksys_app/route/router_logger.dart';
import '../page/administration/local_network_settings/_local_network_settings.dart';
import '../page/administration/mac_filtering/_mac_filtering.dart';
import 'constants.dart';

part 'route_home.dart';
part 'route_cloud_login.dart';
part 'route_local_login.dart';
part 'route_dashboard.dart';
part 'route_settings.dart';
part 'route_advanced_settings.dart';
part 'route_otp.dart';
part 'route_pnp.dart';
part 'route_add_nodes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);
  return GoRouter(
    refreshListenable: router,
    observers: [ref.read(routerLoggerProvider)],
    initialLocation: '/',
    routes: [
      homeRoute,
      // ref.read(otpRouteProvider),
      LinksysRoute(
        name: RouteNamed.prepareDashboard,
        path: RoutePath.prepareDashboard,
        config: LinksysRouteConfig(pageWidth: FullPageWidth()),
        builder: (context, state) => PrepareDashboardView(),
      ),
      LinksysRoute(
        name: RouteNamed.selectNetwork,
        path: RoutePath.selectNetwork,
        config: const LinksysRouteConfig(noNaviRail: true),
        builder: (context, state) => SelectNetworkView(),
      ),
      dashboardRoute,
      pnpRoute,
      addNodesRoute,
    ],
    redirect: (context, state) {
      return router._redirectLogic(state);
    },
    debugLogDiagnostics: true,
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  StreamSubscription? _errorSub;
  RouterNotifier(this._ref) {
    // _ref.listen(authProvider, (_, state) {
    //   if (!state.isLoading && !state.hasError) {
    //     notifyListeners();
    //   }
    // });
    _ref.listen(otpProvider.select((value) => value.step), (_, __) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  String? _redirectLogic(GoRouterState state) {
    if (state.matchedLocation == '/pnp/index.html') {
      return '/pnp';
    }

    final loginType =
        _ref.watch(authProvider.select((data) => data.value?.loginType));
    if (state.matchedLocation == '/') {
      switch (loginType) {
        case LoginType.remote:
          return RoutePath.prepareDashboard;
        case LoginType.local:
          return RoutePath.prepareDashboard;
        default:
          return null;
      }
    }

    // if no network Id for remote login
    final managedNetworkId = _ref.read(selectedNetworkIdProvider);
    if (loginType == LoginType.remote &&
        managedNetworkId == null &&
        state.matchedLocation != RoutePath.selectNetwork) {
      logger.d('empty network');
      return RoutePath.prepareDashboard;
    }

    return null;
  }
}
