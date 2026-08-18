import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/providers/card_density_provider.dart';
import 'package:privacy_gui/page/_shared/providers/card_tab_state_provider.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/views/usp_sliver_dashboard_view.dart';
import 'package:privacy_gui/localization/fallback_font_resolver.dart';
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
/// geometry below is taken from the real layout stack — read from it where the
/// value is reachable without a `BuildContext`, and pinned against it by
/// `dashboard_card_probe_geometry_test.dart` where it is not:
///
/// * Column count per breakpoint — `GridLayoutContext.currentMaxColumns`
///   (ui_kit `layout_extensions.dart`): 4 / 8 / 12. **Pinned**, not read: the
///   getter needs a context.
/// * Page margin per breakpoint — `AppLayoutConfig.margin(width)`, called.
/// * Slot width — `UspSliverDashboardView._buildSliverDashboard`:
///   `(screenWidth − margin·2 − (cols−1)·AppSpacing.lg) / cols`.
/// * Card width for a span — `span·slot + (span−1)·AppSpacing.lg`, with the
///   span clamped to `[minColumns, min(maxColumns, cols)]` exactly as
///   `UspSliverDashboardView._handleResizeEnd` clamps it.

// --- Grid geometry (references production, never copies it) ------------------
//
// Every number below is read from the layout stack rather than restated here.
// An earlier revision restated the five breakpoints and the six margin steps as
// local constants, which made a silent drift possible in exactly one direction:
// production moves a breakpoint, the gate keeps measuring the old regime and
// stays green (#1248 review W-4). What cannot be referenced — the 4/8/12 column
// mapping, which production only exposes through a `BuildContext` — is pinned
// against the real getter by `dashboard_card_probe_geometry_test.dart`.

/// Grid inter-slot spacing used by `UspSliverDashboardView` as both
/// `crossAxisSpacing` and `mainAxisSpacing`. This is `AppSpacing.lg`, NOT the
/// responsive `layoutGutter` — the dashboard view hardcodes `AppSpacing.lg`.
const double kGridGutter = AppSpacing.lg;

/// Fixed slot height of the dashboard grid, in logical pixels.
const double kSlotHeight = UspSliverDashboardView.slotHeight;

/// Column count for a screen width — mirrors `GridLayoutContext.currentMaxColumns`
/// (`responsive<int>(mobile: 4, tablet: 8, desktop: AppLayoutConfig.maxColumns)`).
///
/// The one replica left in this file: production resolves it off a
/// `BuildContext`, and the gate computes widths without pumping anything. The
/// thresholds come from `AppLayoutConfig`, and the mapping itself is pinned
/// against `context.currentMaxColumns` by the geometry guard test.
int gridColumnsForWidth(double screenWidth) {
  if (AppLayoutConfig.isMobileWidth(screenWidth)) return 4;
  if (AppLayoutConfig.isTabletWidth(screenWidth)) return 8;
  return AppLayoutConfig.maxColumns;
}

/// Page margin for a screen width — production's own function, so the six
/// margin steps and the breakpoints they hang off are read, not restated.
double gridMarginForWidth(double screenWidth) =>
    AppLayoutConfig.margin(screenWidth);

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
  final int columnSpan;

  /// Which spec column count this realizes ('min', 'preferred', 'max').
  final String label;

  const CardWidthCase({
    required this.screenWidth,
    required this.cardWidth,
    required this.columnSpan,
    required this.label,
  });

  /// Rounded key for screen width.
  String get screenKey => screenWidth.toStringAsFixed(0);

  /// Rounded key for de-duplication and stable test names.
  String get widthKey => cardWidth.toStringAsFixed(0);
}

/// Minimum screen width filter parsed from external --dart-define or env var
/// (`MIN_SCREEN=400` or `min_screen=400`).
double get minScreenFilter {
  const d = String.fromEnvironment('MIN_SCREEN', defaultValue: '');
  if (d.isNotEmpty) return double.tryParse(d) ?? 0.0;

  const d2 = String.fromEnvironment('min_screen', defaultValue: '');
  if (d2.isNotEmpty) return double.tryParse(d2) ?? 0.0;

  final env = Platform.environment;
  final e = env['MIN_SCREEN'] ?? env['min_screen'];
  if (e != null && e.isNotEmpty) return double.tryParse(e) ?? 0.0;

  return 0.0;
}

