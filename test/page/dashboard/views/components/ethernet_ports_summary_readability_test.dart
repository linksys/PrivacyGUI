@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';

/// Ethernet Ports summary-tile readability (#1228).
///
/// ## Why this file exists alongside the #1183 gate
///
/// #1228 clears 52 coordinates by letting the two summary tiles stack once the
/// card is too narrow to hold them side by side. Everything that makes that the
/// *right* fix is invisible to the gate, which only knows whether a row fits:
///
///   - Constraining the text alone would have satisfied the gate while showing
///     no label at all. At the narrowest realization each tile's row has 50.7px
///     for a 40px disc and a 12px gap, so the text column is squeezed to zero and
///     the row still overflows by 1.3px — under the gate's 2px tolerance.
///   - Stacking at the standard 12px tile padding fits the gate equally well
///     while cutting the second tile in half: the pair is 136px against the
///     121px the card gives its content.
///   - "The two tiles stay visually consistent with each other — they are a
///     matched pair" (ticket AC) is a claim about two subtrees being identical,
///     which no overflow measurement can make.
///
/// So each group below asserts on the rendered tree. Each was run against a
/// mutation of the code it guards, and each fired:
///
///   | mutation                                  | what failed                  |
///   |-------------------------------------------|------------------------------|
///   | `compact` padding dropped (always 12px)   | tiles fully visible (2)      |
///   | `_kSideBySideMinWidth` 352 → 0            | legible share @min (3), stack (2) |
///   | LAN tile given `flex: 2` and no `compact` | matched pair (3)             |
///   | `_kSideBySideMinWidth` 352 → 600          | side by side @desktop (1)    |
///
/// Nothing here re-measures overflow — that is the gate's job, and both
/// `ethernet_ports` keys are gone from `known_overflows.json`.
///
/// Tagged `dashboard-card` so it gates PRs: `run_tests.sh` excludes
/// `golden||loc||ui`, so a `ui`-tagged test here would block nothing.
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is one square em, so
    // what does and does not fit — and therefore what ellipsizes — is fiction.
    await loadAppFonts();
  });

  const cardId = 'ethernet_ports';
  final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);
  final heightRows = spec.getConstraints(DisplayMode.normal).minHeightRows;

  /// Pumps the card at one width, as the gate does — one pump, real fonts.
  Future<void> pumpAt(
    WidgetTester tester, {
    required CardWidthCase widthCase,
    required Locale locale,
  }) =>
      probeCardOverflow(
        tester,
        cardId: cardId,
        widthCase: widthCase,
        cardHeightRows: heightRows,
        tabIndex: 0,
        locale: locale,
      );

  /// The width cases the gate measures: the narrowest realization of the card's
  /// min and preferred spans. Sourced from the same helper the gate uses, so
  /// this test cannot drift from the widths that are actually enforced.
  final narrowCases = widthCasesFor(spec);

  /// A mainstream desktop realization — 1440px screen, the card's default span.
  final desktopCase = CardWidthCase(
    screenWidth: 1440,
    cardWidth: cardWidthAt(1440, 6),
    columnSpan: 6,
    label: 'desktop',
  );

  /// The two summary tiles, in order (WAN, LAN). They are the card's only
  /// [LayoutBlock]s.
  List<Rect> tileRects(WidgetTester tester) {
    final finder = find.byType(LayoutBlock);
    return [
      for (var i = 0; i < finder.evaluate().length; i++)
        tester.getRect(finder.at(i)),
    ];
  }

  /// The card's own content viewport — the shorter of the two scroll views in
  /// the tree (the pump harness wraps the whole card in one as well).
  Rect contentViewport(WidgetTester tester) {
    final finder = find.byType(SingleChildScrollView);
    var best = Rect.largest;
    for (var i = 0; i < finder.evaluate().length; i++) {
      final r = tester.getRect(finder.at(i));
      if (r.height < best.height) best = r;
    }
    return best;
  }

  group('both summary tiles stay whole where the card is narrow (#1228)', () {
    // The vertical budget is the point. A tile that overflows nothing but is
    // sliced by the viewport has not been fixed, and the gate cannot tell the
    // difference because the template scrolls rather than clips.
    for (final wc in narrowCases) {
      testWidgets('@${wc.label} ${wc.widthKey}px both tiles are fully visible',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('en'));

        final viewport = contentViewport(tester);
        final tiles = tileRects(tester);

        expect(tiles.length, 2,
            reason: 'expected exactly the WAN and LAN tiles');
        for (var i = 0; i < tiles.length; i++) {
          expect(
            tiles[i].bottom,
            lessThanOrEqualTo(viewport.bottom),
            reason:
                'tile $i ends at ${tiles[i].bottom} but the card only shows '
                'content down to ${viewport.bottom}. The stacked pair must fit '
                'the ${viewport.height}px the card gives its content — that is '
                'why stacking tightens the tile padding (#1228).',
          );
        }
      });
    }
  });

  group('the tiles are a matched pair (#1228)', () {
    // The two tiles used to be two copies of the same markup, so they could
    // drift. They are now one widget rendered from two specs; this pins the
    // consequence rather than the implementation.
    for (final wc in [...narrowCases, desktopCase]) {
      testWidgets('@${wc.label} ${wc.widthKey}px the tiles are the same size',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('el'));

        final tiles = tileRects(tester);
        expect(tiles.length, 2);
        expect(tiles[0].width, closeTo(tiles[1].width, 0.01),
            reason: 'the WAN and LAN tiles must be the same width');
        expect(tiles[0].height, closeTo(tiles[1].height, 0.01),
            reason: 'the WAN and LAN tiles must be the same height — equal '
                'padding and an equal disc');
      });
    }
  });

  group('the state label keeps a legible share of the tile (#1228)', () {
    // 46px is measured, not chosen: it is the narrowest text column in which any
    // shipped locale renders both of a tile's labels in full (`zh`, 45.6px). A
    // label with less than that is being truncated for no gain, which is exactly
    // what side by side does at the narrowest width — 0px of text, and the row
    // still over by 1.3px.
    const minLegibleTextPx = 46.0;

    // Locales whose labels exceed the budget at these widths, so the label fills
    // whatever it is given and its box measures the budget itself.
    for (final tag in ['el', 'nl', 'fi']) {
      for (final wc in narrowCases) {
        testWidgets(
            '@${wc.label} ${wc.widthKey}px $tag label gets '
            '>= ${minLegibleTextPx.toInt()}px', (tester) async {
          await pumpAt(tester, widthCase: wc, locale: Locale(tag));

          final labels = find.descendant(
            of: find.byType(LayoutBlock).first,
            matching: find.byType(Text),
          );
          expect(labels.evaluate(), isNotEmpty,
              reason: 'the WAN tile rendered no text at all');

          final widest = [
            for (var i = 0; i < labels.evaluate().length; i++)
              tester.getRect(labels.at(i)).width,
          ].reduce((a, b) => a > b ? a : b);

          expect(
            widest,
            greaterThanOrEqualTo(minLegibleTextPx),
            reason: 'the WAN tile gives its longest label only '
                '${widest.toStringAsFixed(1)}px. Below ${minLegibleTextPx.toInt()}px '
                'no shipped locale renders a tile label in full, so the tile is '
                'clean but says nothing (#1228).',
          );
        });
      }
    }
  });

  group('side by side survives where it fits (#1228)', () {
    // The stacking is a narrow-width degradation, not a redesign: mainstream
    // desktop keeps the original arrangement. A threshold raised past the
    // desktop realization would fail here.
    testWidgets('@desktop ${desktopCase.widthKey}px the tiles share a row',
        (tester) async {
      await pumpAt(tester, widthCase: desktopCase, locale: const Locale('el'));

      final tiles = tileRects(tester);
      expect(tiles.length, 2);
      expect(tiles[0].top, closeTo(tiles[1].top, 0.01),
          reason: 'at ${desktopCase.widthKey}px the tiles must still sit side '
              'by side, not stacked');
      expect(tiles[1].left, greaterThan(tiles[0].right),
          reason: 'the LAN tile must start after the WAN tile ends');
    });

    for (final wc in narrowCases) {
      testWidgets('@${wc.label} ${wc.widthKey}px the tiles stack',
          (tester) async {
        await pumpAt(tester, widthCase: wc, locale: const Locale('el'));

        final tiles = tileRects(tester);
        expect(tiles.length, 2);
        expect(tiles[1].top, greaterThanOrEqualTo(tiles[0].bottom),
            reason: 'at ${wc.widthKey}px side by side leaves the text column '
                '0px, so the tiles must stack (#1228)');
      });
    }
  });
}
