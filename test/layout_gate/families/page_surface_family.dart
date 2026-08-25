/// The page surface family: whole pages, on the shared runner (#1349).
///
/// The gate's third family, and the one the #1335 refactor was sequenced to make
/// possible — adding it to two frameworks would have produced three. It is a
/// **pilot**: two pages, whose deliverable is a per-cell cost number and the
/// decision that number supports (`doc/testing/overflow_gate_architecture.md` §8
/// and §10 Q5), not merely two green suites.
///
/// ## Why one class with two instances, where chrome has two classes
///
/// §3.2's recorded decision is "one family class per widget, not per suite", and
/// `ChromeTopBarFamily` / `ChromeHeaderFamily` are two classes because those two
/// widgets have **unrelated hosts and different axes**. Two pages do not: a page
/// is hosted exactly one way — the app's own route scaffolding, [pageSurfaceHost]
/// — and swept on exactly one axis, the screen width. What differs between
/// `page.dhcp` and `page.wifi_settings` is the route, the fixture and the premise,
/// which are *values*. So the shape is one family parameterised by a
/// [PageSurfaceCase], and each instance still carries its own [name] and its own
/// pinned cell count, which is what §3.2's decision is actually protecting
/// (a widget discriminator never becomes an axis).
///
/// Reversal cost, recorded per §10.1: split into one class per page and the two
/// `enumerateCells` bodies become copies of each other.
///
/// ## Overflow is **not** monotone in screen width here, and the reason is sharp
///
/// The second essential difference of §2. For a card it is monotone, so the
/// narrowest realization is the worst case; for chrome it is not, because the top
/// nav appears at 601px. For a **page** it is not monotone for a stronger reason:
/// `AppLayoutConfig.margin(width)` steps *up* at four breakpoints, so the content
/// box a page is granted gets **narrower as the screen gets wider**:
///
///   | screen | margin | content | note                                        |
///   |--------|--------|---------|---------------------------------------------|
///   | 320    | 16     | 288     | product floor, narrowest content overall    |
///   | 480    | 16     | 448     | golden CI's phone coordinate                |
///   | 600    | 16     | 568     | last width before the step                  |
///   | **601**| 32     | **537** | 31px *narrower* than 600px                  |
///   | 905    | 32     | 841     | last width of the tablet margin             |
///   | 906    | 24     | 858     | wider content again                         |
///   | 1240   | 24     | 1216    | widest content the app ever grants           |
///   | **1241**| 200   | **841** | 375px narrower than 1240px — the #1302 pinch |
///   | 1280   | 200    | 880     | golden CI's desktop coordinate              |
///   | **1441**| 256   | **929** | 111px narrower than 1440px                  |
///   | **1681**| 352   | **977** | 191px narrower than 1680px                  |
///
/// [kPageSweepWidths] is that table's four step-ups, its floor, and golden CI's
/// two coordinates — a literal list, because there is nothing to derive it from
/// and a derived "worst case" would be wrong four times over. #1302 measured the
/// 1241px pinch as the worst *desktop* case for the device-detail page (`fr`
/// +30px, against +20px at 1280px), which is the same arithmetic reaching a
/// different page.
///
/// Locale is a first-class axis for the same reason it is everywhere else in this
/// family: #1302's row was clean in `en` at every width it broke in `fr`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/fallback_font_resolver.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import '../sweep.dart';

/// Screen widths swept per locale — see the library header's table.
///
/// Eight, not twelve: every width here is either a margin step-up (the four the
/// content box narrows at), the product floor, or one of golden CI's two
/// coordinates, which are what make the `file:line` join of §8 comparable. A
/// ninth width would cost 26 cells per page and answer a question one of these
/// already answers.
const kPageSweepWidths = <double>[
  320, // product floor; content 288 — narrowest the app ever lays out
  480, // golden CI's phone coordinate
  601, // margin 16 → 32: content 537, narrower than 600px's 568
  905, // last width of the 32px margin; content 841
  1241, // margin 24 → 200: content 841, the #1302 desktop pinch
  1280, // golden CI's desktop coordinate
  1441, // margin 200 → 256: content 929
  1681, // margin 256 → 352: content 977
];

/// The surface height every page is measured at.
///
/// 1600, which is what both pilot pages' golden configs use
/// (`usp_dhcp_detail_view_test.dart`, `usp_wifi_settings_view_test.dart`). Height
/// is not an axis, but it is not free either: content that never enters the
/// viewport of a lazy sliver never lays out and therefore never reports, so a
/// short surface would measure the top of a page and call the whole page clean.
/// Matching the golden height keeps this sweep's coverage no worse than the
/// scout's on the axis this sweep does not vary.
const kPageSweepHeight = 1600.0;

