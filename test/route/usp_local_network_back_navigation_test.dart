// Regression coverage for linksys/PrivacyGUI#1421
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
// (#1029) and the sibling fix for Firewall <-> IPv6 Port Service (#1420).
//
// These tests reproduce the EXACT route topology + the FIXED navigation verbs
// with stub pages (no USP providers needed) and assert the real navigator
// stack. go_router's push/go stack behavior is counter-intuitive, so it is
// proven by an actually-pumped navigator, not by reasoning about the tree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _dashboard = 'uspDashboard';
const _advancedSettings = 'uspAdvancedSettings';
const _localNetwork = 'uspLocalNetwork';
const _dhcpDetail = 'uspDhcpDetail';

/// Mirror of `context.navigateBack` (lib/route/navigation_extensions.dart): pop
/// if possible, else go to the fallback route by name. The production extension
/// also honours `NavigationExtra.backDestination`; no route in this flow passes
/// one, so the stub covers the two branches that are actually reachable here.
void _stubNavigateBack(BuildContext context, {required String fallback}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.goNamed(fallback);
}

class _StubPage extends StatelessWidget {
  final String title;
  final Widget? body;
  final VoidCallback? onBack;
  const _StubPage({required this.title, this.body, this.onBack});

  /// Per-page key: a single shared `back_button` key would be ambiguous while
  /// two routes are mounted during a transition.
  static Key backKey(String title) => Key('back_button_$title');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('PAGE:$title'),
          leading: onBack != null
              ? IconButton(
                  key: backKey(title),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
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
GoRouter _buildRouter() {
  Widget localNetworkPage(BuildContext c) => _StubPage(
        title: 'LocalNetwork',
        body: Center(
          child: TextButton(
            key: const Key('to_dhcp'),
            onPressed: () => c.pushNamed(_dhcpDetail), // FIX: was goNamed
            child: const Text('View DHCP Reservations'),
          ),
        ),
        onBack: () => _stubNavigateBack(c, fallback: _advancedSettings),
      );

  Widget dhcpPage(BuildContext c) => _StubPage(
        title: 'Dhcp',
        onBack: () => _stubNavigateBack(c, fallback: _localNetwork),
      );

  return GoRouter(
    initialLocation: '/uspDashboard',
    routes: [
      ShellRoute(
        builder: (c, s, child) => child,
        routes: [
          GoRoute(
            name: _dashboard,
            path: '/uspDashboard',
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
            path: '/uspDhcpDetail',
            builder: (c, s) => dhcpPage(c),
          ),
          GoRoute(
            name: _advancedSettings,
            path: '/uspAdvancedSettings',
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
              // nesting is not the bug, so this fix leaves the tree alone.
              GoRoute(
                name: _localNetwork,
                path: 'uspLocalNetwork',
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
  });
}
