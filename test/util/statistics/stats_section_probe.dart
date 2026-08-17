import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/fallback_font_resolver.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../overflow_probe.dart';

/// Shared overflow harness for the Statistics page's sections (#1270).
///
/// ## Why this file exists
///
/// #1226 (dashboard Traffic Analysis), #1252 (Statistics Traffic Monitor) and
/// #1258 (Statistics WiFi Channels) each measured the same layout shape, and each
/// grew its own copy of the same 40-line pump. By #1258 the copies were three
/// deep and `sectionWidthFor` was character-identical in two of them, so the rule
/// of three was met and #1270 folded them here.
///
/// The split against `overflow_probe.dart`: that file owns the *mechanism* (installing
/// the collector, parsing Flutter's report, settling). This file owns the
/// Statistics page's *geometry and scaffolding* — the margin arithmetic, the
/// theme+locale wiring `lib/app.dart` does, and the one-pump rule. It sits beside
/// `test/util/dashboard/dashboard_card_probe.dart`, which does the same job for
/// the dashboard grid, rather than inside `overflow_probe.dart`, so that a
/// dashboard test importing the mechanism does not also import the Statistics
/// page's layout facts.
///
/// The dashboard's own third copy of `overflowsAt`
/// (`usp_traffic_analysis_card_legend_test.dart`) is not migrated here: it pumps a
/// *card* through `probeCardOverflow`, not a section, so all it ever shared with
/// these two was the tolerance filter. That part is now [kOverflowTolerancePx].

/// The width a single Statistics section renders to on a [screenWidth] screen:
/// full content width minus the page margin on both edges. The section card's own
/// padding then reduces this further, exactly as in production.
///
/// The margin comes from ui_kit's own [AppLayoutConfig.margin] rather than a copy
/// of its breakpoint table: the Statistics page pads each section by
/// `context.layoutMargin` (`usp_statistics_view.dart:86`), which is that same
/// function. A local copy is correct only until ui_kit moves a breakpoint, and
/// then the tests measure the wrong widths and still pass.
double sectionWidthFor(double screenWidth) =>
    screenWidth - AppLayoutConfig.margin(screenWidth) * 2;

/// The narrow realizations of a Statistics section that matter.
///
/// The page is a single-column scroll list, so a section spans the full content
/// width:
///
/// - **1241px screen** — the D1 desktop-large pinch. The 200px page margins open
///   just above 1240px, so a 1241px screen yields a *narrower* section (841px)
///   than a 1240px one (1192px) — the same regime that broke the dashboard twin
///   (density design §D1).
/// - **905px tablet** — 32px margins, 841px section.
/// - **601px** — the tablet floor (32px margins), 537px section.
/// - **320px** — the framework's narrowest supported screen (density design
///   §2.3), 16px margins, 288px section. The production floor, and the absolute
///   worst case for these rows.
const narrowStatsScreens = <double>[1241.0, 905.0, 601.0, 320.0];

/// Built once per test process, not once per pump: `createLightTheme()` walks the
/// whole JSON config, and every call site wants the same base.
final _baseTheme = ThemeJsonConfig.defaultConfig().createLightTheme();

/// Testers that have already pumped in the current test — see the one-pump rule
/// in [probeSectionOverflow]. Entries are removed by the tester's own tearDown,
/// so this never grows beyond the tests running concurrently (one).
final _pumped = <WidgetTester>{};

/// Pumps [section] **once** at [screenWidth] with the section sized to the width
/// the page gives it, mirroring how it lays out inside the scrollable Statistics
/// tab, and returns the RenderFlex overflows beyond [tolerancePx].
///
/// [overrides] are the provider overrides the section's data comes from (e.g.
/// `statisticsOverrides(wifiData: ...)`); [sectionWidth] defaults to what the page
/// would give a section on that screen ([sectionWidthFor]), and the
/// degradation-guard tests pass an explicit narrower value to reach below the
/// production floor while keeping the screen — and therefore ui_kit's layout
/// regime — realistic.
///
/// ## One pump per call, and why this fails loudly instead of documenting it
///
/// Flutter reports a given `RenderFlex`'s overflow only once per render-object
/// lifetime. A second pump in the same test reuses the element tree, so a
/// genuinely overflowing width reads back **clean** — the failure mode that
/// #1258's own first measurement pass fell into, and the reason #1270 called it
/// out as the one behaviour the extraction must not lose. A shared helper makes
/// that trap cheaper to fall into, so calling this twice in one test is an error
/// rather than a caveat in a comment: measure a second width in a second
/// `testWidgets`.
Future<List<OverflowIncident>> probeSectionOverflow(
  WidgetTester tester, {
  required Widget section,
  required double screenWidth,
  required Locale locale,
  List<Override> overrides = const [],
  double? sectionWidth,
  double tolerancePx = kOverflowTolerancePx,
}) async {
  if (!_pumped.add(tester)) {
    fail('probeSectionOverflow was called twice in the same test. Flutter '
        'reports a RenderFlex overflow once per render-object lifetime, so the '
        'second call would read clean no matter how badly the section '
        'overflows. Split the second measurement into its own testWidgets.');
  }
  addTearDown(() => _pumped.remove(tester));

  final surface = Size(screenWidth, 900.0);
  final width = sectionWidth ?? sectionWidthFor(screenWidth);

  // A section wider than the viewport is not a wide section: the box that sizes
  // it lives inside the viewport, so Flutter clamps it to the screen and the
  // measurement is silently of some narrower width. #1258's geometry group asked
  // for 288 / 537 / 841px sections on a 320px screen and got 238 / 270 / 270 —
  // three cases, two layouts, and every name in the report wrong.
  if (width > screenWidth) {
    fail('probeSectionOverflow was asked for a ${width}px section on a '
        '${screenWidth}px screen, which the viewport would clamp to '
        '$screenWidth. Pass the screen the page really produces that section on '
        '(see narrowStatsScreens) instead of overriding sectionWidth, or keep '
        'the override below the screen width.');
  }

  // Same call as `lib/app.dart`, not a copy of its body — see #1285.
  final theme = FallbackFontResolver.withFallbackFont(_baseTheme, locale);

  return runWithOverflowCollection((sink) async {
    await tester.binding.setSurfaceSize(surface);
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
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
                child: SizedBox(width: width, child: section),
              ),
            ),
          ),
        ),
      ),
    );
    await settleIgnoringAnimations(tester);
    return sink.where((i) => i.pixels > tolerancePx).toList();
  });
}
