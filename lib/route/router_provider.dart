import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/factory.dart';
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

import 'package:privacy_gui/page/linkup/views/linkup_view.dart';
import 'package:privacy_gui/page/login/views/_views.dart';
import 'package:privacy_gui/page/login/views/local_reset_router_password_view.dart';
import 'package:privacy_gui/page/login/views/login_cloud_ra_pin_view.dart';
import 'package:privacy_gui/page/login/views/login_cloud_ra_view.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/nodes/views/add_nodes_view.dart';
import 'package:privacy_gui/page/otp_flow/providers/_providers.dart';
import 'package:privacy_gui/page/otp_flow/views/_views.dart';
import 'package:privacy_gui/page/instant_setup/explanation_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/call_support/call_support_main_region_view.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/call_support/call_support_more_region_view.dart';
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
import 'package:privacy_gui/page/support/views/callback_view.dart';
import 'package:privacy_gui/page/support/faq_list_view.dart';
import 'package:privacy_gui/page/instant_topology/views/instant_topology_view.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';
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
      LinksysRoute(
        name: 'factory',
        path: '/factory',
        builder: (context, state) => const FactoryView(),
      ),
      dashboardRoute,
      pnpRoute,
      pnpTroubleshootingRoute,
      addNodesRoute,
    ],
    redirect: (context, state) {
      if (state.matchedLocation == '/') {
        return BuildConfig.factoryMode
            ? Future.value('/factory')
            : router._redirectPnpLogic(state);
      } else if (state.matchedLocation.startsWith('/pnp')) {
        return router._goPnpPath(state);
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
      shouldGoPnp = await pnp
          .fetchDeviceInfo()
          .then((_) async =>
              await pnp.pnpCheck() || !(await pnp.isRouterPasswordSet()))
          .onError((_, __) => false);
    } else {
      shouldGoPnp = false;
    }

    if (shouldGoPnp) {
      await _ref.read(authProvider.notifier).logout();
      return _goPnp(state.uri.query);
    } else {
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

  Future<String?> _authCheck(GoRouterState state) {
    return _ref.read(authProvider.notifier).init().then((authState) async {
      logger.i(
          '[Route]: Check credentials done: Login type = ${authState?.loginType}, ${authState?.localPassword}');
      FlutterNativeSplash.remove();
      return switch (authState?.loginType ?? LoginType.none) {
        LoginType.remote => await _prepare(state, RoutePath.dashboardHome)
            .then((path) => path ?? RoutePath.dashboardHome),
        LoginType.local => await _prepare(state, RoutePath.dashboardHome)
            .then((path) => path ?? RoutePath.dashboardHome),
        _ => _home(),
      };
    });
  }

  String _home() {
    return BuildConfig.forceCommandType == ForceCommand.local
        ? RoutePath.localLoginPassword
        : RoutePath.home;
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
      naviPath = await _prepareRemote(networkId, serialNumber);
    } else if (loginType == LoginType.local) {
      naviPath = await _prepareLocal(serialNumber);
    }
    //
    if (naviPath != null) {
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
      return _home();
    }
  }

  Future<String?> _prepareRemote(
      String? networkId, String? serialNumber) async {
    logger.i('[Prepare]: remote - $networkId, $serialNumber');
    if (_ref.read(selectedNetworkIdProvider) == null) {
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
    if (isSearialNumberChanged(serialNumber)) {
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

  bool isSearialNumberChanged(String? serialNumber) =>
      serialNumber != null &&
      serialNumber == _getStateDeviceInfo()?.serialNumber;
  NodeDeviceInfo? _getStateDeviceInfo() =>
      _ref.read(dashboardManagerProvider).deviceInfo;
}
