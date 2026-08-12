@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/fallback_font_resolver.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_traffic_monitor_section.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../golden_test/golden_framework/mocks/mock_dashboard_cards.dart';
import '../../../../golden_test/page/dashboard/cards/fixtures/cards_test_data.dart';
import '../../../../util/app_test_fonts.dart';
import '../../../../util/overflow_probe.dart';

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
/// Tagged `dashboard-card` so it gates PRs — `run_tests.sh` excludes
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

  /// The width a single Statistics section renders to on a [screenWidth] screen:
  /// full content width minus the page margin on both edges. The section card's
  /// own padding then reduces this further, exactly as in production.
  ///
  /// The margin comes from ui_kit's own [AppLayoutConfig.margin] rather than a
  /// copy of its breakpoint table: the Statistics page pads each section by
  /// `context.layoutMargin` (`usp_statistics_view.dart:86`), which is that same
  /// function. A local copy is correct only until ui_kit moves a breakpoint, and
  /// then this test measures the wrong widths and still passes.
  double sectionWidthFor(double screenWidth) =>
      screenWidth - AppLayoutConfig.margin(screenWidth) * 2;

  final baseTheme = ThemeJsonConfig.defaultConfig().createLightTheme();

  /// Pumps the real [StatsTrafficMonitorSection] once at [screenWidth] with the
  /// section sized to the width the page gives it, mirroring how the section
  /// lays out inside the scrollable Statistics tab, and returns the RenderFlex
  /// overflows beyond a 2px tolerance (the gate's own tolerance).
  ///
  /// One pump per call: Flutter reports a given RenderFlex's overflow only once
  /// per render-object lifetime, so a second pump in the same test would report
  /// a genuinely overflowing width as clean.
  Future<List<OverflowIncident>> overflowsAt({
    required WidgetTester tester,
    required double screenWidth,
    required Locale locale,
  }) async {
    final surface = Size(screenWidth, 900.0);
    final sectionWidth = sectionWidthFor(screenWidth);

    var theme = baseTheme;
    final cjkFallback = FallbackFontResolver.prefixedFallbackFor(locale);
    if (cjkFallback != null) {
      theme = theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamilyFallback: cjkFallback),
      );
    }

    return runWithOverflowCollection((sink) async {
      await tester.binding.setSurfaceSize(surface);
      tester.view.physicalSize = surface;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: cardOverrides(
            trafficAnalysisState: testTrafficWithHistory,
          ),
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: sectionWidth,
                    child: const StatsTrafficMonitorSection(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await settleIgnoringAnimations(tester);
      return sink.where((i) => i.pixels > 2.0).toList();
    });
  }

  /// The Statistics page is a single-column scroll list, so a section spans the
  /// full content width. These are the narrow realizations that matter:
  ///
  /// - 1241px screen: the D1 desktop-large pinch. The 200px page margins open
  ///   just above 1240px, so a 1241px screen yields a *narrower* section
  ///   (841px) than a 1240px one (1192px) — the same regime that broke the
  ///   dashboard twin (density design §D1).
  /// - 905px tablet: 32px margins, 841px section.
  /// - 601px: the tablet floor (32px margins), 537px section.
  /// - 320px: the framework's narrowest supported screen (density design §2.3),
  ///   16px margins, 288px section — the absolute worst case for this row.
  const narrowScreens = <double>[1241.0, 905.0, 601.0, 320.0];

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