/// Narrowest screen width the framework commits to supporting, in logical px.
///
/// **This is a product decision, not a geometric one** (density design §2.3).
/// Geometry alone permits narrower cards — a 240px screen yields a 152px
/// 3-column card — but no shipping device is that narrow, and designing every
/// card to survive a width no user has is not worth the cost. So the framework
/// declares 320px as its floor and the narrowest card width follows from it.
///
/// Lowering this **moves the gate's baseline**: narrower cards overflow more, so
/// entries would have to be added to `test/fixtures/known_overflows.json`.
/// Revisit only if narrower targets appear (automotive head units, embedded
/// panels), and re-baseline deliberately when you do.
const double kMinSupportedScreenWidth = 320.0;

/// Upper bound of the enumerated screen-width range, in logical px.
///
/// Not a supported-hardware limit — just where enumeration can stop. Above the
/// last margin breakpoint (1680px) the (columns, margin) regime never changes
/// again, so card width grows monotonically with screen width and no wider
/// screen can be any span's narrowest realization. 2560px (5K half-width) is
/// comfortably past that edge.
const double kMaxScannedScreenWidth = 2560.0;

/// How far the enumerated narrowest width can sit *above* the true continuum
/// infimum, in logical px. See [narrowestRealizationOf] — the bound is 0.5px,
/// which is a quarter of the gate's 2.0px overflow tolerance, so it cannot flip
/// a verdict.
const double kEnumerationSlackPx = 0.5;

/// The narrowest realization of a [span] over integer screen widths in the
/// supported range: the smallest card width the grid produces for it, and the
/// screen width that produces it. Null when [minScreen] is above
/// [kMaxScannedScreenWidth], i.e. the range holds no realization at all.
///
/// ## Why enumerate instead of sampling
///
/// The gate pumps one width per span and claims that is exhaustive, because
/// overflow is monotonic in width — so the *narrowest* realization is the worst
/// case. That argument is only sound if the width really is the narrowest. This
/// used to be found by scanning a hand-written list of 19 screen widths, which
/// made the invariant an assertion rather than a guarantee: the list happened to
/// contain each span's true minimum, but nothing enforced that, and it was
/// demonstrably lossy once [minScreen] excluded the widths it did contain (a
/// floor of 602px sent a 3-column span to 198.25px, 6.5px wide of the real
/// 191.75px). Enumerating the range makes the invariant hold by construction
/// (#1225).
///
/// ## What the enumeration guarantees — and the 0.5px it does not
///
/// Card width is piecewise-linear and *increasing* in screen width within each
/// (columns, margin) regime, so each regime's narrowest width is at its left
/// edge. Enumerating every integer from the floor up — plus the floor itself,
/// which is the left edge of whichever regime it lands in — therefore evaluates
/// every regime. A coarser step would not: a 3px step from 320 lands on 602 and
/// reports a 3-column card as 191.75px instead of 191.375px.
///
/// But the breakpoints are **exclusive** (`screenWidth <= 600` is still 4
/// columns), so four regimes open just *above* an integer and their infimum is
/// approached rather than attained: a 3-column card tends to 191.0px as the
/// screen tends down to 600px, while the narrowest integer width is 191.375px @
/// 601px. The enumeration is therefore exact over integer screen widths and
/// within [kEnumerationSlackPx] (0.5px, worst case span 4) of the continuum
/// infimum. Fractional logical widths do occur in production
/// (1080 / 2.75 = 392.7), so this is a real if tiny gap — bounded well inside
/// the gate's 2.0px tolerance, and pinned by a test.
({double screenWidth, double cardWidth})? narrowestRealizationOf(
  int span, {
  double? minScreen,
}) {
  final floor =
      math.max(minScreen ?? minScreenFilter, kMinSupportedScreenWidth);
  if (floor > kMaxScannedScreenWidth) return null;

  var bestScreen = floor;
  var bestWidth = cardWidthAt(floor, span);
  for (var screen = floor.ceilToDouble();
      screen <= kMaxScannedScreenWidth;
      screen += 1.0) {
    final width = cardWidthAt(screen, span);
    if (width < bestWidth) {
      bestWidth = width;
      bestScreen = screen;
    }
  }
  return (screenWidth: bestScreen, cardWidth: bestWidth);
}

