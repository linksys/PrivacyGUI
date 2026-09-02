// The health dialog's action-button navigation, behind linksys/PrivacyGUI#1435.
//
// Bug: 4 of the 9 dimension action buttons did nothing. The shell navigated with
// `context.push(routeName)`, but `push` takes a *location* and every dimension
// supplies a `RouteNamed.*` value. go_router's `normalizeUri` prepends a slash to
// a path that lacks one (configuration.dart:264-266), so `'uspFirewall'` became
// the root-level `/uspFirewall` — and Firewall is registered as a relative child
// of `/uspAdvancedSettings`, so that location matched no route.
//
// The five that appeared to work did so only because a top-level route's name and
// its path happen to be the same string. That is a coincidence, not a design, and
// the tests below assert it as one: `push` is checked to succeed for the five and
// to hit the error builder for the four, so the mechanism is pinned rather than
// described.
//
// Fix: `pushHealthActionTarget` (usp_dashboard_shell.dart) uses `pushNamed`, which
// resolves through the route tree and builds the nested location.
//
// Scope, stated plainly:
//
//   - This DOES bite the production call site. The verb lives in a named
//     top-level function which these tests call directly, so reverting it to
//     `push` turns the four nested cases red. That is the whole reason the
//     closure was lifted out of `build`.
//   - The route NAMES come from `lib/route/constants.dart`, so a rename breaks
//     this file at compile time, and the target SET is checked against the real
//     `HealthDimensions` registry, so adding a tenth target fails here until its
//     nesting is declared.
//   - What is NOT guarded HERE: `_targets`' locations mirror
//     `route_usp_dashboard.dart` by hand, so re-nesting a route there without
//     touching this file leaves these green. That gap is now closed one level up
//     — `test/route/usp_navigation_invariants_test.dart` walks the real tree and
//     pins every location it produces (#1434), so a re-nesting fails there. This
//     file keeps its hand-written mirror on purpose: it is what makes the `push`
//     vs `pushNamed` mechanism visible at all.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension_registry.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';
import 'package:privacy_gui/route/constants.dart';

/// Every distinct health-action target, mapped to the location the REAL tree
/// gives it (`lib/route/route_usp_dashboard.dart`).
///
/// The four nested locations below used to be the odd ones, and they were odd in
/// `lib/`, not here: `uspInternetSettings` was the only nested `RoutePath`
/// constant written relative, while `uspUnifiedDiagnostics`, `uspFirewall` and
/// `uspDmz` were declared **absolute** despite being children — `concatenatePaths`
/// splits on `/` and drops empty segments, so the leading slash was silently
/// discarded and the declaration read root-level. #1434 made the slash mean what
/// it says (relative for a nested child) and pins it in
/// `test/route/usp_navigation_invariants_test.dart`. The locations below are
/// unchanged by that, which is exactly the point: it was a declaration fix, not a
/// routing change.
const _targets = <String, String>{
  // Nested — these four were the dead buttons.
  RouteNamed.uspUnifiedDiagnostics: '/uspMenu/uspUnifiedDiagnostics',
  RouteNamed.uspInternetSettings: '/uspAdvancedSettings/uspInternetSettings',
  RouteNamed.uspFirewall: '/uspAdvancedSettings/uspFirewall',
  RouteNamed.uspDmz: '/uspAdvancedSettings/uspDmz',
  // Top level — these five worked by coincidence.
  RouteNamed.uspWifiSettings: '/uspWifiSettings',
  RouteNamed.uspDeviceList: '/uspDeviceList',
  RouteNamed.uspTopology: '/uspTopology',
  RouteNamed.uspAdmin: '/uspAdmin',
  RouteNamed.uspFirmwareUpdate: '/uspFirmwareUpdate',
};

/// The four targets whose location is nested, i.e. the ones `push` cannot reach.
const _nestedTargets = <String>{
  RouteNamed.uspUnifiedDiagnostics,
  RouteNamed.uspInternetSettings,
  RouteNamed.uspFirewall,
  RouteNamed.uspDmz,
};

const _notFound = 'NOT_FOUND';

Widget _stub(String name) => Scaffold(body: Center(child: Text('PAGE:$name')));

