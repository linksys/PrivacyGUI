@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';

/// Legend readability for System Status and Network Health (#1233).
///
/// ## Why this file exists alongside the #1183 gate
///
/// #1233 clears 132 coordinates by letting six legend rows *give* instead of
/// overflowing. But "gives" has a failure mode the gate cannot see: a row that
/// truncates its content to nothing is as clean as a row that fits. Two of the
/// ticket's acceptance criteria are exactly that blind spot —
///
///   - "Network Health's composed average/peak labels stay readable, not
///     truncated to uselessness"
///   - "Series colours remain associable with their series at the narrowest
///     clean width — a legend that loses its mapping has lost its purpose"
///
/// — so they need assertions on the rendered tree, not on overflow.
///
/// Tagged `dashboard-card` so it gates PRs: `run_tests.sh` excludes
/// `golden||loc||ui`, so a `ui`-tagged test here would block nothing. (The older
/// `usp_network_health_card_legend_test.dart` is `ui`-tagged for that reason —
/// it covers label *composition* from #1145, not degradation.)
///
/// ## Why the `network_health` pumps pin `CardDensity.normal` (#1291)
///
/// #1291 gave that card a `normalAbove: 366`, so its narrowest 3-column
/// realization (191.375px) no longer *selects* the arrangement these groups
/// measure — it yields the popup form, which has no legend, no interface readout
/// and no WAN/LAN row to assert on. The claims themselves did not stop being
/// true: `showCardNormalForm` renders this same normal form in a full-bleed sheet
/// on a phone too narrow to host a dialog, so a legend row at ~157px of content
/// is a form that ships and still has to stay readable. The pin is what keeps
/// these assertions pointed at the form they were written for; which width
/// selects which form is `usp_network_health_density_test.dart`'s question, not
/// this file's.
///
/// `system_status` is left unpinned deliberately — it declares no `normalAbove`,
/// so its narrowest realization still renders the normal form on the grid, and
/// pinning would hide the day someone gives it a threshold.
void main() {
  setUpAll(() async {
    // Real fonts: under the Ahem block font every glyph is one square em, so
    // what does and does not fit — and therefore what ellipsizes — is fiction.
    await loadAppFonts();
  });

  /// Pumps [cardId] at the narrowest width the grid ever gives its min span —
  /// the worst case the gate measures, and where degradation is at its most
  /// aggressive. One pump, as the gate does.
  ///
  /// [density] pins the form under measurement. Pass it for any card that
  /// declares a `normalAbove`, where this width would otherwise select the popup
  /// form and there would be no legend to assert on (see the header).
  Future<void> pumpNarrowest(
    WidgetTester tester, {
    required String cardId,
    required int minSpan,
    required int heightRows,
    required int tabIndex,
    required Locale locale,
    CardDensity? density,
  }) async {
    final narrowest = narrowestRealizationOf(minSpan, minScreen: 0)!;
    await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: CardWidthCase(
        screenWidth: narrowest.screenWidth,
        cardWidth: narrowest.cardWidth,
        columnSpan: minSpan,
        label: 'min',
      ),
      cardHeightRows: heightRows,
      tabIndex: tabIndex,
      locale: locale,
      density: density,
    );
  }

  /// Every `Text` in the tree that actually painted a non-empty string.
  List<Text> renderedTexts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.data != null && t.data!.isNotEmpty)
      .toList();

  /// The single `Text` whose data contains [needle], or a failure naming what
  /// was actually rendered — a missing label is the interesting failure here, so
  /// the message has to be diagnosable.
  Text textContaining(WidgetTester tester, String needle) {
    final matches =
        renderedTexts(tester).where((t) => t.data!.contains(needle)).toList();
    expect(matches, isNotEmpty,
        reason: 'no rendered Text contains "$needle". Rendered: '
            '${renderedTexts(tester).map((t) => t.data).toList()}');
    return matches.first;
  }

  group('Network Health composed labels stay readable (#1233)', () {
    // The Errors and Loss legends carry `{series}  Avg: {avg}  Peak: {peak}` —
    // the longest legend strings in either card. They are allowed to take a
    // second line; they are NOT allowed to ellipsize, because the ellipsis would
    // land in the middle of a statistic and a half-shown number misinforms in a
    // way a missing one does not.
    for (final tab in [1, 2]) {
      for (final tag in ['de', 'fi', 'fr', 'ru']) {
        testWidgets('tab $tab legend labels are never ellipsized in $tag',
            (tester) async {
          final locale = _localeFor(tag);
          await pumpNarrowest(
            tester,
            cardId: 'network_health',
            minSpan: 3,
            heightRows: 3,
            tabIndex: tab,
            locale: locale,
            density: CardDensity.normal,
          );

          // The composed labels are the ones whose text contains the localized
          // "Avg" fragment; identify them through the ARB string rather than by
          // position, so a reordered row does not silently pass.
          final avgFragment = _avgFragment(locale);
          final composed = renderedTexts(tester)
              .where((t) => t.data!.contains(avgFragment))
              .toList();

          expect(composed, isNotEmpty,
              reason: 'the legend must still show its average — that value is '
                  'the tab\'s only numeric readout. Rendered: '
                  '${renderedTexts(tester).map((t) => t.data).toList()}');

          for (final t in composed) {
            expect(t.overflow, isNot(TextOverflow.ellipsis),
                reason: 'composed legend label "${t.data}" would clip a '
                    'statistic mid-number. It must wrap to a second line '
                    'instead — the chart above is Expanded and yields the '
                    'height (#1226 rule 3).');
            expect(t.maxLines, isNull,
                reason: 'composed legend label "${t.data}" is line-capped, so '
                    'the tail of the statistic is dropped silently.');
          }
        });
      }
    }
  });

  group('series colours stay associable (#1233)', () {
    // A legend is a colour→series mapping. Degradation may shorten a label or
    // move an entry to another line, but every series that has a dot must still
    // have a label, or the mapping is gone. Asserting on the count of coloured
    // dots against the count of legend labels catches the failure mode where a
    // row survives by dropping children.
    testWidgets('System Status Trends shows both series entries',
        (tester) async {
      await pumpNarrowest(
        tester,
        cardId: 'system_status',
        minSpan: 3,
        heightRows: 3,
        tabIndex: 1,
        locale: _localeFor('de'),
      );

      final avgFragment = _avgFragment(_localeFor('de'));
      final entries = renderedTexts(tester)
          .where((t) => t.data!.contains(avgFragment))
          .toList();
      expect(entries.length, 2,
          reason: 'Trends charts CPU and Memory, so both legend entries must '
              'survive — one dropped entry leaves a coloured line on the chart '
              'with nothing naming it. Rendered: '
              '${renderedTexts(tester).map((t) => t.data).toList()}');
    });

    testWidgets('System Status Correlation names both series', (tester) async {
      final locale = _localeFor('fr');
      await pumpNarrowest(
        tester,
        cardId: 'system_status',
        minSpan: 3,
        heightRows: 3,
        tabIndex: 3,
        locale: locale,
      );
      final l = await AppLocalizations.delegate.load(locale);

      // These two labels are bare series names, so unlike the composed ones they
      // MAY ellipsize (#1226 rule 2 — the colour does the identifying). What must
      // not happen is the label disappearing.
      textContaining(tester, l.cpu);
      // The traffic label is the one that gets clipped at this width, so match
      // its first word rather than the whole string.
      textContaining(tester, l.trafficRate.split(' ').first);
    });

    testWidgets('Network Health Health tab keeps both interface readouts',
        (tester) async {
      final locale = _localeFor('ru');
      await pumpNarrowest(
        tester,
        cardId: 'network_health',
        minSpan: 3,
        heightRows: 3,
        tabIndex: 0,
        locale: locale,
        density: CardDensity.normal,
      );
      final l = await AppLocalizations.delegate.load(locale);

      // `ru` is the worst case: 'Глобальная сеть' for WAN plus a long tier word.
      // Both lights are Flexible and one-line, so the tier may clip — but each
      // interface must still be named, because the dot's colour alone does not
      // say which interface it belongs to.
      textContaining(tester, l.wan.split(' ').first);
      textContaining(tester, l.lan);
    });
  });

  group('the Health tab keeps its gauge intact (#1233)', () {
    // Why this test exists: the obvious fix for the WAN/LAN row was #1226's
    // `Wrap`, and it measurably made things worse — the row grew a second run,
    // the Expanded above it could not yield (it holds a fixed 120px gauge), and
    // the gauge's own centre column started overflowing instead (3 coordinates
    // became 15). The row is a one-line `Row` of Flexibles for that reason, and
    // this pins the reason so the "consistent with the other five rows" refactor
    // does not silently reintroduce it.
    for (final tag in ['ru', 'de', 'th']) {
      testWidgets('WAN/LAN row stays one line in $tag', (tester) async {
        final locale = _localeFor(tag);
        await pumpNarrowest(
          tester,
          cardId: 'network_health',
          minSpan: 3,
          heightRows: 3,
          tabIndex: 0,
          locale: locale,
          density: CardDensity.normal,
        );
        final l = await AppLocalizations.delegate.load(locale);

        final wanText = textContaining(tester, l.wan.split(' ').first);
        final lanText = textContaining(tester, l.lan);

        for (final t in [wanText, lanText]) {
          expect(t.maxLines, 1,
              reason: 'the WAN/LAN readout "${t.data}" must stay one line: the '
                  'gauge above it is a fixed 120px inside an Expanded, so any '
                  'extra height here pushes the gauge centre out of its own '
                  'circle instead.');
        }

        // Same line, not stacked — the y centres coincide.
        final wanBox = tester.getRect(find.byWidget(wanText));
        final lanBox = tester.getRect(find.byWidget(lanText));
        expect((wanBox.center.dy - lanBox.center.dy).abs(), lessThan(1.0),
            reason: 'WAN and LAN sit on different lines, so the row is taller '
                'than one line and the gauge loses the height.');
      });
    }
  });
}

Locale _localeFor(String tag) =>
    AppLocalizations.supportedLocales.firstWhere((l) {
      final t = l.countryCode == null || l.countryCode!.isEmpty
          ? l.languageCode
          : '${l.languageCode}_${l.countryCode}';
      return t == tag;
    });

/// The localized 'Avg' fragment, taken from the ARB string itself rather than
/// hardcoded, so this stays correct when a translation changes.
String _avgFragment(Locale locale) {
  // `seriesAvgValue` is '{series}  Avg: {value}' — feeding it empty placeholders
  // leaves exactly the literal text around them.
  final l = lookupAppLocalizations(locale);
  return l.seriesAvgValue('', '').trim();
}
