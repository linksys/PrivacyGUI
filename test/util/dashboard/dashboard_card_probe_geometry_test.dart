@Tags(['dashboard-card'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_card_probe.dart';

/// Pins the overflow gate's grid geometry to the production layout stack
/// (#1248 review W-4).
///
/// ## The failure this exists to catch
///
/// The gate's claim is "each card was pumped at its narrowest realization". That
/// claim is only as good as the geometry that computes the realization, and the
/// geometry is not the code production runs: production resolves columns and
/// margins off a `BuildContext`, while the gate needs the widths *before* it has
/// a tree to pump. So `dashboard_card_probe.dart` reads what it can from
/// `AppLayoutConfig` and mirrors the rest.
///
/// A mirror drifts in one direction only, and it is the bad one. Move a
/// breakpoint or a margin step in production and the gate keeps measuring the
/// old regime: it pumps a width no user gets, finds no overflow there, and stays
/// **green** while the real narrowest realization goes unmeasured. Nothing else
/// in the suite would notice — the gate's own 1698 cases would all still pass.
///
/// So these tests read the production getters through a real `BuildContext` at
/// each breakpoint edge and compare them against what the probe computes for the
/// same width.
///
/// ## What is pinned versus what is merely referenced
///
/// `kGridGutter`, `kSlotHeight` and `gridMarginForWidth` are now *references*
/// (`AppSpacing.lg`, `UspSliverDashboardView.slotHeight`,
/// `AppLayoutConfig.margin`), so there is nothing left to drift and asserting
/// equality on them would be a tautology. Two things still need pinning:
///
/// 1. `gridColumnsForWidth` — the 4/8/12 mapping, which production only exposes
///    as `context.currentMaxColumns`.
/// 2. `gridMarginForWidth`'s **source**. `context.pageMargin` prefers an
///    app-installed `AppLayoutProvider` over `AppLayoutConfig`, so calling the
///    config directly is correct only while the app installs no provider. That
///    is true today and is asserted below, rather than assumed.
void main() {
  /// Screen widths to compare at: every breakpoint edge (below / on / above),
  /// the supported floor and the enumeration ceiling, plus one interior width
  /// per regime so a boundary-only sweep can't hide a wrong regime body.
  ///
  /// The edges matter more than the interiors: `AppLayoutConfig`'s predicates
  /// are `<=` on the low side and `>` on the high side, so an off-by-one in
  /// either the probe or production shows up only at `b`, `b ± 1`.
  final widths = <double>{
    kMinSupportedScreenWidth,
    kMinSupportedScreenWidth + 1,
    400,
    for (final b in <double>[
      AppLayoutConfig.breakpointMobile,
      AppLayoutConfig.breakpointTablet,
      AppLayoutConfig.breakpointDesktop,
      AppLayoutConfig.breakpointDesktopLarge,
      AppLayoutConfig.breakpointDesktopExtraLarge,
    ]) ...[
      b - 1,
      b,
      b + 1,
    ],
    800,
    1000,
    1300,
    1500,
    2000,
    kMaxScannedScreenWidth,
  }.toList()
    ..sort();

  /// Reads the production layout getters at [screenWidth].
  ///
  /// The `MediaQuery` sits *inside* `MaterialApp` so it overrides the one the
  /// app inserts from the test view — the getters all resolve through
  /// `MediaQuery.sizeOf`, so this is the same input production gives them.
  Future<({int columns, double margin, AppLayoutProvider? provider})> readAt(
    WidgetTester tester,
    double screenWidth,
  ) async {
    late final int columns;
    late final double margin;
    AppLayoutProvider? provider;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(screenWidth, 900)),
          child: Builder(
            builder: (context) {
              columns = context.currentMaxColumns;
              margin = context.pageMargin;
              provider = AppLayoutProvider.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    return (columns: columns, margin: margin, provider: provider);
  }

  group('probe geometry matches the production layout stack', () {
    testWidgets(
        'column count equals context.currentMaxColumns at every '
        'breakpoint edge', (tester) async {
      for (final w in widths) {
        final production = await readAt(tester, w);

        expect(
          gridColumnsForWidth(w),
          production.columns,
          reason: 'At ${w}px the grid gives production '
              '${production.columns} columns but the gate computes '
              '${gridColumnsForWidth(w)}. The gate would pump every card at a '
              'width no user gets — and still report green. Fix '
              'gridColumnsForWidth in dashboard_card_probe.dart to match '
              'GridLayoutContext.currentMaxColumns, then re-baseline the gate.',
        );
      }
    });

    testWidgets(
        'page margin equals context.pageMargin at every breakpoint '
        'edge', (tester) async {
      for (final w in widths) {
        final production = await readAt(tester, w);

        expect(
          gridMarginForWidth(w),
          production.margin,
          reason: 'At ${w}px production lays out with '
              '${production.margin}px page margins but the gate assumes '
              '${gridMarginForWidth(w)}px, so every card width it derives at '
              'this width is wrong by '
              '${(production.margin - gridMarginForWidth(w)).abs() * 2}px.',
        );
      }
    });

    testWidgets('slot and card widths follow from the production parameters',
        (tester) async {
      for (final w in widths) {
        final production = await readAt(tester, w);

        // The formula the dashboard view computes in `_buildSliverDashboard`,
        // evaluated on the values just read out of the tree rather than on the
        // probe's own. Only the *shape* is restated here; every number in it
        // came from production.
        final available = w - production.margin * 2;
        final expectedSlot =
            (available - (production.columns - 1) * AppSpacing.lg) /
                production.columns;

        expect(
          gridSlotWidth(w),
          closeTo(expectedSlot, 0.0001),
          reason: 'Slot width diverges at ${w}px: gate ${gridSlotWidth(w)} vs '
              'production $expectedSlot.',
        );

        // Spans past the column count are clamped, which is what makes a
        // 12-column card measurable on a 4-column grid at all.
        for (var span = 1; span <= AppLayoutConfig.maxColumns; span++) {
          final effective =
              span > production.columns ? production.columns : span;
          final expectedCard =
              effective * expectedSlot + (effective - 1) * AppSpacing.lg;

          expect(
            cardWidthAt(w, span),
            closeTo(expectedCard, 0.0001),
            reason: 'Card width diverges for span $span at ${w}px: gate '
                '${cardWidthAt(w, span)} vs production $expectedCard.',
          );
        }
      }
    });

    testWidgets(
        'the app installs no AppLayoutProvider, so reading '
        'AppLayoutConfig directly is reading production', (tester) async {
      // `context.pageMargin` is `AppLayoutProvider.maybeOf(this)?.margin(width)
      // ?? AppLayoutConfig.margin(width)`. The probe calls the config half.
      // That is production only while no provider is installed above the
      // dashboard — install one with custom margins and the gate would silently
      // measure the unconfigured geometry.
      final production = await readAt(tester, 800);
      expect(production.provider, isNull,
          reason: 'The harness itself must not install a provider, or this '
              'test proves nothing about the app.');

      final sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      final installers = sources
          .where((f) => f.readAsStringSync().contains('AppLayoutProvider('))
          .map((f) => f.path)
          .toList()
        ..sort();

      expect(
        installers,
        isEmpty,
        reason: 'These files construct an AppLayoutProvider: '
            '${installers.join(', ')}. If one of them wraps the dashboard, its '
            'margins — not AppLayoutConfig\'s — are what production lays out '
            'with, and gridMarginForWidth must read through the provider '
            'instead. Until then the gate measures a grid the app no longer '
            'uses.',
      );
    });

    test('the width sweep really crosses every regime it claims to', () {
      // A guard on the guard: if this list ever narrows to one regime, the
      // comparisons above keep passing while covering nothing.
      expect(
        widths.map(gridColumnsForWidth).toSet(),
        {4, 8, AppLayoutConfig.maxColumns},
        reason: 'The sweep must exercise all three column regimes.',
      );
      expect(
        widths.map(gridMarginForWidth).toSet().length,
        6,
        reason: 'The sweep must exercise all six margin steps '
            '(16 / 32 / 24 / 200 / 256 / 352).',
      );
    });
  });
}
