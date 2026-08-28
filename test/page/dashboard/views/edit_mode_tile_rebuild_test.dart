/// #1395 AC2 — the one behavioural change in the bump that the suite *can* cover:
/// 2.3.1's tile-content caching, and what it does to an edit-mode wrapper.
///
/// `sliver_dashboard` 2.3.1 stopped rebuilding tile content when edit mode
/// toggles: *"toggling is now nearly free — only the edit chrome rebuilds. If a
/// tile's content depends on edit mode, read it reactively inside the tile."*
/// `DashboardItem` caches what `itemBuilder` returned (`_cachedWidget ??=`,
/// `dashboard_item_widget.dart:487`) and invalidates it only on a content-signature
/// or dimension change (`:239`) — despite a stale comment at `:190` still claiming
/// the global edit mode is one of the triggers. It is not, and 0.9.1's rebuild was.
///
/// Our tile content *does* depend on the flag: in edit mode a card is wrapped in
/// `JiggleShake(child: AbsorbPointer(...))`, and the absorber is not decoration —
/// the comment on it records that a tap reaching card content in edit mode is how
/// accidental deletions happened.
///
/// ## Nothing regressed, and that was luck
///
/// On 2.6.0 the wrapper still appears, because entering edit mode also changes the
/// *shape* of the tree around the tiles: the grid background appears
/// (`gridStyle: isEditMode ? … : null`), the trash zone appears (`trashBuilder`),
/// and [CardFormToolbarLayer] wraps the grid. Each of those alone remounts the tile
/// elements, which discards the cache and calls `itemBuilder` again. Measured by
/// holding all three constant across the toggle: `itemBuilder` is then not called a
/// second time and every card stays unwrapped in edit mode. Held constant one at a
/// time, any one of the other two still saves it — so the behaviour rests on
/// coincidence three times over, and would be lost by exactly the kind of change
/// 2.x invites (mount the chrome once, animate its opacity).
///
/// So the flag is read where the changelog says to read it: inside the tile, by
/// [EditModeAffordance], below the cache boundary where an element rebuilds without
/// its parent's permission.
///
/// ## What each group is for
///
/// The page-level group asserts the user-visible behaviour on the real page, with
/// the real controller, factory and edit-mode notifier — but it *cannot* fail for
/// the right reason, because the incidental remounts above would carry a
/// parent-passed flag too. It earned its keep on a different axis: row 6 of the
/// table below is a crash on entering edit mode that only a real page could see.
/// The affordance group is the one that pins the mechanism:
/// it flips the provider under a tile whose element is never remounted, which is
/// what the package's cache leaves us with.
///
/// ## Mutation table
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | edit_mode_affordance | read the flag once (`ref.read`) or take it from a constructor parameter, instead of watching it | 'the affordance follows the flag without being rebuilt from above' — and, run, the three page-level tests stayed green, which is the whole reason that group exists |
/// | 2 | edit_mode_affordance | drop `AbsorbPointer`, keep `JiggleShake` | 'entering edit mode wraps the cards' (the absorber is named separately) |
/// | 3 | edit_mode_affordance | wrap unconditionally, ignoring edit mode | 'a card outside edit mode is not wrapped' |
/// | 4 | edit_mode_affordance | wrap on `isEditing == false` | 'leaving edit mode unwraps them again' |
/// | 5 | usp_sliver_dashboard_view | stop wrapping cards in the affordance at all | every test in both groups |
/// | 6 | usp_sliver_dashboard_view | hoist the grid's per-build `ScrollController` into the `State` — the obvious fix for what reads like a leak | both toggle tests, with `ScrollController attached to multiple scroll views`: `CardFormToolbarLayer` changes the tree shape above the `Scrollable`, so a shared instance has two positions attached during the frame the layer appears in. Found by running it. |
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/effects/edit_mode_affordance.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:privacy_gui/page/dashboard/views/components/effects/jiggle_shake.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_dashboard_page.dart';
import '../../../util/settle.dart';

final _theme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Desktop, so the grid is on its 12-column breakpoint — the one a fresh
/// controller starts on, and the one where cards are wide enough that a lazy
/// sliver builds several of them.
const _desktopSurface = Size(1280, 1600);

/// The real notifier, minus the logout listener its [build] installs.
///
/// The subject here is the affordance, not the notifier: [authProvider] would
/// have to be stood up for a container that only ever needs the flag flipped.
/// Subclassing keeps the provider — and so the affordance's `ref.watch` — the
/// real one.
class _TestEditModeNotifier extends DashboardEditModeNotifier {
  @override
  DashboardEditState build() => const DashboardEditState();