/// One page: what to pump, what to feed it, and what must be on screen for the
/// measurement to mean anything.
class PageSurfaceCase {
  const PageSurfaceCase({
    required this.id,
    required this.view,
    required this.overrides,
    required this.requires,
    required this.forbids,
  });

  /// The sweep name's suffix — `page.dhcp` — and therefore part of every cell id.
  final String id;

  /// The sweep name this case is measured under, and the only place it is built.
  ///
  /// [PageSurfaceFamily.name] returns this rather than composing `page.$id`
  /// itself, so the prefix that every cell id and every baseline row carries is
  /// written once — the failure messages below quote it, and a name assembled in
  /// two places is a name that can disagree with the committed baseline.
  String get sweepName => 'page.$id';

  /// The real view, built fresh per cell.
  final Widget Function() view;

  /// The page's data providers. Rebuilt per cell rather than shared, because a
  /// `ProviderScope` may not be handed a list whose length changes between pumps
  /// and a shared list invites exactly that edit.
  final List<Override> Function() overrides;

  /// Widget types that must be on screen once the page has settled.
  ///
  /// **The premise, and it is a value rather than a body** — #1364/#1366's whole
  /// finding, applied to a family written after them. Both pilot pages open with
  /// `if (status.isLoading) return AppLoader()`, so a fixture that drifts out of
  /// shape does not fail: it renders a centred spinner, which is a tree that
  /// cannot overflow at any width in any locale. Every cell would be green and
  /// the sweep would be measuring a loader. Naming a widget that only exists on
  /// the loaded path is what makes that impossible, and keeping it a field is
  /// what makes deleting it visible — `page_surface_family_test.dart` pins these
  /// lists per case, so an emptied premise fails there instead of passing here.
  final List<Type> requires;

  /// Widget types that must **not** be on screen.
  ///
  /// [requires] already excludes the loading and error paths by construction, so
  /// this is the second, blunter direction: it names the tree the sweep would
  /// otherwise have measured, so the failure says "this page is still loading"
  /// rather than "a card is missing".
  ///
  /// Both instances are `const [AppLoader]` today, which reads as a knob nobody
  /// turns — deliberately kept anyway, and for the same reason [requires] is a
  /// field: a premise held in a **body** is deletable in silence (#1364), and a
  /// hard-coded `AppLoader` here could not be pinned per case by
  /// `page_surface_family_test.dart`. It also stops being redundant the moment a
  /// [requires] entry names a widget that *can* coexist with a loader — a card
  /// that renders its own frame while its provider resolves, which is the shape
  /// most of this app's cards have.
  final List<Type> forbids;

  /// Asserts this cell measured the loaded page, not a spinner.
  ///
  /// On the case rather than in the family because every value it reads is here:
  /// the family would otherwise reach through `page.` for all of them, which is
  /// Feature Envy with the family's own name as the only local ingredient (and
  /// that is [sweepName] now). Reads the tree currently pumped by the test, the
  /// way every `flutter_test` finder does.
  void checkPremise() {
    for (final type in requires) {
      expect(
        find.byType(type),
        findsWidgets,
        reason: '$sweepName rendered no $type, so this cell measured something '
            'other than the loaded page. Every width and locale would be green '
            'against a spinner.',
      );
    }
    for (final type in forbids) {
      expect(
        find.byType(type),
        findsNothing,
        reason: '$sweepName still shows $type after settling, so this cell '
            'measured the loading or error path rather than the page.',
      );
    }
  }
}

/// The page surface family: `page.<id>`, one axis, 26 locales each.
class PageSurfaceFamily extends OverflowSurfaceFamily {
  const PageSurfaceFamily(this.page);

  final PageSurfaceCase page;

  @override
  String get name => page.sweepName;

