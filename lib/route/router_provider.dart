import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
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
import 'package:privacy_gui/page/_shared/providers/usp_bars_visible_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/views/usp_dashboard_view.dart';
import 'package:privacy_gui/page/menu/views/usp_menu_view.dart';
import 'package:privacy_gui/page/support/views/usp_support_view.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';
import 'package:privacy_gui/page/devices/views/usp_device_list_view.dart';
import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart'
    as usp_instant_privacy;
import 'package:privacy_gui/page/admin/views/usp_admin_view.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/dhcp/views/usp_dhcp_detail_view.dart';
import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';
import 'package:privacy_gui/page/system_log/views/usp_system_log_view.dart';
import 'package:privacy_gui/page/advanced_settings/views/usp_advanced_settings_view.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';
import 'package:privacy_gui/page/dmz/views/usp_dmz_view.dart';
import 'package:privacy_gui/page/local_network/views/usp_local_network_view.dart';
import 'package:privacy_gui/page/static_routing/views/usp_static_routing_view.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart';
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
import 'package:privacy_gui/page/apps/views/usp_apps_view.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/unified_diagnostics_view.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/speed_test_view.dart';
import 'package:privacy_gui/page/ai_assistant/views/router_assistant_view.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';

// PnP (Plug and Play) imports
import 'package:privacy_gui/page/instant_setup/views/pnp_entry_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_no_internet_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_isp_settings_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_pppoe_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_static_ip_view.dart';

// Remote Assistance imports
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_confirm_view.dart';