  void setEditing(bool editing) =>
      state = DashboardEditState(isEditing: editing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps the **real** page, with the real widget factory, the real layout
  /// controller and the real edit-mode notifier.
  ///
  /// A stand-in `itemBuilder` would measure nothing here: what is under test is
  /// whether the cards on the real page carry the affordance, so the builder has to
  /// be the page's own. [dashboardPageOverrides] is the fixture the layout gate
  /// already uses for this page for the same reason (`mock_dashboard_page.dart`).
  Future<ProviderContainer> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = _desktopSurface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: dashboardPageOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: UspSliverDashboardView()),
      ),
    ));
    // Not `pumpAndSettle`: the page carries looping animations (and edit mode adds
    // one — `JiggleShake` never ends, which is the point of it). The gate's own
    // settle is the one that tolerates them.
    await settleIgnoringAnimations(tester);
    return container;
  }

  /// Enters or leaves edit mode the way the header bar does, and lets the frame
  /// the toggle produces land.
  Future<void> setEditing(
    WidgetTester tester,
    ProviderContainer container, {
    required bool editing,
  }) async {
    final notifier = container.read(dashboardEditModeProvider.notifier);
    if (editing) {
      await notifier.enterEditMode();
    } else {
      await notifier.commitEditMode();
    }
    await settleIgnoringAnimations(tester);
  }

  /// The absorber that blocks content interactions while the overlay keeps the
  /// card hittable for drag and resize. Scoped to the grid's own subtree, because
  /// the page chrome has absorbers of its own.
  Finder absorbersInCards() => find.descendant(
        of: find.byType(JiggleShake),
        matching: find.byType(AbsorbPointer),
      );

  group('the premise: 2.6.0 really does cache tile content (#1395)', () {
    /// The cache boundary both fixes are built on, asserted against the package
    /// rather than quoted from its changelog.
    ///
    /// No mutation table: the code under test is `sliver_dashboard`'s, and
    /// mutating a pub-cache package is not an edit anyone can commit — the same
    /// reason `density_control_gesture_spike_test.dart` gives. The positive
    /// control is what stands in for one: if this harness could not make the
    /// package call `itemBuilder` again at all, the first test would pass for the
    /// wrong reason.
    Future<int Function()> pumpGrid(
      WidgetTester tester, {
      required ValueNotifier<double> ratio,
    }) async {
      var calls = 0;
      final controller = DashboardController(
        initialSlotCount: 12,
        initialLayout: UspWidgetSpecs.createDefaultLayout(),
        maxHistoryLength: 0,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        theme: _theme,
        home: Scaffold(
          body: ValueListenableBuilder<double>(
            valueListenable: ratio,
            builder: (context, value, _) => CustomScrollView(
              slivers: [
                SliverDashboard(
                  controller: controller,
                  itemBuilder: (context, item) {
                    calls++;
                    return const SizedBox.expand();
                  },
                  slotAspectRatio: value,
                  breakpoints: {0: 12},
                ),
              ],
            ),
          ),
        ),
      ));
      return () => calls;
    }

    testWidgets('a rebuild that changes nothing about an item does not rebuild '
        'its content', (tester) async {
      final ratio = ValueNotifier<double>(1.5);
      addTearDown(ratio.dispose);
      final calls = await pumpGrid(tester, ratio: ratio);

      final built = calls();
      expect(built, greaterThan(0), reason: 'the premise of the premise');

      // Same items, same geometry, new parent build — which is all a page rebuild
      // is when a provider it watches publishes.
      ratio.notifyListeners();
      await tester.pump();

      expect(calls(), built,
          reason: 'this is the boundary: anything a tile reads from the page '
              'build is frozen at the first frame, which is why the edit-mode '
              'flag and the package templates are read inside the tile');
    });

    testWidgets('a dimension change does', (tester) async {
      final ratio = ValueNotifier<double>(1.5);
      addTearDown(ratio.dispose);
      final calls = await pumpGrid(tester, ratio: ratio);

      final built = calls();
      ratio.value = 2.5;
      await tester.pump();

      expect(calls(), greaterThan(built),
          reason: 'the positive control: the harness can make the package '
              'rebuild tile content, so the test above measures the cache and '
              'not a harness that cannot trigger anything');
    });
  });

  group('edit-mode tile wrapping on the real page (#1395)', () {
    testWidgets('a card outside edit mode is not wrapped', (tester) async {
      final container = await pumpDashboard(tester);

      expect(container.read(dashboardEditModeProvider).isEditing, isFalse,
          reason: 'the page opens in view mode');
      expect(find.byType(JiggleShake), findsNothing,
          reason: 'nothing jiggles on a dashboard nobody is editing');
    });

    testWidgets('entering edit mode wraps the cards', (tester) async {
      final container = await pumpDashboard(tester);

      final cardsBefore = find.byType(AppCard).evaluate().length;
      expect(cardsBefore, greaterThan(0),
          reason: 'the premise: this fixture really does build cards. A lazy '
              'sliver builds only what fits the viewport, which is enough — the '
              'cache is per tile, so one unwrapped tile is the bug.');

      await setEditing(tester, container, editing: true);

      expect(find.byType(JiggleShake), findsWidgets,
          reason: 'the affordance the grid is edited through');
      expect(absorbersInCards(), findsWidgets,
          reason: 'and the absorber is the half that carries behaviour: '
              'without it a tap in edit mode reaches card content, which is '
              'how accidental deletions happened.');
    });

    testWidgets('leaving edit mode unwraps them again', (tester) async {
      final container = await pumpDashboard(tester);

      await setEditing(tester, container, editing: true);
      expect(find.byType(JiggleShake), findsWidgets);

      await setEditing(tester, container, editing: false);

      expect(find.byType(JiggleShake), findsNothing,
          reason: 'otherwise the cards are left jiggling and inert on a '
              'committed dashboard');
    });
  });

  group('the affordance reads edit mode for itself (#1395)', () {
    /// Pumps one affordance and hands back the container, with **nothing above it
    /// that reacts to edit mode**.
    ///
    /// That is the whole point: this stands in for a cached tile, whose element
    /// survives the toggle and whose parent will not rebuild it. If the flag were
    /// taken from above — a constructor parameter, an enclosing `build` — the
    /// wrapper could not appear here, and 2.3.1 is exactly the change that makes
    /// the real tiles behave like this one.
    Future<ProviderContainer> pumpAffordance(WidgetTester tester) async {
      final container = ProviderContainer(overrides: [
        dashboardEditModeProvider.overrideWith(_TestEditModeNotifier.new),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: EditModeAffordance(child: SizedBox(width: 40, height: 40)),
          ),
        ),
      ));
      return container;
    }

    testWidgets('the affordance follows the flag without being rebuilt from '
        'above', (tester) async {
      final container = await pumpAffordance(tester);
      final element = tester.element(find.byType(EditModeAffordance));

      expect(find.byType(JiggleShake), findsNothing);

      (container.read(dashboardEditModeProvider.notifier)
              as _TestEditModeNotifier)
          .setEditing(true);
      await tester.pump();
      // A second pump, past `JiggleShake`'s random 0-50ms start delay: the
      // `Future.delayed` is scheduled *during* the frame above, so only the next
      // one can retire it, and a pending timer fails the test at teardown.
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.byType(JiggleShake), findsOneWidget,
          reason: 'the affordance watches the provider itself');
      expect(absorbersInCards(), findsOneWidget);
      expect(tester.element(find.byType(EditModeAffordance)), same(element),
          reason: 'and it did so without being remounted — which is the '
              'situation a cached tile leaves it in');

      (container.read(dashboardEditModeProvider.notifier)
              as _TestEditModeNotifier)
          .setEditing(false);
      await tester.pump();

      expect(find.byType(JiggleShake), findsNothing);
    });

    testWidgets('the child is passed through untouched outside edit mode',
        (tester) async {
      await pumpAffordance(tester);

      // Scoped, and to the box this test pumped: `MaterialApp` and `Scaffold`
      // bring `SizedBox`es of their own, so an unscoped `findsWidgets` would pass
      // for an affordance that returned `SizedBox.shrink()` and dropped the card.
      expect(
          find.descendant(
            of: find.byType(EditModeAffordance),
            matching: find.byWidgetPredicate(
                (w) => w is SizedBox && w.width == 40 && w.height == 40),
          ),
          findsOneWidget,
          reason: 'view mode returns the child, not a wrapper around it');
      // Scoped to the affordance's own subtree: `MaterialApp` brings absorbers of
      // its own, and they are not what this is about.
      expect(
          find.descendant(
            of: find.byType(EditModeAffordance),
            matching: find.byType(AbsorbPointer),
          ),
          findsNothing,
          reason: 'a view-mode card must stay interactive: its own gestures are '
              'the whole of the dashboard outside edit mode');
    });
  });
}
