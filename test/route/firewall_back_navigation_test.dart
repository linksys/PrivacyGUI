// Regression coverage for linksys/PrivacyGUI#1420
//
// Bug: Dashboard > Firewall Overview > "View details" -> Firewall page, then
// into IPv6 Port Service, then back twice, landed on Advanced Settings instead
// of the Dashboard.
//
// Root cause (proven with a pumped navigator, see the fix commit): the
// Firewall <-> IPv6 Port Service hops used `goNamed`, which REPLACES the
// go_router location and drops the Dashboard from the poppable stack. After the
// go-dance, `canPop()` was false on Firewall, so its back arrow fell through to
// `backFallback: uspAdvancedSettings`. The route-tree nesting of `uspFirewall`
// under `uspAdvancedSettings` is NOT the cause here: a plain
// Dashboard -> Firewall (push) -> back already returns to the Dashboard even
// while nested (verified below).
//
// Fix: Firewall -> IPv6 now uses `pushNamed`, and IPv6's back pops (via
// `backFallback`) instead of `goNamed`. This mirrors the working
// DeviceList <-> DeviceDetail model (#1029).
//
// These tests reproduce the EXACT route topology + the FIXED navigation verbs
// with stub pages (no USP providers needed) and assert the real navigator
// stack. go_router's nested-route stack behavior is counter-intuitive, so the
// behavior is proven by an actually-pumped navigator, not by reasoning.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _dashboard = 'uspDashboard';
const _advancedSettings = 'uspAdvancedSettings';
const _firewall = 'uspFirewall';
const _ipv6 = 'uspIpv6PortService';

/// Test double for `context.navigateBack` (lib/route/navigation_extensions.dart):
/// pop if possible, else go to the fallback route by name.
///
/// The production extension has a third branch that honours
/// `NavigationExtra.backDestination` between the two. It is left out because no
/// call site in `lib/` sets `backDestination` (the three `NavigationExtra(...)`
/// constructions pass only `data` / `naviType`), so that branch is unreachable
/// for every route in this flow.
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

  /// Per-page key. A single shared `back_button` key would be ambiguous while
  /// two routes are mounted at once, and it makes a wrong-page tap silently
  /// look like a pass.
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

