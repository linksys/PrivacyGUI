@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/providers/card_density_provider.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
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

/// Pumps a [CardDensityHost] in a box of exactly [cardWidth], on a screen of
/// [screenWidth]. The two are varied independently on purpose — that is the only
/// way to tell a width-driven selection from a screen-driven one.
///
/// The horizontal viewport is what makes them independent: under a bounded
/// ancestor a `SizedBox(width: 600)` on a 320px screen silently resolves to 320,
/// so the card would be handed the screen width and the test would assert
/// nothing. Unbounded, the box tightens to exactly [cardWidth].
Future<void> _pumpHost(
  WidgetTester tester, {
  required double cardWidth,
  required double screenWidth,
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
            width: cardWidth,
            height: 400,
            child: CardDensityHost(
              cardId: _kCardId,
              normalAbove: normalAbove,
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

    testWidgets('the compact band is measured on the card', (tester) async {
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

    testWidgets('is not measured at all', (tester) async {
      // With no threshold the density is a constant, so no LayoutBuilder is
      // inserted. Two things ride on this. It is what made #1232's "no card's
      // rendered output changes yet" true by construction rather than by luck,
      // back when all 18 cards were in this branch — 15 still are, since #1288
      // moved `device_info`, `lan_info` and `time_settings` out of it. And it
      // keeps a drag-resize from rebuilding those 15 cards' whole subtrees once
      // per layout pass to recompute a value that cannot change.
      await _pumpHost(
        tester,
        cardWidth: 150,
        screenWidth: 1920,
        normalAbove: null,
      );
      expect(
        find.descendant(
          of: find.byType(CardDensityHost),
          matching: find.byType(LayoutBuilder),
        ),
        findsNothing,
      );
    });

    testWidgets('a declared threshold is measured', (tester) async {
      // The converse of the above, so the short-circuit cannot silently become
      // unconditional and disable the whole mechanism.
      await _pumpHost(
        tester,
        cardWidth: 150,
        screenWidth: 1920,
        normalAbove: 400,
      );
      expect(
        find.descendant(
          of: find.byType(CardDensityHost),
          matching: find.byType(LayoutBuilder),
        ),
        findsOneWidget,
      );
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
        final widget = factory.buildWidget(spec.id);
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

    testWidgets('an unpinned card on the gate path measures itself',
        (tester) async {
      // The control for the above: the gate's own 1644-case sweep passes no
      // density, and must keep taking the production path.
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
        final host = factory.buildWidget(spec.id) as CardDensityHost;
        expect(
          host.normalAbove,
          spec.normalAbove,
          reason: '${spec.id} must receive its own spec threshold',
        );
      }
    });
  });
}
