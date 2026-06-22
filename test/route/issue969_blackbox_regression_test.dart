// Independent black-box / regression coverage for issue #969.
//
// Authored by the INTEGRATION/E2E verification sub-agent (NOT the implementer).
// These assertions are written against the FROZEN acceptance criteria, exercising
// the REAL production route tree (uspDashboardRoute) — complementing the dev's
// behavioral tests which run on a hand-built replica.
//
// AC1  Dashboard -> PF detail -> back -> Dashboard (incl. web canonical-URL).
// AC2  Advanced Settings -> PF detail -> back -> Advanced Settings (no regression).
// AC3  Dashboard has NO Instant Privacy entry (claim verification).
// AC-原則 The advanced-settings sub-routes must NOT be collaterally damaged.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/route/constants.dart';

void main() {
  List<RouteBase> shellRoutes() => uspDashboardRoute.routes;

  GoRoute? directChild(String name) {
    for (final r in shellRoutes()) {
      if (r is GoRoute && r.name == name) return r;
    }
    return null;
  }

  GoRoute? childOf(GoRoute parent, String name) {
    for (final r in parent.routes) {
      if (r is GoRoute && r.name == name) return r;
    }
    return null;
  }

  group('#969 black-box: real production route structure', () {
    test('AC1 structure: uspPortForwardingDetail is a DIRECT child of the '
        'dashboard ShellRoute (flat canonical URL)', () {
      final pf = directChild(RouteNamed.uspPortForwardingDetail);
      expect(pf, isNotNull,
          reason: 'PF detail must be a parallel direct child of the shell');
      // Canonical URL is a single flat top-level segment.
      expect(pf!.path, RoutePath.uspPortForwardingDetail);
      expect(pf.path, '/uspPortForwardingDetail');
      expect('/'.allMatches(pf.path).length, 1,
          reason: 'flat top-level path => exactly one slash => no synthetic '
              'Advanced Settings parent on web reload/deep-link');
    });

    test('AC2 + AC-原則: uspAdvancedSettings still exists as a direct shell '
        'child AND retains ALL six legitimate nested sub-routes', () {
      final adv = directChild(RouteNamed.uspAdvancedSettings);
      expect(adv, isNotNull);

      // The six sub-routes that MUST remain nested (back -> Advanced Settings).
      const expectedNested = [
        RouteNamed.uspInternetSettings,
        RouteNamed.uspLocalNetwork,
        RouteNamed.uspFirewall,
        RouteNamed.uspDmz,
        RouteNamed.uspStaticRouting,
        RouteNamed.uspIpv6PortService,
      ];
      for (final name in expectedNested) {
        expect(childOf(adv!, name), isNotNull,
            reason: '$name must remain nested under uspAdvancedSettings '
                '(must not be collaterally un-nested by the #969 fix)');
      }
      expect(adv!.routes.whereType<GoRoute>().length, expectedNested.length,
          reason: 'Advanced Settings should have exactly the six known '
              'sub-routes — no more (PF detail must be gone), no fewer.');
    });

    test('AC2 regression: uspPortForwardingDetail is NOT nested under '
        'uspAdvancedSettings anymore', () {
      final adv = directChild(RouteNamed.uspAdvancedSettings)!;
      expect(childOf(adv, RouteNamed.uspPortForwardingDetail), isNull,
          reason: 'PF detail must no longer be a child of Advanced Settings');
    });

    test('AC3: Instant Privacy is a parallel shell sibling, NOT under '
        'Advanced Settings and NOT under Dashboard', () {
      // It exists as its own top-level shell child (parallel route).
      expect(directChild(RouteNamed.uspInstantPrivacy), isNotNull);

      // It is NOT a child of Advanced Settings.
      final adv = directChild(RouteNamed.uspAdvancedSettings)!;
      expect(childOf(adv, RouteNamed.uspInstantPrivacy), isNull);

      // The dashboard route itself has no nested Instant Privacy child.
      final dash = directChild(RouteNamed.uspDashboard)!;
      expect(childOf(dash, RouteNamed.uspInstantPrivacy), isNull);
    });
  });
}
