@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';

/// Gauge-centre readability (#1234).
///
/// ## Why this file exists alongside the #1183 gate
///
/// `system_status`'s Monitor tab drew two `AppGauge(size: 100)` in a
/// `spaceEvenly` row inside a box measured at 161.4px, so it overflowed by a
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
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is one square em, so
    // what fits — and therefore what ellipsizes — is fiction.
    await loadAppFonts();
  });

  const cardId = 'system_status';
  final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);
  final constraints = spec.getConstraints(DisplayMode.normal);

  /// Pumps the Monitor tab at the narrowest width the grid ever gives the card's
  /// min span — the worst case the gate measures, and the only width where the
  /// diameter bound actually bites. One pump, as the gate does.
  Future<void> pumpAt(
    WidgetTester tester, {
    required int columns,
    required String label,
    required Locale locale,
  }) async {
    final narrowest = narrowestRealizationOf(columns, minScreen: 0)!;
    await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: CardWidthCase(
        screenWidth: narrowest.screenWidth,
        cardWidth: narrowest.cardWidth,
        columnSpan: columns,
        label: label,
      ),
      cardHeightRows: constraints.minHeightRows,
      tabIndex: 0,
      locale: locale,
    );
  }

  Future<void> pumpNarrowest(WidgetTester tester, Locale locale) =>
      pumpAt(tester,
          columns: constraints.minColumns, label: 'min', locale: locale);

  Future<void> pumpPreferred(WidgetTester tester, Locale locale) =>
      pumpAt(tester,
          columns: constraints.preferredColumns,
          label: 'preferred',
          locale: locale);

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

  RenderParagraph paragraphOf(WidgetTester tester, Text text) =>
      tester.renderObject<RenderParagraph>(find.byWidget(text));

  /// Whether [text] had to drop content to fit. `didExceedMaxLines` is the
  /// renderer's own verdict, so this does not re-derive metrics the layout
  /// already computed.
  bool isClipped(WidgetTester tester, Text text) =>
      paragraphOf(tester, text).didExceedMaxLines;

  /// How many lines [text] actually painted, counted off the renderer's own
  /// glyph boxes. This is the only measurement that distinguishes "ellipsized
  /// onto one line" — by design, for a label longer than the circle — from
  /// "wrapped mid-word", since both leave the widget's `data` intact and both
  /// fit inside the box the gate measures.
  int lineCount(WidgetTester tester, Text text) {
    final boxes = paragraphOf(tester, text).getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.data!.length),
    );
    expect(boxes, isNotEmpty,
        reason: '"${text.data}" painted no glyphs at all');
    return boxes.map((b) => b.top.round()).toSet().length;
  }

  group('the reading survives the shrunken circle (#1234 AC4)', () {
    // The gauges are the tab's headline: the label names a series, the reading
    // *is* the datum. So the two are held to different standards below — the
    // reading may never give, the label may ellipsize but may never wrap.
    for (final tag in ['en', 'de', 'ru', 'th']) {
      testWidgets('both gauges show their full percentage in $tag',
          (tester) async {
        await pumpNarrowest(tester, _localeFor(tag));

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
          expect(isClipped(tester, reading), isFalse,
              reason: 'gauge $i\'s reading "${reading.data}" is clipped at the '
                  'narrowest width. The circle has been bounded below the size '
                  'of the number it exists to show.');
          expect(lineCount(tester, reading), 1,
              reason: 'gauge $i\'s reading "${reading.data}" wrapped onto a '
                  'second line inside the arc.');
        }
      });

      testWidgets('neither gauge label wraps inside the arc in $tag',
          (tester) async {
        await pumpNarrowest(tester, _localeFor(tag));
        final l = await AppLocalizations.delegate.load(_localeFor(tag));

        final labels = [
          for (var i = 0; i < 2; i++) centreTexts(tester, i).last,
        ];
        expect(labels.map((t) => t.data), containsAll([l.cpu, l.memory]),
            reason: 'each gauge must name its own series; got '
                '${labels.map((t) => t.data).toList()}');

        for (final label in labels) {
          // One line, clipped or not. `de`'s `Arbeitsspeicher` is 88.1px of
          // `bodySmall` inside a 72.7px circle, so the ellipsis is *expected*
          // there and asserting `isClipped == false` would be a lie. What must
          // not happen is the soft wrap: a mid-word break inside a 72.7px arc
          // costs the label its readability and the centre its shape, and every
          // gate case stays green through it.
          expect(lineCount(tester, label), 1,
              reason: 'gauge label "${label.data}" painted '
                  '${lineCount(tester, label)} lines inside the arc. The label '
                  'is a series name: it ellipsizes to one line, and the full '
                  'string stays available in the legend row below.');

          // The centre is a `Stack` child with loose `size × size` constraints,
          // and `Stack` clips by default — so a centre that outgrew its circle
          // would vanish at the edges rather than report anything.
          final gauge = tester.getRect(find.ancestor(
              of: find.byWidget(label), matching: find.byType(AppGauge)));
          final rect = tester.getRect(find.byWidget(label));
          expect(rect.left, greaterThanOrEqualTo(gauge.left - 1.0));
          expect(rect.right, lessThanOrEqualTo(gauge.right + 1.0),
              reason:
                  'gauge label "${label.data}" extends past its own circle, '
                  'so the Stack is clipping it.');
        }
      });
    }

    testWidgets('the two gauges stay side by side and the same size',
        (tester) async {
      // The rejected alternative, pinned: stacking the circles vertically also
      // clears the overflow, and would leave every assertion above true. But
      // the tab's value is the CPU-against-memory comparison, and two circles
      // of different diameters or on different rows no longer make it.
      await pumpNarrowest(tester, _localeFor('de'));

      final first = tester.getRect(find.byType(AppGauge).at(0));
      final second = tester.getRect(find.byType(AppGauge).at(1));

      expect((first.center.dy - second.center.dy).abs(), lessThan(2.0),
          reason: 'the gauges are on different rows (${first.center.dy} vs '
              '${second.center.dy}), so the comparison they exist for now needs '
              'a vertical scan. #1234 shrinks the circles instead of stacking '
              'them precisely to avoid this.');
      expect(second.left, greaterThanOrEqualTo(first.right - 1.0),
          reason: 'the gauges overlap horizontally.');
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
      await pumpPreferred(tester, _localeFor('de'));
      final l = await AppLocalizations.delegate.load(_localeFor('de'));

      for (var i = 0; i < 2; i++) {
        final label = centreTexts(tester, i).last;
        expect(isClipped(tester, label), isFalse,
            reason: 'gauge label "${label.data}" is ellipsized at the '
                'preferred width, where the circle is at its natural size. '
                'The centre is now degrading in the layout the grid hands the '
                'card by default, not just at the narrowest one.');
      }
      expect([for (var i = 0; i < 2; i++) centreTexts(tester, i).last.data],
          containsAll([l.cpu, l.memory]));
    });
  });
}

Locale _localeFor(String tag) =>
    AppLocalizations.supportedLocales.firstWhere((l) {
      final t = l.countryCode == null || l.countryCode!.isEmpty
          ? l.languageCode
          : '${l.languageCode}_${l.countryCode}';
      return t == tag;
    });
