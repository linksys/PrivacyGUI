import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../overflow_probe.dart';
import 'kitchen_sink_overrides.dart';

/// Layout math + pump harness for driving a real dashboard card through the
/// [OverflowIncident] probe, keyed off the same registries the app uses:
///
/// * [UspWidgetSpecs.all]      — the card list + its grid constraints.
/// * [UspWidgetFactory]        — id → widget (so we never hand-instantiate).
/// * [cardTabIndexProvider]    — tab selection (so we sweep tabs without taps).
///
/// The point is fidelity + reusability: the pixel widths we test are the ones
/// the production grid actually produces (not a hardcoded slot size), and a new
/// card added to those registries is picked up automatically.
///
/// ## Why the geometry mirrors production exactly
///
/// The dashboard renders cards in a responsive grid whose column count and
/// margins change per breakpoint. A card's on-screen width is therefore a
/// function of **both** the screen width and the card's column span — the same
/// card spans a different pixel width on mobile vs desktop. Testing a single
/// hardcoded width (an earlier version used a fixed 70px slot) misses the
/// narrowest realizations, which is exactly where overflow happens. So the
/// constants and formulas below are copied from the real layout stack:
///
/// * Column count per breakpoint — `GridLayoutContext.currentMaxColumns`
///   (ui_kit `layout_extensions.dart`): 4 / 8 / 12.
/// * Page margin per breakpoint — `AppLayoutConfig.margin(width)`.
/// * Slot width — `UspSliverDashboardView._buildSliverDashboard`:
///   `(screenWidth − margin·2 − (cols−1)·AppSpacing.lg) / cols`.
/// * Card width for a span — `span·slot + (span−1)·AppSpacing.lg`, with the
///   span clamped to `[minColumns, min(maxColumns, cols)]` exactly as
///   `UspSliverDashboardView._handleResizeEnd` clamps it.

// --- Breakpoint constants (mirrors ui_kit AppLayoutConfig) -------------------

/// Grid inter-slot spacing used by `UspSliverDashboardView` as both
/// `crossAxisSpacing` and `mainAxisSpacing`. This is `AppSpacing.lg`, NOT the
/// responsive `layoutGutter` — the dashboard view hardcodes `AppSpacing.lg`.
const double kGridGutter = 16.0;

/// Fixed slot height of the dashboard grid, in logical pixels.
/// Mirrors `UspSliverDashboardView._slotHeight`.
const double kSlotHeight = 120.0;

/// Breakpoint thresholds from `AppLayoutConfig` (logical px).
const double _bpMobile = 600.0;
const double _bpTablet = 905.0;
const double _bpDesktop = 1240.0;
const double _bpDesktopLarge = 1440.0;
const double _bpDesktopXL = 1680.0;

/// Column count for a screen width — mirrors `currentMaxColumns`
/// (mobile 4 / tablet 8 / desktop 12).
int gridColumnsForWidth(double screenWidth) {
  if (screenWidth <= _bpMobile) return 4;
  if (screenWidth <= _bpTablet) return 8;
  return 12;
}

/// Page margin for a screen width — mirrors `AppLayoutConfig.margin`.
double gridMarginForWidth(double screenWidth) {
  if (screenWidth > _bpDesktopXL) return 352.0;
  if (screenWidth > _bpDesktopLarge) return 256.0;
  if (screenWidth > _bpDesktop) return 200.0;
  if (screenWidth > _bpTablet) return 24.0;
  if (screenWidth > _bpMobile) return 32.0;
  return 16.0;
}

/// Per-slot width at a given screen width — mirrors the `slotWidth` computation
/// in `UspSliverDashboardView._buildSliverDashboard`.
double gridSlotWidth(double screenWidth) {
  final cols = gridColumnsForWidth(screenWidth);
  final avail = screenWidth - gridMarginForWidth(screenWidth) * 2;
  return (avail - (cols - 1) * kGridGutter) / cols;
}

/// On-screen width of a card spanning [span] columns at [screenWidth]. The span
/// is clamped to the grid's column count, matching production (a card can't be
/// wider than the grid).
double cardWidthAt(double screenWidth, int span) {
  final cols = gridColumnsForWidth(screenWidth);
  final effective = span.clamp(1, cols);
  return effective * gridSlotWidth(screenWidth) + (effective - 1) * kGridGutter;
}

/// Logical height of a card that spans [rows] grid rows.
double dashboardCardHeight(int rows) =>
    rows * kSlotHeight + (rows - 1) * kGridGutter;

// --- Width cases -------------------------------------------------------------

/// One width the gate pumps a card at: the [cardWidth] it renders to, the
/// [screenWidth] that produces it (needed for cards that read `context.colWidth`
/// / `currentMaxColumns` internally), and a human [label] naming the span.
class CardWidthCase {
  final double screenWidth;
  final double cardWidth;

  /// Which spec column count this realizes ('min', 'preferred', 'max').
  final String label;

  const CardWidthCase({
    required this.screenWidth,
    required this.cardWidth,
    required this.label,
  });

  /// Rounded key for de-duplication and stable test names.
  String get widthKey => cardWidth.toStringAsFixed(0);
}

/// Screen widths scanned to find each span's **narrowest** realization. Covers
/// every (columns, margin) regime plus the band edges where the narrowest slot
/// occurs (e.g. 601 = first tablet width, still low margin ⇒ tightest slots).
const List<double> _scanScreens = [
  320,
  360,
  414,
  480,
  600,
  601,
  720,
  768,
  905,
  906,
  1024,
  1240,
  1241,
  1366,
  1440,
  1441,
  1680,
  1681,
  1920,
];

