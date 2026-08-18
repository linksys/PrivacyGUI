@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../util/app_test_fonts.dart';
import '../../../../util/dashboard/dashboard_card_probe.dart';

/// The de-duplicated legend's one invariant (#1245).
///
/// ## What this file is for
///
/// #1245 replaced four `_LegendDot`s, two `_LegendEntry`s and one
/// `_StatLegendEntry` with `AppChartLegendEntry` from ui_kit (proposed as
/// linksys/privacyGUI-UI-kit#26, shipped in v2.37.0). The seven copies each
/// carried the same rule in a comment — a **bare series name** may be clipped to
/// one line, because the chart is already colour-coded and the colour does the
/// identifying; a label with a **value composed into it** may not, because an
/// ellipsis lands mid-number and a half-shown statistic misinforms in a way a
/// missing one does not (§2.10a point 2).
///
/// The kit encodes that rule in the *entrance*: `.seriesName` shortens,
/// `.statistic` wraps, and no constructor takes the behaviour as a parameter, so
/// a call site cannot get it wrong by forgetting a flag — which is what
/// `_StatLegendEntry`'s `ellipsize: false` default invited. This file checks the
/// half the kit cannot: that every call site reached for the entrance matching
/// the label it actually passes.
///
/// That is #1245 AC 3, "the ellipsize-vs-soft-wrap distinction survives
/// extraction, **per label kind, not per call site**", stated as an assertion
/// rather than as a comment in seven files.
///
/// ## Why it reads the label, not the call site
///
/// The check is derived from the rendered string: a label containing a digit is
/// a statistic and must be [ChartLegendLabelBehavior.wrap]; a label containing
/// none is a name and must be [ChartLegendLabelBehavior.shorten]. So it holds for
/// rows this file never enumerates — a legend added to a sixth card is covered
/// the day it renders, and a label that *grows* a value ('Upload' →
/// 'Upload: 1.2 MB/s') fails until its entrance changes with it.
///
/// ## What it deliberately does not cover
///
/// - Which rows overflow: that is the #1183 gate
///   (`dashboard_card_overflow_test.dart`), and #1245 is explicitly not allowed
///   to move it.
/// - Whether a composed label stays *readable* once it wraps:
///   `dashboard_legend_readability_test.dart`, which #1245 AC 4 requires to pass
///   unmodified.
/// - `_TrafficLight` in `usp_network_health_card`: deliberately not migrated (the
///   kit's mark box is 16px against its 10px dot, on the one row in the card that
///   has no width to spare — see the widget's own doc comment), so it is not an
///   `AppChartLegendEntry` and this sweep does not see it.
void main() {
  setUpAll(() async {
    // Real fonts, for the same reason the readability test loads them: the
    // behaviour under test is what happens when text does not fit.
    await loadAppFonts();
  });

  /// Every legend entry in the pumped tree, in paint order.
  List<AppChartLegendEntry> entries(WidgetTester tester) => tester
      .widgetList<AppChartLegendEntry>(find.byType(AppChartLegendEntry))
      .toList();

  /// Pumps one (card, tab, locale) at the widest realization the grid gives the
  /// card, and returns its legend entries.
  ///
  /// Widest, not narrowest: the label kind is a property of the string, not of
  /// the width, and a wide pump renders every entry on one run where a narrow one
  /// may drop a card into its popup form and show no legend at all. The narrow
  /// end is the gate's and the readability test's job.
  Future<List<AppChartLegendEntry>> pumpLegend(
    WidgetTester tester, {
    required String cardId,
    required int tabIndex,
    required Locale locale,
  }) async {
    await probeCardOverflow(
      tester,
      cardId: cardId,
      widthCase: CardWidthCase(
        screenWidth: 1440,
        cardWidth: 456,
        columnSpan: 6,
        label: 'wide',
      ),
      cardHeightRows: 4,
      tabIndex: tabIndex,
      locale: locale,
      // Pinned for the same reason `dashboard_legend_readability_test` pins it:
      // a card with a `normalAbove` must be measured in the form that has a
      // legend, and which width selects which form is another file's question.
      density: CardDensity.normal,
    );
    return entries(tester);
  }

  /// The rows #1245 migrated, as (card, tab, how many entries that tab renders).
  ///
  /// The counts are asserted, not just the behaviour: an entry that silently
  /// disappears leaves a coloured series on the chart with nothing naming it, and
  /// a legend that lost its mapping has lost its purpose. Where a tab's entry
  /// count is data-dependent it is recorded as null and only non-emptiness is
  /// checked — `device_analytics` Signal emits one entry per signal level that
  /// has clients, which is a property of the fixture rather than of the card.
  const rows = <(String, int, int?)>[
    ('system_status', 0, 2), // Monitor — gauges, composed 'CPU: 47%'
    ('system_status', 1, 2), // Trends — composed 'Avg: 42%  Peak: 87%'
    ('system_status', 2, 1), // Distribution — composed sample count
    ('system_status', 3, 2), // Correlation — bare series names
    ('traffic_analysis', 0, 2), // Monitor — bare 'Upload' / 'Download'
    ('traffic_analysis', 1, 2), // Comparison — composed 'WAN: 1.2 MB/s'
    ('traffic_analysis', 2, 2), // Distribution — composed byte totals
    ('traffic_analysis', 3, 2), // Trends — bare unit names
    ('network_health', 1, 2), // Errors — composed avg/peak
    ('network_health', 2, 1), // Loss — composed avg/peak
    ('wifi_performance', 0, 4), // Signal — four bare tier names
    ('wifi_performance', 1, 2), // Speed — bare 'Downlink' / 'Uplink'
    ('device_analytics', 1, null), // Signal — one per populated level
  ];

  group('a legend entry\'s behaviour follows its label kind (#1245 AC 3)', () {
    // Three locales, not one: 'de' and 'ru' are where the strings are longest
    // and therefore where the behaviour actually fires, and 'en' is the reading
    // most reviewers check against.
    for (final tag in ['en', 'de', 'ru']) {
      for (final (cardId, tabIndex, expected) in rows) {
        testWidgets('$cardId tab $tabIndex in $tag', (tester) async {
          final found = await pumpLegend(
            tester,
            cardId: cardId,
            tabIndex: tabIndex,
            locale: _localeFor(tag),
          );

          expect(found, isNotEmpty,
              reason: '$cardId tab $tabIndex renders no AppChartLegendEntry. '
                  'Either the legend was dropped, or the row went back to a '
                  'hand-rolled dot+label — #1245 removed the last copy of that '
                  'shape from this repo.');
          if (expected != null) {
            expect(found.length, expected,
                reason: 'expected $expected legend entries, found '
                    '${found.map((e) => e.label).toList()}. A dropped entry '
                    'leaves a series on the chart with nothing naming it.');
          }

          for (final entry in found) {
            final composed = _hasDigit(entry.label);
            expect(
              entry.labelBehavior,
              composed
                  ? ChartLegendLabelBehavior.wrap
                  : ChartLegendLabelBehavior.shorten,
              reason: composed
                  ? 'legend label "${entry.label}" has a value in it, so it '
                      'must use AppChartLegendEntry.statistic: shortening it '
                      'puts the ellipsis mid-number, and half a statistic '
                      'misinforms where a missing one does not (§2.10a '
                      'point 2).'
                  : 'legend label "${entry.label}" is a bare name, so it must '
                      'use AppChartLegendEntry.seriesName: the chart is already '
                      'colour-coded, so a clipped name still keys it, and '
                      'wrapping spends height the row may not have.',
            );
          }
        });
      }
    }
  });
}

/// Whether [label] carries a value the reader needs whole.
///
/// A digit is the signal, because that is what every composed label in these
/// five cards has and no bare series name does: they are localized names of
/// series, units and quality tiers ('Upload', 'Bytes/sec', 'Excellent'), while
/// the composed ones all interpolate a number ('CPU: 47%', 'WAN: 1.2 MB/s',
/// 'Errors  Avg: 0.02/s  Peak: 0.10/s').
///
/// Deliberately not a hardcoded list of the 13 rows: derived from the string, the
/// rule also covers a legend added to a sixth card, and it fails the day a bare
/// name grows a value without its entrance changing to match.
bool _hasDigit(String label) => RegExp(r'\d').hasMatch(label);

Locale _localeFor(String tag) =>
    AppLocalizations.supportedLocales.firstWhere((l) {
      final t = l.countryCode == null || l.countryCode!.isEmpty
          ? l.languageCode
          : '${l.languageCode}_${l.countryCode}';
      return t == tag;
    });
