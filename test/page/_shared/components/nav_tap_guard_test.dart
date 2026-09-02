// Regression coverage for linksys/PrivacyGUI#1445
//
// Bug: the two shared entry components forward a tap straight into
// `context.pushNamed(...)` with no re-entrancy guard, so a double-tap yields
// TWO stack entries for the same page — two backs to leave, one shared
// provider behind both, a dirty-page prompt that fires twice. `goNamed` used
// to hide it (replacing a location twice is the same location); it surfaced
// once the verb became `pushNamed` (#1434).
//
//   DashboardCardTemplate : lib/page/_shared/components/dashboard_card_template.dart
//   NavLinkBlock          : lib/page/_shared/components/layout_blocks/setting_blocks.dart
//
// Fix: both route their tap through `NavTapGuard`, a same-gesture guard that
// swallows the second tap of a double-tap and re-arms on the next frame.
//
// These tests pump the REAL production components under a real go_router (no
// USP providers needed) and count how many times the detail route is built.
// A double-tap must build it once; a later, separate tap must build it again
// (Acceptance #4 — same-gesture guard, not a route-level dedup). Reverting the
// guard on either component turns the matching "double tap" case red, because
// the two taps then reach `pushNamed` twice within the same frame.
//
// Same-gesture is modelled the way a real double-tap arrives: two `tap()`
// calls with no settling frame between them, so both are dispatched before the
// guard's post-frame re-arm runs. The subsequent `pumpAndSettle` + a fresh tap
// is a new frame, i.e. a legitimate later navigation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks/setting_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

const _home = 'home';
const _detail = 'detail';

void main() {
  // Without an AppTheme the kit's spacing resolves to degenerate values and the
  // footer link can be laid out off-screen, making the tap target unhittable.
  final testTheme = AppTheme.create(
    brightness: Brightness.light,
    seedColor: Colors.blue,
    designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
  );

  /// Builds a router with a stub detail route whose builder bumps [buildCount],
  /// and a home route hosting [entry]. Pushing `detail` twice therefore shows
  /// up as `buildCount == 2` — one entry per push.
  GoRouter buildRouter(
      Widget Function(BuildContext) entry, List<int> buildCount) {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          name: _home,
          path: '/home',
          builder: (c, s) => Scaffold(body: Center(child: entry(c))),
        ),
        GoRoute(
          name: _detail,
          path: '/detail',
          builder: (c, s) {
            buildCount[0]++;
            return const Scaffold(body: Center(child: Text('PAGE:detail')));
          },
        ),
      ],
    );
  }

  Future<void> pump(WidgetTester t, GoRouter router) async {
    await t.pumpWidget(MaterialApp.router(
      theme: testTheme,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await t.pumpAndSettle();
  }

  group('#1445 a double-tap on a shared entry component pushes once', () {
    testWidgets('DashboardCardTemplate detail link: double-tap => one push',
        (t) async {
      final count = [0];
      final router = buildRouter(
        (c) => SizedBox(
          width: 420,
          height: 260,
          child: DashboardCardTemplate(
            title: 'Card',
            detailRoute: _detail,
            content: const SizedBox.shrink(),
          ),
        ),
        count,
      );
      await pump(t, router);

      final link = find.text('View details');
      expect(link, findsOneWidget,
          reason: 'the detail footer link must be laid out to be tappable');

      // A double-tap: two taps in the SAME frame (no pump between them).
      await t.tap(link);
      await t.tap(link);
      await t.pumpAndSettle();

      expect(count[0], 1,
          reason: 'a double-tap must build the detail route exactly once; '
              'without the guard both taps reach pushNamed => 2');
      expect(find.text('PAGE:detail'), findsOneWidget);
    });

    testWidgets('NavLinkBlock: double-tap => one push', (t) async {
      final count = [0];
      final router = buildRouter(
        (c) => NavLinkBlock(
          title: 'Go',
          onTap: () => c.pushNamed(_detail),
        ),
        count,
      );
      await pump(t, router);

      final link = find.text('Go');
      expect(link, findsOneWidget);

      await t.tap(link);
      await t.tap(link);
      await t.pumpAndSettle();

      expect(count[0], 1,
          reason: 'a double-tap must build the detail route exactly once; '
              'without the guard both taps reach onTap => 2');
      expect(find.text('PAGE:detail'), findsOneWidget);
    });

    // Acceptance #4: the guard is a same-gesture guard, not a route-level
    // dedup. A separate navigation later in the session must still work.
    testWidgets('DashboardCardTemplate: a later, separate tap navigates again',
        (t) async {
      final count = [0];
      final router = buildRouter(
        (c) => SizedBox(
          width: 420,
          height: 260,
          child: DashboardCardTemplate(
            title: 'Card',
            detailRoute: _detail,
            content: const SizedBox.shrink(),
          ),
        ),
        count,
      );
      await pump(t, router);

      // First gesture.
      await t.tap(find.text('View details'));
      await t.pumpAndSettle();
      expect(count[0], 1);

      // Come back to the card, then navigate again as a fresh gesture.
      router.goNamed(_home);
      await t.pumpAndSettle();
      await t.tap(find.text('View details'));
      await t.pumpAndSettle();

      expect(count[0], 2,
          reason: 'the guard must not block a legitimate later navigation '
              'to the same page (Acceptance #4)');
    });

    testWidgets('NavLinkBlock: a later, separate tap navigates again',
        (t) async {
      final count = [0];
      final router = buildRouter(
        (c) => NavLinkBlock(
          title: 'Go',
          onTap: () => c.pushNamed(_detail),
        ),
        count,
      );
      await pump(t, router);

      await t.tap(find.text('Go'));
      await t.pumpAndSettle();
      expect(count[0], 1);

      router.goNamed(_home);
      await t.pumpAndSettle();
      await t.tap(find.text('Go'));
      await t.pumpAndSettle();

      expect(count[0], 2,
          reason: 'the guard must not block a legitimate later navigation '
              'to the same page (Acceptance #4)');
    });
  });
}