/// Builds a router matching the REAL topology (uspFirewall nested under
/// uspAdvancedSettings, uspIpv6PortService as its sibling) and the FIXED
/// navigation verbs:
///   Dashboard -> Firewall : pushNamed (dashboard_card_template.dart)
///   Advanced Settings -> Firewall : pushNamed (usp_advanced_settings_view.dart)
///   Firewall -> IPv6 : pushNamed (usp_firewall_view.dart, the fix)
///   IPv6 back : navigateBack(fallback: uspFirewall) (usp_ipv6_port_service_view.dart, the fix)
///   Firewall back : navigateBack(fallback: uspAdvancedSettings) (unchanged)
///
/// [initialLocation] models a cold start / browser refresh straight onto a URL;
/// the redirect in `router_provider.dart` returns `state.uri` unchanged for
/// `/usp...` paths when logged in, so a deep link really does land there.
GoRouter _buildRouter({String initialLocation = '/uspDashboard'}) {
  Widget firewallPage(BuildContext c) => _StubPage(
        title: 'Firewall',
        body: Center(
          child: TextButton(
            key: const Key('to_ipv6'),
            onPressed: () => c.pushNamed(_ipv6), // FIX: was goNamed
            child: const Text('IPv6 Port Service'),
          ),
        ),
        onBack: () => _stubNavigateBack(c, fallback: _advancedSettings),
      );

  Widget ipv6Page(BuildContext c) => _StubPage(
        title: 'IPv6',
        // FIX: backFallback -> navigateBack (pop), was goNamed(uspFirewall).
        onBack: () => _stubNavigateBack(c, fallback: _firewall),
      );

  return GoRouter(
    initialLocation: initialLocation,
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
                  key: const Key('to_firewall'),
                  onPressed: () => c.pushNamed(_firewall),
                  child: const Text('View details'),
                ),
              ),
            ),
          ),
          GoRoute(
            name: _advancedSettings,
            path: '/uspAdvancedSettings',
            builder: (c, s) => _StubPage(
              title: 'AdvancedSettings',
              body: Center(
                child: TextButton(
                  key: const Key('to_firewall_from_adv'),
                  onPressed: () => c.pushNamed(_firewall),
                  child: const Text('Firewall'),
                ),
              ),
            ),
            routes: [
              // uspFirewall stays NESTED under uspAdvancedSettings (unchanged).
              GoRoute(
                name: _firewall,
                path: 'uspFirewall',
                builder: (c, s) => firewallPage(c),
              ),
              // uspIpv6PortService is its sibling under uspAdvancedSettings.
              GoRoute(
                name: _ipv6,
                path: 'uspIpv6PortService',
                builder: (c, s) => ipv6Page(c),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  /// Taps the back arrow of PAGE:[from], asserting it is on screen first so a
  /// missing `onBack` names the page instead of throwing a bare StateError.
  Future<void> back(WidgetTester t, String from) async {
    final button = find.byKey(_StubPage.backKey(from));
    expect(button, findsOneWidget,
        reason: 'expected the back arrow of PAGE:$from to be on screen');
    await t.tap(button);
    await t.pumpAndSettle();
  }

  group('#1420 firewall back navigation', () {
    testWidgets('plain: Dashboard > Firewall > back returns to Dashboard',
        (t) async {
      await t.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('to_firewall')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:Firewall'), findsOneWidget);

      await back(t, 'Firewall');
      // Already true before the fix, while nested: this is the control that
      // falsifies "the nesting is the root cause".
      expect(find.text('PAGE:Dashboard'), findsOneWidget,
          reason: 'Back from Firewall must return to Dashboard');
    });

    testWidgets(
        'reported chain: Dashboard > Firewall > IPv6 > back > back returns to '
        'Dashboard', (t) async {
      await t.pumpWidget(MaterialApp.router(routerConfig: _buildRouter()));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('to_firewall')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:Firewall'), findsOneWidget);

      await t.tap(find.byKey(const Key('to_ipv6')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:IPv6'), findsOneWidget);

      // First back: IPv6 -> Firewall.
      await back(t, 'IPv6');
      expect(find.text('PAGE:Firewall'), findsOneWidget,
          reason: 'Back from IPv6 must return to Firewall');

      // Second back: Firewall -> Dashboard (the reported failure was Advanced
      // Settings).
      await back(t, 'Firewall');
      expect(find.text('PAGE:Dashboard'), findsOneWidget,
          reason: 'Final back must return to Dashboard, not Advanced Settings');
    });

    testWidgets(
        'regression: Advanced Settings > Firewall > back returns to Advanced '
        'Settings', (t) async {
      final router = _buildRouter();
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      await t.pumpAndSettle();

      // Advanced Settings is reached from the menu with `go`
      // (usp_menu_view.dart:115), so it becomes the stack root — the second real
      // entry point into Firewall.
      router.goNamed(_advancedSettings);
      await t.pumpAndSettle();
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget);

      await t.tap(find.byKey(const Key('to_firewall_from_adv')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:Firewall'), findsOneWidget);

      await back(t, 'Firewall');
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason: 'Firewall reached via Advanced Settings must return there');
    });

    testWidgets(
        'regression: Advanced Settings > Firewall > IPv6 > back > back returns '
        'to Advanced Settings', (t) async {
      final router = _buildRouter();
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      await t.pumpAndSettle();

      // Same `go`-rooted entry as the previous case.
      router.goNamed(_advancedSettings);
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('to_firewall_from_adv')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('to_ipv6')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:IPv6'), findsOneWidget);

      await back(t, 'IPv6'); // IPv6 -> Firewall
      expect(find.text('PAGE:Firewall'), findsOneWidget);

      await back(t, 'Firewall'); // Firewall -> Advanced Settings
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason: 'Entering via Advanced Settings must unwind back to it');
    });

    // Pins the one behaviour this PR does change outside the reported chain.
    //
    // On a cold start / browser refresh straight onto the IPv6 URL there is no
    // pushed stack, but the URL is nested, so go_router reconstructs
    // [AdvancedSettings, IPv6] and `canPop()` is TRUE. `backFallback` therefore
    // never fires: back pops to Advanced Settings, whereas the old
    // unconditional `goNamed(uspFirewall)` always landed on Firewall.
    //
    // Accepted, not a regression to chase: the landing page is the parent in the
    // URL, which is what every other nested page does on refresh (Local Network,
    // DMZ, Static Routing all pop to Advanced Settings). Making back land on
    // Firewall would require nesting uspIpv6PortService under uspFirewall — a
    // route-tree change, deliberately out of scope for this minimal fix.
    testWidgets(
        'deep link straight onto IPv6 pops to Advanced Settings (fallback does '
        'not fire — canPop is true from the nested URL)', (t) async {
      await t.pumpWidget(MaterialApp.router(
          routerConfig: _buildRouter(
              initialLocation: '/uspAdvancedSettings/uspIpv6PortService')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:IPv6'), findsOneWidget);

      await back(t, 'IPv6');
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason: 'a nested deep link rebuilds the parent, so back pops to it');
    });
  });
}
