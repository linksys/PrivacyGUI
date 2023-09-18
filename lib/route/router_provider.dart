import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/picker/region_picker_view.dart';
import 'package:linksys_app/page/components/picker/simple_item_picker.dart';
import 'package:linksys_app/page/dashboard/view/_view.dart';
import 'package:linksys_app/page/dashboard/view/account/_account.dart';
import 'package:linksys_app/page/dashboard/view/account/two_step_verification_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/_administration.dart';
import 'package:linksys_app/page/dashboard/view/administration/internet_settings/connection_type_selection_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/internet_settings/internet_settings_mac_clone_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/internet_settings/internet_settings_mtu_picker.dart';
import 'package:linksys_app/page/dashboard/view/administration/internet_settings/internet_settings_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/lan/dhcp_reservations/dhcp_reservations_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/mac_filtering/mac_filtering_enter_mac_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/mac_filtering/mac_filtering_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/port_forwarding/port_forwarding_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/port_forwarding/port_range_forwarding/port_range_forwarding_list_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/port_forwarding/port_range_triggering/port_range_triggering_list_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/port_forwarding/select_online_device_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/port_forwarding/select_protocol_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/port_forwarding/single_port_forwarding/single_port_forwarding_list_view.dart';
import 'package:linksys_app/page/dashboard/view/dashboard_devices.dart';
import 'package:linksys_app/page/dashboard/view/dashboard_menu_view.dart';
import 'package:linksys_app/page/dashboard/view/dashboard_shell.dart';
import 'package:linksys_app/page/dashboard/view/devices/change_device_avatar_view.dart';
import 'package:linksys_app/page/dashboard/view/devices/change_device_name_view.dart';
import 'package:linksys_app/page/dashboard/view/devices/device_detail_view.dart';
import 'package:linksys_app/page/dashboard/view/devices/offline_devices_view.dart';
import 'package:linksys_app/page/dashboard/view/nodes/_nodes.dart';
import 'package:linksys_app/page/dashboard/view/nodes/change_node_name_view.dart';
import 'package:linksys_app/page/dashboard/view/nodes/node_light_guide_view.dart';
import 'package:linksys_app/page/dashboard/view/notifications/notification_settings_page.dart';
import 'package:linksys_app/page/dashboard/view/topology/_topology.dart';
import 'package:linksys_app/page/dashboard/view/topology/topology_view.dart';
import 'package:linksys_app/page/landing/view/_view.dart';
import 'package:linksys_app/page/linkup/view/linkup_view.dart';
import 'package:linksys_app/page/login/view/_view.dart';
import 'package:linksys_app/page/otp_flow/view/_view.dart';
import 'package:linksys_app/page/wifi_settings/view/_view.dart';
import 'package:linksys_app/provider/auth/_auth.dart';
import 'package:linksys_app/provider/otp/otp.dart';

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
    initialLocation: '/',
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
    final managedNetworkId = _ref.read(selectedNetworkIdProvider);
    if (loginType != LoginType.none &&
        managedNetworkId == null &&
        state.matchedLocation != RoutePath.selectNetwork) {
      return RoutePath.prepareDashboard;
    }

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
    logger.d('did push the page - ${route.runtimeType}');
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
