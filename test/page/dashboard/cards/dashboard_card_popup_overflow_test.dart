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
/// 15 of the 18 cards is still always normal, because they declare no
/// `normalAbove` (#1240 AC 1). This file sweeps the form that selection reaches
/// for only three of them, and only at their narrowest realization.
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
/// The popup form renders an icon and one value; it has no tab bar, so a tab
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
