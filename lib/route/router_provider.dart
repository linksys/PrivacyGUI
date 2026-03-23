import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/landing/_landing.dart';
import 'package:privacy_gui/page/login/views/_views.dart';
import 'package:privacy_gui/page/login/auto_parent/views/auto_parent_first_login_view.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'navigation_extra.dart';

// USP dashboard imports
import 'package:privacy_gui/page/dashboard/views/usp_dashboard_view.dart';
import 'package:privacy_gui/page/menu/views/usp_menu_view.dart';
import 'package:privacy_gui/page/support/views/usp_support_view.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';
import 'package:privacy_gui/page/devices/views/usp_device_list_view.dart';
import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart'
    as usp_instant_privacy;
import 'package:privacy_gui/page/admin/views/usp_admin_view.dart';
import 'package:privacy_gui/page/dhcp/views/usp_dhcp_detail_view.dart';
import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';
import 'package:privacy_gui/page/system_log/views/usp_system_log_view.dart';
import 'package:privacy_gui/page/advanced_settings/views/usp_advanced_settings_view.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';
import 'package:privacy_gui/page/dmz/views/usp_dmz_view.dart';
import 'package:privacy_gui/page/local_network/views/usp_local_network_view.dart';
import 'package:privacy_gui/page/static_routing/views/usp_static_routing_view.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart';
import 'package:privacy_gui/page/network_diagnostics/views/usp_network_diagnostics_view.dart';
import 'package:privacy_gui/page/statistics/views/usp_statistics_view.dart';
import 'package:privacy_gui/page/test_console/views/usp_test_console_view.dart';
import 'package:privacy_gui/page/dmz/providers/usp_dmz_notifier.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/views/usp_internet_settings_view.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';
import 'package:privacy_gui/page/ipv6_port_service/providers/usp_ipv6_port_service_notifier.dart';
import 'package:privacy_gui/page/port_forwarding/providers/usp_port_forwarding_page_notifier.dart';
import 'package:privacy_gui/page/dhcp/providers/usp_dhcp_reservations_notifier.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';

// PnP (Plug and Play) imports
import 'package:privacy_gui/page/instant_setup/views/pnp_admin_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_no_internet_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_isp_settings_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_pppoe_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_static_ip_view.dart';

part 'route_home.dart';
part 'route_local_login.dart';
part 'route_usp_dashboard.dart';
part 'route_pnp.dart';

// init path enum
enum LocalWhereToGo {
  login,
  firstTimeLogin,
  ;
}

final appRoutes = [
  localLoginRoute,
  autoParentFirstLoginRoute,
  homeRoute,
  uspDashboardRoute,
  pnpRoute,
  pnpNoInternetRoute,
];

