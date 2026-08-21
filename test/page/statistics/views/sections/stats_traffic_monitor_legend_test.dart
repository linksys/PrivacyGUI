@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_traffic_monitor_section.dart';

import '../../../../golden_test/golden_framework/mocks/mock_dashboard_cards.dart';
import '../../../../golden_test/page/dashboard/cards/fixtures/cards_test_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/overflow_probe.dart';
import '../../../../util/statistics/stats_section_probe.dart';

/// Overflow tests for the Statistics-page Traffic Monitor legend row (#1252).
///
/// ## Why this file exists
///
/// `StatsTrafficMonitorSection`'s legend is a near-duplicate of the dashboard
/// Traffic Analysis Monitor legend that #1226 fixed
/// (`usp_traffic_analysis_card.dart`): two dot+label pairs, then two byte
/// totals, laid out with a `Row` + `Spacer`. `Spacer` is an `Expanded`, so it
/// absorbs slack while the content fits and collapses to zero when it does not,
/// at which point the unconstrained content takes its full intrinsic width and
/// overflows on the right.
///
/// Unlike the dashboard card, this section is **not** in `UspWidgetSpecs.all`,
/// so the #1183 overflow gate never scans it — there is no ratchet entry and no
/// gate failure. This is prophylactic work justified by the #1226 measurement
/// of the identical shape. The AC is therefore a measurement of the row itself,
/// not "N gate coordinates removed": these tests pin the chosen shape (`Wrap`
/// with `spaceBetween`) clean at the narrow widths the Statistics page produces,
/// in the widest locales, and verify the byte totals are never dropped.
///
/// Tagged `layout-gate` so it gates PRs — `run_tests.sh` excludes
/// `golden||loc||ui`, and a `ui`-tagged regression test would not block anything.
///
/// ## Mutation ledger
///
/// Every group here was shown to fail under a mutation of the code it guards —
/// an overflow test that cannot fail is worse than no test, because it reports
/// the shape as pinned (precedent: `dashboard_legend_readability_test.dart`).
///
///   | mutation                                       | what failed              |
///   |------------------------------------------------|--------------------------|
///   | `Wrap` reverted to the pre-fix `Row` + `Spacer` | no overflow @288px (4)   |
///   | totals wrapped in `Flexible` + 1-line ellipsis  | totals legible (2)       |
///   | totals wrapped in `Flexible` only               | totals legible (2)       |
///   | both totals replaced by `SizedBox.shrink()`     | totals legible (2)       |
///
/// The pre-fix mutation leaves the totals group green, which is correct: under
/// `Row` + `Spacer` the totals are still whole and unflexed, they merely
/// overflow — that is the other group's job. The two groups are independent.
void main() {
  setUpAll(() async {
    // Real fonts: text widths — and therefore overflow — are meaningless under
    // the Ahem block font.
    await loadAppFonts();
  });

  /// Pumps the real [StatsTrafficMonitorSection] once at [screenWidth] with the
  /// section sized to the width the page gives it, and returns the RenderFlex
  /// overflows beyond the gate's own tolerance.
  ///
  /// The scaffolding — margin arithmetic, `lib/app.dart`'s theme+locale wiring,
  /// the one-pump rule — is [probeSectionOverflow] since #1270; this wrapper only
  /// binds this file's section and its fixture, so every call below is unchanged.
  Future<List<OverflowIncident>> overflowsAt({
    required WidgetTester tester,
    required double screenWidth,
    required Locale locale,
  }) =>
      probeSectionOverflow(
        tester,
        section: const StatsTrafficMonitorSection(),
        screenWidth: screenWidth,
        locale: locale,
        overrides: cardOverrides(
          trafficAnalysisState: testTrafficWithHistory,
        ),
      );

  /// The narrow realizations that matter, and why — see [narrowStatsScreens].
  /// 320px yields the 288px section that is this row's absolute worst case.
  const narrowScreens = narrowStatsScreens;

  group('legend + totals row is clean (#1252)', () {
    // The widest upload/download locales measured for the #1226 twin: `fr`
    // ("Téléchargement"/"Téléversement"), plus de/fi/ru which were worst at the
    // narrowest realization. If the row is clean in English but not in these,
    // the fix relies on English being short.
    for (final tag in ['fr', 'de', 'fi', 'ru']) {
      for (final screen in narrowScreens) {
        testWidgets(
          'no overflow at ${sectionWidthFor(screen).toStringAsFixed(0)}px '
          'section (${screen.toStringAsFixed(0)}px screen) in $tag',
          (tester) async {
            final locale = AppLocalizations.supportedLocales.firstWhere((l) {
              final t = l.countryCode == null || l.countryCode!.isEmpty
                  ? l.languageCode
                  : '${l.languageCode}_${l.countryCode}';
              return t == tag;
            });
            final overflows = await overflowsAt(
              tester: tester,
              screenWidth: screen,
              locale: locale,
            );
            expect(
              overflows,
              isEmpty,
              reason: 'Traffic Monitor legend overflows in $tag at a '
                  '${screen.toStringAsFixed(0)}px screen '
                  '(${sectionWidthFor(screen).toStringAsFixed(0)}px section): '
                  '${overflows.join(', ')}',
            );
          },
        );
      }
    }
  });

  group('byte totals stay legible (#1252)', () {
    // The legend keys a chart that is already colour-coded, so a clipped legend
    // label still communicates. The byte totals are the section's content: an
    // ellipsis lands mid-number, and a half-shown statistic misinforms in a way
    // a missing one does not (§2.10a point 2). So the AC is not "the totals are
    // somewhere in the tree" — it is that they are present, unellipsized, and
    // not flex children that could shrink.
    //
    // Located by their exact formatted values, derived from the same fixture the
    // widget renders. A substring test cannot work here: `_formatSpeed` uses
    // `['B/s', 'KB/s', 'MB/s', 'GB/s']`, so the two speed tiles above the chart
    // and every y-axis label also contain a `B`, and a `contains('B')` count
    // stays satisfied even with both totals deleted.
    /// The formatted totals the widget must render, read from the same fixture
    /// it is pumped with.
    ///
    /// Resolved inside each test rather than at group level: a fixture that
    /// stopped carrying a `wan` snapshot would make the lookup throw while the
    /// group body is still being built, which reports as a load failure for the
    /// whole file instead of naming the fixture. Loud either way, but only one of
    /// the two says what to fix.
    String totalFor(String kind) {
      final wan =
          testTrafficWithHistory.history.last.interfaces[TrafficInterface.wan];
      expect(
        wan,
        isNotNull,
        reason:
            'testTrafficWithHistory must carry a wan snapshot — the section '
            'renders totals only when it does, so without one these tests would '
            'assert against a legend that never had any',
      );
      final bytes =
          kind == 'sent' ? wan!.totalBytesSent : wan!.totalBytesReceived;
      return UspFormatters.formatBytes(bytes);
    }

    /// True if a [Flexible] (or [Expanded], its subclass) sits between the total
    /// and the legend [Wrap] — i.e. the total can be squeezed below its
    /// intrinsic width.
    bool canShrink(Finder totalFinder) {
      var flexed = false;
      totalFinder.evaluate().single.visitAncestorElements((ancestor) {
        // Stop at the `Wrap`: it is the layout that decides this total's width,
        // so a `Flexible` above it constrains the whole legend row, not the
        // total within the row. Reaching the `Wrap` means "nothing between here
        // and the layout can squeeze it", which is the property under test — not
        // "not found yet".
        if (ancestor.widget is Wrap) return false;
        if (ancestor.widget is Flexible) {
          flexed = true;
          return false;
        }
        return true;
      });
      return flexed;
    }

    for (final kind in ['sent', 'received']) {
      testWidgets(
        'the $kind total is whole and unshrinkable at the narrowest width',
        (tester) async {
          final expected = totalFor(kind);
          await overflowsAt(
            tester: tester,
            screenWidth: 320.0,
            locale: const Locale('de'),
          );

          final finder = find.text(expected);
          expect(
            finder,
            findsOneWidget,
            reason: 'the $kind byte total ($expected) must survive '
                'the degradation — the `Wrap` moves it to a second line, it may '
                'not discard it',
          );

          final text = tester.widget<Text>(finder);
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason: 'the $kind total must never ellipsize: an ellipsis '
                'lands mid-number',
          );
          expect(
            text.maxLines,
            isNull,
            reason: 'the $kind total must not be line-capped',
          );
          expect(
            canShrink(finder),
            isFalse,
            reason: 'the $kind total must not be a flex child — it keeps '
                'its intrinsic width and the whole totals group wraps instead',
          );
        },
      );
    }
  });
}
