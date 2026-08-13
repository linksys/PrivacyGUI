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

/// WiFi Performance readability (#1229).
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
/// which #1229 does not modify: those coordinates were already clean. It is
/// asserted here anyway, because "already clean" is not the same as "checked",
/// and because nothing else in the suite would notice if a later fix to this file
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
///   | mutation                                     | this file | the gate |
///   |----------------------------------------------|-----------|----------|
///   | drop `SignalTier.fair` from the legend list   | 5 fail    | green    |
///   | `Row` + `Flexible` entries, no `Wrap`         | 3 fail    | green    |
///   | drop the per-radio SNR readout               | 2 fail    | green    |
///   | `Wrap` back to a bare `Row` (pre-#1229)      | green     | 33 fail  |
///
/// The last row is the instructive one, and it is why the second differs from
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

  group('per-band metrics stay distinguishable (#1229 AC4)', () {
    // AC4 covers the Channels tab, which #1229 does not touch — those
    // coordinates were already clean. Asserted anyway: the AC is gate-invisible,
    // and this pins what "distinguishable" was verified to mean at 261px, namely
    // that each radio keeps its own band / channel line and its own client-count
    // / SNR line, with nothing clipped.
    for (final tag in ['en', 'ru']) {
      testWidgets('each radio keeps its own channel and SNR line in $tag',
          (tester) async {
        final locale = _localeFor(tag);
        await pumpNarrowest(tester, tabIndex: 2, locale: locale);

        final texts = renderedTexts(tester);
        final bands =
            texts.where((t) => _bandRe.hasMatch(t.data!.trim())).toList();
        expect(bands.length, greaterThanOrEqualTo(2),
            reason:
                'the comparison between bands is this tab\'s purpose, so at '
                'least two radios must be named. Rendered: '
                '${texts.map((t) => t.data).toList()}');

        // `Ch <n> · <bandwidth>` and the SNR readout are unique to the per-radio
        // rows (the header badge and the donut centre also mention clients, so a
        // client-count match alone would not be).
        final channels = texts.where((t) => t.data!.startsWith('Ch ')).toList();
        final snrs = texts.where((t) => t.data!.contains(_snrMarker)).toList();
        expect(channels, hasLength(bands.length),
            reason:
                'every radio needs its channel and bandwidth — that is what '
                'makes the bands comparable rather than merely listed.');
        expect(snrs, hasLength(bands.length),
            reason: 'every radio needs its own SNR readout.');

        for (final t in [...bands, ...channels, ...snrs]) {
          expect(isClipped(tester, t), isFalse,
              reason: '"${t.data}" is clipped at the narrowest width, so this '
                  'band\'s reading cannot be compared with the others\'.');
        }

        // Band label and channel share a line; each radio's rows are disjoint
        // from the next radio's, which is what keeps two readings from reading as
        // one.
        final bandTops = bands.map((t) => rectOf(tester, t).top).toList()
          ..sort();
        for (var i = 1; i < bandTops.length; i++) {
          expect(bandTops[i] - bandTops[i - 1], greaterThan(16.0),
              reason: 'two band rows are within 16px of each other, so their '
                  'readouts visually merge.');
        }
        for (final band in bands) {
          final bandRect = rectOf(tester, band);
          final onSameLine = channels.where((c) =>
              (rectOf(tester, c).center.dy - bandRect.center.dy).abs() < 2.0);
          expect(onSameLine, isNotEmpty,
              reason: 'band "${band.data}" has no channel readout on its own '
                  'line, so the channel cannot be attributed to it.');
        }
      });
    }
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
