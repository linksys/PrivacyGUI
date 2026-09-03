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
// swallows a repeat tap and re-arms at the end of the next frame.
//
// These tests pump the REAL production components under a real go_router (no
// USP providers needed) and count how many times the detail route is built.
// Reverting the guard on either component turns its two "one push" cases red.
//
// The two halves of the window, because the guard is only responsible for one
// of them:
//
//   * before any frame renders, the link is still live and both taps reach
//     `pushNamed` — the guard's job. Modelled two ways: two `tap()` calls with
//     no pump between them (one event batch), and `elapseWithoutFrame`, i.e.
//     wall-clock time passing with no frame rendered, which is a long janky
//     frame or a heavy detail-page build. The second is the shape users hit,
//     since a tap that appears to do nothing is what makes them tap again.
//   * from the first rendered frame on, the pushed route's `ModalBarrier`
//     covers the component and the framework blocks the repeat tap by itself.
//     Pinned below on an UNGUARDED link, so the guard's window needing to be
//     no wider than one frame is asserted rather than assumed.
//
// A later, separate tap must still navigate (Acceptance #4 — same-gesture
// guard, not a route-level dedup).

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

  /// Advances the clock **without** rendering a frame, unlike `pump(duration)`.
  /// That is a janky frame on the real device: time passes, the pushed route
  /// has not been laid out, so no barrier exists and the link is still live.
  void elapseWithoutFrame(WidgetTester t, Duration d) =>
      (t.binding as AutomatedTestWidgetsFlutterBinding).elapseBlocking(d);

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

      // Two taps in one event batch: no pump between them, so no frame has
      // rendered and no barrier covers the link yet.
      await t.tap(link);
      await t.tap(link);
      await t.pumpAndSettle();

      expect(count[0], 1,
          reason: 'two taps before any frame renders must build the detail '
              'route exactly once; without the guard both reach pushNamed => 2');
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
          reason: 'two taps before any frame renders must build the detail '
              'route exactly once; without the guard both reach onTap => 2');
      expect(find.text('PAGE:detail'), findsOneWidget);
    });

    // The shape a user actually produces: the first tap seems to do nothing
    // because the frame is long, so they tap again 150ms later. Wall-clock
    // time has passed but no frame has rendered, so the framework's barrier is
    // not there yet and only the guard stands between this and two pushes.
    testWidgets('DashboardCardTemplate: repeat tap during a janky frame',
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

      await t.tap(find.text('View details'));
      elapseWithoutFrame(t, const Duration(milliseconds: 150));
      await t.tap(find.text('View details'), warnIfMissed: false);
      await t.pumpAndSettle();

      expect(count[0], 1,
          reason: '150ms with no frame rendered is still the same window; '
              'without the guard this is where the double push happens => 2');
    });

    testWidgets('NavLinkBlock: repeat tap during a janky frame', (t) async {
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
      elapseWithoutFrame(t, const Duration(milliseconds: 150));
      await t.tap(find.text('Go'), warnIfMissed: false);
      await t.pumpAndSettle();

      expect(count[0], 1,
          reason: '150ms with no frame rendered is still the same window; '
              'without the guard this is where the double push happens => 2');
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

  // The framework's half of the handoff, asserted on an UNGUARDED link so it
  // measures Flutter and not NavTapGuard. It is why the guard re-arms after one
  // frame instead of debouncing on a wall clock: past that frame the pushed
  // route's ModalBarrier owns the repeat tap, and a timer would only be
  // blocking taps that cannot reach the link anyway. If a future Flutter stops
  // covering the previous route, this goes red and the guard's window is the
  // thing to widen.
  group('#1445 once a frame renders, the pushed route blocks the repeat tap',
      () {
    testWidgets('unguarded link, taps one frame apart => still one push',
        (t) async {
      final count = [0];
      final router = buildRouter(
        (c) => InkWell(
          onTap: () => c.pushNamed(_detail),
          child: const SizedBox(
            width: 200,
            height: 60,
            child: Text('UNGUARDED'),
          ),
        ),
        count,
      );
      await pump(t, router);

      final link = find.text('UNGUARDED');
      await t.tap(link);
      await t.pump(const Duration(milliseconds: 16));
      await t.tap(link, warnIfMissed: false);
      await t.pumpAndSettle();

      expect(count[0], 1,
          reason: 'one rendered frame is enough for the pushed route to cover '
              'the link, so the second tap never reaches it — no guard involved');
    });
  });
}
