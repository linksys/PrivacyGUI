import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Both config imports survive #1474 phase 9, and neither is a mode read: this
// library uses `BuildConfig.skipPnp` in `_prepare()` and
// `GlobalConfig.feature.enableTestConsole` in the `route_usp_dashboard.dart` part.
// Those are feature flags. The mode axis is now read only through
// `appModeProfileProvider`, and `test/core/mode/composition_root_test.dart` is what
// keeps this file at zero.
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/session_entry.dart';
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
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
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
// Speed Test disabled: blocked by FW support (#857)
// import 'package:privacy_gui/page/unified_diagnostics/views/speed_test_view.dart';
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

/// The routes every surface registers.
///
/// **Not the whole table.** `remoteAssistanceRoute` is not here: since #1497 the
/// table is composed by `SurfaceStrategy.routes()`, and a local build genuinely
/// has no route to the agent UI — which is the structural half of #1357, replacing
/// a redirect that had to recognise `/remoteAssistance` and refuse it. Anything
/// added to this list is registered in *both* modes; a mode-specific route goes in
/// that mode's surface.
final sharedAppRoutes = [
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

/// Turn a [SupportSessionEntry] into the confirm-route location it names.
///
/// The page-layer half of cause 3's entry: `lib/core/` may not depend on
/// `lib/route/`, so the strategies answer with a *kind* of entry and this maps it —
/// the same division that lets `SessionOutcome` exist. Three shapes, and they are
/// the three the two call sites below used to build inline.
///
/// Top-level rather than a method on [RouterNotifier] because both consumers need
/// it and one of them is the `redirect` closure, which has no notifier in scope for
/// the branch it lives in. Public only so its three answers can be asserted
/// directly: they are the destinations of all eight automatic RA endings plus every
/// supporter link, and reached through the router they are unreachable from a test —
/// which is how the `?ended=true` arm could have been inverted with a green suite.
@visibleForTesting
String supportSessionLocation(
  String? sessionId,
  String? token,
  bool previousSessionEnded,
) {
  // Keyed on the session id alone, with an empty token spelled out rather than
  // omitted. Two reasons, and the first is the one that made this a review finding:
  // [SupportSessionEntry]'s fields are independently nullable, so an id with no
  // token is a value the sealed type invites — and requiring both would silently
  // *discard the id*, sending a resumable session to the bare confirm path and its
  // red `_buildMissingParamsView()`. Second, `&token=` empty is preserved from the
  // string this replaced: a half-formed supporter link should reach the confirm view
  // and be reported by its `_hasRequiredParams`, not be rerouted as if the session
  // had ended.
  if (sessionId != null) {
    return '${RoutePath.remoteAssistanceConfirm}'
        '?session=$sessionId'
        '&token=${token ?? ''}';
  }
  return previousSessionEnded
      ? '${RoutePath.remoteAssistanceConfirm}?ended=true'
      : RoutePath.remoteAssistanceConfirm;
}

final routerKey = GlobalKey<NavigatorState>();
final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);
  return GoRouter(
    navigatorKey: routerKey,
    refreshListenable: router,
    observers: [ref.read(routerLoggerProvider)],
    initialLocation: '/',
    routes: ref.watch(surfaceStrategyProvider).routes(),
    redirect: (context, state) {
      if (state.matchedLocation == '/') {
        return router.autoConfigurationLogic(state);
      } else if (state.matchedLocation == RoutePath.localLoginPassword) {
        // The discarded `Future` is **pre-existing**, and #1498 did not change what
        // it discards — before phase 9 this call ended in `return RoutePath
        // .remoteAssistanceConfirm` for a remote build and that was dropped too;
        // now it ends in `SessionStrategy.entryPoint` and the answer is dropped.
        // Recorded rather than fixed because both halves are outside a refactor's
        // remit: the fire-and-forget also runs `authCheck` concurrently with the
        // `redirectLogic` whose value *is* returned, so two redirect decisions are
        // in flight for one navigation, and awaiting it would change where a remote
        // build's hand-typed `/localLoginPassword` lands. `localLoginRoute` is in
        // `sharedAppRoutes`, i.e. registered in both modes, so "which surface owns
        // the login route" is the `SurfaceStrategy.routes()` question this really
        // is. Belongs on #1498's ticket, not in it.
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
        //
        // Unconditional since #1474 phase 7, and that is the point of the phase:
        // this branch is only reachable if `/remoteAssistance` matched a
        // registered route, and only `RemoteSurface.routes()` registers one. In a
        // local build the location does not exist, so go_router answers it with
        // its own 404 instead of this redirect refusing it to `/uspDashboard`.
        //
        // The gate that stood here checked the BUILD axis (`BuildConfig.isRemote()`),
        // and #1357 item 1's concern survives the removal for the same reason:
        // the route table is composed from `AppMode`, which is derived from that
        // same build flag, so the surface that registers the route is the surface
        // whose bridge `sse_providers.dart` constructs. There is no longer a pair
        // of reads that could disagree.
        //
        // The `?session=` entry in `autoConfigurationLogic` still needs its own
        // check — an unmatched location returned *from* a redirect renders
        // go_router's error page, so no route table can decline it.
        return state.uri.toString();
      } else if (state.matchedLocation.startsWith('/usp')) {
        // USP routes — is there a session, and if not, where does this mode get
        // one? Cause 3 answers both halves; this branch only maps the answer onto
        // a location, which is the half `lib/core/` cannot do.
        //
        // The `if (GlobalConfig.remote.isActive)` that stood here was the last mode
        // read in `lib/route/` outside `autoConfigurationLogic`, and it wrapped
        // *three* of the four returns below. Note that the local and remote arms
        // read auth with different verbs (`watch` and `read`) and different
        // predicates (`isLoggedIn`, `isRemoteAssistance`); both are preserved
        // inside the strategies, and the difference is documented on
        // `SessionStrategy.guardEntry` as the reason this is a member.
        return switch (
            ref.read(appModeProfileProvider).session.guardEntry(ref)) {
          SessionAlreadyHeld() => state.uri.toString(),
          OwnCredentialsEntry() => router._home(),
          SupportSessionEntry(
            :final sessionId,
            :final token,
            :final previousSessionEnded,
          ) =>
            supportSessionLocation(sessionId, token, previousSessionEnded),
        };
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
    // Where does this mode's session come from, given the location we were entered
    // at? Cause 3 (`SessionStrategy.entryPoint`) decides; this maps the answer.
    //
    // Two `BuildConfig.isRemote()` reads stood here until #1474 phase 9 — the
    // `?session=` translation and the `force=remote` cold-entry redirect — and both
    // were session entry by cause, which is why the ticket's scope widened to take
    // them. With them gone `lib/route/` reads no mode flag at all.
    //
    // The `?session=` one was the more dangerous of the epic's two RA entry points,
    // because ungated it produced a *hybrid* configuration rather than a refusal:
    // `activate(config)` registers a Guardian-proxied `UspClient` while
    // `BuildConfig.isRemote()` stays false, so `sse_providers.dart` takes its local
    // branch and builds a bridge with `BridgeEndpoints.local` paths and
    // `AuthBehavior.local` against the Guardian origin — on-router paths, no bearer
    // token, wrong host. It is now inexpressible: only `RemoteSessionStrategy`
    // constructs the request that `activate` needs (see `SessionRequest`).
    //
    // A local build still ignores the parameter and continues to the normal login
    // flow — with a `logger.w`, authored in `LocalSessionStrategy.entryPoint`,
    // because it is the only evidence an RA deployment's `force` dart-define is
    // unset or misspelled. The parameter is not sanitised out of the URL: nothing
    // downstream reads it once entry declines, and rewriting the location here would
    // fight the `?session=` the login redirect already passes through.
    final entryLocation =
        switch (_ref.read(appModeProfileProvider).session.entryPoint(
              _ref,
              state.uri,
            )) {
      SupportSessionEntry(
        :final sessionId,
        :final token,
        :final previousSessionEnded,
      ) =>
        supportSessionLocation(sessionId, token, previousSessionEnded),
      // Local entry answers "not a location", so that `authCheck` below stays the
      // one thing that decides where a credential-less app goes — it knows about
      // PnP, first-time login and cloud-versus-local, which cause 3 does not.
      // `SessionAlreadyHeld` is unreachable from `entryPoint` (see `SessionEntry`);
      // it is listed rather than defaulted so the switch stays exhaustive.
      OwnCredentialsEntry() || SessionAlreadyHeld() => null,
    };
    if (entryLocation != null) {
      return entryLocation;
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

    // if not logged in and navigate into dashboard, then back to home
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