  @override
  List<String> get axisNames => const ['screen_px'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() {
    return [
      for (final width in kPageSweepWidths)
        for (final locale in AppLocalizations.supportedLocales)
          OverflowSweepCell(
            // `screen_px`, the same spelling the chrome families use, and for the
            // same reason: what this sweep varies is the screen the page is laid
            // out in, not a box inside one.
            axes: {'screen_px': width.toStringAsFixed(0)},
            locale: locale,
            surfaceSize: Size(width, kPageSweepHeight),
            build: () => pageSurfaceHost(
              view: page.view(),
              locale: locale,
              overrides: page.overrides(),
            ),
          ),
    ];
  }

  /// Checks the cell's premise: the page reached its loaded state.
  ///
  /// Delegates to [PageSurfaceCase.checkPremise], which is where the values it
  /// asserts live — see [PageSurfaceCase.requires] for why this is the premise a
  /// *page* needs and the two chrome families do not.
  ///
  /// ## Why no readability assertion runs per cell, and where one runs instead
  ///
  /// Rule 4 of the gate skill — every overflow assertion needs a readability
  /// assertion beside it — and §7 permits a family to decline only with a stated
  /// reason. The reason is not "pages have no readable text"; it is that the two
  /// candidates are not answerable *per cell over a whole page*:
  ///
  /// - `UiKitPageView`'s own title is `maxLines: 1` + ellipsis inside a `Tooltip`,
  ///   so a truncated title is the component's declared degradation and
  ///   `hasSplitToken` cannot fire on it — asserting either would be a test that
  ///   cannot fail.
  /// - Every other string on these pages is a card's, and a page-wide sweep for
  ///   ellipsized text finds the many labels that are *designed* to ellipsize
  ///   (device names, SSIDs, lease hostnames). A verdict that fires on intended
  ///   truncation is a verdict nobody can act on.
  ///
  /// So readability is asserted where the pilot actually changed the trade: the
  /// `Flexible` in `usp_dhcp_reservations_detail_card.dart` turned an overflow into
  /// a **wrap**, and a wrap is invisible to every cell here. That one site carries
  /// its own guard, in the suite file next to these sweeps
  /// (`test/page/_shared/page_surface_overflow_test.dart`), across both widths the
  /// defect appeared at and all 26 locales, with its own premise pinning that some
  /// locale really does wrap. What a *cell* checks is the coarser thing only a cell
  /// can: that a page lost its content silently.
  @override
  Future<void> onCellSettled(
      WidgetTester tester, OverflowSweepCell cell) async {
    page.checkPremise();
  }
}

/// Hosts [view] the way the app does: a [LinksysRoute] under a real [GoRouter],
/// with `lib/app.dart`'s theme and locale wiring and the GetIt singletons the top
/// bar reads.
///
/// **The one place a real page is pumped in this family.** `probeViewOverflow`
/// (`test/util/detail_view_probe.dart`, #1302) delegates here rather than keeping
/// its own copy: that file's own header argues the scaffolding is "the answer to
/// how do I pump a real view" and that two copies of it would drift, and the
/// pilot is what gave the answer a home under `families/`, where §3.1 puts host
/// construction.
///
/// Three parts are load-bearing, and each cost real debugging time somewhere in
/// this family:
/// - **A `GoRouter` ancestor.** `UspTopBar` sits in both pilot pages'
///   `UiKitPageView.topbar`, and `MenuHolderState.didChangeDependencies` calls
///   `GoRouter.of(context)` unguarded.
/// - **`LinksysRoute`, not `GoRoute`.** It is what the app builds its routes with
///   and what carries the dirty-guard contract these pages sit under; a plain
///   `GoRoute` would pump a page the app never renders.
/// - **The `MediaQuery` inside `MaterialApp.builder`.** Wrapped outside, the app
///   overrides it and the view never observes `disableAnimations`.
///
/// The surface is **not** set here — [runOverflowSweep] owns that through
/// `setLayoutSurface` (invariant 2), which is also why this returns a widget
/// rather than pumping one.
Widget pageSurfaceHost({
  required Widget view,
  required Locale locale,
  List<Override> overrides = const [],
}) {
  // Same call as `lib/app.dart`, not a copy of its body — see #1285.
  final theme = FallbackFontResolver.withFallbackFont(_baseTheme, locale);

  return ProviderScope(
    // `commonOverrides()` is called for its GetIt side effect as much as for the
    // two overrides it returns; the top bar and `buildStudioThemeData` read those
    // singletons outside the widget tree.
    overrides: [...commonOverrides(), ...overrides],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          LinksysRoute(
            path: '/',
            name: 'test_root',
            builder: (context, state) => view,
          ),
        ],
      ),
    ),
  );
}

/// Built once per test process, not once per pump: `createLightTheme()` walks the
/// whole JSON config, and every call site wants the same base.
final _baseTheme = ThemeJsonConfig.defaultConfig().createLightTheme();
