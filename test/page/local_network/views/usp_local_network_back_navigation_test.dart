// The back-navigation stack semantics behind linksys/PrivacyGUI#1421.
//
// Bug: Dashboard > LAN Information > "View details" -> Local Network page, then
// into DHCP Settings ("View DHCP Reservations"), then back twice, landed on
// Advanced Settings instead of the Dashboard.
//
// Root cause (measured with a pumped navigator, matrix below): the
// Local Network -> DHCP Settings hop used `goNamed`, which REPLACES the
// go_router location and drops the Dashboard from the poppable stack.
// `uspDhcpDetail` is a top-level shell sibling, so the `go` unwound the stack to
// a single page: DHCP's back then saw `canPop() == false` and fell through to
// `backFallback: uspLocalNetwork`, which again had no stack, so Local Network's
// back fell through to `backFallback: uspAdvancedSettings` — the reported
// symptom, and exactly the View History in the issue log.
//
// The route-tree nesting of `uspLocalNetwork` under `uspAdvancedSettings` is NOT
// the cause: a plain Dashboard -> Local Network (push) -> back already returns
// to the Dashboard while nested (proven by the first test below). The 2x2 that
// settles it — promoting the route to a shell sibling does not fix the reported
// chain, changing the verb does:
//
//   promoted route | push to DHCP | Dashboard > LN > DHCP > back > back
//   ---------------|--------------|------------------------------------
//   no             | no           | Advanced Settings  (the bug)
//   no             | YES          | Dashboard          (this fix)
//   YES            | no           | Advanced Settings  (still broken)
//   YES            | YES          | Dashboard
//
// Fix: Local Network -> DHCP now uses `pushNamed`; DHCP's back already popped
// via `backFallback`. This mirrors the working DeviceList <-> DeviceDetail model
// (#1029). The Firewall <-> IPv6 Port Service pair has the same root cause and
// is fixed in the companion PR for #1420, not on this branch.
//
// These tests mirror the route nesting and the FIXED navigation verbs with stub
// pages (no USP providers needed) and assert the real navigator stack.
// go_router's push/go stack behavior is counter-intuitive, so it is proven by an
// actually-pumped navigator, not by reasoning about the tree.
//
// Scope, stated plainly. The route names, the paths and `navigateBack` come from
// `lib/`, so a rename or a change to the back-navigation extension breaks this
// file. The production `pushNamed` call site does not — reverting it leaves these
// tests green. What is pinned is the stack semantics the fix relies on, and
// #1421's exact chain through them. Two further gaps, on purpose:
//
//   - Plain `GoRoute`, not `LinksysRoute`: the dirty guard's `onExit` is not in
//     this harness. It changes nothing for a clean page (it returns true), and a
//     dirty page's alert is the guard's own concern, not the stack's.
//   - The fix is about in-session back. On a browser reload / shared link there
//     is no in-memory stack: go_router rebuilds the match from the URL alone, so
//     the Dashboard is not in the history to return to and back unwinds along
//     the URL instead. No verb at a call site can change that. The last two
//     tests pin both cold-URL landings so the limit is asserted rather than
//     asserted-in-prose; it is how every nested page under Advanced Settings
//     behaves and is tracked separately.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';

// Aliases for the REAL route constants, so renaming one in
// lib/route/constants.dart breaks this file at compile time instead of leaving
// it green against a dead name.
const _dashboard = RouteNamed.uspDashboard;
const _advancedSettings = RouteNamed.uspAdvancedSettings;
const _localNetwork = RouteNamed.uspLocalNetwork;
const _dhcpDetail = RouteNamed.uspDhcpDetail;

class _StubPage extends StatelessWidget {
  final String title;
  final Widget? body;

  /// Mirrors `UiKitPageView`'s wiring (ui_kit_page_view.dart:549-552): a page
  /// with a back arrow calls the production `context.navigateBack` extension
  /// with this fallback. Null means no back arrow (the Dashboard).
  final String? backFallback;

  const _StubPage({required this.title, this.body, this.backFallback});