/// The [CardWidthCase]s to test [spec] at: the narrowest realization of each of
/// its min / preferred / max column spans, de-duplicated by resulting width.
List<CardWidthCase> widthCasesFor(WidgetSpec spec, {double? minScreen}) {
  final floor = minScreen ?? minScreenFilter;

  final c = spec.getConstraints(DisplayMode.normal);
  final spans = <String, int>{
    'min': c.minColumns,
    'preferred': c.preferredColumns,
    'max': c.maxColumns,
  };

  final byWidth = <String, CardWidthCase>{};
  for (final entry in spans.entries) {
    // Null means the floor is past the enumerated range, so no span has a
    // realization and the card gets no cases at all. Bailing out of the whole
    // loop (rather than skipping this span) is only sound because the floor is
    // the sole null cause and every span here shares the same floor — if one is
    // null they all are. Give `narrowestRealizationOf` a second null path and
    // this must become a `continue`, or spans will be dropped silently.
    final narrowest = narrowestRealizationOf(entry.value, minScreen: floor);
    if (narrowest == null) return [];
    final wc = CardWidthCase(
      screenWidth: narrowest.screenWidth,
      cardWidth: narrowest.cardWidth,
      columnSpan: entry.value,
      label: entry.key,
    );
    // De-dup by rounded width; keep the first (min-labelled) if identical.
    byWidth.putIfAbsent(wc.widthKey, () => wc);
  }
  return byWidth.values.toList();
}

/// A mainstream desktop realization of [spec] — the card's preferred span on a
/// 1440px screen.
///
/// The readability tests that accompany the #1183 gate all need one width the
/// card is *not* cramped at, because every narrow-width degradation they guard
/// has a second half: it must not fire where the card has room. The gate itself
/// only ever pumps narrowest realizations ([widthCasesFor]), so this width is
/// measured by nothing else.
///
/// Taken from the spec rather than hardcoded so a card whose preferred span
/// changes moves this with it (#1238).
CardWidthCase desktopCaseFor(WidgetSpec spec, {double screenWidth = 1440}) {
  final span = spec.getConstraints(DisplayMode.normal).preferredColumns;
  return CardWidthCase(
    screenWidth: screenWidth,
    cardWidth: cardWidthAt(screenWidth, span),
    columnSpan: span,
    label: 'desktop',
  );
}

/// Every [LayoutBlock] in the pumped tree, in paint order.
///
/// [LayoutBlock] is the app's card-section container, so on most cards this is
/// "the sections", and their rects are what an arrangement assertion (stacked vs
/// side by side) is made of.
List<Rect> layoutBlockRects(WidgetTester tester) {
  final finder = find.byType(LayoutBlock);
  return [
    for (var i = 0; i < finder.evaluate().length; i++)
      tester.getRect(finder.at(i)),
  ];
}

/// The pumped card's own content viewport — the rect of the vertical
/// `SingleChildScrollView` inside [AppCard].
///
/// Use this — not the content column's own bottom — when asking whether
/// something is *visible*: `DashboardCardTemplate` scrolls, so a section can sit
/// below the viewport while overflowing nothing, which is precisely the failure
/// the gate cannot see.
///
/// ## Why it is identified this way
///
/// This used to be "the shorter of the two scroll views in the tree", asserting a
/// count of exactly two — the pump harness's page-level one plus the card's. That
/// held only while tabbed cards did not scroll their content. Since #1267 the WiFi
/// Performance Channels tab does, and a tabbed card also carries a *horizontal*
/// scroll view for its tab strip (`AppTabs(isScrollable: true)`), so the count is
/// three and "the shortest" would have picked the tab strip — a ~40px rect at the
/// top of the card, against which every "is it visible" assertion fails for the
/// wrong reason.
///
/// Scoping to [AppCard] drops the harness's, and the axis filter drops the tab
/// strip's. The result is still asserted to be exactly one rather than assumed:
/// picking from an empty finder would return [Rect.largest] and every visibility
/// assertion would pass against an infinite viewport — a silently green test,
/// which is the failure mode worth being loud about.
Rect cardContentViewport(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(AppCard),
    matching: find.byType(SingleChildScrollView),
  );
  final rects = <Rect>[];
  for (var i = 0; i < finder.evaluate().length; i++) {
    final scrollView = finder.at(i);
    final state = tester.state<ScrollableState>(
      find.descendant(of: scrollView, matching: find.byType(Scrollable)),
    );
    if (state.position.axis != Axis.vertical) continue;
    rects.add(tester.getRect(scrollView));
  }

  expect(
    rects,
    hasLength(1),
    reason: 'expected exactly one vertical scroll view inside the card — its '
        'content region. Found ${rects.length}, so this no longer identifies '
        'the card\'s own viewport and these measurements are meaningless.',
  );
  return rects.single;
}

