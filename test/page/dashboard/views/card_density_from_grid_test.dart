/// #1401 — a card's density comes from the box the grid already computed, and
/// asking for it costs nothing per frame.
///
/// `CardDensityHost` used to open a `LayoutBuilder` to measure its own box, and
/// skip doing so for cards with no declared threshold. The skip was the perf
/// workaround: a `LayoutBuilder` under every card rebuilds that card's subtree on
/// every layout pass of a drag-resize, and for a threshold-less card it would do
/// that to recompute a constant. `DashboardItemBreakpointBuilder` (2.1.0) hands
/// the tile its real pixel box and re-invokes the builder only when the *resolved
/// breakpoint* transitions, so the skip has nothing left to protect.
///
/// ## What "does not rebuild per frame" can honestly mean here
///
/// `LayoutItem.contentSignature` includes `w` and `h` (`layout_item.dart:101`),
/// and `DashboardItem` invalidates its cached subtree whenever the signature
/// changes (`dashboard_item_widget.dart:245`). A drag-resize *does* change the
/// span, so the tile rebuilds at each quantized step in every regime — no builder
/// configuration avoids that, and a test asserting zero rebuilds across a resize
/// would be asserting something no version of this code has ever done.
///
/// So the claim is split into the two things that are separately true:
///
/// 1. A width change that moves pixels but crosses no band costs **zero**
///    rebuilds. That is the window-resize case, and it is where the deleted skip
///    used to matter.
/// 2. A drag-resize rebuilds **once per quantized span step, not once per frame**.
///    Sixteen pointer moves that walk a card from 6 columns to 3 produce three
///    span changes, and the assertion is against the step count rather than a
///    magic number.
///
/// Both are observed on the real page, through the real factory, because the
/// number under test is the one the grid computed — a stand-in grid would be a
/// test about arithmetic this file already does in `densityForSuppliedWidth`.
///
/// ## Why `device_info` at 1280x1600
///
/// It is the first card after the full-width `stats_panel`, so a lazy sliver has
/// it on the first frame at every breakpoint. And the numbers work out on the
/// right side of its declared 262px threshold: at 12 columns and a 200px page
/// margin the slot is 58.67px, so the card measures 432px at `w 6` (normal) and
/// 208px at `w 3` (compact — above `kPopupBelow`, below 262). Every one of those
/// figures is asserted rather than assumed, because all of them are derived.
///
/// ## Mutation table
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | usp_sliver_dashboard_view | `cardWidth: null` at the `buildWidget` call — a builder that has the width and drops it. (Going back to `itemBuilder`, which has no width to pass, does not compile at all: that is what `cardWidth` being required buys.) | 'every card is told the box it was laid out in' *and* 'the shrink flips the card into its compact form' — run, and both failed |
/// | 2 | usp_sliver_dashboard_view | `itemLayoutBuilder` instead of `itemBreakpointBuilder`, the other 2.x builder that reports pixels | 'a window resize inside a band rebuilds nothing', run: 1 build becomes 4. `trackDimensions` is then unconditional and there is no resolver to gate it, so every pixel invalidates the tile |
/// | 3 | usp_sliver_dashboard_view | `breakpointResolver: (w, h, item, slots) => w` — a resolver that reports the raw width, which "transitions" on every pixel | the same test with the same 1 → 4, one layer down: the resolver is what makes the cache hold. The drag-resize tests survive it, which is worth knowing — a drag changes the span, and the span changes the tile's pixel width in *steps*, so per-pixel invalidation is a window-resize failure and not a gesture one |
/// | 4 | usp_widget_factory | `densityBandFor` returns `CardDensity.normal` always — a resolver that never transitions | 'the shrink flips the card into its compact form', run: the card is still `normal` at 208px, because the breakpoint wrapper holds its cached subtree when the resolved value does not move. The rebuild-count tests survive, which is the row's other half: a constant resolver is *cheaper*, and cheap is not the property under test |
/// | 5 | card_density_scope | resolve the width with `densityForWidth` and a `0` default instead of `densityForSuppliedWidth` | nothing here — the width is never absent on this path. Covered in `card_density_scope_test.dart`, and recorded here so the gap is deliberate |
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../../../util/dashboard_page_harness.dart';
import '../../../util/settle.dart';