/// Navigator key for the old dashboard shell (kept for component compatibility).
/// Components like root_container, snack_bar, and menu_holder reference this.
/// TODO: Migrate components to use uspShellNavigatorKey and remove this.
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerKey = GlobalKey<NavigatorState>();
final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);
  return GoRouter(
    navigatorKey: routerKey,
    refreshListenable: router,
    observers: [ref.read(routerLoggerProvider)],
    initialLocation: '/',
    routes: appRoutes,
    redirect: (context, state) {
      if (state.matchedLocation == '/') {
        return router.autoConfigurationLogic(state);
      } else if (state.matchedLocation == RoutePath.localLoginPassword) {
        router.autoConfigurationLogic(state);
        return router.redirectLogic(state);
      } else if (state.matchedLocation.startsWith('/autoParentFirstLogin')) {
        // bypass auto parent first login page
        return state.uri.toString();
      } else if (state.matchedLocation.startsWith('/pnp') ||
          state.matchedLocation.startsWith('/pnpNoInternetConnection')) {
        // PnP routes — no auth required, pass through.
        return state.uri.toString();
      } else if (state.matchedLocation.startsWith('/usp')) {
        // USP routes — check auth, redirect to login when logged out.
        final loginType =
            ref.watch(authProvider.select((value) => value.value?.loginType));
        if (loginType == null || loginType == LoginType.none) {
          return router._home();
        }
        return state.uri.toString();
      }
      return router.redirectLogic(state);
    },
    debugLogDiagnostics: true,
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  StreamSubscription? _errorSub;
  RouterNotifier(this._ref);

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  Future<String?> autoConfigurationLogic(GoRouterState state) async {
    final loginType = _ref.read(authProvider
        .select((value) => value.value?.loginType ?? LoginType.none));

    logger.i('[Route]: [AutoConfigurationLogic]: loginType=$loginType');

    // If no stored credentials, check if PnP has been completed before.
    if (loginType == LoginType.none && !BuildConfig.skipPnp) {
      final prefs = await SharedPreferences.getInstance();
      final pnpConfiguredSN = prefs.getString(pPnpConfiguredSN);
      if (pnpConfiguredSN == null || pnpConfiguredSN.isEmpty) {
        // No PnP record → send user through PnP setup flow.
        logger.i('[Route]: No PnP configured SN found, routing to /pnp');
        return RoutePath.pnp;
      }
    }

    return authCheck(state);
  }

  Future<String?> redirectLogic(GoRouterState state) async {
    final loginType =
        _ref.watch(authProvider.select((data) => data.value?.loginType));

    // if have no login type and navigate into dashboard, then back to home
    if ((loginType == null || loginType == LoginType.none) &&
        (state.matchedLocation.startsWith('/dashboard') ||
            state.matchedLocation.startsWith('/usp'))) {
      logger.d('[Route]: No login type but intend to dashboard, lead to Home');
      return _home();
    }
    return state.matchedLocation == RoutePath.home
        ? _home()
        : await (_prepare(state).then((_) => null));
  }

  FutureOr<String?> goFirstTimeLogin(GoRouterState state) {
    logger.i('[Route]: Mark First Time Login');
    _ref.read(autoParentFirstLoginStateProvider.notifier).state = true;
    return authCheck(state);
  }

  Future<String?> authCheck(GoRouterState state) {
    return _ref.read(authProvider.notifier).init().then((authState) async {
      logger.i(
          '[Route]: Check credentials done: Login type = ${authState?.loginType}');

      FlutterNativeSplash.remove();
      return switch (authState?.loginType ?? LoginType.none) {
        LoginType.local => await _prepare(state, RoutePath.uspDashboard)
            .then((path) => path ?? RoutePath.uspDashboard),
        _ => _home(state.uri.query),
      };
    });
  }

  String _home([String? query]) {
    return '${RoutePath.localLoginPassword}?$query';
  }

  Future<String?> _prepare(GoRouterState state, [String? goToPath]) async {
    logger.d('[Prepare]: prepare data. Go to path: $goToPath');
    final prefs = await SharedPreferences.getInstance();
    String? serialNumber = prefs.getString(pCurrentSN);
    final loginType =
        _ref.read(authProvider.select((value) => value.value?.loginType));
    String? naviPath;

    if (loginType == LoginType.local) {
      naviPath = await _prepareLocal(serialNumber);
    }
    //
    if (naviPath != null) {
      logger.i('[Prepare]: naviPath - $naviPath');
      return naviPath;
    }
    logger.d('[Prepare]: device info check - $serialNumber');
    final nodeDeviceInfo = await _ref
        .read(sessionProvider.notifier)
        .fetchDeviceInfoAndInitializeServices()
        .then<NodeDeviceInfo?>((nodeDeviceInfo) {
      logger.d(
          '[Prepare]: Services initialized via fetchDeviceInfoAndInitializeServices');
      return nodeDeviceInfo;
    }).onError((error, stackTrace) => null);

    if (nodeDeviceInfo != null) {
      logger.d('[Prepare]: SN changed: ${nodeDeviceInfo.serialNumber}');

      final naviPath = goToPath ?? state.uri.toString();
      logger.d('[Prepare]: Prepare go to $naviPath');
      return naviPath;
    } else {
      logger.i('[Prepare]: Error handling for unable to get deviceinfo');
      return _home('error=noDeviceInfo');
    }
  }

  Future<String?> _prepareLocal(String? serialNumber) async {
    logger.i('[Prepare]: local - $serialNumber');
    // If auto parent first login, then go to auto parent first login page
    final autoParentFirstLogin = _ref.read(autoParentFirstLoginStateProvider);
    if (autoParentFirstLogin) {
      logger.i('[Prepare]: autoParentFirstLogin');
      _ref.read(autoParentFirstLoginStateProvider.notifier).state = false;
      return RoutePath.autoParentFirstLogin;
    }
    if (isSerialNumberChanged(serialNumber)) {
      return null;
    }

    try {
      final deviceInfo =
          await _ref.read(sessionProvider.notifier).forceFetchDeviceInfo();
      final newSerialNumber = deviceInfo.serialNumber;

      if (serialNumber == newSerialNumber) {
        return null;
      }

      // Save serial number if serial number changed
      await _ref
          .read(sessionProvider.notifier)
          .saveSelectedNetwork(newSerialNumber, '');
    } catch (e) {
      logger.w('[Prepare]: forceFetchDeviceInfo failed in _prepareLocal: $e');
    }

    return null;
  }

  bool isSerialNumberChanged(String? serialNumber) =>
      serialNumber != null &&
      serialNumber == _getStateDeviceInfo()?.serialNumber;
  NodeDeviceInfo? _getStateDeviceInfo() =>
      _ref.read(sessionProvider).deviceInfo;
}

final autoParentFirstLoginStateProvider = StateProvider<bool>((ref) {
  return false;
});
