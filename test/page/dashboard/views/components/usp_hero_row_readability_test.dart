@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/dashboard/text_readability_probe.dart';

/// Hero-row readability (#1236 AC 4, #1237 AC 5).
///
/// The hero inner row of `lan_info` and `time_settings` is the largest shape in
/// the #1183 baseline (48 of 84 coordinates). The gate owns the overflow: revert
/// either `Flexible` and the coordinates come back. It cannot own the two
/// acceptance criteria that say what the *content* must still be afterwards,
/// because both fixes make the row fit and neither leaves anything to report:
///
///   - #1236 AC 4 — "Network addresses and device identifiers stay readable;
///     truncating an IP or MAC in the middle makes it useless."
///   - #1237 AC 5 — "Timezone names — the longest strings on this card — stay
///     identifiable."
///
/// Both are satisfied by *soft-wrapping* rather than ellipsizing, and that is a
/// choice, not a property of the widgets: adding `maxLines: 1` to any of these
/// would leave all 1644 gate cases green while cutting `192.168.1.100 ~ 192.…`
/// out of the middle. So the criteria get assertions.
///
/// The last group is the awkward one and the reason this file is not just a
/// ratchet formality: #1237's fix *introduces* an ellipsis on the sync badge. A
/// capsule cannot take a second line (§2.10a point 2), so that trade is
/// deliberate, but it is exactly the trade #1236 rejected one file over — and a
/// badge that has been squeezed to `Sync…`, or past it to `S…`, is
/// indistinguishable from a correct one in a green gate. What is asserted is the
/// floor: enough glyphs to key the state, plus the colour that also encodes it.
///
/// Tagged `dashboard-card` so it gates PRs — `run_tests.sh` excludes
/// `golden||loc||ui`, so a `ui` tag here would block nothing.
///
/// ## Mutation ledger
///
/// Measured with the four cards' allowlist entries already deleted, i.e. against
/// the ratchet as this branch leaves it (§2.10b point 4).
///
///   | mutation                                                | this file | the gate |
///   |---------------------------------------------------------|-----------|----------|
///   | `maxLines: 1` + ellipsis on `lan_info`'s router IP      | 4 fail    | green    |
///   | `maxLines: 1` + ellipsis on the DHCP status label       | 4 fail    | green    |
///   | `maxLines: 1` + ellipsis on the InfoGrid value renderer | 4 fail    | green    |
///   | the deleted single-child `Row` restored around the badge | green     | 21 fail  |
///   | `normalAbove` deleted from either card's `WidgetSpec`    | green     | green    |
///
/// The first three rows are the point: every one of them is a plausible "fix the
/// overflow" edit, all three are invisible to the gate, and all three destroy a
/// reading the two tickets name explicitly. Each kills exactly the group that
/// names it — all four of its locales and nothing else — so the failure says
/// which criterion broke, not just that something did. (Row three mutates the
/// shared renderer at `list_blocks.dart:234`, so it ellipsizes `lan_info`'s grid
/// values too; those assertions read the hero row, which is why only the
/// timezone group moves.)
///
/// The fourth row is the boundary, and it runs the other way: restoring the
/// defect #1237 actually fixed returns all 21 of that card's coordinates while
/// leaving this file green. The two verifications are meant not to overlap. The
/// gate owns the overflow outright, so this file does not restate it; what it
/// covers is the readability the gate stays green through either way.
///
/// The fifth row is green twice over and says so on purpose. Deleting a
/// `normalAbove` withdraws the promise that these cards degrade below it, and
/// neither this file (which pins density — see `pumpNarrowest`) nor the gate
/// (whose 191.4px normal form fits, which is the whole reason #1288 exists) can
/// see it go. That defect belongs to `usp_hero_row_density_test.dart`, and the
/// row is recorded here so the gap is documented from both sides rather than
/// assumed covered by whichever file the reader happens to open first.
void main() {
  setUpAll(() async {
    // Real fonts: under Ahem every glyph is one square em, so what wraps —
    // and therefore what stays whole — is fiction.
    await loadAppFonts();
  });

  /// Pumps [cardId]'s first tab at the narrowest realization of its `minColumns`
  /// span: the worst case the gate measures, and the only width where the hero
  /// row's 61.4px column bites.
  ///
  /// Density is pinned to [CardDensity.normal], and that pin is what keeps this
  /// file measuring what it was written to measure. Since #1288 both cards
  /// declare a `normalAbove` (250 / 256) well above this 191.4px width, so in
  /// production the card here renders the *popup* form — one value over the
  /// card's name, no DHCP status and no timezone grid, i.e. none of the strings asserted
  /// below. Without the pin every assertion in this file would start failing on
  /// a missing widget, and the honest reading of that failure is not "the
  /// readability regressed" but "this width no longer shows this content".
  ///
  /// Which leaves the question of whether the assertions still mean anything,
  /// and they do: 191.4px is the narrowest width the *normal* form is ever asked
  /// to render, so it remains the strictest test of the wrap-not-ellipsis
  /// choices #1236 and #1237 made — and those choices still govern every width
  /// from `normalAbove` up. #1288 narrowed where the normal form is *selected*;
  /// it did not soften what the normal form owes the reader when it is. The
  /// degraded forms are a different claim with a different test file
  /// (`usp_hero_row_density_test.dart`).
  Future<void> pumpNarrowest(
    WidgetTester tester, {
    required String cardId,
    required Locale locale,
  }) async {
    final constraints = (UspWidgetSpecs.getById(cardId) ??
            (throw ArgumentError.value(
                cardId, 'cardId', 'no such card in UspWidgetSpecs.all')))
        .getConstraints(DisplayMode.normal);
    final narrowest =
        narrowestRealizationOf(constraints.minColumns, minScreen: 0)!;
    await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: CardWidthCase(
        screenWidth: narrowest.screenWidth,
        cardWidth: narrowest.cardWidth,
        columnSpan: constraints.minColumns,
        label: 'min',
      ),
      cardHeightRows: constraints.minHeightRows,
      tabIndex: 0,
      locale: locale,
      density: CardDensity.normal,
    );
  }

  const kLanInfo = 'lan_info';
  const kTimeSettings = 'time_settings';

  group('addresses and identifiers stay whole (#1236 AC4)', () {
    // `en` is included deliberately: this shape overflowed in every locale, so
    // the English rendering is as much of a test case as `el` is.
    for (final tag in ['en', 'de', 'el', 'ru']) {
      testWidgets('$tag — the router IP is never cut', (tester) async {
        await pumpNarrowest(tester,
            cardId: kLanInfo, locale: supportedLocaleFor(tag));

        // Measured: 105.8px of `titleLarge` in a 61.4px column, so it paints on
        // two lines. Two lines is fine — `192.168.1.1` split after a dot is
        // still the address. `192.16…` is not, and that is what any `maxLines`
        // here would produce.
        expect(tester.isTextClipped(find.text('192.168.1.1')), isFalse,
            reason: 'the router IP was truncated. An address that has lost its '
                'last octet cannot be typed into a browser, which is the one '
                'thing this hero exists for (#1236 AC 4).');
        expect(find.text('192.168.1.1'), findsOneWidget);
      });

      testWidgets('$tag — the DHCP status keeps both words', (tester) async {
        await pumpNarrowest(tester,
            cardId: kLanInfo, locale: supportedLocaleFor(tag));

        // The composed status, per §2.10a point 2: ~49px of column would
        // ellipsize `DHCP Enabled` to `DHCP…`, dropping the word that carries
        // the state. Soft-wrap keeps it; `el` pays 81px of height for 3 runs
        // and the card's `SingleChildScrollView` absorbs that.
        final status = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .firstWhere((d) => d.startsWith('DHCP '),
                orElse: () => throw TestFailure(
                    'no DHCP status text found on the card at all'));

        expect(tester.isTextClipped(find.text(status)), isFalse,
            reason: 'the DHCP status "$status" was truncated, so the row now '
                'shows a protocol name and no state.');
        expect(status.trim().split(RegExp(r'\s+')).length, greaterThan(1),
            reason: 'the status collapsed to a single token ("$status") — the '
                'state word is what the row is for.');
      });
    }
  });

  group('the timezone name stays identifiable (#1237 AC5)', () {
    for (final tag in ['en', 'de', 'ru', 'th']) {
      testWidgets('$tag — the timezone value is never cut', (tester) async {
        await pumpNarrowest(tester,
            cardId: kTimeSettings, locale: supportedLocaleFor(tag));

        // Measured: 137.8px of value in a 133.4px cell, so it wraps to 2 lines
        // and stays whole. `America/Los_Ang…` and `America/…` are both
        // ambiguous between real zones, which is what "identifiable" rules out.
        expect(tester.isTextClipped(find.text('America/Los_Angeles')), isFalse,
            reason: 'the timezone name was truncated. Zone names share long '
                'prefixes, so a cut one names a region and not a zone '
                '(#1237 AC 5).');
      });
    }
  });

  group('the sync badge is squeezed, not emptied (#1237, the trade)', () {
    for (final tag in ['en', 'de', 'ru']) {
      testWidgets('$tag — the badge keeps enough to read', (tester) async {
        await pumpNarrowest(tester,
            cardId: kTimeSettings, locale: supportedLocaleFor(tag));

        // The badge label is whichever `bodySmall`-sized text sits inside the
        // capsule; find it by the widget rather than by string, since every
        // locale spells it differently.
        final badge = tester
            .widgetList<Text>(find.descendant(
              of: find.byType(AppBadge),
              matching: find.byType(Text),
            ))
            .where((t) => (t.data ?? '').isNotEmpty)
            .toList();
        expect(badge, hasLength(1),
            reason: 'expected exactly one label inside the sync badge; got '
                '${badge.map((t) => t.data).toList()}');
        final data = badge.single.data!;

        // One line always — a capsule cannot grow one (§2.10a point 2). Whether
        // it ellipsizes is locale-dependent (`de`'s `Synchronisiert` is 85.1px
        // in a 45.4px capsule and does; `en`'s `Synced` does not), so clipping
        // is permitted and *emptying* is not.
        expect(tester.textLineCount(find.text(data)), 1,
            reason: 'the badge label "$data" wrapped to a second line, which a '
                'capsule cannot hold — it will paint outside its own pill.');

        // The floor. `de` shows 45.4px of an 85.1px string today, i.e. about
        // half. Below ~24px there is an ellipsis and one or two glyphs, at
        // which point the badge says nothing and the colour is carrying the
        // whole state. Nothing in the gate can see that happen, because a
        // narrower badge overflows *less*.
        final painted = tester.paragraphOf(find.text(data)).size.width;
        expect(painted, greaterThan(24.0),
            reason: 'the sync badge label "$data" painted only '
                '${painted.toStringAsFixed(1)}px, so it has been squeezed past '
                'the point of naming its own state. #1237 accepted an ellipsis '
                'here; it did not accept an empty capsule.');
      });
    }
  });
}
