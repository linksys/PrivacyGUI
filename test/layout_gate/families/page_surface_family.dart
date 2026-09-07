/// The page surface family: whole pages, on the shared runner (#1349).
///
/// The gate's third family, and the one the #1335 refactor was sequenced to make
/// possible — adding it to two frameworks would have produced three. It began as a
/// **pilot**: two pages, whose deliverable is a per-cell cost number and the
/// decision that number supports (`doc/testing/overflow_gate_architecture.md` §8
/// and §10 Q5), not merely two green suites. The number came in and the decision it
/// supports was "pages graduate one at a time, not as a class" (§11.3), so #1377's
/// wave 1 took it to **seven** cases and epic #1369 takes the remaining 38 in
/// waves. Which pages, and why those, is `page_surface_cases.dart`.
///
/// ## Why one class with N instances, where chrome has two classes
///
/// §3.2's recorded decision is "one family class per widget, not per suite", and
/// `ChromeTopBarFamily` / `ChromeHeaderFamily` are two classes because those two
/// widgets have **unrelated hosts and different axes**. Pages do not: a page
/// is hosted exactly one way — the app's own route scaffolding, [pageSurfaceHost]
/// — and swept on exactly one axis, the screen width. What differs between
/// `page.dhcp` and `page.port_forwarding` is the route, the fixture and the premise,
/// which are *values*. So the shape is one family parameterised by a
/// [PageSurfaceCase], and each instance still carries its own [name] and its own
/// pinned cell count, which is what §3.2's decision is actually protecting
/// (a widget discriminator never becomes an axis). Wave 1 is the evidence the shape
/// was right: five pages arrived as five values and this file was not edited.
///
/// Reversal cost, recorded per §10.1: split into one class per page and the seven
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
///   | **1080**| 24    | **1032**| golden CI's third coordinate — and the widest content this list renders |
///   | 1240   | 24     | 1192    | widest content below the pinch              |
///   | **1241**| 200   | **841** | 351px narrower than 1240px — the #1302 pinch |
///   | 1280   | 200    | 880     | golden CI's desktop coordinate              |
///   | **1441**| 256   | **929** | 111px narrower than 1440px                  |
///   | **1681**| 352   | **977** | 191px narrower than 1680px                  |
///
/// [kPageSweepWidths] is that table's four step-ups (601, 1241, 1441, 1681), its
/// floor (320), the last width before the 906px step *down* (905), and the three
/// **committed** golden coordinates (480, 1080, 1280) — a literal list, because
/// there is nothing to derive it from and a derived "worst case" would be wrong
/// four times over. #1302 measured the 1241px pinch as the worst *desktop* case for
/// the device-detail page (`fr` +30px, against +20px at 1280px), which is the same
/// arithmetic reaching a different page.
///
/// **"Golden CI's two coordinates" was wrong and is corrected here (#1370).** Two
/// is the count of `GoldenDevice.defaults` in this repo — `phone480` and
/// `desktop1280` at `golden_test_config.dart:33`. Golden CI runs more, because
/// `golden_runner.dart:43` synthesises a device from
/// `--dart-define=screens=<width>`: §1.3 records it sweeping four (`phone320`,
/// `phone480`, `desktop1241`, `desktop1280`) and §5's note records `screen1080`
/// arriving on 2026-08-24. **#1372 closed the list on 2026-08-26 by adding 1080**,
/// so all five are now here.
///
/// ## Why 1080 is in the list, and it is not because of #1368's 53 flags
///
/// The obvious argument was the weak one. #1368 records golden CI flagging 53
/// screens at `screen1080` the day the width was added there, so "1080 finds
/// things" reads as settled — but the two sites in this repo's own committed
/// capture of such a run (`test/fixtures/golden_overflow_warnings.json`, 16 records
/// at `screens=1080`) are `firmware_update_card.dart:77`, a **loading** skeleton
/// reached through `usp_admin_view.dart`, and `usp_sliver_dashboard_view.dart:414`,
/// the delete target that exists only in **edit mode**. Neither appears in any of
/// the five committed baselines, at any width. What those two want is page and
/// state coverage, which is #1369's and #1380's job; adding a width does not reach
/// them.
///
/// The real argument is the table above. Before 1080 joined, the widest content box
/// this list ever rendered was 1681's **977px** — and the app grants up to 1192px
/// below the pinch and 1856px at 2560px, where the margin stops growing. Every
/// width here had been chosen for a *narrow*-side reason (the floor, the step-ups)
/// or for the golden join, so a defect that needs a **wide** box to appear — a
/// fixed-count grid gaining a column, a legend that grows with its chart — was
/// outside the sweep by construction. 1080 grants 1032px, wider than all eight, and
/// it is a coordinate golden CI already runs, so it closes §8's last comparability
/// gap in the same cell.
///
/// The band is narrowed, not closed: 1032px is still short of 1192px and far short
/// of 1856px, and `page_surface_family_test.dart` pins both numbers so the residual
/// gap stays a stated one. Measured 2026-08-26 before it landed: the fifteen swept
/// pages × 1080/1240/1920/2560 × 26 locales is **1,560 cells at zero**, so 1080
/// enters on the coverage argument alone and no find is claimed for it.
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
/// Nine, not twelve: four are margin step-ups (the widths the content box narrows
/// at), one is the product floor, one is the last width before the 906px step
/// *down*, and three are widths golden CI runs, which are what make the `file:line`
/// join of §8 comparable. A tenth width would cost 26 cells per page and answer a
/// question one of these already answers.
///
/// **#1372 closed this list on 2026-08-26**: 1080 in, nothing cut. Its two decisions
/// are argued in the header — 1080 for the wide-side band and *not* for #1368's
/// flags, and 905/1441/1681 kept despite zero finds across 43 pages, because two of
/// them are step-ups and the zero rests on the 27 pages a fixture could render.
const kPageSweepWidths = <double>[
  320, // product floor; content 288 — narrowest the app ever lays out. Also golden CI's phone320
  480, // committed golden coordinate (GoldenDevice.phone480)
  601, // margin 16 → 32: content 537, narrower than 600px's 568
  905, // last width of the 32px margin; content 841
  1080, // golden CI coordinate since 614aad41; content 1032 — the widest box this list renders (#1372)
  1241, // margin 24 → 200: content 841, the #1302 desktop pinch. Also golden CI's desktop1241
  1280, // committed golden coordinate (GoldenDevice.desktop1280)
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
    this.needsMaterialAncestor = false,
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

  /// The real view, built fresh per cell — **the page's own class, unwrapped**.
  ///
  /// Unwrapped is a contract, not a style note. `page_roster_test.dart`'s third
  /// assertion joins a swept case to its roster row through
  /// `page.view().runtimeType`, so a closure that returns `Scaffold(body: TheView())`
  /// resolves to `Scaffold` — a type no file under `lib/page/**/views/` declares — and
  /// the ⟺ between the 45 discovered pages and the swept cases breaks in both
  /// directions at once: the case looks like a page nothing declares, and its page
  /// looks like a file no case sweeps. Both dashboard cases were written that way and
  /// both failures were exactly that (#1380). A page that needs scaffolding says so
  /// with [needsMaterialAncestor] instead, which the host applies and the oracle
  /// looks through.
  final Widget Function() view;

  /// Whether the host must supply a [Material] ancestor for this page.
  ///
  /// Almost no page needs it: every other case returns its own `UiKitPageView` or
  /// `StyledAppPageView`, so [pageSurfaceHost]'s `LinksysRoute` is all the
  /// scaffolding they take. The two dashboard pages have none of their own — in the
  /// app their `Material` comes from `UspDashboardShell`, the `ShellRoute` above them
  /// — and pumped bare every `AppCard`'s `InkWell` throws `No Material widget found`,
  /// 17 exceptions per cell and not one of them an overflow.
  ///
  /// A **flag** rather than a wrapper inside [view] for two reasons. The join above
  /// is the first. The second is #1364's finding one layer down: scaffolding held in
  /// a closure body is invisible, so nobody can tell whether a page is pumped under
  /// chrome the other 42 are measured without. As a field it is pinned per case by
  /// `page_surface_family_test.dart`, so growing this from two to three pages is an
  /// edit someone has to defend. What it may **not** become is the real shell — see
  /// [kSliverDashboardPageCase] for why no page here is pumped under one.
  final bool needsMaterialAncestor;

  /// [view] as the family actually pumps it.
  ///
  /// The one place the [needsMaterialAncestor] wrapper is applied, so the wrapper
  /// cannot differ between the two dashboard cases, and `view()` stays the bare page
  /// for anything that asks what class this case sweeps.
  Widget hostedView() =>
      needsMaterialAncestor ? Scaffold(body: view()) : view();

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
              view: page.hostedView(),
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
