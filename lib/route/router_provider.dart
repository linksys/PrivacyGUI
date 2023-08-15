import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/core/http/linksys_http_client.dart';
import 'package:linksys_moab/core/utils/logger.dart';
import 'package:linksys_moab/page/dashboard/view/_view.dart';
import 'package:linksys_moab/page/dashboard/view/account/_account.dart';
import 'package:linksys_moab/page/dashboard/view/administration/_administration.dart';
import 'package:linksys_moab/page/dashboard/view/administration/internet_settings/internet_settings_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_devices.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_menu_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_shell.dart';
import 'package:linksys_moab/page/dashboard/view/devices/device_detail_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/_nodes.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_detail_view.dart';
import 'package:linksys_moab/page/dashboard/view/topology/_topology.dart';
import 'package:linksys_moab/page/landing/view/_view.dart';
import 'package:linksys_moab/page/login/view/_view.dart';
import 'package:linksys_moab/page/otp_flow/view/_view.dart';
import 'package:linksys_moab/page/wifi_settings/view/_view.dart';
import 'package:linksys_moab/provider/auth/_auth.dart';
import 'package:linksys_moab/provider/otp/otp.dart';

import '../page/dashboard/view/administration/lan/lan_view.dart';
import 'constants.dart';

part 'route_home.dart';
part 'route_login.dart';
part 'route_dashboard.dart';
part 'route_settings.dart';
part 'route_otp.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);
  return GoRouter(
    refreshListenable: router,
    observers: [Logger()],
    routerNeglect: true,
    routes: [
      homeRoute,
      // ref.read(otpRouteProvider),
      GoRoute(
        name: RouteNamed.prepareDashboard,
        path: RoutePath.prepareDashboard,
        builder: (context, state) => PrepareDashboardView(),
      ),
      GoRoute(
        name: RouteNamed.selectNetwork,
        path: RoutePath.selectNetwork,
        builder: (context, state) => SelectNetworkView(),
      ),
      dashboardRoute,
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
    if (state.matchedLocation == '/') {
      final loginType =
          _ref.watch(authProvider.select((data) => data.value?.loginType));

      switch (loginType) {
        case LoginType.remote:
          return '/prepareDashboard';
        case LoginType.local:
          return '/prepareDashboard';
        default:
          return null;
      }
    }
    // if (state.location.startsWith('/otp')) {
    //   final step = _ref.watch(otpProvider).step;

    //   switch (step) {
    //     case OtpStep.chooseOtpMethod:
    //       return '/otp/otpSelectMethod';
    //     case OtpStep.addPhone:
    //       return '/otp/otpAddPhone';
    //     case OtpStep.inputOtp:
    //       return 'otp/otpInputCode';
    //     case OtpStep.finish:
    //     default:
    //       return null;
    //   }
    // }

    return null;
  }
}

class Logger extends NavigatorObserver {
  /// The [Navigator] pushed `route`.
  ///
  /// The route immediately below that one, and thus the previously active
  /// route, is `previousRoute`.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.d('did push the page - $route');
  }

  /// The [Navigator] popped `route`.
  ///
  /// The route immediately below that one, and thus the newly active
  /// route, is `previousRoute`.
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.d('did pop the page - $route');
  }

  /// The [Navigator] removed `route`.
  ///
  /// If only one route is being removed, then the route immediately below
  /// that one, if any, is `previousRoute`.
  ///
  /// If multiple routes are being removed, then the route below the
  /// bottommost route being removed, if any, is `previousRoute`, and this
  /// method will be called once for each removed route, from the topmost route
  /// to the bottommost route.
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.d('did remove the page - $route');
  }

  /// The [Navigator] replaced `oldRoute` with `newRoute`.
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    logger.d('did replace the page - $newRoute');
  }
}
