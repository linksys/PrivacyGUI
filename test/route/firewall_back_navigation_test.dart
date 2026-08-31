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

/// Mirror of `context.navigateBack` (lib/route/navigation_extensions.dart): pop
/// if possible, else go to the fallback route by name.
void _navigateBack(BuildContext context, {required String fallback}) {
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
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('PAGE:$title'),
          leading: onBack != null
              ? IconButton(
                  key: const Key('back_button'),
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
GoRouter _buildRouter() {
  Widget firewallPage(BuildContext c) => _StubPage(
        title: 'Firewall',
        body: Center(
          child: TextButton(
            key: const Key('to_ipv6'),
            onPressed: () => c.pushNamed(_ipv6), // FIX: was goNamed
            child: const Text('IPv6 Port Service'),
          ),
        ),
        onBack: () => _navigateBack(c, fallback: _advancedSettings),
      );

  Widget ipv6Page(BuildContext c) => _StubPage(
        title: 'IPv6',
        // FIX: backFallback -> navigateBack (pop), was goNamed(uspFirewall).
        onBack: () => _navigateBack(c, fallback: _firewall),
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
  Future<void> back(WidgetTester t) async {
    await t.tap(find.byKey(const Key('back_button')));
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

      await back(t);
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
      await back(t);
      expect(find.text('PAGE:Firewall'), findsOneWidget,
          reason: 'Back from IPv6 must return to Firewall');

      // Second back: Firewall -> Dashboard (the reported failure was Advanced
      // Settings).
      await back(t);
      expect(find.text('PAGE:Dashboard'), findsOneWidget,
          reason: 'Final back must return to Dashboard, not Advanced Settings');
    });

    testWidgets(
        'regression: Advanced Settings > Firewall > back returns to Advanced '
        'Settings', (t) async {
      final router = _buildRouter();
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      await t.pumpAndSettle();

      router.goNamed(_advancedSettings);
      await t.pumpAndSettle();
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget);

      await t.tap(find.byKey(const Key('to_firewall_from_adv')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:Firewall'), findsOneWidget);

      await back(t);
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason: 'Firewall reached via Advanced Settings must return there');
    });

    testWidgets(
        'regression: Advanced Settings > Firewall > IPv6 > back > back returns '
        'to Advanced Settings', (t) async {
      final router = _buildRouter();
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      await t.pumpAndSettle();

      router.goNamed(_advancedSettings);
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('to_firewall_from_adv')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('to_ipv6')));
      await t.pumpAndSettle();
      expect(find.text('PAGE:IPv6'), findsOneWidget);

      await back(t); // IPv6 -> Firewall
      expect(find.text('PAGE:Firewall'), findsOneWidget);

      await back(t); // Firewall -> Advanced Settings
      expect(find.text('PAGE:AdvancedSettings'), findsOneWidget,
          reason: 'Entering via Advanced Settings must unwind back to it');
    });
  });
}