  /// Per-page key: a single shared `back_button` key would be ambiguous while
  /// two routes are mounted during a transition.
  static Key backKey(String title) => Key('back_button_$title');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('PAGE:$title'),
          leading: backFallback != null
              ? IconButton(
                  key: backKey(title),
                  icon: const Icon(Icons.arrow_back),
                  // The real extension, not a copy: pop if possible, else honour
                  // NavigationExtra.backDestination, else goNamed(fallback).
                  onPressed: () => context.navigateBack(fallback: backFallback),
                )
              : null,
        ),
        body: body ?? const SizedBox.shrink(),
      );
}

/// Builds a router matching the REAL topology (`uspLocalNetwork` nested under
/// `uspAdvancedSettings`, `uspDhcpDetail` a top-level shell sibling) and the
/// FIXED navigation verbs:
///   Dashboard -> Local Network : pushNamed (dashboard_card_template.dart:509)
///   Advanced Settings -> Local Network : pushNamed (usp_advanced_settings_view.dart:77)
///   Local Network -> DHCP : pushNamed (usp_local_network_view.dart, the fix)
///   DHCP back : navigateBack(fallback: uspLocalNetwork) (usp_dhcp_detail_view.dart:43, unchanged)
///   Local Network back : navigateBack(fallback: uspAdvancedSettings) (unchanged)
///
/// `initialLocation` models a browser reload or a shared link: F5 gives
/// go_router nothing but the URL, which is exactly a fresh router at that
/// location. `redirect` in the real tree only guards login, so a deep link into
/// a `/usp...` path really does land there.
GoRouter _buildRouter({String? initialLocation}) {
  Widget localNetworkPage(BuildContext c) => _StubPage(
        title: 'LocalNetwork',
        body: Center(
          child: TextButton(
            key: const Key('to_dhcp'),
            onPressed: () => c.pushNamed(_dhcpDetail), // FIX: was goNamed
            child: const Text('View DHCP Reservations'),
          ),
        ),
        backFallback: _advancedSettings,
      );

  const dhcpPage = _StubPage(
    title: 'Dhcp',
    backFallback: _localNetwork,
  );

  return GoRouter(
    initialLocation: initialLocation ?? RoutePath.uspDashboard,
    routes: [
      ShellRoute(
        builder: (c, s, child) => child,
        routes: [
          GoRoute(
            name: _dashboard,
            path: RoutePath.uspDashboard,
            builder: (c, s) => _StubPage(
              title: 'Dashboard',
              body: Center(
                child: TextButton(
                  key: const Key('to_local_network'),
                  onPressed: () => c.pushNamed(_localNetwork),
                  child: const Text('View details'),
                ),
              ),
            ),
          ),
          // uspDhcpDetail is a top-level sibling of uspDashboard (unchanged):
          // that is why a `go` to it wiped the whole stack.
          GoRoute(
            name: _dhcpDetail,
            path: RoutePath.uspDhcpDetail,
            builder: (c, s) => dhcpPage,
          ),
          GoRoute(
            name: _advancedSettings,
            path: RoutePath.uspAdvancedSettings,
            builder: (c, s) => _StubPage(
              title: 'AdvancedSettings',
              body: Center(
                child: TextButton(
                  key: const Key('to_local_network_from_adv'),
                  onPressed: () => c.pushNamed(_localNetwork),
                  child: const Text('Local Network'),
                ),
              ),
            ),
            routes: [
              // uspLocalNetwork stays NESTED under uspAdvancedSettings: the
              // nesting is not the bug, so this fix leaves the tree alone. The
              // relative path is `RoutePath.uspLocalNetwork`, as the real tree
              // now declares it (route_usp_dashboard.dart:158-159). It used to be
              // the NAME here, which mirrored the pre-#1434 tree and passed only
              // because the two constants hold the same string.
              GoRoute(
                name: _localNetwork,
                path: RoutePath.uspLocalNetwork,
                builder: (c, s) => localNetworkPage(c),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  /// Taps the back arrow of the page currently on top, asserting it is there
  /// first so a missing `onBack` reports the page instead of a bare StateError.
  Future<void> back(WidgetTester t, String from) async {
    final button = find.byKey(_StubPage.backKey(from));
    expect(button, findsOneWidget,
        reason: 'expected the back arrow of PAGE:$from to be on screen');
    await t.tap(button);
    await t.pumpAndSettle();
  }

  group('#1421 local network back navigation', () {
    testWidgets('plain: Dashboard > Local Network > back returns to Dashboard',
        (t) async {
      await t.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('to_local_network')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:LocalNetwork'), findsOneWidget);

      await back(t, 'LocalNetwork');
      // Already true before the fix, while nested: this is the control that
      // falsifies "the nesting is the root cause".
      expect(find.text('PAGE:Dashboard'), findsOneWidget,
          reason: 'Back from Local Network must return to Dashboard');
    });

    testWidgets(
        'reported chain: Dashboard > Local Network > DHCP > back > back returns '
        'to Dashboard', (t) async {
      await t.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('to_local_network')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:LocalNetwork'), findsOneWidget);

      await t.tap(find.byKey(const Key('to_dhcp')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:Dhcp'), findsOneWidget);

      // First back: DHCP -> Local Network.
      await back(t, 'Dhcp');
      expect(find.text('PAGE:LocalNetwork'), findsOneWidget,
          reason: 'Back from DHCP Settings must return to Local Network');

      // Second back: Local Network -> Dashboard (the reported failure was
      // Advanced Settings). This is the assertion that fails on `goNamed`.
      await back(t, 'LocalNetwork');
      expect(find.text('PAGE:Dashboard'), findsOneWidget,
          reason: 'Final back must return to Dashboard, not Advanced Settings');
    });

    testWidgets(
        'regression: Advanced Settings > Local Network > back returns to '
        'Advanced Settings', (t) async {
      final router = _buildRouter();
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      await t.pumpAndSettle();

      // Advanced Settings is reached from the menu with `go`, so it becomes the
      // stack root — the second real entry point into Local Network.
      router.goNamed(_advancedSettings);
      await t.pumpAndSettle();
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget);

      await t.tap(find.byKey(const Key('to_local_network_from_adv')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:LocalNetwork'), findsOneWidget);

      await back(t, 'LocalNetwork');
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason:
              'Local Network reached via Advanced Settings must return there');
    });

    testWidgets(
        'regression: Advanced Settings > Local Network > DHCP > back > back '
        'returns to Advanced Settings', (t) async {
      final router = _buildRouter();
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      await t.pumpAndSettle();

      router.goNamed(_advancedSettings);
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('to_local_network_from_adv')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('to_dhcp')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:Dhcp'), findsOneWidget);

      await back(t, 'Dhcp'); // DHCP -> Local Network
      expect(find.text('PAGE:LocalNetwork'), findsOneWidget);

      await back(t, 'LocalNetwork'); // Local Network -> Advanced Settings
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason: 'Entering via Advanced Settings must unwind back to it');
    });

    // The two cold-URL cases: what a reload or a shared link does. Raised in
    // review as "does #1421 still reproduce on F5?" — it does end on Advanced
    // Settings, and these pin why that is the URL's answer and not the fix's.

    testWidgets(
        'cold URL onto Local Network pops to Advanced Settings (the nested URL '
        'rebuilds the parent, so canPop is true and the fallback never fires)',
        (t) async {
      await t.pumpWidget(MaterialApp.router(
          routerConfig: _buildRouter(
              initialLocation:
                  '${RoutePath.uspAdvancedSettings}/$_localNetwork')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:LocalNetwork'), findsOneWidget);

      await back(t, 'LocalNetwork');
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason: 'a cold nested URL has no entry point to return to');
    });

    testWidgets(
        'cold URL onto DHCP unwinds to Advanced Settings (fallback chain, since '
        'a top-level URL leaves nothing to pop)', (t) async {
      await t.pumpWidget(MaterialApp.router(
          routerConfig:
              _buildRouter(initialLocation: RoutePath.uspDhcpDetail)));
      await t.pumpAndSettle();
      expect(find.text('PAGE:Dhcp'), findsOneWidget);

      // canPop() is false here, so this hop is the `backFallback` goNamed —
      // which then rebuilds Advanced Settings as Local Network's parent.
      await back(t, 'Dhcp');
      expect(find.text('PAGE:LocalNetwork'), findsOneWidget);

      await back(t, 'LocalNetwork');
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason:
              'the fallback chain ends at the URL parent, not the Dashboard');
    });
  });
}
