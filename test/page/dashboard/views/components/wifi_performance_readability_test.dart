@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';

/// WiFi Performance readability (#1229, extended by #1266).
///
/// ## Why this file exists alongside the #1183 gate
///
/// #1229 clears 45 coordinates by letting two legend rows *give* — `Row` becomes
/// `Wrap`, labels become `Flexible` with a one-line ellipsis. Both halves of that
/// have a failure mode the gate is blind to, because the gate cannot tell a row
/// that fits from a row that fits *because it destroyed its content*:
///
///   - the `Wrap` could survive by dropping entries, leaving coloured dots on the
///     bar/chart with nothing naming them;
///   - the ellipsis could become load-bearing and clip every tier name to a stub,
///     which is a green gate and an unreadable legend.
///
/// The card's fourth acceptance criterion is the other blind spot — "per-band
/// metrics stay distinguishable at the narrowest clean width — the card's value
/// is the comparison between bands". That one is about the **Channels** tab,
/// which #1229 did not modify: those coordinates were already clean. It was
/// asserted here anyway, because "already clean" is not the same as "checked" —
/// and that turned out to be the point. #1266 found the tab's band/channel row
/// was only clean because `'Ch '` was a hardcoded English abbreviation, gave it
/// the same `Wrap` treatment, and rewrote this group's invariant accordingly
/// (see the group's own comment). So the tab is now guarded here for the ordinary
/// reason as well: nothing else in the suite would notice if a later fix
/// collapsed the per-band rows.
///
/// Tagged `dashboard-card` so it gates PRs: `run_tests.sh` excludes
/// `golden||loc||ui`, so a `ui`-tagged test here would block nothing.
///
/// ## Mutation ledger
///
/// Each group was verified to fail under a mutation of the code it guards; a
/// readability test that passes on the broken layout is worse than none. Each
/// mutation was also run against the gate, because a mutation the gate already
/// catches proves nothing about *this* file.
///
///   | mutation                                          | this file | the gate |
///   |---------------------------------------------------|-----------|----------|
///   | drop `SignalTier.fair` from the legend list        | 5 fail    | green    |
///   | `Row` + `Flexible` entries, no `Wrap`             | 3 fail    | green    |
///   | drop the per-radio SNR readout                    | 2 fail    | green    |
///   | `Wrap` back to a bare `Row` (pre-#1229, tab 0)    | green     | 33 fail  |
///   | Channels `Column`: `stretch` → `start` (#1266)    | 1 fail    | green    |
///   | `loc(context).channel` → `'Ch '` (#1266)         | 4 fail    | green    |
///   | Channels `Wrap` → `Row` + `Spacer`, localized     | 1 fail    | 3 fail   |
///
/// The fourth row is the instructive one, and it is why the second differs from
/// the obvious guess. Reverting to a bare `Row` does **not** clip anything: a
/// `Row` hands its non-flex children unbounded width, so each entry's inner
/// `Flexible` never binds, every label paints at full intrinsic width, and the
/// *outer* `Row` overflows — which is precisely the pre-#1229 failure the gate
/// already measures (33 coordinates, tab 0). The gate owns that regression.
///
/// The regression the gate cannot see is the one that *succeeds* at fitting:
/// wrap each entry in `Flexible` and keep the single `Row`. Now the entries are
/// flex children, each takes a quarter of 261px, the inner `Flexible` binds, and
/// every tier name ellipsizes to a stub — in `en` too, not just the long
/// translations. All 157 wifi_performance gate cases stay green. That is the
/// shape a well-meaning "just make it fit" edit lands on, and only this file
/// fails it.
///
/// The three #1266 rows say the same thing about the Channels tab, and the last
/// two are a pair worth reading together. Localizing `'Ch '` on its own costs 3
/// gate coordinates (`th` @261, `tr` @261 and @288) — the ratchet forbids it.
/// Hardening on its own costs nothing and gains nothing the gate can see. Only
/// the two together are both green and honest, which is why they shipped as one
/// change and why the middle row matters: with the abbreviation back, this file
/// fails in every locale while the gate notices nothing at all.
///
/// The `stretch` → `start` row is the subtlest of the set. `spaceBetween` is a
/// no-op under loose width constraints, so dropping the `stretch` slides the
/// channel readout left to sit one `spacing` gap after the band label, in every
/// locale, while overflowing nothing — a pure visual regression that all 157
/// gate cases pass.
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is one square em, so what
    // fits — and therefore what ellipsizes — is fiction.
    await loadAppFonts();
  });

  const cardId = 'wifi_performance';
  final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);
  final constraints = spec.getConstraints(DisplayMode.normal);

  /// Pumps the card at the narrowest width the grid ever gives its min span —
  /// the worst case the gate measures, and where degradation is most aggressive.
  /// One pump, as the gate does.
  Future<void> pumpNarrowest(
    WidgetTester tester, {
    required int tabIndex,
    required Locale locale,
  }) async {
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
      tabIndex: tabIndex,
      locale: locale,
    );
  }

  /// Pumps the card at the narrowest realization of its *preferred* span — the
  /// width the grid gives it by default, and the only place where "this fits on
  /// one line" is a claim about the design rather than about degradation.
  Future<void> pumpPreferred(
    WidgetTester tester, {
    required int tabIndex,
    required Locale locale,
  }) async {
    final narrowest =
        narrowestRealizationOf(constraints.preferredColumns, minScreen: 0)!;
    await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: CardWidthCase(
        screenWidth: narrowest.screenWidth,
        cardWidth: narrowest.cardWidth,
        columnSpan: constraints.preferredColumns,
        label: 'preferred',
      ),
      cardHeightRows: constraints.minHeightRows,
      tabIndex: tabIndex,
      locale: locale,
    );
  }

  /// Every `Text` in the tree that actually painted a non-empty string.
  List<Text> renderedTexts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.data != null && t.data!.isNotEmpty)
      .toList();

  /// The one rendered `Text` holding exactly [label], or a failure naming what
  /// was rendered instead — a *missing* label is the interesting failure here, so
  /// the message has to be diagnosable.
  ///
  /// Exact match rather than `contains`: a clipped `Text` still carries its full
  /// string (the ellipsis is a paint-time effect), so equality stays correct
  /// under degradation while `contains` would let one tier name match another's.
  Text exactly(WidgetTester tester, String label) {
    final matches =
        renderedTexts(tester).where((t) => t.data == label).toList();
    expect(matches, hasLength(1),
        reason: 'expected exactly one rendered Text "$label". Rendered: '
            '${renderedTexts(tester).map((t) => t.data).toList()}');
    return matches.single;
  }

  /// Whether [text] had to drop content to fit — the question the gate cannot
  /// answer. `didExceedMaxLines` is the renderer's own verdict, so this does not
  /// re-derive text metrics the layout already computed.
  bool isClipped(WidgetTester tester, Text text) => tester
      .renderObject<RenderParagraph>(find.byWidget(text))
      .didExceedMaxLines;

  Rect rectOf(WidgetTester tester, Text text) =>
      tester.getRect(find.byWidget(text));

  group('legend entries survive degradation (#1229)', () {
    // A legend is a colour→series mapping, and the `Wrap` may reorder it or push
    // entries onto later runs. What it may not do is lose one: a dropped entry
    // leaves a coloured bar with nothing naming it.
    //
    // Asserted on the labels rather than on the dots because both come from the
    // same `for` over `SignalTier`, so a dropped entry drops both — the label is
    // a faithful proxy and the dot is file-private (same choice as #1233).
    testWidgets('the Signal tab names all four signal tiers', (tester) async {
      final locale = _localeFor('ru');
      await pumpNarrowest(tester, tabIndex: 0, locale: locale);
      final l = await AppLocalizations.delegate.load(locale);

      for (final label in [l.excellent, l.good, l.fair, l.weak]) {
        exactly(tester, label);
      }
    });

    testWidgets('the Speed tab names both series', (tester) async {
      final locale = _localeFor('ru');
      await pumpNarrowest(tester, tabIndex: 1, locale: locale);
      final l = await AppLocalizations.delegate.load(locale);

      exactly(tester, l.downlink);
      exactly(tester, l.uplink);
    });
  });

  group('legend labels are not clipped at the narrowest width (#1229)', () {
    // The `Flexible` + one-line ellipsis is a safety net, not the mechanism: at
    // 261px the `Wrap` absorbs all four tier names by running onto a second line,
    // and measurement confirms none of them clips — `ru`'s longest,
    // 'Удовлетворительный', renders at 123px inside a ~243px run.
    //
    // So this is a canary, and deliberately so. If a translation grows past a
    // whole run, or spacing/entry count changes, the ellipsis starts firing and
    // the legend degrades from "wrapped" to "truncated" with the gate still
    // green. That is exactly the transition worth failing on.
    for (final tag in ['en', 'ru', 'th']) {
      testWidgets('Signal tier names render in full in $tag', (tester) async {
        final locale = _localeFor(tag);
        await pumpNarrowest(tester, tabIndex: 0, locale: locale);
        final l = await AppLocalizations.delegate.load(locale);

        for (final label in [l.excellent, l.good, l.fair, l.weak]) {
          final t = exactly(tester, label);
          expect(isClipped(tester, t), isFalse,
              reason:
                  'tier name "$label" is ellipsized at the narrowest width. '
                  'The Wrap is supposed to spend a second run before any label '
                  'gives; a clipped tier name means the legend has stopped '
                  'keying the bar colours.');
        }
      });

      testWidgets('Speed series names render in full in $tag', (tester) async {
        final locale = _localeFor(tag);
        await pumpNarrowest(tester, tabIndex: 1, locale: locale);
        final l = await AppLocalizations.delegate.load(locale);

        for (final label in [l.downlink, l.uplink]) {
          final t = exactly(tester, label);
          expect(isClipped(tester, t), isFalse,
              reason: 'series name "$label" is ellipsized at the narrowest '
                  'width, so the chart\'s two colours are no longer named.');
        }
      });
    }

    testWidgets('each tier label stays beside its own dot', (tester) async {
      // Dot and label live in one `Row(mainAxisSize: min)` precisely so the
      // `Wrap` moves them together. If an entry ever splits across runs, the
      // colour and the word it explains end up on different lines and the
      // mapping is gone even though every label is present.
      final locale = _localeFor('ru');
      await pumpNarrowest(tester, tabIndex: 0, locale: locale);
      final l = await AppLocalizations.delegate.load(locale);

      // The dots are 8px circles; find them by their decoration rather than by
      // the private widget type.
      final dots = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).shape == BoxShape.circle)
          .toList();
      expect(dots, hasLength(4),
          reason: 'the Signal legend must paint one colour dot per tier');

      for (final label in [l.excellent, l.good, l.fair, l.weak]) {
        final labelRect = rectOf(tester, exactly(tester, label));
        final sameRun = dots
            .map((d) => tester.getRect(find.byWidget(d)))
            .where((r) => (r.center.dy - labelRect.center.dy).abs() < 2.0)
            .where((r) => r.right <= labelRect.left + 1.0);
        expect(sameRun, isNotEmpty,
            reason: 'tier "$label" has no colour dot to its left on the same '
                'line, so its entry was split across runs.');
      }
    });
  });

  group('per-band metrics stay distinguishable (#1229 AC4, #1266)', () {
    // AC4 covers the Channels tab. #1229 left it alone — those coordinates were
    // already clean — and asserted it anyway, because the AC is gate-invisible.
    //
    // #1266 then overturned the design decision this group originally pinned.
    // #1229 recorded "band label and channel share a line" as the meaning of
    // distinguishable, which was true of the `Row` + `Spacer` it measured. But
    // that row only fit because `'Ch '` was a hardcoded English abbreviation:
    // with the real `channel` key it overflowed in `th` and `tr` on the shipped
    // fixture, so #1266 localized it and gave the row the #1226 `Wrap`. The
    // channel readout may now take a second run.
    //
    // So the invariant weakens from *same line* to *attributable*: each radio's
    // band and channel must be adjacent and belong to the same block, separated
    // from the next radio's. That is what actually carries AC4 — "the card's
    // value is the comparison between bands" survives a two-line block, and does
    // not survive a channel readout that cannot be assigned to a band.
    for (final tag in ['en', 'ru', 'tr']) {
      testWidgets('each radio keeps its own channel and SNR readout in $tag',
          (tester) async {
        final locale = _localeFor(tag);
        await pumpNarrowest(tester, tabIndex: 2, locale: locale);
        final l = await AppLocalizations.delegate.load(locale);

        final texts = renderedTexts(tester);
        final bands =
            texts.where((t) => _bandRe.hasMatch(t.data!.trim())).toList();
        expect(bands.length, greaterThanOrEqualTo(2),
            reason:
                'the comparison between bands is this tab\'s purpose, so at '
                'least two radios must be named. Rendered: '
                '${texts.map((t) => t.data).toList()}');

        // `<channel> <n> · <bandwidth>` and the SNR readout are unique to the
        // per-radio rows (the header badge and the donut centre also mention
        // clients, so a client-count match alone would not be).
        //
        // Matched on the localized `channel` string, not on `'Ch '`: that literal
        // is exactly what #1266 removed, and a test that still recognised it
        // would silently match nothing and pass on `hasLength(0)` if the band
        // regex also stopped matching.
        final channels =
            texts.where((t) => t.data!.startsWith('${l.channel} ')).toList();
        final snrs = texts.where((t) => t.data!.contains(_snrMarker)).toList();
        expect(channels, hasLength(bands.length),
            reason:
                'every radio needs its channel and bandwidth — that is what '
                'makes the bands comparable rather than merely listed. Looked '
                'for a "${l.channel} " prefix in: '
                '${texts.map((t) => t.data).toList()}');
        expect(snrs, hasLength(bands.length),
            reason: 'every radio needs its own SNR readout.');

        for (final t in [...bands, ...channels, ...snrs]) {
          expect(isClipped(tester, t), isFalse,
              reason: '"${t.data}" is clipped at the narrowest width, so this '
                  'band\'s reading cannot be compared with the others\'.');
        }

        // Each radio's block is disjoint from the next radio's, which is what
        // keeps two readings from reading as one.
        final bandTops = bands.map((t) => rectOf(tester, t).top).toList()
          ..sort();
        for (var i = 1; i < bandTops.length; i++) {
          expect(bandTops[i] - bandTops[i - 1], greaterThan(16.0),
              reason: 'two band rows are within 16px of each other, so their '
                  'readouts visually merge.');
        }

        // Attribution, post-#1266: the channel readout may sit on the band's
        // line or on the run directly below it, but it must be nearer to its own
        // band than to any other — a readout that drifts closer to the next
        // radio's block is worse than a missing one, because it reads as that
        // radio's channel.
        for (final band in bands) {
          final bandRect = rectOf(tester, band);
          final nearest = channels.reduce((a, b) =>
              (rectOf(tester, a).center.dy - bandRect.center.dy).abs() <
                      (rectOf(tester, b).center.dy - bandRect.center.dy).abs()
                  ? a
                  : b);
          final nearestRect = rectOf(tester, nearest);
          expect(nearestRect.top, greaterThanOrEqualTo(bandRect.top - 1.0),
              reason: 'the channel readout nearest band "${band.data}" sits '
                  'above it, so it belongs to the block before this one.');

          final otherBandTops = bands
              .where((b) => b != band)
              .map((b) => rectOf(tester, b).top)
              .where((top) => top > bandRect.top);
          for (final nextTop in otherBandTops) {
            expect(nearestRect.top, lessThan(nextTop),
                reason: 'the channel readout for band "${band.data}" is below '
                    'the next band label, so it reads as that band\'s channel.');
          }
        }
      });
    }

    testWidgets('the channel readout is right-aligned while it fits (#1266)',
        (tester) async {
      // `Wrap(alignment: spaceBetween)` is only a drop-in for the old `Spacer`
      // while the row is width-bounded: a `Wrap` under loose constraints
      // shrink-wraps to its widest run, leaving `spaceBetween` no free space to
      // distribute, and the channel string silently slides left to sit one
      // `spacing` gap after the band label. The `CrossAxisAlignment.stretch` on
      // the enclosing Column is what prevents that, and nothing else would
      // notice if it were reverted to `start` — the gate cannot see it, because
      // a shrink-wrapped row overflows nothing.
      //
      // `en` at the preferred width, where every radio's block is comfortably
      // one run: both children share a run, so the right edges must line up.
      final locale = _localeFor('en');
      await pumpPreferred(tester, tabIndex: 2, locale: locale);
      final l = await AppLocalizations.delegate.load(locale);

      final texts = renderedTexts(tester);
      final bands = texts.where((t) => _bandRe.hasMatch(t.data!.trim()));
      final channels =
          texts.where((t) => t.data!.startsWith('${l.channel} ')).toList();
      expect(channels, isNotEmpty);

      for (final band in bands) {
        final bandRect = rectOf(tester, band);
        final sameRun = channels.where((c) =>
            (rectOf(tester, c).center.dy - bandRect.center.dy).abs() < 2);
        expect(sameRun, isNotEmpty,
            reason: 'at the preferred width every block should still be one '
                'run, so band "${band.data}" should share its line with its '
                'channel readout.');

        // The measurement that actually detects a lost `stretch`, and the reason
        // it is not "the channel sits well right of the band": the channel string
        // is ~100px wide, so it clears the band by a wide margin even when the
        // row has shrink-wrapped. The comparison has to be against the width the
        // row was *offered*.
        //
        // The block's `Column` is that reference under either alignment: the
        // second row holds an `Expanded` loader, so it takes the full offered
        // width regardless, and the `Column` shrink-wraps to it. So the `Wrap`
        // matching the `Column`'s width is exactly the claim "the Wrap was handed
        // a tight width", and it is what `spaceBetween` needs to do anything.
        final wrapRect = tester.getRect(find.ancestor(
            of: find.byWidget(band), matching: find.byType(Wrap)));
        // Ancestor finders walk outward from the descendant, so `.first` is the
        // innermost — the per-radio block's own Column, not the tab's.
        final columnRect = tester.getRect(find
            .ancestor(of: find.byWidget(band), matching: find.byType(Column))
            .first);
        expect(wrapRect.width, greaterThanOrEqualTo(columnRect.width - 1.0),
            reason: 'the band/channel row for "${band.data}" is narrower than '
                'its own block (${wrapRect.width} vs ${columnRect.width}), so '
                'the Wrap shrink-wrapped and `spaceBetween` had no free space '
                'to distribute. The enclosing Column has stopped stretching.');
        expect(rectOf(tester, sameRun.first).right,
            greaterThanOrEqualTo(wrapRect.right - 1.0),
            reason: 'the channel readout does not reach the right edge of its '
                'row, so it is no longer where the old `Spacer` put it.');
      }
    });
  });
}

/// Band labels are `WifiRadioUIModel.band` — `2.4GHz`, `5GHz`, `6GHz`.
final _bandRe = RegExp(r'^\d+(\.\d+)?GHz$');

/// The SNR readout's literal prefix. `snrValue` is `SNR: {value} dB`, and the
/// marker is taken from the string's own shape rather than hardcoded per locale.
const _snrMarker = 'SNR';

Locale _localeFor(String tag) =>
    AppLocalizations.supportedLocales.firstWhere((l) {
      final t = l.countryCode == null || l.countryCode!.isEmpty
          ? l.languageCode
          : '${l.languageCode}_${l.countryCode}';
      return t == tag;
    });