/// The [CardWidthCase]s to test [spec] at: the narrowest realization of each of
/// its min / preferred / max column spans, de-duplicated by resulting width.
///
/// WHY NARROWEST-PER-SPAN IS SUFFICIENT (measured, see #1183)
///   RenderFlex overflow on a card is **monotonic in width** (a wider card
///   never overflows more than a narrower one — verified across every card:
///   overflow strictly shrinks as width grows and, once clean, stays clean) and
///   **independent of height**. So for each span, the narrowest pixel width it
///   can reach across all breakpoints is its worst case; wider realizations of
///   the same span can't reveal anything new. Testing all breakpoints × spans
///   verbatim would be ~5× the tests for identical coverage.
List<CardWidthCase> widthCasesFor(WidgetSpec spec) {
  final c = spec.getConstraints(DisplayMode.normal);
  final spans = <String, int>{
    'min': c.minColumns,
    'preferred': c.preferredColumns,
    'max': c.maxColumns,
  };

  final byWidth = <String, CardWidthCase>{};
  for (final entry in spans.entries) {
    // Find the screen that makes this span narrowest.
    double? bestScreen;
    double bestWidth = double.infinity;
    for (final screen in _scanScreens) {
      final w = cardWidthAt(screen, entry.value);
      if (w < bestWidth) {
        bestWidth = w;
        bestScreen = screen;
      }
    }
    final wc = CardWidthCase(
      screenWidth: bestScreen!,
      cardWidth: bestWidth,
      label: entry.key,
    );
    // De-dup by rounded width; keep the first (min-labelled) if identical.
    byWidth.putIfAbsent(wc.widthKey, () => wc);
  }
  return byWidth.values.toList();
}

// --- Tab registry ------------------------------------------------------------

/// Number of tabs each tabbed card exposes. Non-listed cards are single-view
/// (one "tab", index 0). Sourced from each card's `DashboardCardTemplate.tabbed`
/// definition and **validated at runtime** by `tab count matches registry` in
/// the gate — if a card gains/loses a tab, that meta-test fails and points here.
const Map<String, int> kTabbedCardTabCounts = {
  'firewall_overview': 2,
  'network_health': 3,
  'wifi_performance': 3,
  'device_analytics': 4,
  'system_status': 4,
  'traffic_analysis': 4,
};

/// Tab count the gate will sweep for [cardId] (1 for single-view cards).
int tabCountFor(String cardId) => kTabbedCardTabCounts[cardId] ?? 1;

/// Number of tabs the currently-pumped card exposes, discovered from [AppTabs].
/// Used by the runtime-validation meta-test to catch drift from
/// [kTabbedCardTabCounts].
int visibleTabCount(WidgetTester tester) {
  final finder = find.byType(AppTabs);
  if (finder.evaluate().isEmpty) return 1;
  return tester.widget<AppTabs>(finder.first).tabs.length;
}

// --- Pump harness ------------------------------------------------------------

/// Builds a MaterialApp hosting a single dashboard card the way production does:
/// the app is sized to a real [screenWidth] (so cards that read
/// `context.colWidth` / `currentMaxColumns` compute correctly), and the card is
/// placed in a `SizedBox` of its grid-computed [cardWidth] × [cardHeight]. The
/// requested [tabIndex] is pinned via [cardTabIndexProvider] so tabbed cards
/// render the tab we want without a geometric tap (long localized labels make
/// taps flaky).
Widget buildDashboardCardApp({
  required String cardId,
  required Locale locale,
  required double screenWidth,
  required double cardWidth,
  required double cardHeight,
  int tabIndex = 0,
}) {
  final card = UspWidgetFactory().buildWidget(cardId);
  if (card == null) {
    throw StateError(
      'UspWidgetFactory has no widget for id "$cardId". '
      'Every UspWidgetSpecs.all entry must map to a widget.',
    );
  }

  final theme = ThemeJsonConfig.defaultConfig().createLightTheme();

  return ProviderScope(
    overrides: [
      ...kitchenSinkOverrides(),
      cardTabIndexProvider(cardId).overrideWith((ref) => tabIndex),
    ],
    child: Portal(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme,
        // Freeze looping/entrance animations so charts settle to a static frame.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          // Top-left align + scroll view: the card gets its exact grid width and
          // height, and any excess vertical content extends instead of clipping
          // (we hunt horizontal overflow; height is generous, see maxHeightRows).
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: card,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pumps [cardId] once at one [widthCase] / [tabIndex] / [locale] and returns
/// the RenderFlex overflows from that single render.
///
/// ## One pump per call — deliberately
///
/// Flutter reports a given RenderFlex's overflow only **once per render-object
/// lifetime**; re-pumping in the same test reuses the render objects and
/// silently suppresses subsequent overflows (verified — a re-pump after a clean
/// width reports the next overflowing width as clean). So the gate never sweeps
/// multiple widths/tabs in one test: each (card, width, tab, locale) is its own
/// `testWidgets`, giving every measurement a fresh tree. This function does the
/// single pump for one such test.
Future<List<OverflowIncident>> probeCardOverflow(
  WidgetTester tester, {
  required String cardId,
  required CardWidthCase widthCase,
  required int cardHeightRows,
  required int tabIndex,
  required Locale locale,
}) {
  final surface =
      Size(widthCase.screenWidth, dashboardCardHeight(cardHeightRows));
  return runWithOverflowCollection((sink) async {
    await tester.binding.setSurfaceSize(surface);
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      buildDashboardCardApp(
        cardId: cardId,
        locale: locale,
        screenWidth: widthCase.screenWidth,
        cardWidth: widthCase.cardWidth,
        cardHeight: dashboardCardHeight(cardHeightRows),
        tabIndex: tabIndex,
      ),
    );
    await settleIgnoringAnimations(tester);
    return sink;
  });
}
