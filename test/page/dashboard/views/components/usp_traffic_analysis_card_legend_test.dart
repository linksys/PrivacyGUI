@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/overflow_probe.dart';

/// Overflow tests for the Traffic Analysis Monitor legend row (#1226).
///
/// ## Why this file exists alongside the #1183 gate
///
/// The gate pumps each span's **narrowest realization** — the worst case — and is
/// the ratchet that stops this row regressing. It deliberately does *not* pump
/// the widths a card gets on the **default** layout, because those are not worst
/// cases. But Traffic Analysis is the one card in the baseline that overflows on
/// the default layout at mainstream desktop widths (density design §1.7: clean at
/// only 40.6% of screen widths), and that is the reason #1226 is a layout bug
/// rather than a case for a compact form. So the default-layout widths need their
/// own coverage, or the specific breakage that motivated the fix stays unpinned.
///
/// Tagged `dashboard-card` so it gates PRs — `run_tests.sh` excludes
/// `golden||loc||ui`, and a `ui`-tagged regression test would not block anything.
void main() {
  setUpAll(() async {
    // Real fonts: text widths — and therefore overflow — are meaningless under
    // the Ahem block font.
    await loadAppFonts();
  });

  /// Pumps the card alone at [cardWidth] on a [screenWidth] screen, mirroring how
  /// the gate builds it, and returns overflows beyond the gate's own tolerance.
  ///
  /// One pump per call: Flutter reports a given RenderFlex's overflow only once
  /// per render-object lifetime, so a second pump in the same test would report a
  /// genuinely overflowing width as clean.
  ///
  /// #1270 counted this as the third copy of the Statistics sections'
  /// `overflowsAt` and asked for all three to be folded together. They are not the
  /// same helper: this one pumps a **card** through [probeCardOverflow] — grid
  /// geometry, tab index, card height in rows — while those pump a section into a
  /// fixed-width box on the Statistics page. The only substance they shared was
  /// the tolerance, which is now [kOverflowTolerancePx]; the section half lives in
  /// `test/util/statistics/stats_section_probe.dart`. Merging the two shapes would
  /// mean a helper with two mutually exclusive halves.
  Future<List<OverflowIncident>> overflowsAt({
    required WidgetTester tester,
    required double screenWidth,
    required double cardWidth,
    required Locale locale,
    int tabIndex = 0,
  }) async {
    final incidents = await probeCardOverflow(
      tester,
      cardId: 'traffic_analysis',
      widthCase: CardWidthCase(
        screenWidth: screenWidth,
        cardWidth: cardWidth,
        columnSpan: 6,
        label: 'default',
      ),
      // The card's strict height strategy; matches what the grid gives it.
      cardHeightRows: 5,
      tabIndex: tabIndex,
      locale: locale,
    );
    return incidents.where((i) => i.pixels > kOverflowTolerancePx).toList();
  }

  /// The default preset span is 6 (`w: 6`), and the widths that span realizes on
  /// mainstream desktop screens. Derived from the frozen grid formulas rather
  /// than quoted: `cardWidthAt(screen, 6)`.
  ///
  /// #1226 names "496px and 512px, the default-layout widths at 1440px and
  /// 1024px screens". The pairing in the ticket is off by one regime — at 1024px
  /// the 12-column grid uses a 24px margin and yields **480px**, while 512px is
  /// what a 1440px screen yields and 496px appears at 1408/1520/1712px. All three
  /// widths are covered here, so the ticket's intent (clean on the mainstream
  /// desktop default layout) holds as a superset of what it literally asked for.
  const defaultLayoutWidths = <({double screen, double card})>[
    (screen: 1024.0, card: 480.0),
    (screen: 1408.0, card: 496.0),
    (screen: 1440.0, card: 512.0),
    // The narrowest the default span ever gets on a desktop grid (1280px screen,
    // where the 200px page margins bite hardest — density design §1.7 D1).
    (screen: 1280.0, card: 432.0),
  ];

  group('default layout is clean (#1226)', () {
    for (final w in defaultLayoutWidths) {
      testWidgets(
        'no overflow at ${w.card.toStringAsFixed(0)}px '
        '(${w.screen.toStringAsFixed(0)}px screen, span 6)',
        (tester) async {
          // French, not English. Measured before the fix: of all 26 locales, `fr`
          // was the ONLY one that overflowed at these default-layout widths
          // (+92px @ 432, +44 @ 480, +28 @ 496, +12 @ 512) — "Téléchargement" /
          // "Téléversement" are the longest upload/download pair shipped. An
          // English-only version of this test passed before the fix existed, so
          // it would have gated nothing.
          final overflows = await overflowsAt(
            tester: tester,
            screenWidth: w.screen,
            cardWidth: w.card,
            locale: const Locale('fr'),
          );
          expect(
            overflows,
            isEmpty,
            reason: 'Traffic Analysis overflows on the DEFAULT layout at a '
                '${w.screen.toStringAsFixed(0)}px screen — a mainstream desktop '
                'width, so users see this without resizing anything '
                '(density design §1.7). ${overflows.join(', ')}',
          );
        },
      );
    }

    // The widest locales in the baseline for this card, plus the two that were
    // worst at the narrowest realization (de +75px, ru +61px). If the row is
    // clean in English but not in these, the fix relies on English being short.
    for (final tag in ['fr', 'de', 'fi', 'ru', 'zh_TW']) {
      testWidgets('no overflow at 480px in $tag', (tester) async {
        final locale = AppLocalizations.supportedLocales.firstWhere((l) {
          final t = l.countryCode == null || l.countryCode!.isEmpty
              ? l.languageCode
              : '${l.languageCode}_${l.countryCode}';
          return t == tag;
        });
        final overflows = await overflowsAt(
          tester: tester,
          screenWidth: 1024.0,
          cardWidth: 480.0,
          locale: locale,
        );
        expect(overflows, isEmpty,
            reason:
                'default layout overflows in $tag: ${overflows.join(', ')}');
      });
    }
  });

  group('byte totals stay legible (#1226)', () {
    testWidgets('totals are still rendered at the narrowest realization',
        (tester) async {
      // The AC's "byte totals remain readable" — the legend is a key to the
      // chart, but the totals are the card's actual content, so degrading must
      // not drop them. Narrowest realization of the min span (4 @ 601px).
      final narrowest = narrowestRealizationOf(4, minScreen: 0)!;
      await overflowsAt(
        tester: tester,
        screenWidth: narrowest.screenWidth,
        cardWidth: narrowest.cardWidth,
        locale: const Locale('en'),
      );

      // Assert on the formatted byte values from the fixture, not on the
      // direction markers. Those markers are icons (Icons.arrow_upward /
      // arrow_downward) rather than U+2191/U+2193 characters, so a text-prefix
      // finder would pass or fail on how the arrow is drawn rather than on
      // whether the total survived.
      final totals = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data?.isNotEmpty ?? false) &&
            RegExp(r'^[\d.]+\s*(B|KB|MB|GB|TB)$').hasMatch(w.data!),
      );
      expect(totals, findsNWidgets(2),
          reason: 'both byte totals must survive degradation — they are '
              'content, not chrome, so they never shrink or ellipsize');

      // And the icons that label them are still there, so the surviving numbers
      // are still attributable to a direction.
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_upward,
        ),
        findsWidgets,
        reason: 'upload direction marker must survive',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.arrow_downward,
        ),
        findsWidgets,
        reason: 'download direction marker must survive',
      );
    });
  });

  group('every tab is clean at the narrowest realization (#1226)', () {
    // The card has 4 tabs; the baseline's 49 coordinates were all on tab 0, but
    // the other three carry legend rows of the same shape and must stay clean.
    //
    // One locale, not 26, and deliberately: `de` was the widest of the 26 at
    // this realization (+75px before the fix, ahead of ru's +61px — see the
    // sweep above), so it is the worst case rather than a convenient pick. The
    // 26 × 4 obligation in #1226's AC is carried by the gate
    // (`dashboard_card_overflow_test.dart`), which pumps every locale on every
    // tab; this group exists to fail fast and locally when a tab regresses.
    for (var tab = 0; tab < 4; tab++) {
      testWidgets('tab $tab at the narrowest realization', (tester) async {
        final narrowest = narrowestRealizationOf(4, minScreen: 0)!;
        final overflows = await overflowsAt(
          tester: tester,
          screenWidth: narrowest.screenWidth,
          cardWidth: narrowest.cardWidth,
          locale: const Locale('de'),
          tabIndex: tab,
        );
        expect(overflows, isEmpty,
            reason: 'tab $tab overflows at '
                '${narrowest.cardWidth.toStringAsFixed(0)}px: '
                '${overflows.join(', ')}');
      });
    }
  });
}
