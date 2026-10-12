import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
// The two constants the sheet branch's screen width is derived from, so the case
// follows `showCardNormalForm`'s own condition instead of naming a pixel.
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/helpers/card_identifier.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/_shared/providers/card_density_provider.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../util/dashboard/card_detail_entries.dart';
import '../../../util/dashboard/dashboard_card_probe.dart';
import '../../../util/dashboard/kitchen_sink_overrides.dart';
import '../../../util/overflow_probe.dart';

/// A presented card's detail button closes the presentation it sits in before
/// it navigates (#1453).
///
/// ## The defect, and why both branches are measured
///
/// A card in popup form opens its full form in a presentation, and that form
/// holds the card's only detail button. The button used to push the detail route
/// and leave the presentation where it was, and the two presentations are pushed
/// onto *different* navigators, so they failed differently:
///
/// * **Dialog** (`showAppDialog`, `useRootNavigator: true`) — on the root
///   navigator, above the shell the detail page is pushed into. The page opened
///   under the dialog's barrier and its back arrow was not hit-testable: the
///   user's next tap only dismissed the dialog.
/// * **Sheet** (`showAppBottomSheet`, the nearest navigator) — on the shell
///   navigator, the same one the detail page is pushed into. A page-based
///   navigator re-files a pageless route behind the page below it, so the detail
///   page landed *above* the sheet and looked fine — but the sheet was never
///   closed, and back to the Dashboard found it still open.
///
/// One fix for both is only possible because of where it pops: the
/// presentation's own navigator, not the root one. Popping the root navigator
/// would close the dialog and miss the sheet, so a case that measured one branch
/// could not tell a correct fix from that one.
///
/// ## Why the router is pumped rather than the verb scanned
///
/// `usp_navigation_invariants_test.dart` already pins the *verb* (`pushNamed`),
/// and the verb was right all along. What was wrong is which routes are on which
/// navigator at the moment of the push, and only a pumped navigator with the
/// production topology — a root navigator, and a `ShellRoute` with a navigator of
/// its own — can see that. The tree is the real `uspDashboardRoute` with stub
/// pages, so its names, paths and nesting are the app's.
///
/// Deliberately NOT tagged: the unit job is the one that blocks a PR.

/// The id of every registered card whose presentation holds a detail button.
///
/// Derived from the registry rather than listed: which cards have a detail entry
/// is pinned literally by `dashboard_card_identifier_widget_test.dart`, and this
/// file's subject is what that button does, not which cards have one. The set it
/// subtracts is that test's own, imported rather than restated, so its meta-test
/// is what keeps this enumeration honest: a card gaining an entry has to leave
/// [kCardsWithoutDetailEntry] there, which adds it here. Enumerated at collection
/// time, so the set is the one the cases below are named after.
List<String> _cardsWithDetailEntry() => [
      for (final spec in UspWidgetSpecs.all)
        if (UspWidgetSpecs.selectableForms(spec.id)
                .contains(CardDensity.popup) &&
            !kCardsWithoutDetailEntry.contains(spec.id))
          spec.id,
    ];

/// Rows of viewport the screen gets — tall enough that the presentation is not
/// itself the constraint. The figure the identifier test presents at.
const int _kScreenRows = 6;

/// The Dashboard's grid, with one card in it at [cardWidth] × [cardHeight].
class _DashboardStub extends StatelessWidget {
  const _DashboardStub({
    required this.cardId,
    required this.cardWidth,
    required this.cardHeight,
  });

  final String cardId;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            // Through the production factory, so the card is wrapped in the same
            // `CardDensityHost` the dashboard wraps it in.
            child: UspWidgetFactory().buildWidget(cardId, cardWidth: cardWidth),
          ),
        ),
      );
}

/// A detail page: an app bar whose back arrow goes through the production
/// [NavigationExtension.navigateBack], exactly as `UiKitPageView` wires it.
class _DetailStub extends StatelessWidget {
  const _DetailStub(this.name);

