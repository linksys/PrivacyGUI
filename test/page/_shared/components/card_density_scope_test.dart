@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/providers/card_density_provider.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../util/dashboard/dashboard_card_probe.dart';

/// Density injection (#1232).
///
/// Written before the mechanism, for the reason #1232 gives: the overflow gate
/// asserts only "does not overflow" and cannot see a wrong density, so nothing
/// else in the suite would catch the selection reading the screen instead of the
/// card, or an override being ignored.
const String _kCardId = 'connected_devices';

/// Records what a descendant of the scope actually reads.
class _DensitySpy extends StatelessWidget {
  const _DensitySpy();

  @override
  Widget build(BuildContext context) {
    observed = CardDensityScope.of(context);
    return const SizedBox.shrink();
  }

  static CardDensity? observed;
}

/// Pumps a [CardDensityHost] told it is [cardWidth] wide, in a box of that same
/// width, on a screen of [screenWidth].
///
/// The width and the screen are varied independently on purpose — that is the
/// only way to tell a width-driven selection from a screen-driven one. Since
/// #1401 the width arrives as an argument rather than being measured, so what
/// this rules out is a host that ignores what it was handed and reaches for
/// `MediaQuery` instead.
///
/// The box defaults to the supplied width because that is the production
/// relationship: the grid computes one number and both lays the tile out in it
/// and reports it. [boxWidth] breaks them apart, which is how a test asks
/// whether the density reads the argument or the box.
///
/// The horizontal viewport keeps the box honest: under a bounded ancestor a
/// `SizedBox(width: 600)` on a 320px screen silently resolves to 320. Unbounded,
/// it tightens to exactly the width asked for.
Future<void> _pumpHost(
  WidgetTester tester, {
  required double? cardWidth,
  required double screenWidth,
  double? boxWidth,
  double? normalAbove,
  CardDensity? override,
  Widget child = const _DensitySpy(),
}) async {
  tester.view.physicalSize = Size(screenWidth, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (override != null)
          cardDensityOverrideProvider(_kCardId).overrideWith((ref) => override),
      ],
      child: MaterialApp(
        home: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: boxWidth ?? cardWidth ?? 400,
            height: 400,
            child: CardDensityHost(
              cardId: _kCardId,
              normalAbove: normalAbove,
              cardWidth: cardWidth,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    _DensitySpy.observed = null;
  });

  group('selection reads the card, not the screen', () {
    testWidgets('a narrow card on a wide screen is popup', (tester) async {
      // The failure this pins is the one #1231/#1251 spent two tickets removing
      // from the cards themselves: a screen-derived width. On a 1920px screen a
      // screen-reading implementation would say normal here.
      await _pumpHost(
        tester,
        cardWidth: 150,
        screenWidth: 1920,
        normalAbove: 400,
      );
      expect(_DensitySpy.observed, CardDensity.popup);
    });

    testWidgets('a wide card on a narrow screen is normal', (tester) async {
      // The converse, which a screen-reading implementation also gets wrong —
      // and which a card-reading one must get right even though 600 > 320.
      await _pumpHost(
        tester,
        cardWidth: 600,
        screenWidth: 320,
        normalAbove: 400,
      );
      expect(_DensitySpy.observed, CardDensity.normal);
    });

    testWidgets('the compact band comes from the card width', (tester) async {
      await _pumpHost(
        tester,
        cardWidth: 300,
        screenWidth: 1920,
        normalAbove: 400,
      );
      expect(_DensitySpy.observed, CardDensity.compact);
    });
  });

  group('override hook', () {
    testWidgets('an override wins over the measured width', (tester) async {
      // #1232: "Injection also lets the gate pin a specific form, exactly as it
      // already pins tabs via a provider rather than tapping."
      await _pumpHost(
        tester,
        cardWidth: 900,
        screenWidth: 1920,
        normalAbove: 400,
        override: CardDensity.popup,
      );
      expect(_DensitySpy.observed, CardDensity.popup);
    });

    testWidgets('an override applies even with no threshold declared',
        (tester) async {
      // Otherwise the gate could not pump a degraded form for any card in the
      // app as it stands, since none declares a threshold.
      await _pumpHost(
        tester,
        cardWidth: 900,
        screenWidth: 1920,
        normalAbove: null,
        override: CardDensity.compact,
      );
      expect(_DensitySpy.observed, CardDensity.compact);
    });

    testWidgets('no override leaves the width in charge', (tester) async {
      await _pumpHost(
        tester,
        cardWidth: 150,
        screenWidth: 1920,
        normalAbove: 400,
      );
      expect(_DensitySpy.observed, CardDensity.popup);
    });
  });

  group('absent threshold', () {
    testWidgets('never degrades, at any width', (tester) async {
      for (final w in [100.0, 199.0, 250.0, 900.0]) {
        await _pumpHost(
          tester,
          cardWidth: w,
          screenWidth: 1920,
          normalAbove: null,
        );
        expect(
          _DensitySpy.observed,
          CardDensity.normal,
          reason: 'width $w with no normalAbove must stay normal',
        );
      }
    });
  });

  group('the width is supplied, not measured', () {
    // #1401 AC 1 and AC 2. The host used to open a `LayoutBuilder` to read its
    // own box, and skip doing so for cards with no threshold — the skip being
    // what kept those cards from rebuilding their whole subtrees once per layout
    // pass of a drag-resize, to recompute a value that could not change.
    //
    // Both are gone, and the *reason* for the skip is what these tests keep:
    // there is no measurement to skip, so a threshold-less card and a card with
    // one are now in the same regime, and neither builds per layout pass. What
    // that buys at the grid level — the package holding the cached subtree
    // across the widths that change no band — is pinned in
    // `card_density_from_grid_test.dart`, which has a real grid to observe.
    for (final normalAbove in <double?>[null, 400]) {
      final label = normalAbove == null ? 'no threshold' : 'a threshold';
      testWidgets('the host opens no LayoutBuilder, with $label',
          (tester) async {
        await _pumpHost(
          tester,
          cardWidth: 150,
          screenWidth: 1920,
          normalAbove: normalAbove,
        );
        expect(
          find.descendant(
            of: find.byType(CardDensityHost),
            matching: find.byType(LayoutBuilder),
          ),
          findsNothing,
        );
      });
    }

    testWidgets('the scope is published directly under the host',
        (tester) async {
      // The converse of the above: "no LayoutBuilder" would also be satisfied by
      // a host that published nothing at all, so pin that the scope is there and
      // is what the host returns rather than something further down.
      await _pumpHost(
        tester,
        cardWidth: 150,
        screenWidth: 1920,
        normalAbove: 400,
      );
      final host = tester.element(find.byType(CardDensityHost));
      final children = <Widget>[];
      host.visitChildren((child) => children.add(child.widget));
      expect(children.single, isA<CardDensityScope>());
    });

    testWidgets('the supplied width wins over the box the card sits in',
        (tester) async {
      // The two agree in production, so make them disagree here: a 150px box
      // told it is 600px wide. A host that went back to measuring would say
      // popup. This is the assertion the rest of the file cannot make, since
      // everywhere else box == supplied and both implementations agree.
      await _pumpHost(
        tester,
        cardWidth: 600,
        boxWidth: 150,
        screenWidth: 1920,
        normalAbove: 400,
      );
      expect(_DensitySpy.observed, CardDensity.normal);
    });

    testWidgets('a width there is no answer for resolves to normal',
        (tester) async {
      // A supplied width can be missing or degenerate where a measured one could
      // not: a card built outside a dashboard has no box to report, and the boot
      // frame is where a zero comes from. Popup would be the wrong fallback in
      // both directions — #1400 made stored geometry authoritative, so a boot
      // frame that pinned every card to popup would persist that as the layout
      // the user comes back to.
      //
      // The box stays at 150 throughout, which a measuring host would call
      // popup, so falling back to normal is a decision and not the box speaking.
      for (final width in <double?>[null, 0, -1, double.nan, double.infinity]) {
        await _pumpHost(
          tester,
          cardWidth: width,
          boxWidth: 150,
          screenWidth: 1920,
          normalAbove: 400,
        );
        expect(
          _DensitySpy.observed,
          CardDensity.normal,
          reason: '$width must not select a degraded form',
        );
      }
    });
  });

  group('reading outside a scope', () {
    testWidgets('defaults to normal', (tester) async {
      // Leaf blocks stay density-free (#1232), and shared blocks are used by
      // non-card callers. Reading with no scope above must be normal rather
      // than throwing, or every such caller becomes a crash site.
      await tester.pumpWidget(const MaterialApp(home: _DensitySpy()));
      expect(_DensitySpy.observed, CardDensity.normal);
    });
  });

  group('resize', () {
    testWidgets('a card shrunk past a boundary re-notifies dependents',
        (tester) async {
      await _pumpHost(
        tester,
        cardWidth: 600,
        screenWidth: 1920,
        normalAbove: 400,
      );
      expect(_DensitySpy.observed, CardDensity.normal);

      // Dragging a card narrower is the gesture this whole design exists to
      // survive, so the scope has to notify on it rather than only on first
      // build.
      await _pumpHost(
        tester,
        cardWidth: 150,
        screenWidth: 1920,
        normalAbove: 400,
      );
      expect(_DensitySpy.observed, CardDensity.popup);
    });
  });

  group('wiring', () {
    test('every registered card is built inside a density host', () {
      // The factory is the one place both production and the #1183 probe
      // construct cards, so wrapping there is what makes the gate's override
      // reach the real widget tree. If a card were ever constructed around it,
      // density would silently be normal for that card only.
      final factory = UspWidgetFactory();
      for (final spec in UspWidgetSpecs.all) {
        final widget = factory.buildWidget(spec.id, cardWidth: 600);
        expect(
          widget,
          isA<CardDensityHost>(),
          reason: '${spec.id} must be wrapped in a CardDensityHost',
        );
        expect((widget as CardDensityHost).cardId, spec.id);
      }
    });

    testWidgets('the gate can pin a form on a real card', (tester) async {
      // AC: "The gate can override the selected form so a specific form can be
      // pumped deliberately." Asserted through the probe rather than against the
      // provider, because the provider existing is not the claim — the claim is
      // that a density set by a test survives the whole path the gate uses
      // (probe → factory → host → scope) and lands in the card's subtree.
      await tester.pumpWidget(buildDashboardCardApp(
        cardId: _kCardId,
        locale: const Locale('en'),
        screenWidth: 1920,
        cardWidth: 600,
        cardHeight: 400,
        density: CardDensity.popup,
      ));
      expect(
        tester.widget<CardDensityScope>(find.byType(CardDensityScope)).density,
        CardDensity.popup,
        reason: '600px would otherwise be normal — the pin must win',
      );
    });

    testWidgets('an unpinned card on the gate path uses the probe geometry',
        (tester) async {
      // The control for the above: the gate's own sweep passes no density, and
      // must keep taking the production path — which since #1401 means the width
      // the probe computed for the `SizedBox` is also the width the card selects
      // its form from, rather than something the card reads back out of the box.
      await tester.pumpWidget(buildDashboardCardApp(
        cardId: _kCardId,
        locale: const Locale('en'),
        screenWidth: 1920,
        cardWidth: 600,
        cardHeight: 400,
      ));
      expect(
        tester.widget<CardDensityScope>(find.byType(CardDensityScope)).density,
        CardDensity.normal,
      );
    });

    test('the host carries the threshold its spec declares', () {
      // Three cards declare one since #1288 and 15 do not, so this now covers
      // both directions of the pass-through in one loop — when it was written
      // every spec was null (#1240 AC 1 measured every card as fitting at its
      // narrowest realization) and the only thing it could rule out was a
      // hardcoded null.
      final factory = UspWidgetFactory();
      for (final spec in UspWidgetSpecs.all) {
        final host =
            factory.buildWidget(spec.id, cardWidth: 600) as CardDensityHost;
        expect(
          host.normalAbove,
          spec.normalAbove,
          reason: '${spec.id} must receive its own spec threshold',
        );
      }
    });
  });
}
