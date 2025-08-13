import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_rule_view.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/static_routing_view.dart';
import 'package:privacy_gui/page/components/picker/region_picker_view.dart';
import 'package:privacy_gui/page/components/settings_view/editable_card_list_edit_view.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/_ddns.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacy_gui/page/firmware_update/_firmware_update.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_auth_view.dart';
import 'package:privacy_gui/page/landing/_landing.dart';

import 'package:privacy_gui/page/login/views/_views.dart';
import 'package:privacy_gui/page/login/auto_parent/views/auto_parent_first_login_view.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/page/login/views/login_cloud_auth_view.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/nodes/views/add_nodes_view.dart';
import 'package:privacy_gui/page/otp_flow/providers/_providers.dart';
import 'package:privacy_gui/page/otp_flow/views/_views.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/pnp_admin_view.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_save_settings_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_pppoe_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_static_ip_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart';
import 'package:privacy_gui/page/select_network/_select_network.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_verify_view.dart';
import 'package:privacy_gui/page/support/faq_list_view.dart';
import 'package:privacy_gui/page/instant_topology/views/instant_topology_view.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';
import 'package:privacy_gui/page/vpn/views/vpn_settings_page.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/ip_getter/web_get_local_ip.dart';

part 'route_home.dart';
part 'route_cloud_login.dart';
part 'route_local_login.dart';
part 'route_dashboard.dart';
part 'route_settings.dart';
part 'route_advanced_settings.dart';
part 'route_otp.dart';
part 'route_pnp.dart';
part 'route_add_nodes.dart';
part 'route_menu.dart';

