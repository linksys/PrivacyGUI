import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart'
    as preview;
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../../../../common/config.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/mock_instant_verify_pivot_notifier.dart' as fixture;

// Shared setup for the Instant-Test screenshot (localization golden) tests.
//
// Instant-Test strings are hardcoded English, so every locale renders the same
// English text; the screenshots still show layout at each width.
//
// Pages open through the real Instant-Test route tree (Menu → Instant-Test →
// details / help), inside the DashboardShell, as `testableRouteShellWidget`
// does for single-route pages. Data comes from mock notifiers only — the
// preview notifier's built-in scenarios or a fixed state — and the browser
// probes use the preview's fixed-result service. Nothing calls a router.

/// Instant-Test home, as the Menu route opens it.
const instantTestHome = '/dashboardMenu/menuInstantTest';

/// A help flow page, as its route opens it.
String helpFlow(int flow) => '$instantTestHome/help?flow=$flow';

/// Long pages: mobile captures are tall enough to show the whole flow.
final instantTestScreens = [
  ...responsiveMobileScreens.map((e) => e.copyWith(height: 1600)),
  ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)),
];

Widget instantTestLocApp({
  required Locale locale,
  String location = instantTestHome,
  InstantVerifyPivotNotifier Function()? pivot,
  BrowserDiagnosticService? service,
  ThemeMode themeMode = ThemeMode.system,
}) {
  final router = GoRouter(
    navigatorKey: shellNavigatorKey,
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          LinksysRoute(
            name: RouteNamed.dashboardMenu,
            path: RoutePath.dashboardMenu,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Menu page'))),
            routes: [
              menus.firstWhere(
                  (route) => route.name == RouteNamed.menuInstantTest),
            ],
          ),
        ],
      ),
    ],
  );
  return testableRouter(
    router: router,
    locale: locale,
    themeMode: themeMode,
    overrides: [
      instantVerifyPivotProvider
          .overrideWith(pivot ?? preview.MockInstantVerifyPivotNotifier.new),
      browserDiagnosticServiceProvider
          .overrideWithValue(service ?? preview.MockBrowserDiagnosticService()),
    ],
  );
}

/// A notifier that holds [state] as-is (fetch does nothing).
InstantVerifyPivotNotifier Function() fixedState(
        InstantVerifyPivotState state) =>
    () => fixture.MockInstantVerifyPivotNotifier(state);

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Taps the first text containing [text].
Future<void> tapTextContaining(WidgetTester tester, String text) async {
  final target = find.textContaining(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