/// How far the pumped card's content exceeds its own viewport, in logical px —
/// 0.0 when it fits, and `null` when the card has no scrolling content region.
///
/// ## Why this number has to be asserted somewhere
///
/// A scrolling region cannot report a RenderFlex bottom overflow, because there
/// is no flex being overflowed: the content simply gets taller and the viewport
/// scrolls. That is the point of making the region scroll (#1267) — and it is also
/// how the defect that motivated it becomes *invisible* to the gate. The tri-band
/// Channels tab overflowed by `+9.0px` before, and now the same fixture reports
/// clean at every one of the 26 locales it is swept at.
///
/// So the two readings are not interchangeable, and green on the gate no longer
/// means "the content fits". Whichever test cares about that distinction has to
/// read this instead: > 0 means the user must scroll to see the rest, which is a
/// design decision when it is deliberate and a regression when it is not.
///
/// ## Scoped to the card's own region, on purpose
///
/// Only `SingleChildScrollView`s **inside** [AppCard] count, which excludes the
/// pump harness's page-level scroll view (an ancestor of the card, whose extent is
/// about the surface, not the card). It also excludes the Signal tab's
/// `ListView` — a card region that has always scrolled by design, and whose extent
/// would otherwise be reported here as if it were a shortfall.
///
/// ## `null` means "no vertical region", not "no scroll view at all" (#1296)
///
/// A tabbed card always carries one `SingleChildScrollView` inside [AppCard] — the
/// *horizontal* tab strip of `AppTabs(isScrollable: true)`. So an "is the finder
/// empty" test never fires on a tabbed card, and until #1296 this returned `0.0`
/// for a tabbed card with no scroll net at all: indistinguishable from a net that
/// is installed and whose content fits. Every `expect(shortfall, isNotNull)`
/// written against the documented contract was therefore vacuous on exactly the
/// six cards #1296 is about — it would have passed with the flag flipped back off.
/// The emptiness test has to be about the *vertical* regions that survive the axis
/// filter, which is what `sawVertical` tracks.
double? cardContentScrollShortfall(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(AppCard),
    matching: find.byType(SingleChildScrollView),
  );
  final states = tester.stateList<ScrollableState>(
    find.descendant(of: finder, matching: find.byType(Scrollable)),
  );

  var sawVertical = false;
  var worst = 0.0;
  for (final state in states) {
    final position = state.position;
    if (!position.hasContentDimensions) continue;
    if (position.axis != Axis.vertical) continue;
    sawVertical = true;
    worst = math.max(worst, position.maxScrollExtent);
  }
  return sawVertical ? worst : null;
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
///
/// [cardOverride] replaces the factory lookup with a hand-built card. The gate
/// itself must never pass it — going through the factory is what makes a renamed
/// or unregistered card fail loudly. It exists for the readability tests, which
/// need a *specific* row shape (a long device name, a 3-digit signal reading) and
/// cannot get one from the dashboard's kitchen-sink fixture. The card id is still
/// required, because everything else here — tab pinning, the spec-derived
/// geometry — is keyed off it.
///
/// [density] pins the card's [CardDensity] via [cardDensityOverrideProvider],
/// for the same reason [tabIndex] is pinned rather than tapped: the alternative
/// is contriving a width that happens to fall in the band you want, which
/// couples the test to whatever threshold the spec currently declares. Left
/// null, the card selects its own form from the width it is given — which is
/// what the gate's own sweep must keep doing, since that is the production path.
///
/// [extraOverrides] are appended after [kitchenSinkOverrides], so a provider
/// listed in both takes the value passed here (Riverpod resolves duplicates
/// last-wins — verified, not assumed). It exists for tests about *data* rather
/// than geometry: #1271 needs a client with no noise reading, and the kitchen
/// sink deliberately gives every client one.
///
/// The gate's own default sweep must never pass it: the whole point of one shared
/// fixture is that all 18 cards are measured against the same data. Its **named
/// second profiles** are the one exception, and they are declared in
/// `card_data_profiles.dart` rather than inline — a data profile the gate sweeps
/// is a ratchet dimension, not a test-local convenience (#1267).
Widget buildDashboardCardApp({
  required String cardId,
  required Locale locale,
  required double screenWidth,
  required double cardWidth,
  required double cardHeight,
  int tabIndex = 0,
  Key? repaintKey,
  Widget? cardOverride,
  CardDensity? density,
  List<Override> extraOverrides = const [],
}) {
  final card = cardOverride ?? UspWidgetFactory().buildWidget(cardId);
  if (card == null) {
    throw StateError(
      'UspWidgetFactory has no widget for id "$cardId". '
      'Every UspWidgetSpecs.all entry must map to a widget.',
    );
  }

  // Through the same function `lib/app.dart` uses, not a copy of its body: the
  // copy that used to live here reproduced #1285's double prefix, so the harness
  // measured the defect and could not have seen it fixed.
  final theme = FallbackFontResolver.withFallbackFont(
    ThemeJsonConfig.defaultConfig().createLightTheme(),
    locale,
  );

  return ProviderScope(
    overrides: [
      ...kitchenSinkOverrides(),
      cardTabIndexProvider(cardId).overrideWith((ref) => tabIndex),
      if (density != null)
        cardDensityOverrideProvider(cardId).overrideWith((ref) => density),
      ...extraOverrides,
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
              child: RepaintBoundary(
                key: repaintKey,
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
///
/// [cardOverride] is forwarded to [buildDashboardCardApp] — see there for when
/// passing it is legitimate and when it defeats the point.
///
/// [extraOverrides] is forwarded to [buildDashboardCardApp] — the gate's second
/// data profile (#1267) is passed here, and nothing else in the sweep may use it
/// (see there).
///
/// [after] runs once the card has settled, still inside the overflow collection.
/// It exists for interactions that are themselves layout events — #1239's popup
/// form opens the card's full form in a dialog, and an overflow raised while that
/// dialog lays out happens after this function would otherwise have returned, so
/// it would be reported with no handler installed and lost. It does not pump a
/// second widget tree, so the one-pump-per-test property above still holds: the
/// dialog's render objects are new, and the card's are untouched.
Future<List<OverflowIncident>> probeCardOverflow(
  WidgetTester tester, {
  required String cardId,
  required CardWidthCase widthCase,
  required int cardHeightRows,
  required int tabIndex,
  required Locale locale,
  Key? repaintKey,
  Widget? cardOverride,
  CardDensity? density,
  List<Override> extraOverrides = const [],
  Future<void> Function(WidgetTester tester)? after,
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
        repaintKey: repaintKey,
        cardOverride: cardOverride,
        density: density,
        extraOverrides: extraOverrides,
      ),
    );
    await settleIgnoringAnimations(tester);
    if (after != null) await after(tester);
    return sink;
  });
}

/// Saves the widget rendered under [repaintKey] to a PNG file at [path].
Future<void> saveCardScreenshot(
  WidgetTester tester,
  GlobalKey repaintKey,
  String path, {
  double pixelRatio = 2.0,
}) async {
  await tester.binding.runAsync(() async {
    try {
      final file = File(path);
      if (file.existsSync()) return;

      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        // ignore: avoid_print
        print('[PNG DUMP FAILED] boundary is null for $path');
        return;
      }
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        // ignore: avoid_print
        print(
            '[PNG DUMP SUCCESS] Saved $path (${byteData.lengthInBytes} bytes)');
      } else {
        // ignore: avoid_print
        print('[PNG DUMP FAILED] byteData is null for $path');
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[PNG DUMP EXCEPTION] Failed to save $path: $e\n$st');
    }
  });
}

