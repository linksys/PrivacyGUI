@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
// Two names are wanted here: `AppCard`, the card's own root, used to scope
// finders to the card rather than the pump harness around it; and
// `AppChartLegendEntry`, the shared legend entry #1245 replaced this card's
// private one with.
import 'package:ui_kit_library/ui_kit.dart' show AppCard, AppChartLegendEntry;

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/card_data_profiles.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/overflow_probe.dart';

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
///   | `CardTab.scrollable: false` on Channels (#1267)    | 2 fail    | green    |
///   | drop the band's icon + client count (#1267)        | green     | green    |
///
/// The gate column is this card's own 211 cases (157 default-profile + the 54
/// tri-band ones #1267 added); "green" means all 211 passed.
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
/// translations. All 211 wifi_performance gate cases stay green. That is the
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
/// locale, while overflowing nothing — a pure visual regression that all 211
/// gate cases pass.
///
/// The two #1267 rows are a matched pair about what a *green* gate means here.
///
/// `scrollable: false` fails two tests in this file and nothing in the gate — and
/// the gate's silence is by construction, not by luck: removing the donut left
/// every profile the gate sweeps short enough to fit, so no gate case is tall
/// enough to need the scroll net. The load that exercises it (`sixRadioProfile`)
/// deliberately lives here instead, because coordinates recorded against a router
/// nobody sells would be allowlist entries no ticket could ever clear.
///
/// Dropping the band's icon and client count is green *here* — deliberately. That
/// count is the parity claim, and `wifi_snr_render_parity_test.dart` fails on it
/// (1 test), including the semantics label that keeps a bare numeral accessible.
/// The row is recorded so the next reader does not assume this file guards it.
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
  ///
  /// ## Most call sites drop the returned list, deliberately
  ///
  /// The two that keep it are the ones whose *own* claim is about overflow — the
  /// `sixRadioProfile` load, whose coordinates deliberately live here rather than
  /// in the gate's allowlist (see the header). Every other call site discards it,
  /// and that is not the sink going quiet by accident (#1318): this card declares
  /// no `normalAbove`, so its narrowest realization *is* the normal form on the
  /// grid, and the gate's main sweep already measures overflow at exactly this
  /// coordinate across all three tabs and all 26 locales. Re-asserting it per
  /// readability case would duplicate 26-locale coverage with a 3-locale copy and
  /// give two files a say over one ratchet entry.
  Future<List<OverflowIncident>> pumpNarrowest(
    WidgetTester tester, {
    required int tabIndex,
    required Locale locale,
    List<Override> extraOverrides = const [],
  }) {
    final narrowest =
        narrowestRealizationOf(constraints.minColumns, minScreen: 0)!;
    return probeCardOverflow(
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
      extraOverrides: extraOverrides,
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

    testWidgets('each tier label stays beside its own mark', (tester) async {
      // Mark and label live in one `Row(mainAxisSize: min)` precisely so the
      // `Wrap` moves them together. If an entry ever splits across runs, the
      // colour and the word it explains end up on different lines and the
      // mapping is gone even though every label is present.
      //
      // Since #1245 the entry is ui_kit's `AppChartLegendEntry`, which makes the
      // split structurally impossible — but the assertion stays, because what it
      // really guards is that this row still *uses* an indivisible entry. The
      // probe moved with the implementation: the mark used to be an 8px circular
      // `Container` and is now the entry's `CustomPaint`, so the tier swatch is
      // located through the component rather than through a decoration this file
      // would have to keep guessing.
      final locale = _localeFor('ru');
      await pumpNarrowest(tester, tabIndex: 0, locale: locale);
      final l = await AppLocalizations.delegate.load(locale);

      final entries = tester
          .widgetList<AppChartLegendEntry>(find.byType(AppChartLegendEntry))
          .toList();
      expect(entries, hasLength(4),
          reason: 'the Signal legend must paint one colour mark per tier');

      final marks = entries
          .map((e) => tester.getRect(find
              .descendant(
                of: find.byWidget(e),
                matching: find.byType(CustomPaint),
              )
              .first))
          .toList();

      for (final label in [l.excellent, l.good, l.fair, l.weak]) {
        final labelRect = rectOf(tester, exactly(tester, label));
        final sameRun = marks
            .where((r) => (r.center.dy - labelRect.center.dy).abs() < 2.0)
            .where((r) => r.right <= labelRect.left + 1.0);
        expect(sameRun, isNotEmpty,
            reason: 'tier "$label" has no colour mark to its left on the same '
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
        // per-radio rows (the header badge also reports clients — a total — so a
        // client-count match alone would not be).
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

      var sharedRuns = 0;
      for (final band in bands) {
        final bandRect = rectOf(tester, band);
        // Ancestor finders walk outward from the descendant, so `.first` is the
        // innermost — the per-radio block's own Column, not the tab's.
        final block = find
            .ancestor(of: find.byWidget(band), matching: find.byType(Column))
            .first;
        final wrapRect = tester.getRect(find.ancestor(
            of: find.byWidget(band), matching: find.byType(Wrap)));

        // The measurement that actually detects a lost `stretch`, and the reason
        // it is not "the channel sits well right of the band": the channel string
        // is ~100px wide, so it clears the band by a wide margin even when the
        // row has shrink-wrapped. The comparison has to be against the width the
        // row was *offered*.
        //
        // The block's **other** row is that reference. Under `stretch` the Column
        // hands both rows a tight width, so the `Wrap` and the SNR text measure
        // the same; under `start` each shrink-wraps to its own content, and the
        // SNR readout is ~70px against the row's ~230px. Comparing the two rows
        // is what makes this local — an earlier revision compared the `Wrap` to
        // its `Column`, which stopped discriminating the moment #1267 removed the
        // second row's `Expanded` loader: without a full-width child, `start`
        // shrinks the Column to the Wrap's own width and the two agree either
        // way. Mutation-checked below, not assumed.
        final snrRect = tester.getRect(find.descendant(
            of: block,
            matching: find.byWidgetPredicate(
                (w) => w is Text && (w.data ?? '').contains(_snrMarker))));
        expect(wrapRect.width, closeTo(snrRect.width, 1.0),
            reason: 'the band/channel row for "${band.data}" and its SNR row '
                'were laid out at different widths (${wrapRect.width} vs '
                '${snrRect.width}), so the block is no longer handing its rows '
                'a tight width: the Wrap shrink-wrapped and `spaceBetween` has '
                'no free space to distribute. The enclosing Column has stopped '
                'stretching.');

        // Whether the channel readout shares the band's line is a function of
        // how long the translation is — since #1267 the band shares run 1 with
        // its client count, which costs ~29px, so at 288px `en` the 5GHz block
        // (`Channel 36 (Auto) · 160MHz`) takes a second run where it used to
        // fit. That is not a defect: the run below is still inside the same
        // block, still attributable, and the tab has the height to spend. What
        // must not happen is the `spaceBetween` silently becoming a no-op, so
        // the right-edge claim is asserted on every band that *does* share a
        // run, and at least one must.
        final sameRun = channels.where((c) =>
            (rectOf(tester, c).center.dy - bandRect.center.dy).abs() < 2);
        if (sameRun.isEmpty) continue;
        sharedRuns++;
        expect(rectOf(tester, sameRun.first).right,
            greaterThanOrEqualTo(wrapRect.right - 1.0),
            reason: 'the channel readout does not reach the right edge of its '
                'row, so it is no longer where the old `Spacer` put it.');
      }

      expect(sharedRuns, greaterThan(0),
          reason:
              'no block put its band and channel readout on one line at the '
              'preferred width, so nothing here exercised `spaceBetween` at '
              'all. Either the rows grew or the width shrank; re-measure before '
              'relaxing this.');
    });
  });

  group('the Channels tab absorbs a taller router (#1267)', () {
    // This group exists because #1267's fix makes the gate go quiet.
    //
    // On a tri-band router at the 261px card in `tr`, this tab overflowed by
    // `+9.0px` — and the screenshot was worse than the number: the donut, fixed
    // at 120px inside an `Expanded` that had ~40px to give, was `Center`ed, and a
    // `Center` spills its oversized child in *both* directions, so it painted
    // over the 6GHz block and hid that radio's SNR entirely. Only the part that
    // fell past the bottom edge was ever reported.
    //
    // The fix had two halves, and they are measured separately below because they
    // are not equally strong:
    //
    //  1. The donut is gone — its slices restated client counts printed two lines
    //     above them. That alone closes the incident, and closes it *better* than
    //     scrolling would have: the tri-band tab now fits, with nothing below the
    //     fold. `shortfall == 0` is that claim, and it is stronger than the
    //     gate's "no overflow" — a card whose content sits past its viewport
    //     overflows nothing at all.
    //  2. The tab scrolls, which is the net for content no fixture here predicts:
    //     a fourth radio, a locale nobody has translated yet. A net with no load
    //     on it is untested, so the second test hangs a six-radio router on it.
    //
    // Neither reading is available to the overflow gate: a scrolling region
    // reports no RenderFlex overflow however tall its content grows, so all 52
    // tri-band gate cases are green now and would stay green if the content grew
    // by 200px. `cardContentScrollShortfall` is what replaces that signal.
    testWidgets('tri-band fits with nothing below the fold', (tester) async {
      final locale = _localeFor('tr');
      final incidents = await pumpNarrowest(tester,
          tabIndex: 2,
          locale: locale,
          extraOverrides: triBandProfile.overrides());

      expect(incidents, isEmpty,
          reason: 'the coordinate #1267 was opened for is overflowing again: '
              '${incidents.join(', ')}');

      // The profile reached the render. Without this the whole test would pass
      // just as happily on the two-radio fixture, which fits trivially.
      for (final marker in triBandProfile.markers) {
        expect(find.textContaining(marker), findsWidgets,
            reason: 'the tri-band override did not reach the tree (looked for '
                '"$marker"), so this test is measuring the default fixture.');
      }

      final shortfall = cardContentScrollShortfall(tester);
      expect(shortfall, isNotNull,
          reason:
              'the Channels tab has no scrolling content region, so content '
              'taller than the card has nowhere to go — it is painted outside '
              'the box again. Check `CardTab.scrollable` at the card\'s '
              '`DashboardCardTemplate.tabbed(...)` call site.');
      expect(shortfall, 0.0,
          reason: 'a tri-band router now has to scroll this tab at the card\'s '
              'own minimum size, so its third radio is below the fold on '
              'arrival. Scrolling is the net for shapes no fixture predicts, not '
              'the reading experience for hardware we ship — if this is '
              'deliberate, the card\'s `minHeightRows` is the thing to change.');

      // Three radios, three complete readouts, none clipped — the 6GHz one being
      // the reading the donut used to cover.
      final texts = renderedTexts(tester);
      final bands =
          texts.where((t) => _bandRe.hasMatch(t.data!.trim())).toList();
      final snrs = texts.where((t) => t.data!.contains(_snrMarker)).toList();
      expect(bands.map((t) => t.data), containsAll(['2.4GHz', '5GHz', '6GHz']));
      expect(snrs, hasLength(3),
          reason: 'each of the three radios needs its own SNR readout. '
              'Rendered: ${texts.map((t) => t.data).toList()}');

      // Inside the viewport, not merely un-overflowed: the donut's spill is the
      // reason this is measured against the viewport rect rather than trusted.
      final viewport = cardContentViewport(tester);
      for (final t in [...bands, ...snrs]) {
        expect(isClipped(tester, t), isFalse,
            reason: '"${t.data}" is clipped at this width.');
        final rect = rectOf(tester, t);
        expect(rect.top, greaterThanOrEqualTo(viewport.top - 1.0),
            reason: '"${t.data}" starts above the content viewport.');
        expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 1.0),
            reason: '"${t.data}" ends ${rect.bottom - viewport.bottom}px below '
                'the viewport, so it is only readable after scrolling — which '
                'contradicts the shortfall of 0 measured above.');
      }
    });

    testWidgets('a six-radio router scrolls, and every radio stays reachable',
        (tester) async {
      // Six radios is one past today's hardware (see `testRadiosSixRadio`), and
      // that is the point: it is the smallest load that puts this tab clearly
      // past its viewport, so the net is measured rather than assumed.
      final incidents = await pumpNarrowest(tester,
          tabIndex: 2,
          locale: _localeFor('tr'),
          extraOverrides: sixRadioProfile.overrides());

      expect(incidents, isEmpty,
          reason: 'content taller than the card is overflowing instead of '
              'scrolling — the tab is no longer opted in, or something in it '
              'fills vertically again: ${incidents.join(', ')}');

      final shortfall = cardContentScrollShortfall(tester);
      expect(shortfall, isNotNull,
          reason: 'no scrolling content region, so this router\'s radios are '
              'painted outside the card.');
      expect(shortfall, greaterThan(0.0),
          reason: 'six radio blocks fit the card without scrolling, so this '
              'test no longer loads the mechanism it exists to test. Add radios '
              'rather than deleting the assertion.');

      // Silent scrolling is the "clean but unreadable" failure this epic keeps
      // meeting: nothing looks broken, so nobody knows to look. The thumb only
      // paints when there is extent to scroll — `ScrollbarPainter.paint` returns
      // early otherwise — so asserting the widget is present is asserting the
      // affordance appears exactly here and not on cards that fit.
      expect(
          find.descendant(
              of: find.byType(AppCard), matching: find.byType(Scrollbar)),
          findsOneWidget,
          reason:
              'the scrolling region has no scrollbar, so three of these six '
              'radios are hidden with nothing on screen saying so.');

      final texts = renderedTexts(tester);
      final snrs = texts.where((t) => t.data!.contains(_snrMarker)).toList();
      expect(snrs, hasLength(6),
          reason:
              'a radio was dropped from the render rather than scrolled to. '
              'Rendered: ${texts.map((t) => t.data).toList()}');

      // Reachable = inside the viewport plus what can be scrolled to. Content
      // past that is laid out and unreachable at every scroll offset, which looks
      // exactly like scrolling and is not.
      final viewport = cardContentViewport(tester);
      final reachableBottom = viewport.bottom + shortfall!;
      for (final t in snrs) {
        final rect = rectOf(tester, t);
        expect(isClipped(tester, t), isFalse,
            reason: '"${t.data}" is clipped, so scrolling did not give this '
                'content room — it only moved where it is cut off.');
        expect(rect.bottom, lessThanOrEqualTo(reachableBottom + 1.0),
            reason: '"${t.data}" ends ${rect.bottom - reachableBottom}px past '
                'the furthest the user can scroll, so it cannot be read at any '
                'offset. Scrollable extent: ${viewport.height + shortfall}px.');
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
