@Tags(['dashboard-card'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../util/app_test_fonts.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';
import '../../../util/overflow_probe.dart';

/// Popup-form sweep for every registered card (#1239).
///
/// The #1183 gate (`dashboard_card_overflow_test.dart`) pins no density, so
/// every card selects its own form from the width the grid gives it — which for
/// 11 of the 18 cards is still always normal, because they declare no
/// `normalAbove` (#1240 AC 1). The other **seven** declare one (#1288-#1291,
/// #1321), and they are the cards a width can put into this form.
///
/// The sweep below is wider than those seven: it covers the **nine** cards the grid
/// can render under [kPopupBelow] at all, whether or not they declare a threshold
/// — see [_canReachPopupBand]. Three of the nine (`network_status`,
/// `system_status`, `firewall_overview`) reach the band by width but stay normal
/// there, so for them this measures a form only a #1299 pick can produce. Kept in
/// rather than filtered on `normalAbove`, because a card that declares one later
/// must not be arriving at its first measurement at the same time.
///
/// ## Why the form is pinned rather than provoked by a width
///
/// Popup is opt-in: it is reached only through a declared `normalAbove`, and
/// when this file was written no spec declared one, so no width produced it for
/// any card. Pinning it through `cardDensityOverrideProvider` (the hook #1232
/// built) is what made the sweep possible at all — and it stayed the right shape
/// once #1288's three thresholds arrived, for the same reason the gate pins tabs
/// instead of tapping them: the test states which form it is measuring instead of
/// depending on whatever threshold the spec currently declares. The complement —
/// that a declared threshold makes production *select* this form — is
/// `usp_hero_row_density_test.dart`, which pins nothing.
///
/// ## What the widths mean here
///
/// Each card is pumped at its narrowest production realization — the same width
/// the gate uses, which is under 200px for the narrow spans. That is where a
/// real popup form would be shown, and (overflow being monotonic in width) it is
/// the worst case for the form.
///
/// ## No allowlist
///
/// `known_overflows.json` baselines the normal form's inherited debt. The popup
/// form is new code and starts clean, so a failure here is a regression in this
/// ticket's work, not history — there is nothing to grandfather.
///
/// ## Tabs are not swept
///
/// The popup form renders one value over the card's name; it has no tab bar, so a tab
/// index selects nothing. The dialog it opens does show the card's tabs, and
/// that is swept at tab 0 — the tabs' own overflow across every tab is the
/// #1183 gate's job, at grid widths narrower than the dialog's.
///
/// ## Which cards are swept — and the half that has no popup form at all
///
/// Only the cards the grid can actually put below [kPopupBelow], which turns out
/// to be exactly the ones whose spec permits a 3-column span. The grid's
/// narrowest realizations are 191.4px for a 3-column floor, 260.5px for a
/// 4-column floor, and 288px for anything wider (a full-width card clamped to the
/// 4-column mobile grid). Only the first is under 200px.
///
/// So nine of the eighteen registered widgets can never select popup at any
/// width, whatever they declare — [densityForWidth] compares the *rendered*
/// width against the threshold, and their own `minColumns` floors them above it.
/// Sweeping a popup form for them would be measuring a state production cannot
/// produce.
///
/// That is worth stating plainly because it decides what the middle band is for:
/// **compact is the only degraded form those nine cards can reach.** #1232's
/// measurement found the compact band had no consumers and this ticket's popup
/// form does not change that — but it is not dead by construction, it is the
/// only degradation available to half the dashboard.
///
/// `what this file sweeps` pins the inventory and the rule behind it, so a spec
/// changing `minColumns` surfaces here rather than silently adding or dropping
/// coverage.

/// Locale identity, matching the #1183 gate's key so test names line up between
/// the two sweeps.
String _localeTag(Locale l) => l.countryCode == null || l.countryCode!.isEmpty
    ? l.languageCode
    : '${l.languageCode}_${l.countryCode}';

/// Same tolerance the #1183 gate uses, for the same reason: sub-pixel shaping
/// differences between the mac and ubuntu rasterizers.
const double _tolerancePx = 2.0;

/// Locales the dialog sweep runs. The popup form itself is swept in all 26; the
/// dialog is a second pump per case, so it takes the three that bound the text:
/// English as the baseline, German for the longest Latin compounds, Traditional
/// Chinese for the widest glyphs.
const List<Locale> _dialogLocales = [
  Locale('en'),
  Locale('de'),
  Locale('zh', 'TW'),
];

/// The narrowest width the grid produces for [spec] — the same case the #1183
/// gate treats as the worst case. Null when a `MIN_SCREEN` filter has excluded
/// every realization, matching [widthCasesFor]'s empty return.
CardWidthCase? _narrowestCaseFor(WidgetSpec spec) {
  final cases = widthCasesFor(spec);
  return cases.isEmpty ? null : cases.first;
}

/// Whether the grid can make [spec] narrow enough to select its popup form.
///
/// A card the grid keeps above [kPopupBelow] has no popup form to sweep at any
/// width, whatever it declares — [densityForWidth] compares the *rendered* width
/// against the threshold, so a floor above it settles the question.
bool _canReachPopupBand(WidgetSpec spec) {
  final wc = _narrowestCaseFor(spec);
  return wc != null && wc.cardWidth < kPopupBelow;
}

/// Rows of viewport the picked sweep gives the screen.
///
/// Six rows is 800px — a laptop, and comfortably more than the tallest card's
/// declared 528px, so the presentation is measured against a screen that is not
/// itself the constraint. The tile inside it is still one row.
const int _fullScreenRows = 6;

/// Whether the user can put [spec] into popup by *picking* it (#1299).
///
/// A different and larger inventory than [_canReachPopupBand], which is why it is
/// a second predicate rather than a widened one. Reaching the band by width takes
/// a `minColumns` of 3, which nine cards have; picking popup is offered for every
/// card the template builds, which is all of them but `stats_panel`. The eight
/// cards in the difference have a popup form that production can show and no
/// width sweep can reach.
bool _canBePickedIntoPopup(WidgetSpec spec) =>
    UspWidgetSpecs.selectableForms(spec.id).contains(CardDensity.popup);

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('what this file sweeps', () {
    // The widgets the grid keeps above kPopupBelow, and which therefore have no
    // popup form to measure. Every one has a minColumns of 4 or more; see the
    // file header for the widths.
    const noPopupForm = [
      'stats_panel',
      'topology',
      'wifi_status',
      'wifi_networks',
      'dhcp_reservations',
      'port_forwarding',
      'wifi_performance',
      'traffic_analysis',
      'device_analytics',
    ];

    test('is every card the grid can make narrow enough to degrade', () {
      final skipped = UspWidgetSpecs.all
          .where((s) => !_canReachPopupBand(s))
          .map((s) => s.id)
          .toList();

      expect(
        skipped,
        noPopupForm,
        reason: 'the sweeps below skip cards whose narrowest realization is '
            'already above the popup threshold, so this list is the inventory '
            'of cards with no popup form. An id appearing here has silently '
            'lost popup coverage; an id disappearing has silently gained a '
            'popup form nothing had reviewed. Either way, the spec change that '
            'moved it is the thing to look at',
      );
    });

    // Every count this file's header quotes, asserted from the specs. The header
    // had drifted to "15 of the 18 declare no normalAbove … only three of them"
    // while six declared one and nine were being swept — a doc-only claim about
    // an inventory that three tickets kept changing, so it went stale silently
    // and was read as current.
    test('the header\'s counts are the specs\' counts', () {
      expect(UspWidgetSpecs.all, hasLength(18));
      expect(
        UspWidgetSpecs.all.where((s) => s.normalAbove != null).length,
        7,
        reason: 'the cards a width can put into a degraded form at all',
      );
      expect(
        UspWidgetSpecs.all.where(_canReachPopupBand).length,
        9,
        reason: 'what the popup sweep below covers',
      );
      expect(
        UspWidgetSpecs.all.where(_canBePickedIntoPopup).length -
            UspWidgetSpecs.all.where(_canReachPopupBand).length,
        8,
        reason:
            'the cards with a popup form no width sweep can reach, which is '
            'what the pick sweep exists for',
      );
    });

    test('the cards swept for a form no width selects are named in the header',
        () {
      final pinnedOnly = UspWidgetSpecs.all
          .where((s) => _canReachPopupBand(s) && s.normalAbove == null)
          .map((s) => s.id)
          .toList();

      expect(
          pinnedOnly, ['network_status', 'system_status', 'firewall_overview'],
          reason: 'these reach the band by width but stay normal there, so the '
              'sweep measures a form only a #1299 pick produces. A card leaving '
              'this list has just started selecting popup by width — which is a '
              'product change, not a test detail');
    });

    test('and it is minColumns that decides, nothing else', () {
      // Ties the width filter to the one spec field a reader would change to
      // move a card in or out of the sweep. Without this, "not swept" looks
      // like a property of the card rather than of one number in its spec.
      for (final id in noPopupForm) {
        final c =
            UspWidgetSpecs.getById(id)!.getConstraints(DisplayMode.normal);
        expect(
          c.minColumns,
          greaterThanOrEqualTo(4),
          reason: '$id is skipped because the grid floors it above the popup '
              'threshold, which is a consequence of minColumns >= 4. A '
              '3-column floor realizes at 191.4px and does reach the band',
        );
      }
    });
  });

  group('popup form', () {
    for (final spec in UspWidgetSpecs.all.where(_canReachPopupBand)) {
      final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
      final wc = _narrowestCaseFor(spec)!;

      for (final locale in AppLocalizations.supportedLocales) {
        final tag = _localeTag(locale);
        testWidgets('${spec.id} is clean @${wc.widthKey}px ($tag)',
            (tester) async {
          final incidents = await probeCardOverflow(
            tester,
            cardId: spec.id,
            widthCase: wc,
            cardHeightRows: rows,
            tabIndex: 0,
            locale: locale,
            density: CardDensity.popup,
          );

          expect(
            find.byType(CardPopupForm),
            findsOneWidget,
            reason: '${spec.id} did not render the popup form — a card that '
                'bypasses the template would silently keep its full form here',
          );

          final significant =
              incidents.where((i) => i.pixels > _tolerancePx).toList();
          expect(
            significant,
            isEmpty,
            reason: '${spec.id} popup form overflowed at ${wc.widthKey}px '
                '($tag):\n${significant.join('\n')}',
          );
        });
      }
    }
  });

  /// The one thing the fixed presentation width has to be measured against.
  ///
  /// `showCardNormalForm` gives every card the same [kCardPresentationWidth]
  /// rather than the width its spec declares (250–386 across the seven that
  /// declare one). That is only sound while the fixed width clears all of them: a card
  /// declaring more than the presentation offers would be handed back the very
  /// width it said it could not be read at.
  ///
  /// It lives here rather than beside the presentation because `_shared` cannot
  /// see the specs — the constant is a `_shared` decision and the thresholds are
  /// the dashboard's, and this is the file that imports both.
  group('the presentation width', () {
    test('clears every threshold a card declares', () {
      final declared = {
        for (final spec in UspWidgetSpecs.all)
          if (spec.normalAbove != null) spec.id: spec.normalAbove!,
      };

      expect(
        declared,
        isNotEmpty,
        reason:
            'with no card declaring a threshold this test asserts nothing — '
            'the floor it pins would be vacuous',
      );
      for (final entry in declared.entries) {
        expect(
          entry.value,
          lessThanOrEqualTo(kCardPresentationWidth),
          reason:
              '${entry.key} declares it needs ${entry.value}px to be whole, '
              'and the presentation offers ${kCardPresentationWidth}px. Either '
              'raise the presentation width or re-measure the threshold — as it '
              'stands, tapping the popup form hands this card back a width it '
              'has already said it cannot be read at',
        );
      }
    });
  });

  group('the dialog it opens', () {
    for (final spec in UspWidgetSpecs.all.where(_canReachPopupBand)) {
      final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
      final wc = _narrowestCaseFor(spec)!;

      for (final locale in _dialogLocales) {
        final tag = _localeTag(locale);
        testWidgets('${spec.id} normal form is clean in the dialog ($tag)',
            (tester) async {
          final incidents = await probeCardOverflow(
            tester,
            cardId: spec.id,
            widthCase: wc,
            cardHeightRows: rows,
            tabIndex: 0,
            locale: locale,
            density: CardDensity.popup,
            after: (t) async {
              await t.tap(find.byType(CardPopupForm));
              await settleIgnoringAnimations(t);
            },
          );

          // The presentation is the only way to read this card, so an empty or
          // absent one is a total loss of the card's content, not a cosmetic
          // problem.
          expect(
            find.byType(AppDialog),
            findsOneWidget,
            reason: '${spec.id}: tapping the popup form must open the dialog',
          );

          final significant =
              incidents.where((i) => i.pixels > _tolerancePx).toList();
          expect(
            significant,
            isEmpty,
            reason: '${spec.id} normal form overflowed inside the dialog '
                '($tag):\n${significant.join('\n')}',
          );
        });
      }
    }
  });

  /// The same presentation, opened from a *picked* popup tile (#1299).
  ///
  /// The sweep above models the width path: the card degrades because the grid
  /// made it narrow, and its cell keeps whatever height the layout gave it. A pick
  /// is the other path, and it pins the box — `applyCardForms` writes
  /// [UspWidgetSpecs.popupHeightRows], so the cell is one row whatever the card
  /// declares it needs.
  ///
  /// That height is a consequence of the degradation, so it must not be what the
  /// presentation *undoing* the degradation is sized to. Sweeping the two heights
  /// separately is what keeps the distinction visible: pass `declared` here and
  /// every case passes while production shows a card in a box a third of its
  /// height.
  ///
  /// The group was written failing — 51 of 51, by +11px to +91px, all `bottom` —
  /// which is what the sweep above cannot see: it feeds the *declared* height, so
  /// it measures the one geometry that was never broken.
  ///
  /// ## Mutation table
  ///
  /// | # | mutated | mutation | killed by |
  /// |---|---|---|---|
  /// | 1 | `card_popup_form` | `_open` sizes the presentation to the cell alone | 51 of 51 |
  /// | 2 | `usp_widget_factory` | the factory supplies no `normalHeight` | 51 of 51 |
  /// | 3 | `card_grid_geometry` | `dashboardRowsToHeight` drops the inter-row gap | **survived** — 480px is still room enough for every card's chrome, so the arithmetic is pinned against the real grid in `card_form_toolbar_test.dart` instead |
  group('the dialog a picked popup opens', () {
    test('is offered for every card but the one with no popup form', () {
      final pickable = UspWidgetSpecs.all
          .where(_canBePickedIntoPopup)
          .map((s) => s.id)
          .toSet();
      final excluded = UspWidgetSpecs.all
          .map((s) => s.id)
          .where((id) => !pickable.contains(id))
          .toList();

      expect(
        excluded,
        UspWidgetSpecs.cardsWithoutPopupForm.toList(),
        reason: 'the pick inventory is decided by cardsWithoutPopupForm alone, '
            'not by minColumns — so unlike the width sweep above, a spec '
            'widening its floor does not remove a card from this sweep. An id '
            'appearing here has lost its popup form',
      );
      expect(
        pickable.length,
        greaterThan(UspWidgetSpecs.all.where(_canReachPopupBand).length),
        reason: 'if picking ever became as narrow an inventory as the width '
            'path, these two groups would be measuring the same thing and one '
            'of them should go',
      );
    });

    for (final spec in UspWidgetSpecs.all.where(_canBePickedIntoPopup)) {
      // The tile the pick collapses the card to, not the card's own narrowest
      // span: a picked popup is `popupColumns` wide wherever the grid allows it.
      final wc = pickedTileCase();

      for (final locale in _dialogLocales) {
        final tag = _localeTag(locale);
        testWidgets('${spec.id} normal form is clean in the dialog ($tag)',
            (tester) async {
          final incidents = await probeCardOverflow(
            tester,
            cardId: spec.id,
            widthCase: wc,
            // What the pick pins the cell to.
            cardHeightRows: UspWidgetSpecs.popupHeightRows,
            // A full-height screen: the tile is short, the device is not.
            screenHeightRows: _fullScreenRows,
            tabIndex: 0,
            locale: locale,
            density: CardDensity.popup,
            after: (t) async {
              await t.tap(find.byType(CardPopupForm));
              await settleIgnoringAnimations(t);
            },
          );

          expect(
            find.byType(AppDialog),
            findsOneWidget,
            reason: '${spec.id}: tapping the popup form must open the dialog',
          );

          final significant =
              incidents.where((i) => i.pixels > _tolerancePx).toList();
          expect(
            significant,
            isEmpty,
            reason: '${spec.id} normal form overflowed inside the dialog '
                'opened from a picked popup tile ($tag). The tile is '
                '${dashboardCardHeight(UspWidgetSpecs.popupHeightRows)}px tall '
                'and this card declares '
                '${dashboardCardHeight(spec.getConstraints(DisplayMode.normal).minHeightRows)}px'
                ':\n${significant.join('\n')}',
          );
        });
      }
    }
  });

  /// What the tile actually says, which no overflow probe can see.
  ///
  /// The sweeps above measure that the tile fits. A tile showing the card's
  /// *name* fits just as well as one showing its value — better, since the fixed
  /// strings are shorter — so the form could be entirely useless and every case
  /// above would stay green. Reported from the built app: the picked tiles read
  /// "Network St…", "System Stat…", "Community…", because eleven of the seventeen
  /// pickable cards declared no `popupValue` and fell back to their title.
  ///
  /// The fallback stays (a form with nothing in it is worse than one showing the
  /// card's name), so this is the test that says the fallback is not the design.
  ///
  /// ## Mutation table
  ///
  /// | # | mutated | mutation | killed by |
  /// |---|---|---|---|
  /// | 1 | any card | its `popupValue` argument removed | that card's case, by the title it falls back to |
  /// | 2 | any card | `popupValue: title` (a value that is the name) | that card's case — the second assertion, which is why non-null is not the whole claim |
  group('the value a picked popup shows', () {
    for (final spec in UspWidgetSpecs.all.where(_canBePickedIntoPopup)) {
      testWidgets('${spec.id} degrades to a value, not to its own name',
          (tester) async {
        await probeCardOverflow(
          tester,
          cardId: spec.id,
          widthCase: pickedTileCase(),
          cardHeightRows: UspWidgetSpecs.popupHeightRows,
          screenHeightRows: _fullScreenRows,
          tabIndex: 0,
          locale: const Locale('en'),
          density: CardDensity.popup,
        );

        final form = tester.widget<CardPopupForm>(find.byType(CardPopupForm));
        expect(
          form.value,
          isNotNull,
          reason: '${spec.id} declares no popupValue, so its tile shows its '
              'title — and at two columns the title is ellipsized to a few '
              'characters. Which number is worth seeing at a glance is the '
              "card's own judgement (see DashboardCardTemplate.popupValue), so "
              'it has to be declared where the card is built',
        );
        expect(
          form.value,
          isNot(form.title),
          reason: '${spec.id} degrades to its own name, which the tile would '
              'have shown anyway — the form is then a label, not a value',
        );
      });
    }
  });

  /// The height the presentation is given, and where that number comes from.
  ///
  /// `minHeightRows` is the floor the grid enforces — the smallest box the card
  /// can be dragged to — and the presentation was sized to it. That is the wrong
  /// end of the range: the card the user is being shown is the one the dashboard
  /// would have laid out, and what the dashboard lays out is
  /// `getPreferredHeightCells()` (`layout_item_factory.dart:49`). For the six
  /// cards whose strategy is `strict(N)` with `N` above their floor the two
  /// differ by one to two grid rows — topology declares a floor of 3 and prefers
  /// 5, so it was presented at 392px in a box it fills at 664px, which is what
  /// "topology 也是太小" was.
  ///
  /// The overflow sweeps cannot see this either: a box that is too *small* for a
  /// card whose content scrolls or shrink-wraps overflows nothing. It just shows
  /// a third of the card.
  ///
  /// ## Mutation table
  ///
  /// | # | mutated | mutation | killed by |
  /// |---|---|---|---|
  /// | 1 | `usp_widget_factory` | `_normalHeightOf` reads `minHeightRows` again | the six cards whose preferred rows exceed their floor |
  /// | 2 | `usp_widget_factory` | `_normalHeightOf` reads `maxHeightRows` | every card, in the other direction |
  /// | 3 | `card_popup_form` | the viewport cap applied to every card, not only the ones over it | every card, once the cap binds below the declaration — the cap itself is pinned in `card_popup_form_test.dart`, on a screen small enough for it to bind |
  group('the height a picked popup presents at', () {
    for (final spec in UspWidgetSpecs.all.where(_canBePickedIntoPopup)) {
      final constraints = spec.getConstraints(DisplayMode.normal);
      // No spec uses `AspectRatioHeightStrategy`, the only strategy whose
      // preferred height depends on the span, so the column count is not part of
      // this question and the argument is left off deliberately.
      final preferred = dashboardCardHeight(
        constraints.getPreferredHeightCells(),
      );

      testWidgets('${spec.id} gets the ${preferred}px its spec prefers',
          (tester) async {
        await probeCardOverflow(
          tester,
          cardId: spec.id,
          widthCase: pickedTileCase(),
          cardHeightRows: UspWidgetSpecs.popupHeightRows,
          screenHeightRows: _fullScreenRows,
          tabIndex: 0,
          locale: const Locale('en'),
          density: CardDensity.popup,
          after: (t) async {
            await t.tap(find.byType(CardPopupForm));
            await settleIgnoringAnimations(t);
          },
        );

        expect(
          tester
              .getSize(find.descendant(
                of: find.byType(AppDialog),
                matching: find.byType(DashboardCardTemplate),
              ))
              .height,
          preferred,
          reason: '${spec.id} declares a floor of '
              '${constraints.minHeightRows} rows and prefers '
              '${constraints.getPreferredHeightCells()}. The presentation is the '
              'only way to read a picked card, so the height it gets has to be '
              'the one the dashboard would have laid the card out at, not the '
              'smallest box the grid would ever allow',
        );
      });
    }
  });

  group('the summary strip', () {
    // `stats_panel` is skipped twice over, and it is the only widget of which
    // that is true. The other eight are ordinary template cards that would gain
    // a popup form the moment their `minColumns` allowed a 3-column span; this
    // one would not, because there is no card there to degrade. Pinning the
    // second reason separately keeps the skip list from being read as "these
    // cards may bypass the template".
    final spec = UspWidgetSpecs.getById('stats_panel')!;

    test('is floored above the popup threshold by its own spec', () {
      // `minColumns: 6` of 12, and always placed full width. Its narrowest
      // realization is therefore the whole grid at the 320px screen floor —
      // 288px. No width the grid produces selects a popup form for it, so a
      // popup form is not missing functionality; it is unreachable code.
      final wc = _narrowestCaseFor(spec)!;
      expect(
        wc.cardWidth,
        greaterThanOrEqualTo(kPopupBelow),
        reason: 'if the grid can now make the summary strip narrower than the '
            'popup threshold, this exemption is void and it needs a degraded '
            'form like every other widget',
      );
    });

    testWidgets('is not a card, so it has no form to degrade', (tester) async {
      // Structural half: it is a row of five stat tiles, with no title, no icon
      // and no single value the popup form is built from — and no
      // `DashboardCardTemplate`, which is where that form lives. Pumped through
      // the production path with no density pinned, exactly as the #1183 gate
      // pumps it.
      await probeCardOverflow(
        tester,
        cardId: spec.id,
        widthCase: _narrowestCaseFor(spec)!,
        cardHeightRows: spec.getConstraints(DisplayMode.normal).minHeightRows,
        tabIndex: 0,
        locale: const Locale('en'),
      );

      expect(
        find.byType(DashboardCardTemplate),
        findsNothing,
        reason: 'the summary strip is exempt because it is not built from the '
            'card template. If it becomes a template card, drop it from the '
            'skip list above and let the sweep cover it',
      );
    });
  });
}