/// The card these tests resize. See the docstring for why this one.
const _id = 'device_info';

/// The desktop grid: 12 columns, and wide enough that the sliver builds several
/// cards on the first frame.
const _desktop = Size(1280, 1600);

/// The web pointer-move gate, as in `edit_mode_interactions_test.dart`: we ship
/// only web, so a gesture test that says nothing measures a path no user takes.
const _kThrottleWindow = Duration(milliseconds: 16);

/// Counts how often the page asks for a card to be built.
///
/// The count is what "does not rebuild per frame" is about: `buildWidget` is
/// called from `_buildItemWidget`, which the grid invokes only when it decides a
/// tile's cached subtree is stale. Everything else about the factory is the real
/// one — the cards, the specs, and `densityBandFor`, which is the resolver the
/// grid asks about transitions.
class _CountingWidgetFactory extends UspWidgetFactory {
  final Map<String, int> calls = {};

  @override
  Widget? buildWidget(String id, {required double? cardWidth}) {
    calls.update(id, (n) => n + 1, ifAbsent: () => 1);
    return super.buildWidget(id, cardWidth: cardWidth);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps the real page with a counting factory in place of the real one, and
  /// hands back both.
  Future<(ProviderContainer, _CountingWidgetFactory)> pumpCounting(
    WidgetTester tester, {
    bool editing = false,
  }) async {
    final factory = _CountingWidgetFactory();
    final container = await pumpDashboardPage(
      tester,
      size: _desktop,
      editing: editing,
      extraOverrides: [uspWidgetFactoryProvider.overrideWithValue(factory)],
    );
    return (container, factory);
  }

  /// The stored geometry of [id].
  Map<String, dynamic> itemOf(DashboardController controller, String id) =>
      controller.exportLayout().firstWhere((item) => item['id'] == id,
          orElse: () => fail('No item "$id" in the layout'));

  /// The tile's rendered width — the box the grid actually laid the card out in,
  /// read from the render tree rather than from the argument under test.
  double tileWidth(WidgetTester tester, String id) =>
      tester.getSize(find.byKey(ValueKey<String>(id))).width;

  /// The density published inside [id]'s tile.
  ///
  /// The scope nearest the tile, which is the host's: an open popup form mounts a
  /// second one for its presentation, and nothing here opens one.
  CardDensity densityIn(WidgetTester tester, String id) => tester
      .widget<CardDensityScope>(find
          .descendant(
            of: find.byKey(ValueKey<String>(id)),
            matching: find.byType(CardDensityScope),
          )
          .first)
      .density;

  /// Every card the sliver has built and laid out, by id.
  List<String> onScreenCards(WidgetTester tester) => find
      .byType(CardDensityHost)
      .evaluate()
      .map((e) => (e.widget as CardDensityHost).cardId)
      .toList();

  /// Runs [body] as the web build on a desktop host, which is what the resize
  /// gesture arms and throttles against. Same three globals, and the same reason
  /// for each, as `edit_mode_interactions_test.dart`.
  Future<void> onWebDesktop(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    debugOverrideIsWeb = true;
    final epoch = tester.binding.clock.now();
    debugThrottleClock = () => tester.binding.clock.now().difference(epoch);
    try {
      await body();
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      debugDefaultTargetPlatformOverride = null;
      debugOverrideIsWeb = false;
      debugThrottleClock = null;
    }
  }

  group('the grid supplies the width (#1401)', () {
    testWidgets('every card is told the box it was laid out in',
        (tester) async {
      await pumpCounting(tester);

      final cards = onScreenCards(tester);
      expect(cards, contains(_id), reason: 'the premise: the page built cards');

      for (final host in find
          .byType(CardDensityHost)
          .evaluate()
          .map((e) => e.widget as CardDensityHost)) {
        expect(
          host.cardWidth,
          isNotNull,
          reason: '${host.cardId} was built by the grid, so it has a box',
        );
        expect(
          host.cardWidth,
          closeTo(tileWidth(tester, host.cardId), 1.0),
          reason:
              '${host.cardId} must be told its own width, not a neighbour\'s '
              'and not the screen\'s',
        );
      }
    });

    testWidgets('and publishes the band that width selects', (tester) async {
      // A consistency check across every card on screen, and a weak one on its
      // own: the default layout puts them all at half width or wider, so every
      // band on this surface is `normal` and an implementation that ignored the
      // width would agree here. The degraded band is checked where a card
      // actually enters one — 'the shrink flips the card into its compact form'
      // below, and `card_density_scope_test.dart` for the arithmetic.
      final (_, factory) = await pumpCounting(tester);

      for (final id in onScreenCards(tester)) {
        expect(
          densityIn(tester, id),
          densityForSuppliedWidth(
            width: tileWidth(tester, id),
            normalAbove: factory.getSpec(id)?.normalAbove,
          ),
          reason: '$id at ${tileWidth(tester, id)}px',
        );
      }
    });

    testWidgets('the derived figures this file rests on are the real ones',
        (tester) async {
      // Every number in the docstring, asserted once here so the tests below can
      // read as behaviour rather than as arithmetic. If the grid, the margin or
      // the default layout moves, this fails first and names what moved.
      final (container, _) = await pumpCounting(tester);
      final controller = container.read(uspSliverDashboardControllerProvider);

      expect(controller.slotCount.value, 12,
          reason: '1280px is the 12-col grid');
      expect(itemOf(controller, _id)['w'], 6,
          reason: 'the default layout places this card at half width');
      expect(tileWidth(tester, _id), closeTo(432, 1.0),
          reason: 'slot 58.67px, six of them plus five 16px gutters');
      expect(densityIn(tester, _id), CardDensity.normal,
          reason: '432px is above the declared 262px threshold');
    });
  });

  group('a resize does not rebuild card subtrees per frame (#1401 AC 3)', () {
    testWidgets('a window resize inside a band rebuilds nothing',
        (tester) async {
      final (container, factory) = await pumpCounting(tester);
      final controller = container.read(uspSliverDashboardControllerProvider);

      final builtOnce = factory.calls[_id];
      expect(builtOnce, isNotNull, reason: 'the premise');
      final widthBefore = tileWidth(tester, _id);

      // Three widths that all resolve to the same grid and the same band: 12
      // columns and a 200px margin hold from 1240px up, and the card stays far
      // above its 262px threshold throughout. Each step moves the tile by ~8px,
      // which is what the old `LayoutBuilder` would have rebuilt on.
      for (final width in [1290.0, 1300.0, 1310.0]) {
        tester.view.physicalSize = Size(width, _desktop.height);
        await settleIgnoringAnimations(tester);
      }

      expect(controller.slotCount.value, 12,
          reason: 'the premise: no breakpoint was crossed, so a rebuild would '
              'have nothing to do with the grid changing under it');
      expect(tileWidth(tester, _id), greaterThan(widthBefore),
          reason: 'the other premise: the card really did get wider, so the '
              'package really was handed new dimensions to consider');
      expect(densityIn(tester, _id), CardDensity.normal,
          reason: 'and stayed in the same band, which is what makes zero the '
              'right number below');

      expect(factory.calls[_id], builtOnce,
          reason:
              'not one rebuild across three resize frames. This is what the '
              'deleted skip-measurement branch used to buy for threshold-less '
              'cards, now available to every card: the resolver reports no '
              'transition, so the package keeps the cached subtree');
    });

    testWidgets('a drag-resize rebuilds once per span step, not once per frame',
        (tester) async {
      await onWebDesktop(tester, () async {
        final (container, factory) = await pumpCounting(tester, editing: true);
        final controller = container.read(uspSliverDashboardControllerProvider);

        final before = itemOf(controller, _id);
        expect(before['w'], 6, reason: 'the premise');
        final builtBefore = factory.calls[_id]!;

        // The bottom-right corner handle, inside the 20px band, then left in
        // small steps: 16 moves of 14px is 224px, which is three columns at
        // 74.67px each. Every move clears the web throttle window, so all 16
        // land — the worst case for a per-frame rebuild.
        const frames = 16;
        final rect = tester.getRect(find.byKey(const ValueKey<String>(_id)));
        final gesture =
            await tester.startGesture(rect.bottomRight - const Offset(8, 8));
        await tester.pump(const Duration(milliseconds: 50));
        expect(controller.activeItemId.value, _id,
            reason: 'the corner press armed a resize on this card');

        for (var i = 0; i < frames; i++) {
          await gesture.moveBy(const Offset(-14, 0));
          await tester.pump(_kThrottleWindow * 2);
        }
        await gesture.up();
        await settleIgnoringAnimations(tester);

        final after = itemOf(controller, _id);
        final steps = (before['w'] as int) - (after['w'] as int);
        expect(steps, greaterThan(0),
            reason: 'the premise: the drag actually shrank the card');

        final rebuilds = factory.calls[_id]! - builtBefore;
        expect(rebuilds, greaterThan(0),
            reason:
                'the span changed, and a span change is a content-signature '
                'change — the tile has to be rebuilt for it');
        expect(rebuilds, lessThanOrEqualTo(steps + 1),
            reason: 'once per quantized column the card crossed, plus at most '
                'one for the commit. Anything more is the tile rebuilding on '
                'pixels, which is the regime a `LayoutBuilder` under the card '
                'put us in and what an `itemLayoutBuilder` would put us back in');
        expect(rebuilds, lessThan(frames),
            reason: 'and strictly fewer than the frames pumped, stated '
                'separately because that is the sentence in the ticket');
      });
    });

    testWidgets('the shrink flips the card into its compact form',
        (tester) async {
      await onWebDesktop(tester, () async {
        final (container, factory) = await pumpCounting(tester, editing: true);
        final controller = container.read(uspSliverDashboardControllerProvider);

        expect(densityIn(tester, _id), CardDensity.normal,
            reason: 'the premise: 432px is the whole form');
        final others = {
          for (final id in onScreenCards(tester))
            if (id != _id) id: densityIn(tester, id),
        };

        final rect = tester.getRect(find.byKey(const ValueKey<String>(_id)));
        final gesture =
            await tester.startGesture(rect.bottomRight - const Offset(8, 8));
        await tester.pump(const Duration(milliseconds: 50));
        for (var i = 0; i < 16; i++) {
          await gesture.moveBy(const Offset(-14, 0));
          await tester.pump(_kThrottleWindow * 2);
        }
        await gesture.up();
        await settleIgnoringAnimations(tester);

        expect(itemOf(controller, _id)['w'], 3,
            reason: 'three columns, which is this spec\'s minimum');
        expect(tileWidth(tester, _id), closeTo(208, 1.0));
        expect(densityIn(tester, _id), CardDensity.compact,
            reason: '208px is below the declared 262px threshold and above '
                'kPopupBelow, so the transition the resolver reported is the '
                'one the host published');
        expect(factory.densityBandFor(_id, tileWidth(tester, _id)),
            CardDensity.compact,
            reason:
                'and the resolver agrees with the host, which is what keeps '
                'a card from being left in a form the grid thinks it has left');

        for (final entry in others.entries) {
          expect(densityIn(tester, entry.key), entry.value,
              reason:
                  '${entry.key} was not resized, so its form must not move. '
                  'A resolver keyed on the window rather than the tile would '
                  'change all of them at once.');
        }
      });
    });
  });
}
