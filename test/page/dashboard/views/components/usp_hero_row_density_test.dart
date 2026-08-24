@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/test_data/scenes/cards_test_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';
import '../../../../util/dashboard/text_readability_probe.dart';
import '../../../../util/overflow_probe.dart';

/// The three hero cards' declared thresholds, and what each declares them for
/// (#1288).
///
/// `device_info`, `lan_info` and `time_settings` are the first specs in the
/// dashboard to set `normalAbove` (262 / 250 / 256). #1240 measured that all 18
/// cards *fit* at their narrowest realization and correctly left every threshold
/// absent; #1288 measured a different question — whether they can be *read*
/// there — and found these three cannot. Declaring a threshold is what turns that
/// measurement into behaviour, and this file is what holds the behaviour up.
///
/// ## Why the existing files cannot cover this
///
/// Three suites already touch this ground and each stops just short:
///
///   - the #1183 gate (`dashboard_card_overflow_test.dart`) asks only whether a
///     `RenderFlex` overflowed. All three cards were green at 191.4px *before*
///     this ticket — that greenness is the premise of #1288, not a gap in it.
///   - `dashboard_card_popup_overflow_test.dart` sweeps the popup form in all 26
///     locales, but **pins** `CardDensity.popup`. It proves the form does not
///     overflow; it cannot prove any card ever selects it.
///   - `usp_hero_row_readability_test.dart` now pins `CardDensity.normal`, for
///     the reason given in its own `pumpNarrowest`. It proves the normal form
///     still reads at 191.4px; it deliberately says nothing about which form
///     production shows there.
///
/// So the claim with no home is the one this ticket actually makes: **the
/// declared threshold changes what the user sees, at the widths it names.** No
/// density is pinned anywhere in this file — every case goes through
/// `CardDensityHost`'s own `LayoutBuilder`, which is the production path.
///
/// ## The three bands, and why the middle one needs its own widths
///
/// The grid realizes these cards at 191.4px (3-column floor), 260.5px, 288px and
/// upwards (§1.2). Set against thresholds of 250-262, the gate's own realizations
/// land in the popup band and the normal band and **skip the compact band
/// entirely**. So compact is pumped here at two widths the grid does not
/// currently produce for these cards: `kPopupBelow` itself (200px, the band's
/// lower edge) and `normalAbove - 2` (its upper edge). Both are widths the grid
/// *can* produce — a card dragged to a non-floor span on a narrower screen — and
/// a band no test enters is a band whose contents were never seen.
///
/// ## What "reads" means here
///
/// Per `hasSplitToken`: no line break may fall inside a token. Wrapping at a
/// space is not a failure — it is what #1236 and #1237 chose over an ellipsis.
/// `AppBadge` is exempt, because a capsule cannot take a second line and #1237
/// accepted its ellipsis explicitly; its own floor is asserted in
/// `usp_hero_row_readability_test.dart`.
///
/// ## Mutation ledger
///
/// Measured against this file's 24 passing tests (run alongside the readability
/// file's 15, hence a 39-test baseline), each mutation applied to all three cards
/// and reverted before the next:
///
///   | mutation                                                    | this file | the gate | readability |
///   |-------------------------------------------------------------|-----------|----------|-------------|
///   | `normalAbove` deleted from all three specs                  | 21 fail   | green    | green       |
///   | `popupValue` deleted from all three cards                   | 6 fail    | green    | green       |
///   | `HeroBlock` ignores `compact` and always builds the `Row`    | 12 fail   | green    | green       |
///   | the header `leading` made unconditional (no density guard)   | 3 fail    | green    | green       |
///
/// Every row is green in both existing suites, which is the argument for the
/// file. The first is the whole ticket reverted — three specs go back to claiming
/// they need no degraded form, production goes back to painting an unreadable
/// card at 191.4px — and it is the only mutation that reaches more than one
/// group: 3 declaration tests, then all 6 popup and all 12 compact cases, because
/// with no threshold every width selects normal. Nothing that existed before
/// #1288 notices: the gate because the card fits, the readability file because it
/// pins the form it wants.
///
/// The second is the narrowest of the four and the one worth reading twice: with
/// no `popupValue` the popup form falls back to the card's *title*, which
/// renders, fits, and is clean. A 191px card reading "LAN Information" and
/// nothing else is a form that works and says nothing — and it is
/// indistinguishable from a correct one everywhere else, including in this file's
/// other 18 tests. Only the 6 popup cases that read the value catch it.
///
/// The third and fourth are the two halves of one edit — the icon moving out of
/// the hero and into the header — and their counts are what separates them:
/// ignoring `compact` re-cramps the value column across the whole 12-case compact
/// band, while an unconditional header icon fails only the 3 desktop cases, where
/// it puts a second router glyph on a card that had nothing wrong with it. A
/// degradation that leaks upward is the failure mode a density mechanism has that
/// a fixed layout does not, and 3 is all the coverage it takes to see it.
void main() {
  setUpAll(() async {
    // Real fonts: under Ahem every glyph is one square em, so which token is the
    // widest — the entire criterion below — is fiction.
    await loadAppFonts();
  });

  /// One hero card, its declared threshold, and the locale that binds it.
  ///
  /// The locales are #1288 AC 1's measurement, not a guess: `ko` has the smallest
  /// content viewport of the 26 (122.0px) and `device_info`'s hero strings are
  /// device data, so it is worst by height rather than by string; `el` has the
  /// longest DHCP status token (`Ενεργοποιήθηκε`, 107.2px, which beat the IP
  /// address by 1.4px and set `lan_info`'s floor); `ru` has the longest sync
  /// badge (`Синхронизировано`, 112.1px) though the badge is not what sets
  /// `time_settings`' floor — its timestamp is, and that is byte-identical in
  /// every locale.
  const cards = <_HeroCard>[
    _HeroCard(id: 'device_info', worstLocale: 'ko'),
    _HeroCard(id: 'lan_info', worstLocale: 'el'),
    _HeroCard(id: 'time_settings', worstLocale: 'ru'),
  ];

  /// What each card promises to show when it has room for exactly one line.
  ///
  /// Taken from the same fixtures the card renders, so this asserts the card
  /// picked the right *field* rather than that someone typed the right literal
  /// twice. `time_settings` is the exception and has to be: its clock is driven
  /// by a live ticker, so the seconds advance while the test runs and only the
  /// shape is stable — which is itself the assertion, since
  /// `TimeSettingsUIModel.formatDateTime` hardcodes this pattern in every locale.
  final expectedPopupValue = <String, Matcher>{
    'device_info': equals(testSystemInfo.modelName),
    'lan_info': equals(testLanDhcpEnabled.ipAddress),
    'time_settings': matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$')),
  };

  WidgetSpec specOf(String id) =>
      UspWidgetSpecs.getById(id) ??
      (throw ArgumentError.value(id, 'id', 'no such card in UspWidgetSpecs'));

  /// Pumps [cardId] at an arbitrary [cardWidth], letting the card select its own
  /// form.
  ///
  /// The screen is held at 1440px while the card width varies, which is the same
  /// separation `CardDensityHost` makes: density comes from the constraints the
  /// grid hands the card, never from the window. Holding the screen wide is also
  /// what keeps a failure here readable — nothing in the case can be blamed on a
  /// narrow viewport.
  Future<List<OverflowIncident>> pumpAtWidth(
    WidgetTester tester, {
    required String cardId,
    required double cardWidth,
    required String label,
    required Locale locale,
  }) {
    final constraints = specOf(cardId).getConstraints(DisplayMode.normal);
    return probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: CardWidthCase(
        screenWidth: 1440,
        cardWidth: cardWidth,
        columnSpan: constraints.minColumns,
        label: label,
      ),
      cardHeightRows: constraints.minHeightRows,
      tabIndex: 0,
      locale: locale,
    );
  }

  /// The card's own `DashboardCardTemplate`, which is where the header icon and
  /// the popup value are declared.
  DashboardCardTemplate templateOf(WidgetTester tester) =>
      tester.widget<DashboardCardTemplate>(find.byType(DashboardCardTemplate));

  /// Fails if any hero text broke inside a token.
  ///
  /// Every `Text` in the hero is checked rather than a named one, so a card
  /// adding a line to its hero is covered without editing this file — which
  /// matters, because the widest token is a measurement and the line that owns it
  /// has already changed once (`lan_info`'s floor is set by its subtitle, not by
  /// the IP address anyone would have guessed).
  void expectHeroTokensWhole(WidgetTester tester, {required String at}) {
    final texts = find.descendant(
      of: find.byType(HeroBlock),
      matching: find.byType(Text),
    );
    final count = texts.evaluate().length;
    expect(count, greaterThan(0),
        reason: 'no text found in the hero block at all at $at, so the '
            'readability assertions below would pass vacuously');

    for (var i = 0; i < count; i++) {
      final finder = texts.at(i);
      final data = tester.widget<Text>(finder).data ?? '';
      if (data.isEmpty) continue;

      // The one exemption, and it is #1237's decision rather than this file's: a
      // capsule has no second line to wrap onto, so the badge ellipsizes by
      // design. Its floor — enough glyphs to name the state — is asserted in
      // `usp_hero_row_readability_test.dart`.
      final inBadge = find
          .ancestor(of: finder, matching: find.byType(AppBadge))
          .evaluate()
          .isNotEmpty;
      if (inBadge) continue;

      expect(tester.hasSplitToken(finder), isFalse,
          reason: '"$data" broke inside a word at $at: its widest token needs '
              '${tester.widestTokenWidth(finder).toStringAsFixed(1)}px and the '
              'column granted '
              '${tester.paragraphOf(finder).size.width.toStringAsFixed(1)}px. '
              'That is the damage the threshold exists to prevent, so either '
              'the compact form is not shedding enough or the threshold is too '
              'low (#1288).');
    }
  }

  /// Same 2.0px tolerance as the #1183 gate, for the same reason: sub-pixel
  /// shaping differences between the mac and ubuntu rasterizers.
  const tolerancePx = 2.0;

  void expectNoOverflow(List<OverflowIncident> incidents,
      {required String at}) {
    final significant = incidents.where((i) => i.pixels > tolerancePx).toList();
    expect(significant, isEmpty,
        reason: 'overflowed at $at:\n${significant.join('\n')}');
  }

  group('each card declares a threshold', () {
    for (final card in cards) {
      test(card.id, () {
        final normalAbove = specOf(card.id).normalAbove;
        expect(normalAbove, isNotNull,
            reason: 'no threshold declared, so this card claims it needs no '
                'degraded form — which is what #1240 correctly recorded and '
                '#1288 measured to be false for exactly these three cards. '
                'Every group below asserts a form this card would no longer '
                'select.');

        // A property rather than the literal 262 / 250 / 256, so a
        // re-measurement (a longer hostname fixture, #1267's second data
        // profile) can move the number without editing this file — while the two
        // things that would make the declaration meaningless still fail:
        expect(normalAbove, greaterThan(kPopupBelow),
            reason: 'a threshold at or below $kPopupBelow leaves no compact '
                'band at all: every width under it selects popup, so the card '
                'drops straight from whole to one value with nothing in '
                'between (densityForWidth precedence rule 1).');
        expect(normalAbove, lessThanOrEqualTo(288.0),
            reason: '288px is the widest narrowest-realization the grid '
                'produces (§1.2), so a threshold above it degrades the card at '
                'widths the dashboard hands out routinely. At that point the '
                'card needs a smaller normal form, not a higher threshold.');
      });
    }
  });

  group('below 200px the card selects its popup form', () {
    for (final card in cards) {
      final spec = specOf(card.id);
      final narrowest = narrowestRealizationOf(
          spec.getConstraints(DisplayMode.normal).minColumns,
          minScreen: 0)!;

      for (final tag in ['en', card.worstLocale]) {
        testWidgets(
            '${card.id} @${narrowest.cardWidth.toStringAsFixed(0)}px '
            '($tag)', (tester) async {
          final constraints = spec.getConstraints(DisplayMode.normal);
          final incidents = await probeCardOverflow(
            tester,
            cardId: card.id,
            widthCase: CardWidthCase(
              screenWidth: narrowest.screenWidth,
              cardWidth: narrowest.cardWidth,
              columnSpan: constraints.minColumns,
              label: 'min',
            ),
            cardHeightRows: constraints.minHeightRows,
            tabIndex: 0,
            locale: supportedLocaleFor(tag),
          );

          expect(find.byType(CardPopupForm), findsOneWidget,
              reason:
                  'at ${narrowest.cardWidth.toStringAsFixed(1)}px this card '
                  'still rendered its full form. That width is below '
                  '$kPopupBelow and the card declares '
                  'normalAbove=${spec.normalAbove}, so the whole point of the '
                  'declaration is that this is where it stops trying (#1288).');

          // The declared value, not the fallback. A popup form showing the card
          // *title* renders, fits, and tells the user nothing they did not
          // already know from looking at the dashboard.
          final popup =
              tester.widget<CardPopupForm>(find.byType(CardPopupForm));
          expect(popup.value, isNotNull,
              reason:
                  'no popupValue declared, so this card degrades to its own '
                  'title. A card that declares a threshold must also declare '
                  'the one value the threshold is protecting (#1288).');
          expect(popup.value, expectedPopupValue[card.id]!,
              reason:
                  'the popup form is showing "${popup.value}", which is not '
                  'the value the hero paints largest');
          expect(find.text(popup.value!), findsOneWidget,
              reason: 'the declared value was not painted — declaring it and '
                  'showing it are two different things');

          // The header icon is what §2.1 promises alongside the value, and it is
          // only present because the card moved it here for the degraded forms.
          expect(templateOf(tester).leading, isNotNull,
              reason: 'no icon reached the popup form, which §2.1 specifies as '
                  '"icon plus a single value". The icon the hero hides in the '
                  'degraded forms is supposed to reappear in the header');

          expectNoOverflow(incidents,
              at: '${narrowest.cardWidth.toStringAsFixed(1)}px ($tag)');
        });
      }
    }
  });

  group('between 200px and the threshold the card selects its compact form',
      () {
    for (final card in cards) {
      final spec = specOf(card.id);
      // The band's two edges. Nothing between them is measured, and nothing
      // needs to be: every quantity here — the widest token, the hero's height —
      // is monotone in width, so an edge that reads implies the interior does.
      //
      // The fallback keeps an undeclared threshold from throwing out here, in
      // `main`'s body, where it would abort the whole *file* — including the
      // group above that names the actual defect. A mutation ledger measured in
      // "the suite failed to load" says nothing about which assertion caught
      // what.
      final widths = <String, double>{
        'lower edge': kPopupBelow,
        'upper edge': (spec.normalAbove ?? kPopupBelow + 2) - 2,
      };

      for (final edge in widths.entries) {
        for (final tag in ['en', card.worstLocale]) {
          testWidgets(
              '${card.id} @${edge.value.toStringAsFixed(0)}px '
              '(${edge.key}, $tag)', (tester) async {
            final at = '${edge.value.toStringAsFixed(0)}px ($tag)';
            final incidents = await pumpAtWidth(
              tester,
              cardId: card.id,
              cardWidth: edge.value,
              label: edge.key,
              locale: supportedLocaleFor(tag),
            );

            expect(find.byType(CardPopupForm), findsNothing,
                reason: 'the card degraded all the way to its popup form at '
                    '$at, which is inside its compact band '
                    '[$kPopupBelow, ${spec.normalAbove}). Dropping to one value '
                    'here throws away rows that still fit.');

            // The icon out of the hero — this ticket's one structural change,
            // asserted as an absence in the tree rather than as a flag on the
            // widget, because a `compact` flag that no longer changes the build
            // would satisfy the flag and not the reader.
            final hero = tester.widget<HeroBlock>(find.byType(HeroBlock));
            expect(hero.compact, isTrue,
                reason: 'the hero block is still in its normal arrangement at '
                    '$at');
            expect(find.byWidget(hero.leading), findsNothing,
                reason:
                    'the hero icon is still beside the value at $at, so the '
                    'value column is still the ~61px that made this card '
                    'unreadable — the 200px budget does not fit both (#1288 '
                    'AC 1).');
            expect(templateOf(tester).leading, isNotNull,
                reason: 'the icon left the hero and did not arrive in the '
                    'header at $at, so the card lost its glyph entirely');

            expectHeroTokensWhole(tester, at: at);

            // Horizontal room is not enough on its own: `device_info`'s hero was
            // also 122.0px of content in a 120.0px viewport at 191.4px, i.e.
            // below the fold and invisible while overflowing nothing. Shedding
            // the icon container is what recovered that height too, so the
            // recovery is asserted rather than assumed.
            final viewport = cardContentViewport(tester);
            final heroRect = tester.getRect(find.byType(HeroBlock));
            expect(heroRect.bottom,
                lessThanOrEqualTo(viewport.bottom + tolerancePx),
                reason:
                    'the hero block ends at ${heroRect.bottom.toStringAsFixed(1)}px '
                    'but the card can only show down to '
                    '${viewport.bottom.toStringAsFixed(1)}px at $at, so its last '
                    'line has to be scrolled into view');

            expectNoOverflow(incidents, at: at);
          });
        }
      }
    }
  });

  group('at desktop width the normal form is untouched', () {
    for (final card in cards) {
      final spec = specOf(card.id);
      final wc = desktopCaseFor(spec);

      testWidgets('${card.id} @${wc.widthKey}px (${card.worstLocale})',
          (tester) async {
        final at = '${wc.widthKey}px (${card.worstLocale})';
        final incidents = await pumpAtWidth(
          tester,
          cardId: card.id,
          cardWidth: wc.cardWidth,
          label: 'desktop',
          locale: supportedLocaleFor(card.worstLocale),
        );

        expect(find.byType(CardPopupForm), findsNothing,
            reason: 'the card degraded at $at, which is ${wc.cardWidth.round()}'
                'px — far above its threshold of ${spec.normalAbove}');

        // The other half of every degradation: it must not fire where there is
        // room. A card that renders its compact form on a desktop dashboard has
        // silently downgraded the case that was never broken.
        final hero = tester.widget<HeroBlock>(find.byType(HeroBlock));
        expect(hero.compact, isFalse, reason: 'the hero is compact at $at');
        expect(
          find.descendant(
            of: find.byType(HeroBlock),
            matching: find.byWidget(hero.leading),
          ),
          findsOneWidget,
          reason: 'the hero icon is not beside the value at $at. At this width '
              'the card has room for the arrangement it was designed with, and '
              'the degraded forms exist to spare it, not to replace it.',
        );
        expect(templateOf(tester).leading, isNull,
            reason: 'the header is carrying a second copy of the hero icon at '
                '$at. The header slot is where the icon goes *instead of* the '
                'hero, only in the degraded forms — leaving it unconditional '
                'puts two router glyphs on a card that had no problem.');

        expectNoOverflow(incidents, at: at);
      });
    }
  });
}

/// One card in this file's inventory: which card, and the locale #1288 AC 1
/// measured as its worst.
class _HeroCard {
  const _HeroCard({required this.id, required this.worstLocale});

  final String id;
  final String worstLocale;
}