/// Mirrors the real topology for the nine targets. `onShellContext` receives the
/// shell's `BuildContext` — the same context production closes over when it wires
/// `HealthDialogProviderArgs.onNavigate` (usp_dashboard_shell.dart).
GoRouter _buildRouter(void Function(BuildContext) onShellContext) {
  GoRoute route(String name, String path,
          {List<RouteBase> routes = const []}) =>
      GoRoute(
        name: name,
        path: path,
        builder: (c, s) => _stub(name),
        routes: routes,
      );

  return GoRouter(
    initialLocation: RoutePath.uspDashboard,
    errorBuilder: (c, s) => _stub(_notFound),
    routes: [
      ShellRoute(
        builder: (c, s, child) {
          onShellContext(c);
          return child;
        },
        routes: [
          route(RouteNamed.uspDashboard, RoutePath.uspDashboard),
          route(RouteNamed.uspMenu, RoutePath.uspMenu, routes: [
            // Absolute child path, exactly as declared at :55.
            route(RouteNamed.uspUnifiedDiagnostics,
                RoutePath.uspUnifiedDiagnostics),
          ]),
          route(RouteNamed.uspDeviceList, RoutePath.uspDeviceList),
          route(RouteNamed.uspTopology, RoutePath.uspTopology),
          route(RouteNamed.uspAdmin, RoutePath.uspAdmin),
          route(RouteNamed.uspFirmwareUpdate, RoutePath.uspFirmwareUpdate),
          route(RouteNamed.uspWifiSettings, RoutePath.uspWifiSettings),
          route(RouteNamed.uspAdvancedSettings, RoutePath.uspAdvancedSettings,
              routes: [
                // The real tree passes RoutePath here for Internet Settings and
                // RouteNamed for the other two (:151 vs :166, :173).
                route(RouteNamed.uspInternetSettings,
                    RoutePath.uspInternetSettings),
                route(RouteNamed.uspFirewall, RouteNamed.uspFirewall),
                route(RouteNamed.uspDmz, RouteNamed.uspDmz),
              ]),
        ],
      ),
    ],
  );
}

void main() {
  /// Pumps the probe router and returns the shell context, which is what the
  /// production callback holds.
  Future<(GoRouter, BuildContext)> pumpShell(WidgetTester t) async {
    BuildContext? shell;
    final router = _buildRouter((c) => shell = c);
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    expect(find.text('PAGE:${RouteNamed.uspDashboard}'), findsOneWidget,
        reason: 'the probe router must start on the Dashboard');
    return (router, shell!);
  }

  group('#1435 health dialog action navigation', () {
    testWidgets('every action target in the registry is covered here',
        (t) async {
      final declared = <String>{};

      await t.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (c) {
          // The registry is the SSOT for "every dimension", so a seventh
          // dimension or a new action is picked up without editing this test —
          // it just fails until its nesting is declared in _targets.
          for (final dimension in HealthDimensions.all) {
            for (final action in dimension.getActions(c)) {
              if (action.routeName != null) declared.add(action.routeName!);
            }
          }
          return const SizedBox.shrink();
        }),
      ));
      await t.pumpAndSettle();

      expect(declared, isNotEmpty,
          reason: 'getActions returned nothing — the harness is measuring air');
      expect(declared, _targets.keys.toSet(),
          reason: 'a health action target is not declared in _targets, so its '
              'nesting is unverified — add it with the location '
              'route_usp_dashboard.dart gives it');
    });

    // The fix. Each of these fails on `push`, which is the point.
    for (final entry in _targets.entries) {
      final name = entry.key;
      final location = entry.value;
      final nested = _nestedTargets.contains(name);

      testWidgets(
          'pushHealthActionTarget reaches $name at $location'
          '${nested ? ' (was dead before #1435)' : ''}', (t) async {
        final (router, shell) = await pumpShell(t);

        pushHealthActionTarget(shell, name);
        await t.pumpAndSettle();

        expect(find.text('PAGE:$name'), findsOneWidget,
            reason: 'the named API must resolve $name through the route tree');
        expect(router.state.uri.toString(), location,
            reason: 'and land on the location the real tree declares');
      });
    }

    // Why it was 4 of 9 and not 9 of 9: the mechanism, asserted.
    for (final name in _targets.keys) {
      final nested = _nestedTargets.contains(name);

      testWidgets(
          'the location form of $name ${nested ? 'matches no route' : 'matches, '
              'which is the coincidence that masked the bug'}', (t) async {
        final (_, shell) = await pumpShell(t);

        // This is the pre-#1435 production call, verbatim.
        shell.push(name);
        await t.pumpAndSettle();

        if (nested) {
          expect(find.text('PAGE:$_notFound'), findsOneWidget,
              reason:
                  '/$name is root-level and $name is a nested child, so the '
                  'button silently did nothing');
        } else {
          expect(find.text('PAGE:$name'), findsOneWidget,
              reason:
                  'a top-level route whose name equals its path is reachable '
                  'either way — masking, not correctness');
        }
      });
    }
  });
}