/// Calculates the grid rows needed to fit a target logical height.
int calcRecommendedRows(double targetHeight) {
  int r = 1;
  while (dashboardCardHeight(r) < targetHeight && r < 10) {
    r++;
  }
  return r;
}

/// Re-pumps [cardId] at grid-calculated [recWidth] × [recHeight], saves an
/// adjusted screenshot to [path], and returns any remaining overflow incidents.
Future<List<OverflowIncident>> captureAdjustedCardScreenshot(
  WidgetTester tester, {
  required String cardId,
  required double screenWidth,
  required double recWidth,
  required double recHeight,
  required int tabIndex,
  required Locale locale,
  required String path,
}) async {
  final adjustKey = GlobalKey();
  final surface = Size(
    math.max(screenWidth, recWidth + 32),
    math.max(recHeight + 32, 400.0),
  );
  return runWithOverflowCollection((sink) async {
    await tester.binding.setSurfaceSize(surface);
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      buildDashboardCardApp(
        cardId: cardId,
        locale: locale,
        screenWidth: screenWidth,
        cardWidth: recWidth,
        cardHeight: recHeight,
        tabIndex: tabIndex,
        repaintKey: adjustKey,
      ),
    );
    await settleIgnoringAnimations(tester);
    await saveCardScreenshot(tester, adjustKey, path);
    return sink;
  });
}
