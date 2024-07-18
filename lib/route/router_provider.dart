import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_detail_view.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_list_view.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_view.dart';
import 'package:privacy_gui/page/components/picker/region_picker_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/ddns/_ddns.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacy_gui/page/devices/views/select_device_view.dart';
import 'package:privacy_gui/page/firmware_update/_firmware_update.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/landing/_landing.dart';

import 'package:privacy_gui/page/linkup/views/linkup_view.dart';
import 'package:privacy_gui/page/login/views/_views.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/page/network_admin/_network_admin.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/nodes/views/add_nodes_view.dart';
import 'package:privacy_gui/page/otp_flow/providers/_providers.dart';
import 'package:privacy_gui/page/otp_flow/views/_views.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/call_support/call_support_main_region_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/call_support/call_support_more_region_view.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/page/pnp/pnp_admin_view.dart';
import 'package:privacy_gui/page/pnp/pnp_setup_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/isp_settings/pnp_isp_settings_auth_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/isp_settings/pnp_pppoe_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/isp_settings/pnp_static_ip_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/page/safe_browsing/views/safe_browsing_view.dart';
import 'package:privacy_gui/page/pnp/troubleshooter/views/pnp_no_internet_connection_view.dart';
import 'package:privacy_gui/page/select_network/_select_network.dart';
import 'package:privacy_gui/page/support/views/callback_view.dart';
import 'package:privacy_gui/page/support/faq_list_view.dart';
import 'package:privacy_gui/page/topology/_topology.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_logger.dart';
import '../page/advanced_settings/local_network_settings/_local_network_settings.dart';
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

final routerKey = GlobalKey<NavigatorState>();
final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);
  return GoRouter(
    navigatorKey: routerKey,
    refreshListenable: router,
    observers: [ref.read(routerLoggerProvider)],
    initialLocation: '/',
    routes: [
      localLoginRoute,
      homeRoute,
      // ref.read(otpRouteProvider),
      LinksysRoute(
        name: RouteNamed.prepareDashboard,
        path: RoutePath.prepareDashboard,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 4, centered: true),
        ),
        builder: (context, state) => const PrepareDashboardView(),
      ),
      LinksysRoute(
        name: RouteNamed.selectNetwork,
        path: RoutePath.selectNetwork,
        config: const LinksysRouteConfig(
          noNaviRail: true,
        ),
        builder: (context, state) => const SelectNetworkView(),
      ),
      dashboardRoute,
      pnpRoute,
      pnpTroubleshootingRoute,
      addNodesRoute,
    ],
    redirect: (context, state) {
      if (state.matchedLocation == '/') {
        return router._redirectPnpLogic(state);
      } else if (state.matchedLocation.startsWith('/pnp')) {
        // bypass any pnp views
        return state.uri.toString();
      }
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

  Future<String?> _redirectPnpLogic(GoRouterState state) async {
    await _ref.read(connectivityProvider.notifier).forceUpdate();
    final loginType = _ref.read(authProvider
        .select((value) => value.value?.loginType ?? LoginType.none));
    final pnp = _ref.read(pnpProvider.notifier);
    bool shouldGoPnp = false;
    final routerType =
        _ref.read(connectivityProvider).connectivityInfo.routerType;
    if (BuildConfig.forceCommandType == ForceCommand.local ||
        (routerType != RouterType.others && loginType != LoginType.remote)) {
      shouldGoPnp = await pnp.fetchDeviceInfo().then((_) async =>
          await pnp.pnpCheck() || !(await pnp.isRouterPasswordSet()));
    } else {
      shouldGoPnp = false;
    }
    logger.d('go pnp? $shouldGoPnp, state uri: <${state.uri}>');
    if (shouldGoPnp) {
      return _goPnp(state.uri.query);
    } else {
      return _authCheck();
    }
  }

  Future<String?> _redirectLogic(GoRouterState state) async {
    final loginType =
        _ref.watch(authProvider.select((data) => data.value?.loginType));

    // if no network Id for remote login
    final managedNetworkId = _ref.read(selectedNetworkIdProvider);
    if (loginType == LoginType.remote &&
        managedNetworkId == null &&
        state.matchedLocation != RoutePath.selectNetwork) {
      FlutterNativeSplash.remove();

      logger.d('empty network');
      return RoutePath.prepareDashboard;
    }

    // if have no login type and navigate inot dashboard, then back to home
    if ((loginType == null || loginType == LoginType.none) &&
        state.matchedLocation.startsWith('/dashboard')) {
      return _home();
    }

    return state.matchedLocation == RoutePath.home ? _home() : null;
  }

  FutureOr<String?> _goPnp(String? query) {
    FlutterNativeSplash.remove();
    final path = '${RoutePath.pnp}?${query ?? ''}';
    logger.d('pnp uri : $path');
    return path;
  }

  Future<String?> _authCheck() {
    return _ref.read(authProvider.notifier).init().then((state) {
      logger.d('init auth finish');
      FlutterNativeSplash.remove();
      return switch (state?.loginType ?? LoginType.none) {
        LoginType.remote => RoutePath.prepareDashboard,
        LoginType.local => RoutePath.prepareDashboard,
        _ => _home(),
      };
    });
  }

  String _home() {
    return BuildConfig.forceCommandType == ForceCommand.local
        ? RoutePath.localLoginPassword
        : RoutePath.home;
  }
}
