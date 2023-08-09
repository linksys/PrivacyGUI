import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/page/dashboard/view/_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/_administration.dart';
import 'package:linksys_moab/page/dashboard/view/administration/internet_settings/internet_settings_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_menu_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_shell.dart';
import 'package:linksys_moab/page/dashboard/view/devices/_devices.dart';
import 'package:linksys_moab/page/dashboard/view/topology/_topology.dart';
import 'package:linksys_moab/page/landing/view/_view.dart';
import 'package:linksys_moab/page/login/view/_view.dart';
import 'package:linksys_moab/page/wifi_settings/view/_view.dart';
import 'package:linksys_moab/provider/auth/_auth.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/model/administration_path.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../page/dashboard/view/administration/lan/lan_view.dart';

part 'route_home.dart';
part 'route_login.dart';
part 'route_dashboard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);
  return GoRouter(
    refreshListenable: router,
    routes: [
      homeRoute,
      GoRoute(
        name: 'prepareDashboard',
        path: '/prepareDashboard',
        builder: (context, state) => PrepareDashboardView(),
      ),
      GoRoute(
        name: 'selectNetwork',
        path: '/selectNetwork',
        builder: (context, state) => SelectNetworkView(),
      ),
      GoRoute(
        path: '/fullScreenSpinner',
        builder: (context, state) => AppFullScreenSpinner(),
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

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }

  String? _redirectLogic(GoRouterState state) {
    if (state.matchedLocation == '/') {
      final auth = _ref.watch(authProvider);
      final loginType = auth.value?.loginType ?? LoginType.none;
      if (auth.isLoading) {
        return '/fullScreenSpinner';
      } else {
        switch (loginType) {
          case LoginType.remote:
            return '/prepareDashboard';
          case LoginType.local:
            return '/prepareDashboard';
          default:
            return null;
        }
      }
    }
    return null;
  }
}
