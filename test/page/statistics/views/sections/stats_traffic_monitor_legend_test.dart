@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/fallback_font_resolver.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_traffic_monitor_section.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

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
void main() {
  setUpAll(() async {
    // Real fonts: text widths — and therefore overflow — are meaningless under
    // the Ahem block font.
    await loadAppFonts();
  });

  /// The page margin `AppLayoutConfig.margin(width)` applies at each breakpoint.
  /// Mirrors ui_kit `app_layout_config.dart`; the Statistics page pads each
  /// section by `context.layoutMargin` on both edges
  /// (`usp_statistics_view.dart:86`).
  double pageMarginFor(double screenWidth) {
    if (screenWidth > 1680) return 352.0;
    if (screenWidth > 1440) return 256.0;
    if (screenWidth > 1240) return 200.0; // D1: the big-margin regime.
    if (screenWidth > 905) return 24.0;
    if (screenWidth > 600) return 32.0;
    return 16.0;
  }

  /// The width a single Statistics section renders to on a [screenWidth] screen:
  /// full content width minus the page margin on both edges. The section card's
  /// own padding then reduces this further, exactly as in production.
  double sectionWidthFor(double screenWidth) =>
      screenWidth - pageMarginFor(screenWidth) * 2;

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
    testWidgets('both totals are still rendered at the narrowest width',
        (tester) async {
      // The legend is a key to the chart, but the byte totals are the section's
      // actual content — degrading the layout must not drop them. The `Wrap`
      // moves them to a second line; it must not clip or discard them.
      await overflowsAt(
        tester: tester,
        screenWidth: 320.0,
        locale: const Locale('de'),
      );

      // The two totals are formatted byte counts; find them by the AppIcon
      // arrows that precede each so the assertion does not depend on the exact
      // formatted value. testTrafficWithHistory carries a non-null WAN snapshot,
      // so both totals must be present.
      final texts = find.byType(Text).evaluate().map((e) {
        final w = e.widget as Text;
        return w.data ?? w.textSpan?.toPlainText() ?? '';
      }).toList();
      final byteTotals = texts.where((t) => t.contains('B')).toList();
      expect(
        byteTotals.length,
        greaterThanOrEqualTo(2),
        reason: 'both byte totals (sent + received) must survive degradation — '
            'they are content, not chrome. Found: $texts',
      );
    });
  });
}
