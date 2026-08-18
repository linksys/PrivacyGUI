@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/dashboard/text_readability_probe.dart';

/// Gauge-centre readability (#1234, extended by #1235).
///
/// Both cards with an `AppGauge` are guarded here, because their two fixes fail
/// in opposite directions and the contrast is the point: `system_status`'s twin
/// gauges are **width**-bound and shrink to fit, `network_health`'s single gauge
/// is **height**-bound and its centre scales to fit. One `centerBuilder`
/// ellipsizes its label and the other must never truncate its own — the
/// difference is what the string *is*, exactly as §2.10a point 2 has it.
///
/// ## Why this file exists alongside the #1183 gate
///
/// `system_status`'s Monitor tab drew two `AppGauge(size: 100)` in a
/// `spaceEvenly` row inside a box measured at 157.4px, so it overflowed by a
/// constant +43.0px in all 26 locales. #1234 fixes it by bounding the diameter
/// with a `LayoutBuilder` — at the narrowest realization the circles come out at
/// 72.7px each.
///
/// The gate owns the overflow half of that: revert the bound and 26 coordinates
/// come back. What the gate cannot see is what shrinking the circle does to its
/// *contents*. `centerBuilder`'s widget is a non-positioned `Stack` child, so it
/// is handed loose `size × size` constraints, and a `Column` under loose
/// constraints reports overflow only in its own axis — there is 72.7px of height
/// for ~40px of text, so anything that happens to the width is silent. Two
/// distinct silent failures live there:
///
///   - the label soft-wrapping mid-word inside the arc (`Arbeitsspeicher` is
///     88.1px of `bodySmall` in a 72.7px circle);
///   - the *reading* clipping to a stub, which is the one thing the card exists
///     to show, if the circle ever shrinks below it.
///
/// #1234's fourth acceptance criterion — "gauge readings stay legible at the
/// narrowest clean width" — is exactly this blind spot, which is why it gets a
/// file rather than a gate entry.
///
/// Tagged `dashboard-card` so it gates PRs: `run_tests.sh` excludes
/// `golden||loc||ui`, so a `ui`-tagged test here would block nothing.
///
/// ## Mutation ledger
///
/// Each mutation was run against this file *and* the gate, because a mutation
/// the gate already catches proves nothing about this file (§2.10b point 4).
///
/// The gate column is measured with `system_status`'s allowlist entries already
/// deleted, i.e. against the ratchet as this branch leaves it — with them still
/// in place every mutation below is trivially green and the table would say
/// nothing.
///
///   | mutation                                            | this file | the gate |
///   |-----------------------------------------------------|-----------|----------|
///   | drop `maxLines: 1` from the centre label            | 1 fail    | green    |
///   | `LayoutBuilder` bound removed (`size: 100`)         | green     | 26 fail  |
///   | gauges stacked in a `Wrap` instead of shrunk        | 1 fail    | green    |
///   | bound by width only, dropping the height term       | green     | green    |
///
/// The first row is the reason the file exists: dropping `maxLines` leaves every
/// gate case green while `de` renders `Arbeits`/`speicher` broken across two
/// lines inside a 72.7px circle.
///
/// The second row is the boundary between the two mechanisms — the gate owns the
/// overflow, so this file does not restate it.
///
/// The third row is the design alternative #1234 rejected, and it came out worse
/// than expected. Two 100px runs need ~208px against the 201px (`en`) / 181px
/// (`de`) the `Expanded` offers, so the guess was "overflows the bottom in the
/// long translations". It does not overflow anywhere: `RenderWrap` has no
/// overflow indicator of its own, and the `Expanded` pins its height, so the
/// second circle is *clipped in silence* — measured 108px between gauge centres
/// inside a 181px box, all 209 gate cases green. The general lesson, which
/// §2.10a point 3 states in terms of bottom overflow, is sharper than that: a
/// `Wrap` under an `Expanded` cannot report the height it needed, so "the gate
/// would tell me if the extra run did not fit" is false. That is why the
/// precondition has to be measured before the conversion, not observed after.
///
/// The fourth row is honest rather than useful: at every width the row
/// enumeration actually produces, the height term in the `math.min` is not the
/// binding one (181–201px of height for a 72.7px circle). It is a guard against
/// a future row span, not a live constraint, and nothing here can pin it without
/// inventing a card height the grid never asks for.
///
/// ### `network_health` (#1235), same method, `network_health`'s entries stripped
///
/// Re-measured after #1291 declared this card's threshold, because that ticket
/// changed what the gate is able to see here. The gate column below is the new
/// measurement; the parenthesised number is what it was when #1235 wrote it:
///
///   | mutation                                            | this file | the gate     | density  |
///   |-----------------------------------------------------|-----------|--------------|----------|
///   | `FittedBox` removed entirely                        | 1 fail    | green (was 3)| 9 fail   |
///   | score + tier ellipsized instead of scaled           | 1 fail    | green (was 2)| 9 fail   |
///   | score font shrunk always (`titleLarge`→`bodyMedium`) | 1 fail    | green        | 1 fail   |
///   | `BoxFit.contain` instead of `scaleDown`             | green     | green        | green    |
///
/// **Rows 1 and 2 lost their gate coverage entirely, and that is by design.**
/// #1235's three coordinates were all at 191.375px, and after #1291 the
/// production factory renders the *popup* form there — no gauge, no centre, no
/// overflow to find. At the one realization that still draws the gauge (288px,
/// compact) the metric row is gone, so the centre fits at its natural size and
/// nothing about the fit can overflow either. The gate has not become weaker; the
/// card stopped being rendered in the shape the gate was catching. What follows
/// is that this file and `usp_network_health_density_test.dart` are now the only
/// guard on the centre's fit, so neither may be deleted as "covered by the gate".
///
/// The density column is that file's 17 tests, and its 9s are honest but blunt:
/// they are its `findsOneWidget` precondition on the `FittedBox` refusing to
/// measure a tree that no longer has one. Loud, and correct to keep, but it is
/// this file's single failure that is the real kill — «Удовлетворительный»
/// truncated in `ru`, which is the reading being lost.
///
/// Row 2 is the fix #1235's own text implies ("the tier label is wider than the
/// space inside the circle" ⇒ ellipsize it). It truncates the tier, and when it
/// was measured it also left two of the three coordinates standing, because the
/// overflow was vertical: one line saved in `ru` is enough, 28+16px of column in
/// a 23px box in `de` is not. A wrong diagnosis producing a fix that is both
/// lossy and incomplete is the cheapest possible argument for measuring first.
///
/// Row 3 is why the 12px legibility floor and the unscaled-at-preferred canary
/// are in this file at all. Permanently shrinking the score clears all 209 gate
/// cases — `scaleDown` has *removed* the overflow signal for good, so nothing in
/// the ratchet can ever object to squeezing this centre further. The floor is the
/// replacement signal.
///
/// Row 4 is an equivalent mutant, recorded so nobody reads its greenness as a
/// gap: the centre is handed **loose** constraints, and under loose constraints
/// `contain` never scales *up* either, so the two fits render identically here.
/// `scaleDown` is kept as the honest spelling of the intent — it stays correct if
/// this subtree is ever given a tight box, which `contain` would not.
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is one square em, so
    // what fits — and therefore what ellipsizes — is fiction.
    await loadAppFonts();
  });

  /// Pumps [cardId]'s first tab at the narrowest realization of the given span
  /// — for `min`, the worst case the gate measures and the only width where
  /// either fix bites. One pump, as the gate does.
  ///
  /// The form is pinned to [CardDensity.normal], which it did not need to be
  /// before #1291 declared `network_health`'s threshold. Unpinned, six of the
  /// seven tests in the second group below stopped finding an `AppGauge` at all:
  /// 191.375px is under `kPopupBelow`, so the production factory renders the
  /// popup form there and the centre those tests measure is not on screen. That
  /// is form *selection*, not a layout regression, and reading it as one would
  /// have been the worst possible outcome — the same trap #1288 and #1289 hit and
  /// pinned their way out of.
  ///
  /// Pinned rather than re-pointed at the new live floor because of what each
  /// file is for: this one guards the two mechanisms #1234 and #1235 built, at
  /// the widths they were measured at, and `scaleDown` has to keep working
  /// wherever a future layout re-squeezes this box. Which form the grid *selects*
  /// at each width, and that the selected one is clean, is
  /// `usp_network_health_density_test.dart`'s claim.
  Future<void> pumpAt(
    WidgetTester tester, {
    required String cardId,
    required bool preferred,
    required Locale locale,
  }) async {
    final constraints = (UspWidgetSpecs.getById(cardId) ??
            (throw ArgumentError.value(
                cardId, 'cardId', 'no such card in UspWidgetSpecs.all')))
        .getConstraints(DisplayMode.normal);
    final columns =
        preferred ? constraints.preferredColumns : constraints.minColumns;
    final narrowest = narrowestRealizationOf(columns, minScreen: 0)!;
    await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: CardWidthCase(
        screenWidth: narrowest.screenWidth,
        cardWidth: narrowest.cardWidth,
        columnSpan: columns,
        label: preferred ? 'preferred' : 'min',
      ),
      cardHeightRows: constraints.minHeightRows,
      density: CardDensity.normal,
      // Tab 0 only, and that is the whole of AC 1 rather than a sample of it.
      // #1235 says "all 3 tabs", but `network_health` builds its `AppGauge` in
      // `_HealthOverview`, which `_buildTabContent`'s `switch` reaches for
      // `selectedTab == 0` alone — tabs 1 and 2 are `_ErrorsChart` and
      // `_LossChart`, with no gauge and so no centre to overflow. Likewise
      // `system_status`'s pair belongs to tab 0, Monitor. The gate still sweeps
      // all three tabs of both cards for overflow; what this file adds is the
      // part of AC 1 that has a gauge in it.
      tabIndex: 0,
      locale: locale,
    );
  }

  /// The `Text`s painted inside gauge [i]'s centre, in tree order: the reading
  /// first, its label second.
  ///
  /// Read through the gauge rather than off the card, because the same numbers
  /// appear again in the legend row below — a card-wide `find.text('47%')` would
  /// match whichever came first and pass while the centre was empty.
  List<Text> centreTexts(WidgetTester tester, int i) => tester
      .widgetList<Text>(find.descendant(
        of: find.byType(AppGauge).at(i),
        matching: find.byType(Text),
      ))
      .where((t) => t.data != null && t.data!.isNotEmpty)
      .toList();

  group('the reading survives the shrunken circle (#1234 AC4)', () {
    // The gauges are the tab's headline: the label names a series, the reading
    // *is* the datum. So the two are held to different standards below — the
    // reading may never give, the label may ellipsize but may never wrap.
    for (final tag in ['en', 'de', 'ru', 'th']) {
      testWidgets('both gauges show their full percentage in $tag',
          (tester) async {
        await pumpAt(tester,
            cardId: _kSystemStatus,
            preferred: false,
            locale: supportedLocaleFor(tag));

        expect(find.byType(AppGauge), findsNWidgets(2),
            reason: 'the Monitor tab compares CPU against memory, so both '
                'gauges must be drawn — a fix that fits by dropping one is not '
                'a fix.');

        for (var i = 0; i < 2; i++) {
          final texts = centreTexts(tester, i);
          expect(texts, hasLength(2),
              reason: 'gauge $i should paint a reading and its label; got '
                  '${texts.map((t) => t.data).toList()}');

          final reading = texts.first;
          expect(reading.data, matches(RegExp(r'^\d+%$')),
              reason: 'gauge $i\'s first centre line should be the percentage, '
                  'not "${reading.data}"');
          expect(tester.isTextClipped(find.byWidget(reading)), isFalse,
              reason: 'gauge $i\'s reading "${reading.data}" is clipped at the '
                  'narrowest width. The circle has been bounded below the size '
                  'of the number it exists to show.');
          expect(tester.textLineCount(find.byWidget(reading)), 1,
              reason: 'gauge $i\'s reading "${reading.data}" wrapped onto a '
                  'second line inside the arc.');
        }
      });

      testWidgets('neither gauge label wraps inside the arc in $tag',
          (tester) async {
        await pumpAt(tester,
            cardId: _kSystemStatus,
            preferred: false,
            locale: supportedLocaleFor(tag));
        final l = await AppLocalizations.delegate.load(supportedLocaleFor(tag));

        final labels = [
          for (var i = 0; i < 2; i++) centreTexts(tester, i).last,
        ];
        expect(labels.map((t) => t.data), containsAll([l.cpu, l.memory]),
            reason: 'each gauge must name its own series; got '
                '${labels.map((t) => t.data).toList()}');

        for (final label in labels) {
          // One line, clipped or not. `de`'s `Arbeitsspeicher` is 88.1px of
          // `bodySmall` inside a 72.7px circle, so the ellipsis is *expected*
          // there and asserting `isTextClipped == false` would be a lie. What must
          // not happen is the soft wrap: a mid-word break inside a 72.7px arc
          // costs the label its readability and the centre its shape, and every
          // gate case stays green through it.
          expect(tester.textLineCount(find.byWidget(label)), 1,
              reason: 'gauge label "${label.data}" painted '
                  '${tester.textLineCount(find.byWidget(label))} lines inside the arc. The label '
                  'is a series name: it ellipsizes to one line, and the full '
                  'string stays available in the legend row below.');

          // The centre is a non-positioned `Stack` child under loose
          // `size × size` constraints, and `AppGauge` builds that `Stack` with
          // `clipBehavior: Clip.none` — so a centre wider than its circle is
          // neither clipped nor reported: it paints straight over the arc and
          // into the neighbouring gauge. Bounds have to be asserted because
          // nothing else objects.
          final gauge = tester.getRect(find.ancestor(
              of: find.byWidget(label), matching: find.byType(AppGauge)));
          final rect = tester.getRect(find.byWidget(label));
          expect(rect.left, greaterThanOrEqualTo(gauge.left - 1.0));
          expect(rect.right, lessThanOrEqualTo(gauge.right + 1.0),
              reason: 'gauge label "${label.data}" paints outside its own '
                  'circle, over the arc.');
        }
      });
    }

    testWidgets('the two gauges stay side by side and the same size',
        (tester) async {
      // The rejected alternative, pinned: stacking the circles vertically also
      // clears the overflow, and would leave every assertion above true. But
      // the tab's value is the CPU-against-memory comparison, and two circles
      // of different diameters or on different rows no longer make it.
      await pumpAt(tester,
          cardId: _kSystemStatus,
          preferred: false,
          locale: supportedLocaleFor('de'));

      final first = tester.getRect(find.byType(AppGauge).at(0));
      final second = tester.getRect(find.byType(AppGauge).at(1));

      expect((first.center.dy - second.center.dy).abs(), lessThan(2.0),
          reason: 'the gauges are on different rows (${first.center.dy} vs '
              '${second.center.dy}), so the comparison they exist for now needs '
              'a vertical scan. #1234 shrinks the circles instead of stacking '
              'them precisely to avoid this.');
      // The `AppSpacing.md` reserve exists so the two rings cannot touch, and
      // `spaceEvenly` leaves a third of it between them: 4.0px as measured. A
      // gap that has collapsed to nothing means the reserve was dropped or
      // spent elsewhere, which no gate case can see — two touching circles
      // overflow nothing.
      expect(second.left - first.right, greaterThan(3.0),
          reason: 'the drawn gap between the two rings is '
              '${second.left - first.right}px; they read as one figure of eight '
              'well before they overlap.');
      expect((first.width - second.width).abs(), lessThan(1.0),
          reason: 'the gauges have different diameters (${first.width} vs '
              '${second.width}), so their arcs are no longer comparable.');
    });

    testWidgets('the ellipsis is a narrow-width net, not the normal state',
        (tester) async {
      // The canary #1229 taught: a fix whose safety net is always engaged has
      // stopped being a safety net. At the preferred width the circles are back
      // to their natural 100px, which fits `de`'s 88.1px label with room to
      // spare — so if this ever starts failing, either the bound has begun
      // biting at widths it should not or a translation has outgrown the circle
      // outright, and both want a look rather than a silent ellipsis.
      await pumpAt(tester,
          cardId: _kSystemStatus,
          preferred: true,
          locale: supportedLocaleFor('de'));
      final l = await AppLocalizations.delegate.load(supportedLocaleFor('de'));

      for (var i = 0; i < 2; i++) {
        final label = centreTexts(tester, i).last;
        expect(tester.isTextClipped(find.byWidget(label)), isFalse,
            reason: 'gauge label "${label.data}" is ellipsized at the '
                'preferred width, where the circle is at its natural size. '
                'The centre is now degrading in the layout the grid hands the '
                'card by default, not just at the narrowest one.');
      }
      expect([for (var i = 0; i < 2; i++) centreTexts(tester, i).last.data],
          containsAll([l.cpu, l.memory]));
    });
  });

  group('the health score scales instead of overflowing (#1235)', () {
    // `network_health`'s gauge fails the opposite way round from
    // `system_status`'s. There the binding constraint was width and the circles
    // were shrunk to fit it; here the box is already squashed *vertically* by
    // the layout above — `AppGauge(size: 120)` lays out at 120×67 in `en` and
    // 120×23 in `de`, because `_MetricChip`'s three ~23.1px label columns
    // soft-wrap to between 3 and 6 lines and eat the `Expanded`'s height. The
    // 44px centre column then overflowed the bottom by +21/+11/+9px in
    // `de`/`ru`/`th`, which is #1235's three coordinates.
    //
    // `BoxFit.scaleDown` fixes that, and in doing so takes the signal away from
    // the gate **permanently**: a `FittedBox` always fits its child, so no
    // amount of future height starvation can ever produce an overflow here
    // again. This group is the replacement for the signal that fix removed, and
    // that — not the overflow, which the gate can no longer regress on — is why
    // it exists.
    for (final tag in ['en', 'de', 'ru', 'th', 'fr']) {
      testWidgets('the score and its tier both stay whole in $tag',
          (tester) async {
        await pumpAt(tester,
            cardId: _kNetworkHealth,
            preferred: false,
            locale: supportedLocaleFor(tag));

        final texts = centreTexts(tester, 0);
        expect(texts, hasLength(2),
            reason: 'the centre is the score over its tier; got '
                '${texts.map((t) => t.data).toList()}');

        final score = texts.first;
        expect(score.data, matches(RegExp(r'^\d+$')),
            reason: 'the first centre line should be the health score, not '
                '"${score.data}"');

        // Neither line may be truncated or broken, in any locale. This is AC 4
        // read literally — "a tier abbreviated past recognition is worse than a
        // smaller font" — and it is what makes `scaleDown` the right mechanism
        // rather than the `maxLines: 1` ellipsis used inside `system_status`'s
        // circles: a tier name is the *reading* here, not a series label, so it
        // may shrink but may not lose characters.
        for (final t in texts) {
          expect(tester.isTextClipped(find.byWidget(t)), isFalse,
              reason: '"${t.data}" is ellipsized inside the gauge. The centre '
                  'is supposed to scale down, not truncate — a clipped tier is '
                  'exactly what AC 4 rules out.');
          expect(tester.textLineCount(find.byWidget(t)), 1,
              reason:
                  '"${t.data}" wrapped onto ${tester.textLineCount(find.byWidget(t))} lines '
                  'inside the gauge. `FittedBox` lays its child out unbounded, '
                  'so a wrap here means something re-imposed a width.');
        }
      });
    }

    testWidgets('the score stays above the legibility floor at the narrowest',
        (tester) async {
      // The floor, and the honest reading of it. `de` is the worst realization
      // in the suite: the metric row takes 96px there against `en`'s 48px, so
      // the gauge box is 23px tall and the centre paints at scale 0.52 — a
      // 14.6px score over an 8.4px tier. That is small, and it is a measurement
      // of the density defect rather than a design choice: this card is being
      // rendered at 191px when §1.2 puts its fit width at 420px, and the real
      // remedy is a threshold, at which point `scaleDown` relaxes back to 1.0 on
      // its own.
      //
      // That remedy landed: #1291 declared `normalAbove: 366` and dropped the
      // metric row in the compact band, so no width the grid can select renders
      // this squeeze any more — 191px is the popup form and 200-365px gives the
      // gauge its full 120x120. This case therefore survives as a **pinned**
      // one, and its subject changed with it: not "what the user sees at 191px"
      // but "`scaleDown` still absorbs a starved box", which is the property
      // #1235 bought and the one a future layout could silently spend.
      //
      // So the floor is set just under today's worst case. It is not a claim
      // that 12px is comfortable; it is the tripwire for the squeeze getting
      // *worse*, which is now invisible to everything else in the suite.
      await pumpAt(tester,
          cardId: _kNetworkHealth,
          preferred: false,
          locale: supportedLocaleFor('de'));

      final score = centreTexts(tester, 0).first;
      final painted = tester.getRect(find.byWidget(score));
      expect(painted.height, greaterThan(12.0),
          reason: 'the health score paints at ${painted.height}px tall, below '
              'the 12px floor. The gauge box has been squeezed further than '
              'the 23px #1235 measured — look at what grew above or below it, '
              'because the FittedBox will keep absorbing this silently.');
    });

    testWidgets('the centre is unscaled at the preferred width',
        (tester) async {
      // Same canary as the `system_status` group: a fix whose safety net is
      // always engaged has stopped being a safety net. At the preferred width
      // the metric labels have room, the height comes back, and the centre must
      // paint at its natural size — 28px of `titleLarge`. `en` and `fr` already
      // reach scale 1.0 at the *narrowest* width, so a failure here means the
      // squeeze has spread to the layout the grid hands the card by default.
      await pumpAt(tester,
          cardId: _kNetworkHealth,
          preferred: true,
          locale: supportedLocaleFor('de'));

      final texts = centreTexts(tester, 0);
      final scoreRect = tester.getRect(find.byWidget(texts.first));
      expect(scoreRect.height, closeTo(28.0, 0.5),
          reason: 'the health score paints at ${scoreRect.height}px instead of '
              'its natural 28px, so the centre is being scaled down at the '
              'preferred width and not just at the narrowest one.');
      for (final t in texts) {
        expect(tester.isTextClipped(find.byWidget(t)), isFalse);
      }
    });
  });
}

const _kSystemStatus = 'system_status';
const _kNetworkHealth = 'network_health';