  final String name;

  static Key backKey(String name) => Key('back_$name');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('PAGE:$name'),
          leading: IconButton(
            key: backKey(name),
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.navigateBack(fallback: RouteNamed.uspMenu),
          ),
        ),
      );
}

/// Rebuilds [route] keeping every name, path and nesting, with [dashboard] as the
/// Dashboard's page and a [_DetailStub] for every other.
///
/// The `ShellRoute` gets a navigator key of its own — a fresh one, because the
/// real `uspShellNavigatorKey` would collide with the real tree's — so the sheet
/// branch lands on a shell navigator the way it does in the app. Without it, the
/// shell would share the root navigator and both branches would be one case.
RouteBase _mirror(RouteBase route, Widget dashboard) {
  if (route is GoRoute) {
    final name = route.name!;
    return GoRoute(
      name: name,
      path: route.path,
      builder: (c, s) =>
          name == RouteNamed.uspDashboard ? dashboard : _DetailStub(name),
      routes: [for (final c in route.routes) _mirror(c, dashboard)],
    );
  }
  return ShellRoute(
    navigatorKey: GlobalKey<NavigatorState>(),
    builder: (c, s, child) => child,
    routes: [for (final c in route.routes) _mirror(c, dashboard)],
  );
}

/// Pumps the Dashboard with [cardId] in [density] on [screenWidth], under a
/// router mirroring the real tree, and returns the router.
///
/// [cardRows] defaults to the one grid row a picked popup tile occupies; a card
/// in its normal form needs its own preferred height, or its footer is laid out
/// below the box and a tap on it lands on nothing.
Future<GoRouter> _pumpDashboard(
  WidgetTester tester, {
  required String cardId,
  required double screenWidth,
  required double cardWidth,
  required CardDensity density,
  int cardRows = UspWidgetSpecs.popupHeightRows,
}) async {
  final cardHeight = dashboardCardHeight(cardRows);
  await setLayoutSurface(
      tester, Size(screenWidth, dashboardCardHeight(_kScreenRows)));

  final router = GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: RoutePath.uspDashboard,
    routes: [
      _mirror(
        uspDashboardRoute,
        _DashboardStub(
          cardId: cardId,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...kitchenSinkOverrides(),
        cardDensityOverrideProvider(cardId).overrideWith((ref) => density),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await settleIgnoringAnimations(tester);
  return router;
}

/// Every presentation `showCardNormalForm` can build, mounted or offstage.
///
/// `skipOffstage: false` on purpose: the sheet's failure is a presentation that
/// is still in the tree but hidden behind the page that was pushed over it, and a
/// default finder skips exactly that.
int _presentationCount() =>
    find.byType(AppDialog, skipOffstage: false).evaluate().length +
    find.byType(AppBottomSheet, skipOffstage: false).evaluate().length;

/// The route name the router is on, read from its own state.
String? _currentRouteName(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.route.name;

void main() {
  /// Opens [cardId]'s presentation from its popup tile, presses its detail button,
  /// and asserts the user arrives on a usable detail page — then presses back and
  /// asserts they arrive on a clean Dashboard.
  Future<void> enterAndReturn(
    WidgetTester tester, {
    required String cardId,
    required double screenWidth,
    required double cardWidth,
    required Type presentation,
  }) async {
    await runWithOverflowCollection((_) async {
      final router = await _pumpDashboard(
        tester,
        cardId: cardId,
        screenWidth: screenWidth,
        cardWidth: cardWidth,
        density: CardDensity.popup,
      );
      final key = cardIdentifierKey(cardId);

      await tester.tap(find.bySemanticsIdentifier('card-popup-$key'));
      await settleIgnoringAnimations(tester);
      expect(find.byType(presentation), findsOneWidget,
          reason: 'at ${screenWidth.toStringAsFixed(0)}px the tile must open '
              'a $presentation — a case that drifted onto the other branch '
              'would leave this one unmeasured');

      await tester.tap(find.bySemanticsIdentifier('card-detail-$key'));
      await settleIgnoringAnimations(tester);

      final detail = _currentRouteName(router)!;
      expect(detail, isNot(RouteNamed.uspDashboard),
          reason: 'the detail button must have navigated');
      expect(_presentationCount(), 0,
          reason: 'the presentation must be closed before the detail page '
              'opens — left open, a dialog covers the page and a sheet waits '
              'behind it for the way back (#1453)');
      expect(
          find.byKey(_DetailStub.backKey(detail)).hitTestable(), findsOneWidget,
          reason: 'the detail page\'s own back arrow must take the next tap, '
              'not a barrier left over from the presentation');

      await tester.tap(find.byKey(_DetailStub.backKey(detail)));
      await settleIgnoringAnimations(tester);
      expect(_currentRouteName(router), RouteNamed.uspDashboard,
          reason: 'one back from the detail page must return to the Dashboard');
      expect(_presentationCount(), 0,
          reason: 'and the Dashboard must not come back with the presentation '
              'still open on it');
    });
  }

  group('a presented card\'s detail button', () {
    for (final cardId in _cardsWithDetailEntry()) {
      testWidgets('$cardId: dialog branch', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          // A picked tile on the screen the identifier test presents it on —
          // wide enough for `showCardNormalForm` to seat a dialog.
          final widthCase = pickedTileCase();
          await enterAndReturn(
            tester,
            cardId: cardId,
            screenWidth: widthCase.screenWidth,
            cardWidth: widthCase.cardWidth,
            presentation: AppDialog,
          );
        } finally {
          handle.dispose();
        }
      });

      testWidgets('$cardId: sheet branch', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          // The condition is `screen.width - inset * 2 < kCardPresentationWidth`,
          // so one pixel under is the widest screen the sheet branch claims.
          const screenWidth =
              kCardPresentationWidth + kCardPresentationInset * 2 - 1;
          await enterAndReturn(
            tester,
            cardId: cardId,
            screenWidth: screenWidth,
            cardWidth: cardWidthAt(screenWidth, UspWidgetSpecs.popupColumns),
            presentation: AppBottomSheet,
          );
        } finally {
          handle.dispose();
        }
      });
    }
  });

  /// The other half of the guard: a card in the grid pops nothing.
  ///
  /// The pop is conditional on `CardDensityScope.isPresented`, and in the grid the
  /// navigator the card resolves to is the shell's — whose top route is the
  /// Dashboard itself. An unconditional pop would close the Dashboard instead of
  /// a presentation, and back from the detail page would find nothing to return
  /// to. One card, because the guard is one expression shared by all four call
  /// sites; which cards reach it is the group's subject above.
  testWidgets('a card in the grid navigates without popping the Dashboard',
      (tester) async {
    const cardId = 'system_status';
    final handle = tester.ensureSemantics();
    try {
      await runWithOverflowCollection((_) async {
        final spec = UspWidgetSpecs.getById(cardId)!;
        final widthCase = desktopCaseFor(spec);
        final router = await _pumpDashboard(
          tester,
          cardId: cardId,
          screenWidth: widthCase.screenWidth,
          cardWidth: widthCase.cardWidth,
          density: CardDensity.normal,
          cardRows:
              spec.getConstraints(DisplayMode.normal).getPreferredHeightCells(),
        );

        await tester.tap(find
            .bySemanticsIdentifier('card-detail-${cardIdentifierKey(cardId)}'));
        await settleIgnoringAnimations(tester);
        final detail = _currentRouteName(router)!;
        expect(detail, RouteNamed.uspStatistics);

        await tester.tap(find.byKey(_DetailStub.backKey(detail)));
        await settleIgnoringAnimations(tester);
        expect(_currentRouteName(router), RouteNamed.uspDashboard,
            reason: 'back must still find the Dashboard under the detail page '
                '— a pop in the grid would have removed it');
      });
    } finally {
      handle.dispose();
    }
  });
}