part 'route_home.dart';
part 'route_local_login.dart';
part 'route_usp_dashboard.dart';
part 'route_pnp.dart';
part 'route_remote_assistance.dart';

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
  remoteAssistanceRoute,
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
      } else if (state.matchedLocation.startsWith('/remoteAssistance')) {
        // Remote Assistance routes — no normal auth required, pass through.
        return state.uri.toString();
      } else if (state.matchedLocation.startsWith('/usp')) {
        // USP routes — check auth, redirect to login when logged out.
        // In Remote build mode, redirect to confirm page with restored session params.
        if (GlobalConfig.remote.isActive) {
          // If already connected (USP layer active), allow access
          final isRemoteAssistance = ref.read(authProvider
              .select((value) => value.value?.isRemoteAssistance ?? false));
          if (isRemoteAssistance) {
            return state.uri.toString();
          }

          // Not connected — check for restored session to re-connect
          final raState = ref.read(remoteAccessProvider);
          if (raState.sessionInfo != null && raState.sessionToken != null) {
            // Redirect to confirm page to re-establish connection
            logger
                .i('[Route]: Remote mode refresh, redirecting to confirm page');
            return '${RoutePath.remoteAssistanceConfirm}'
                '?session=${raState.sessionInfo!.id}'
                '&token=${raState.sessionToken}';
          }
          logger.i('[Route]: Remote mode no session, redirecting to RA page');
          return RoutePath.remoteAssistanceConfirm;
        }
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
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      if (next.isLoading) return;
      final prevType = previous?.value?.loginType;
      final nextType = next.value?.loginType;
      if (prevType != nextType) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  Future<String?> autoConfigurationLogic(GoRouterState state) async {
    // Check for Remote Assistance mode via URL parameter
    final raSession = state.uri.queryParameters['session'];
    if (raSession != null && raSession.isNotEmpty) {
      final raToken = state.uri.queryParameters['token'] ?? '';
      logger.i('[Route]: Detected Remote Assistance session: $raSession');
      return '${RoutePath.remoteAssistanceConfirm}?session=$raSession&token=$raToken';
    }

    // Check for Remote build mode (force=remote)
    if (BuildConfig.isRemote()) {
      logger.i('[Route]: Remote build mode detected, redirecting to RA page');
      return RoutePath.remoteAssistanceConfirm;
    }

    final loginType = _ref.read(authProvider
        .select((value) => value.value?.loginType ?? LoginType.none));

    logger.i('[Route]: [AutoConfigurationLogic]: loginType=$loginType');

    // PnP check is now performed AFTER login in _prepare().
    // User must authenticate first before we can check PnP status.
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
    if (state.matchedLocation == RoutePath.home) {
      return _home();
    }
    // Cache refs before async _prepare — same pattern as authCheck.
    final session = _ref.read(sessionProvider.notifier);
    final autoParentLogin = _ref.read(autoParentFirstLoginStateProvider);
    final autoParentLoginNotifier =
        _ref.read(autoParentFirstLoginStateProvider.notifier);
    final cachedDeviceInfo = _ref.read(sessionProvider).deviceInfo;
    return _prepare(
      state,
      loginType: loginType,
      session: session,
      autoParentLogin: autoParentLogin,
      autoParentLoginNotifier: autoParentLoginNotifier,
      cachedDeviceInfo: cachedDeviceInfo,
    ).then((_) => null);
  }

  FutureOr<String?> goFirstTimeLogin(GoRouterState state) {
    logger.i('[Route]: Mark First Time Login');
    _ref.read(autoParentFirstLoginStateProvider.notifier).state = true;
    return authCheck(state);
  }

  Future<String?> authCheck(GoRouterState state) {
    // Cache providers synchronously BEFORE init(). The init() call changes
    // authProvider state which invalidates routerProvider's Ref — any
    // _ref.read() after init() resolves throws the Riverpod assertion:
    // "Cannot use ref functions after the dependency of a provider changed
    // but before the provider rebuilt"
    final session = _ref.read(sessionProvider.notifier);
    final autoParentLogin = _ref.read(autoParentFirstLoginStateProvider);
    final autoParentLoginNotifier =
        _ref.read(autoParentFirstLoginStateProvider.notifier);
    final cachedDeviceInfo = _ref.read(sessionProvider).deviceInfo;

    return _ref.read(authProvider.notifier).init().then((authState) async {
      logger.i(
          '[Route]: Check credentials done: Login type = ${authState?.loginType}');

      FlutterNativeSplash.remove();
      final type = authState?.loginType ?? LoginType.none;
      return switch (type) {
        LoginType.local => await _prepare(
            state,
            goToPath: RoutePath.uspDashboard,
            loginType: type,
            session: session,
            autoParentLogin: autoParentLogin,
            autoParentLoginNotifier: autoParentLoginNotifier,
            cachedDeviceInfo: cachedDeviceInfo,
          ).then((path) => path ?? RoutePath.uspDashboard),
        _ => _home(state.uri.query),
      };
    });
  }

  String _home([String? query]) {
    return '${RoutePath.localLoginPassword}?$query';
  }

  Future<String?> _prepare(
    GoRouterState state, {
    String? goToPath,
    LoginType? loginType,
    required SessionNotifier session,
    required bool autoParentLogin,
    required StateController<bool> autoParentLoginNotifier,
    NodeDeviceInfo? cachedDeviceInfo,
  }) async {
    logger.d('[Prepare]: prepare data. Go to path: $goToPath');

    final prefs = await SharedPreferences.getInstance();
    String? serialNumber = prefs.getString(pCurrentSN);
    String? naviPath;

    if (loginType == LoginType.local) {
      naviPath = await _prepareLocal(
        serialNumber,
        session: session,
        autoParentLogin: autoParentLogin,
        autoParentLoginNotifier: autoParentLoginNotifier,
        cachedDeviceInfo: cachedDeviceInfo,
      );
    }
    //
    if (naviPath != null) {
      logger.i('[Prepare]: naviPath - $naviPath');
      return naviPath;
    }
    logger.d('[Prepare]: device info check - $serialNumber');
    final nodeDeviceInfo = await session
        .fetchDeviceInfoAndInitializeServices()
        .then<NodeDeviceInfo?>((nodeDeviceInfo) {
      logger.d(
          '[Prepare]: Services initialized via fetchDeviceInfoAndInitializeServices');
      return nodeDeviceInfo;
    }).onError((error, stackTrace) => null);

    if (nodeDeviceInfo != null) {
      logger.d('[Prepare]: SN: ${nodeDeviceInfo.serialNumber}');

      // Post-login PnP check — only for local login
      if (loginType == LoginType.local && !BuildConfig.skipPnp) {
        final pnpResult = await _ref
            .read(pnpStatusServiceProvider)
            .check(nodeDeviceInfo.serialNumber);
        if (pnpResult.needsPnp) {
          logger.i('[Prepare]: PnP needed, routing to /pnp');
          return RoutePath.pnp;
        }
        logger.d('[Prepare]: PnP not needed, continuing to dashboard');
      }

      final naviPath = goToPath ?? state.uri.toString();
      logger.d('[Prepare]: Prepare go to $naviPath');
      return naviPath;
    } else {
      logger.i('[Prepare]: Error handling for unable to get deviceinfo');
      return _home('error=noDeviceInfo');
    }
  }

  Future<String?> _prepareLocal(
    String? serialNumber, {
    required SessionNotifier session,
    required bool autoParentLogin,
    required StateController<bool> autoParentLoginNotifier,
    NodeDeviceInfo? cachedDeviceInfo,
  }) async {
    logger.i('[Prepare]: local - $serialNumber');
    // If auto parent first login, then go to auto parent first login page
    if (autoParentLogin) {
      logger.i('[Prepare]: autoParentFirstLogin');
      autoParentLoginNotifier.state = false;
      return RoutePath.autoParentFirstLogin;
    }
    if (isSerialNumberChanged(serialNumber, cachedDeviceInfo)) {
      return null;
    }

    try {
      final deviceInfo = await session.forceFetchDeviceInfo();
      final newSerialNumber = deviceInfo.serialNumber;

      if (serialNumber == newSerialNumber) {
        return null;
      }

      // Save serial number if serial number changed
      await session.saveSelectedNetwork(newSerialNumber, '');
    } catch (e) {
      logger.w('[Prepare]: forceFetchDeviceInfo failed in _prepareLocal: $e');
    }

    return null;
  }

  bool isSerialNumberChanged(
          String? serialNumber, NodeDeviceInfo? cachedDeviceInfo) =>
      serialNumber != null && serialNumber == cachedDeviceInfo?.serialNumber;
}

final autoParentFirstLoginStateProvider = StateProvider<bool>((ref) {
  return false;
});