// init path enum
enum LocalWhereToGo {
  pnp,
  login,
  firstTimeLogin,
  ;
}

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
      autoParentFirstLoginRoute,
      cloudLoginAuthRoute,
      cloudLoginRoute,
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
        return router._autoConfigurationLogic(state);
      } else if (state.matchedLocation == RoutePath.localLoginPassword) {
        router._autoConfigurationLogic(state);
        return router._redirectLogic(state);
      } else if (state.matchedLocation.startsWith('/pnp')) {
        return router._goPnpPath(state);
      } else if (state.matchedLocation.startsWith('/autoParentFirstLogin')) {
        // bypass auto parent first login page
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

  Future<String?> _autoConfigurationLogic(GoRouterState state) async {
    await _ref.read(connectivityProvider.notifier).forceUpdate();
    final loginType = _ref.read(authProvider
        .select((value) => value.value?.loginType ?? LoginType.none));
    final pnp = _ref.read(pnpProvider.notifier);
    LocalWhereToGo whereToGo = LocalWhereToGo.login;
    final routerType =
        _ref.read(connectivityProvider).connectivityInfo.routerType;
    if (BuildConfig.forceCommandType == ForceCommand.local ||
        (routerType != RouterType.others && loginType != LoginType.remote)) {
      whereToGo = await pnp
          .fetchDeviceInfo(false)
          .then((_) async => await pnp.autoConfigurationCheck())
          .then((config) async {
        // Un supported PnP or Unable to get AutoConfigurationSettings case -
        if (config == null) {
          return LocalWhereToGo.login;
        }
        // If isAutoConfigurationSupported is not true, then go to Login
        if (config.isAutoConfigurationSupported != true) {
          // Retail factory reset case - Check admin password
          final isAdminPasswordSet = await pnp.isRouterPasswordSet();
          return isAdminPasswordSet == false
              ? LocalWhereToGo.pnp
              : LocalWhereToGo.login;
        }
        // AutoConfigurationSupported is true case -

        // AutoParent case -
        if (config.autoConfigurationMethod ==
            AutoConfigurationMethod.autoParent) {
          // AutoParent case -
          // First Time Login -> AutoConfigurationSupported is true and userAcknowledgedAutoConfiguration is false
          // Login -> else
          return config.userAcknowledgedAutoConfiguration == false
              ? LocalWhereToGo.firstTimeLogin
              : LocalWhereToGo.login;
        }

        // Prepair case - Check isAutoConfigurationSupported and userAcknowledgedAutoConfiguration

        final userAcknowledgedAutoConfiguration =
            config.userAcknowledgedAutoConfiguration;
        if (userAcknowledgedAutoConfiguration == false) {
          // PnP case -
          // Go PnP -> AutoConfigurationSupported is true and userAcknowledgedAutoConfiguration is false
          // Login -> else
          return LocalWhereToGo.pnp;
        }
        // Factory Reset (UnConfigured) case -
        // Go PnP -> isAdminPasswordDefault is true and isAdminPasswordSetByUser is false
        // Login -> else
        //
        final isRouterPasswordSet = await pnp.isRouterPasswordSet();
        return isRouterPasswordSet == false
            ? LocalWhereToGo.pnp
            : LocalWhereToGo.login;
      }).onError((error, __) {
        logger.e('[Route]: [AutoConfigurationLogic]: Error - $error');
        return LocalWhereToGo.login;
      });
    } else {
      whereToGo = LocalWhereToGo.login;
    }
    logger.i('[Route]: [AutoConfigurationLogic]: whereToGo - $whereToGo');
    if (whereToGo == LocalWhereToGo.pnp) {
      // PnP case -
      await _ref.read(authProvider.notifier).logout();
      return _goPnp(state.uri.query);
    } else if (whereToGo == LocalWhereToGo.firstTimeLogin) {
      // First Time Login case -
      if (!_ref.read(autoParentFirstLoginStateProvider)) {
        await _ref.read(authProvider.notifier).logout();
      }
      return _goFirstTimeLogin(state);
    } else {
      // Login case -
      return _authCheck(state);
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
      logger.d('[Route]: Remote: there is no managed network ID');
      return _prepare(state);
    }

    // check query parameter in remote login
    // if session is not null and different with current session which stores in pref,
    // then logout
    final queryParameters = state.uri.queryParameters;
    final prefs = await SharedPreferences.getInstance();
    final currentSession = prefs.getString(pGRASessionId);
    if (loginType == LoginType.remote &&
        (currentSession == null ||
            (queryParameters['token'] != null &&
                queryParameters['session'] != null &&
                queryParameters['session'] != currentSession))) {
      FlutterNativeSplash.remove();
      logger
          .d('[Route]: session is not null and different with current session');
      await _ref.read(authProvider.notifier).logout();
      return _prepare(state);
    }

    // if have no login type and navigate into dashboard, then back to home
    if ((loginType == null || loginType == LoginType.none) &&
        state.matchedLocation.startsWith('/dashboard')) {
      logger.d('[Route]: No login type but intend to dashboard, lead to Home');
      return _home();
    }
    return state.matchedLocation == RoutePath.home
        ? _home()
        : await (_prepare(state).then((_) => null));
  }

  FutureOr<String?> _goPnp(String query) {
    FlutterNativeSplash.remove();
    final queryParams = query.isEmpty
        ? Uri.tryParse(getFullLocation(_ref))?.query ?? ''
        : query;
    final path = '${RoutePath.pnp}?$queryParams';
    logger.i('[Route]: Go to PnP, URI=$path');
    return path;
  }

  FutureOr<String?> _goFirstTimeLogin(GoRouterState state) {
    logger.i('[Route]: Mark First Time Login');
    _ref.read(autoParentFirstLoginStateProvider.notifier).state = true;
    return _authCheck(state);
  }

  Future<String?> _authCheck(GoRouterState state) {
    return _ref.read(authProvider.notifier).init().then((authState) async {
      logger.i(
          '[Route]: Check credentials done: Login type = ${authState?.loginType}, ${authState?.localPassword}');

      // check query parameter in remote login
      // if session is not null and different with current session which stores in pref,
      // then logout
      final queryParameters = state.uri.queryParameters;
      final prefs = await SharedPreferences.getInstance();
      final currentSession = prefs.getString(pGRASessionId);
      if (authState?.loginType == LoginType.remote &&
          (currentSession == null ||
              (queryParameters['token'] != null &&
                  queryParameters['session'] != null &&
                  queryParameters['session'] != currentSession))) {
        FlutterNativeSplash.remove();
        logger.d(
            '[Route]: session is not null and different with current session');
        await _ref.read(authProvider.notifier).logout();
        return _home(state.uri.query);
      }
      FlutterNativeSplash.remove();
      return switch (authState?.loginType ?? LoginType.none) {
        LoginType.remote => await _prepare(state, RoutePath.dashboardHome)
            .then((path) => path ?? RoutePath.dashboardHome),
        LoginType.local => await _prepare(state, RoutePath.dashboardHome)
            .then((path) => path ?? RoutePath.dashboardHome),
        _ => _home(state.uri.query),
      };
    });
  }

  String _home([String? query]) {
    return BuildConfig.forceCommandType == ForceCommand.local
        ? RoutePath.localLoginPassword
        : '${RoutePath.cloudLoginAuth}?$query';
  }

  FutureOr<String?> _goPnpPath(GoRouterState state) {
    if (_ref.read(pnpProvider).deviceInfo == null) {
      return _goPnp(state.uri.query);
    } else {
      // bypass any pnp views
      return state.uri.toString();
    }
  }

  Future<String?> _prepare(GoRouterState state, [String? goToPath]) async {
    logger.d('[Prepare]: prepare data. Go to path: $goToPath');
    await _ref.read(connectivityProvider.notifier).forceUpdate();
    final prefs = await SharedPreferences.getInstance();
    String? serialNumber = prefs.getString(pCurrentSN);
    final loginType =
        _ref.read(authProvider.select((value) => value.value?.loginType));
    String? naviPath;

    if (loginType == LoginType.remote) {
      final networkId = prefs.getString(pSelectedNetworkId);
      final sessionId = prefs.getString(pGRASessionId);
      naviPath = await _prepareRemote(networkId, serialNumber, sessionId);
    } else if (loginType == LoginType.local) {
      naviPath = await _prepareLocal(serialNumber);
    }
    //
    if (naviPath != null) {
      logger.i('[Prepare]: naviPath - $naviPath');
      return naviPath;
    }
    logger.d('[Prepare]: cache check');
    await ProviderContainer()
        .read(linksysCacheManagerProvider)
        .loadCache(serialNumber: serialNumber ?? '');
    logger.d('[Prepare]: device info check - $serialNumber');
    final nodeDeviceInfo = await _ref
        .read(dashboardManagerProvider.notifier)
        .checkDeviceInfo(serialNumber)
        .then<NodeDeviceInfo?>((nodeDeviceInfo) {
      // Build/Update better actions
      logger.d('[Prepare]: build better actions');
      buildBetterActions(nodeDeviceInfo.services);
      return nodeDeviceInfo;
    }).onError((error, stackTrace) => null);

    if (nodeDeviceInfo != null) {
      logger.d('[Prepare]: SN changed: ${nodeDeviceInfo.serialNumber}');
      await _ref.read(connectivityProvider.notifier).forceUpdate();
      logger.d('[Prepare]: Force update connectivity finish!');

      _ref
          .read(pollingProvider.notifier)
          .checkAndStartPolling(nodeDeviceInfo.serialNumber != serialNumber);

      // RA mode
      final raMode = prefs.getBool(pRAMode) ?? false;
      if (raMode) {
        _ref.read(raSessionProvider.notifier).startMonitorSession();
      }
      final naviPath = goToPath ?? state.uri.toString();
      logger.d('[Prepare]: Prepare go to $naviPath');
      return naviPath;
    } else {
      // TODO #LINKSYS Error handling for unable to get deviceinfo
      logger.i('[Prepare]: Error handling for unable to get deviceinfo');
      return _home('error=noDeviceInfo');
    }
  }

  Future<String?> _prepareRemote(
      String? networkId, String? serialNumber, String? sessionId) async {
    logger.i('[Prepare]: remote - $networkId, $serialNumber, $sessionId');
    if (serialNumber != null && sessionId != null) {
      if (isSerialNumberChanged(serialNumber)) {
        return null;
      }
      await _ref
          .read(dashboardManagerProvider.notifier)
          .saveSelectedNetwork(serialNumber, '');
    } else if (_ref.read(selectedNetworkIdProvider) == null) {
      _ref.read(selectNetworkProvider.notifier).refreshCloudNetworks();
      if (networkId == null || serialNumber == null) {
        return RoutePath.selectNetwork;
      }
      await _ref
          .read(dashboardManagerProvider.notifier)
          .saveSelectedNetwork(serialNumber, networkId);
    }
    return null;
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

    final routerRepository = _ref.read(routerRepositoryProvider);

    final newSerialNumber = await routerRepository
        .send(
          JNAPAction.getDeviceInfo,
          fetchRemote: true,
        )
        .then<String>(
            (value) => NodeDeviceInfo.fromJson(value.output).serialNumber);
    if (serialNumber == newSerialNumber) {
      return null;
    }

    // Save serial number if serial number changed
    await _ref
        .read(dashboardManagerProvider.notifier)
        .saveSelectedNetwork(newSerialNumber, '');

    return null;
  }

  bool isSerialNumberChanged(String? serialNumber) =>
      serialNumber != null &&
      serialNumber == _getStateDeviceInfo()?.serialNumber;
  NodeDeviceInfo? _getStateDeviceInfo() =>
      _ref.read(dashboardManagerProvider).deviceInfo;
}

final autoParentFirstLoginStateProvider = StateProvider<bool>((ref) {
  return false;
});
