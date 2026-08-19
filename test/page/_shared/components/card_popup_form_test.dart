@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/providers/card_density_provider.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../util/overflow_probe.dart';

/// The popup form and the presentation that gives its content back (#1239).
///
/// Written before the form exists, for the reason the whole epic exists: the
/// #1183 gate asserts only "does not overflow", and a popup form that renders
/// nothing at all, loses its tap target, or opens a dialog too narrow for the
/// card would pass it. Everything below is a claim the gate cannot make.
///
/// ## Mutation table
///
/// Each row is one edit to the named source file, applied to the real file and
/// run against this file.
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | `card_popup_form` | `_open` passes `context.size?.height` alone, dropping the declared height | the form gets the height the card declares it needs |
/// | 2 | `usp_widget_factory` | the factory stops supplying `normalHeight` | **nothing here** — this file hands `CardDensityHost` its own value, so the wiring from spec to scope is covered by the picked-popup sweep in `dashboard_card_popup_overflow_test.dart` (51 cases), not by anything below |
/// | 3 | `card_popup_form` | the dialog's width is derived from the viewport again (`screen.width − inset × 2`) | all three of `the dialog is one width …` (1152, 552 and 1152 against 400). Deriving it from the card's *declaration* is the other half of what the old formula did, and it can no longer be written: nothing carries a declared width into the presentation any more, so that mutation would have to re-thread it through `CardDensityScope` first. The compiler pins that half, not a test |
/// | 4 | `card_popup_form` | the dialog keeps the theme's own surface and padding (drop the `containerStyle`/`padding` overrides, keep `maxWidth`) | **six** tests, not the two that name the frame: the two `no second frame` tests, and every width assertion (350 against 400). They measure what the *card* was given, and 24px of padding plus a 1px border on each side is taken out of exactly that — which is the point, since the ring is width the card asked for and did not get |
/// | 5 | `card_popup_form` | `kCardPresentationWidth` raised to 500 | only `is one named constant` — the behaviour tests read the constant rather than the number, deliberately, so that one test is the only place the number is pinned. Anywhere above the floor the specs impose it is a design choice, not a derivation |
/// | 6 | `card_popup_form` | `kCardPresentationWidth` lowered to 300, i.e. *below* that floor | `is one named constant` **and** `clears every threshold a card declares` in `dashboard_card_popup_overflow_test.dart` — the pin lives there because only that file can see the specs. Note what did *not* fire: the 318-case sweep stayed green at 300, so the floor is a readability claim the cards' own specs make, and no overflow probe can stand in for it |
const String _kCardId = 'connected_devices';
const String _kTitle = 'Connected Devices';
const String _kValue = '12 online';

/// Text that appears in the *normal* form only. The single most important
/// assertion in this file is about where this string is and is not: below 200px
/// the card must not be rendering its full content, and after a tap it must be.
const String _kNormalOnly = 'normal-form-only-content';
const Key _kLeadingKey = Key('popup-leading');

/// Height of every surface this file pumps. Named because the presentation's cap
/// is measured against it: a card declaring more than the screen has must be
/// given the screen, and "the screen" has to be one number both sides read.
const double _kScreenHeight = 800.0;

/// Width of a *picked* popup tile on the 4-column phone grid — two columns of
/// twelve, which the grid realizes at 122.3px (pinned in
/// `dashboard_card_popup_overflow_test.dart`, which can see the grid).
///
/// The only width the tile's label has to be legible at, and narrow enough that
/// nearly every card's value or name needs two lines to be read whole.
const double _kPickedTileWidth = 122.0;

/// Which tab a live card is showing — the shape every tabbed dashboard card has
/// (`cardTabIndexProvider`), modelled here because it is the reason a widget
/// *snapshot* cannot be what the presentation renders.
final _tabIndex = StateProvider<int>((ref) => 0);

const String _kTabA = 'tab-a-only-content';
const String _kTabB = 'tab-b-only-content';

/// A card whose selected tab is held outside its own build, so switching tabs
/// takes a rebuild of the *element* that watches it.
///
/// Every tabbed card on the dashboard is built this way, and it is what the
/// presentation broke: handed `this` — a `DashboardCardTemplate` already built by
/// the element above — the dialog holds a frozen widget whose selected index can
/// never change, because the element that reads the provider lives outside the
/// dialog's tree entirely.
class _LiveTabbedCard extends ConsumerWidget {
  const _LiveTabbedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardCardTemplate.tabbed(
      title: _kTitle,
      popupValue: _kValue,
      tabs: const [
        CardTab(label: 'A', content: Text(_kTabA)),
        CardTab(label: 'B', content: Text(_kTabB)),
      ],
      selectedTabIndex: ref.watch(_tabIndex),
      onTabChanged: (i) => ref.read(_tabIndex.notifier).state = i,
    );
  }
}

ThemeData _lightTheme() => ThemeJsonConfig.defaultConfig().createLightTheme();

/// The surface `AppDialog` draws around whatever it is handed — the outer of the
/// two frames in "a frame inside a frame", and the one that must not be there.
///
/// `AppSurface` finders are depth-first, so the first one under the dialog is the
/// dialog's own; every later one belongs to the card.
Finder _dialogSurface() => find
    .descendant(of: find.byType(AppDialog), matching: find.byType(AppSurface))
    .first;

/// A card whose normal form cannot fit a narrow width, for the one claim no
/// production card can support any more: after #1240's re-measurement all 18 fit
/// at every width the grid produces, so a threshold set too low leaves them
/// *readable-or-not* but never overflowing. This one overflows by construction —
/// a 400px child in a `Row` — so the failure a too-low threshold causes is
/// something a test can still see.
Widget _overflowingCard() => DashboardCardTemplate(
      title: _kTitle,
      popupValue: _kValue,
      content: Row(
        children: const [SizedBox(width: 400, height: 20)],
      ),
    );

/// A card whose two forms are distinguishable: [_kValue] is what the popup form
/// is supposed to show, [_kNormalOnly] is what only the full form has.
Widget _card({
  String? popupValue = _kValue,
  String title = _kTitle,
  Widget? leading = const Icon(Icons.devices, key: _kLeadingKey),
}) =>
    DashboardCardTemplate(
      leading: leading,
      title: title,
      popupValue: popupValue,
      content: const Text(_kNormalOnly),
    );

/// Pumps [card] at [cardWidth] on [screenWidth] with its density pinned, and
/// optionally taps it, collecting overflow across the whole interaction.
///
/// The tap happens inside the collection on purpose: opening the presentation is
/// a layout event of its own, and an overflow raised while the dialog lays out
/// would otherwise be reported outside any handler and lost.
Future<List<OverflowIncident>> _pump(
  WidgetTester tester, {
  required double screenWidth,
  required double cardWidth,
  double cardHeight = 240,
  double? normalAbove = 400,
  double? normalHeight,
  CardDensity? density = CardDensity.popup,
  Widget? card,
  bool open = false,
}) {
  final surface = Size(screenWidth, _kScreenHeight);
  return runWithOverflowCollection((sink) async {
    await tester.binding.setSurfaceSize(surface);
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      tester.view.reset();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (density != null)
            cardDensityOverrideProvider(_kCardId)
                .overrideWith((ref) => density),
        ],
        child: Portal(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: _lightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  // The real host, not a hand-built scope: the width→form
                  // selection and the threshold the presentation needs both
                  // travel this path in production.
                  child: CardDensityHost(
                    cardId: _kCardId,
                    normalAbove: normalAbove,
                    normalHeight: normalHeight,
                    child: card ?? _card(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await settleIgnoringAnimations(tester);

    if (open) {
      await tester.tap(find.byType(CardPopupForm));
      await settleIgnoringAnimations(tester);
    }
    return sink;
  });
}

/// Size the card's normal form was actually given inside [ancestor].
Size _presentedFormSize(WidgetTester tester, Type ancestor) => tester.getSize(
      find.descendant(
        of: find.byType(ancestor),
        matching: find.byType(DashboardCardTemplate),
      ),
    );

/// Width the card's normal form was actually given inside [ancestor].
double _presentedFormWidth(WidgetTester tester, Type ancestor) =>
    _presentedFormSize(tester, ancestor).width;

/// Height the card's normal form was actually given inside [ancestor].
double _presentedFormHeight(WidgetTester tester, Type ancestor) =>
    _presentedFormSize(tester, ancestor).height;

/// Horizontal scroll views inside [ancestor]. AC: "No horizontal scrolling is
/// introduced inside the popup or the dialog."
Finder _horizontalScrollViews(Type ancestor) => find.descendant(
      of: find.byType(ancestor),
      matching: find.byWidgetPredicate(
        (w) => w is ScrollView && w.scrollDirection == Axis.horizontal,
      ),
    );

void main() {
  group('the popup form', () {
    testWidgets('shows the card icon and its one value, not its content',
        (tester) async {
      await _pump(tester, screenWidth: 1200, cardWidth: 150);

      expect(find.byKey(_kLeadingKey), findsOneWidget);
      expect(find.text(_kValue), findsOneWidget);
      expect(
        find.text(_kNormalOnly),
        findsNothing,
        reason: 'below 200px the card must not still be rendering its full '
            'content — that is the overflow this form exists to avoid',
      );
    });

    testWidgets('falls back to the card title when no value is declared',
        (tester) async {
      // A card that declares a threshold should also declare the one value it
      // degrades to, but the form cannot render nothing if it does not. The
      // title is the honest stand-in: still readable, still opens the full form.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        card: _card(popupValue: null),
      );

      expect(find.text(_kTitle), findsOneWidget);
      expect(find.text(_kNormalOnly), findsNothing);
    });

    testWidgets('is one tap target, announced with the card it belongs to',
        (tester) async {
      // It is now the only way to read this card, so a screen reader has to hear
      // which card it is — the icon alone says nothing aloud.
      await _pump(tester, screenWidth: 1200, cardWidth: 150);

      final card = tester.widget<AppCard>(
        find.descendant(
          of: find.byType(CardPopupForm),
          matching: find.byType(AppCard),
        ),
      );
      expect(card.onTap, isNotNull);
      expect(card.semanticLabel, contains(_kTitle));
      expect(card.semanticLabel, contains(_kValue));
    });

    testWidgets('is not used, and adds no tap target, at normal density',
        (tester) async {
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 600,
        density: CardDensity.normal,
      );

      expect(find.byType(CardPopupForm), findsNothing);
      expect(find.text(_kNormalOnly), findsOneWidget);
      expect(
        tester.widget<AppCard>(find.byType(AppCard)).onTap,
        isNull,
        reason: 'a card with room is not a button',
      );
    });

    testWidgets('fits at 150px with a long value and a long title',
        (tester) async {
      // The narrowest realization the grid produces is ~191px, and the form has
      // to survive well under it with the longest localized strings.
      final incidents = await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        cardHeight: 120,
        card: _card(
          title: 'Angeschlossene Geräte im Heimnetzwerk',
          popupValue: '128 Geräte derzeit online im Netzwerk',
        ),
      );

      expect(incidents, isEmpty, reason: incidents.join('\n'));
      expect(_horizontalScrollViews(CardPopupForm), findsNothing);
    });
  });

  group('opening the normal form', () {
    testWidgets('a tap shows the card normal form in a dialog', (tester) async {
      final incidents = await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        open: true,
      );

      expect(find.byType(AppDialog), findsOneWidget);
      expect(
        find.text(_kNormalOnly),
        findsOneWidget,
        reason: 'the dialog must show the real normal form, not a summary',
      );
      expect(incidents, isEmpty, reason: incidents.join('\n'));
    });

    testWidgets('the dialog is one width, not the one the card declares',
        (tester) async {
      // The declaration used to be the dialog's width, which made the box a
      // different size for every card — and the numbers the specs declare run
      // 250 to 386, so the difference was visible and arbitrary. The fixed width
      // is above all of them (pinned in `dashboard_card_popup_overflow_test`), so
      // a card that asks for less is served, not squeezed.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        normalAbove: 300,
        open: true,
      );

      expect(_presentedFormWidth(tester, AppDialog), kCardPresentationWidth);
    });

    testWidgets('the dialog is one width on a screen with room to spare',
        (tester) async {
      // The other direction, and the one that made the presentation look wrong
      // on a desktop: with nothing declared the dialog took the whole viewport,
      // so one card sat in a box a thousand pixels wide.
      await _pump(
        tester,
        screenWidth: 600,
        cardWidth: 150,
        normalAbove: null,
        open: true,
      );

      expect(_presentedFormWidth(tester, AppDialog), kCardPresentationWidth);
    });

    testWidgets('the dialog is one width even for a card that asks for more',
        (tester) async {
      // A card asking 2000px used to get a full-bleed sheet on this screen,
      // because no dialog could hold what it asked for. It now gets the same
      // dialog as every other card: the width is the presentation's, and a card
      // that wants more scrolls inside it.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        normalAbove: 2000,
        open: true,
      );

      expect(find.byType(AppDialog), findsOneWidget);
      expect(_presentedFormWidth(tester, AppDialog), kCardPresentationWidth);
    });

    testWidgets('the dialog draws no second frame around the card',
        (tester) async {
      // The card is already a bordered, filled, rounded surface. `AppDialog`
      // draws another one around whatever it is given, so the presentation read
      // as a frame inside a frame. The dialog's surface has to paint nothing and
      // let the card be the frame.
      await _pump(tester, screenWidth: 1200, cardWidth: 150, open: true);

      final style = tester.widget<AppSurface>(_dialogSurface()).style;
      expect(
        style,
        isNotNull,
        reason: 'left to the theme the dialog paints its own container — this '
            'presentation has to override it',
      );
      expect(style!.backgroundColor.a, 0, reason: 'no second fill');
      expect(style.borderWidth, 0, reason: 'no second border');
      expect(style.shadows, isEmpty, reason: 'no second elevation');
      expect(style.backgroundGradient, isNull);
      expect(style.borderGradient, isNull);
    });

    testWidgets('and no second frame spends no space either', (tester) async {
      // The ink is half of it: 24px of dialog padding is a visible ring between
      // the two borders even when the outer one is invisible. Rects rather than
      // the padding value, because what the reader sees is the gap.
      await _pump(tester, screenWidth: 1200, cardWidth: 150, open: true);

      expect(
        tester.getRect(_dialogSurface()),
        tester.getRect(
          find.descendant(
            of: find.byType(AppDialog),
            matching: find.byType(DashboardCardTemplate),
          ),
        ),
        reason: 'the card fills the dialog exactly — any inset is the second '
            'frame, drawn in whitespace instead of ink',
      );
    });

    testWidgets('the form gets the height the card declares it needs',
        (tester) async {
      // The bug this pins (#1299). A *picked* popup does not just narrow the
      // card, it pins the cell to one grid row — so the box this form is tapped
      // out of is 120px, a third of what the card declares. Sizing the
      // presentation to that box means the full form is laid out in the very
      // height the popup form existed to escape, and its fixed chrome alone
      // (header plus gaps) already exceeds it.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        cardHeight: 120,
        normalHeight: 392,
        open: true,
      );

      expect(
        _presentedFormHeight(tester, AppDialog),
        392,
        reason: 'a card that declares it needs 392px must be given 392px — the '
            'cell it was collapsed to is a consequence of the degradation, not '
            'a measure of what the card needs',
      );
    });

    testWidgets('a cell taller than the declaration keeps the cell',
        (tester) async {
      // The other path into this form (#1239): the grid made the card narrow but
      // left its height alone, and a card can be resized taller than its spec's
      // floor. The form cannot tell the two paths apart, so it takes the larger
      // — extra height cannot cause the bottom overflow above, and the taller
      // box is the one the user was actually looking at.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        cardHeight: 500,
        normalHeight: 256,
        open: true,
      );

      expect(_presentedFormHeight(tester, AppDialog), 500);
    });

    testWidgets('with no declared height the form gets the cell',
        (tester) async {
      // Unchanged behaviour for anything that reaches this form without a spec
      // behind it — a card built outside the dashboard factory, or a shared
      // block under test.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        cardHeight: 240,
        normalHeight: null,
        open: true,
      );

      expect(_presentedFormHeight(tester, AppDialog), 240);
    });

    testWidgets('introduces no horizontal scrolling', (tester) async {
      // The card used here has none of its own, so anything found is the
      // presentation's — which is the thing under test.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        open: true,
      );

      expect(_horizontalScrollViews(AppDialog), findsNothing);
    });
  });

  group('the presented form is live, not a snapshot', () {
    // Reported from the built app: "tab 在 popup dialog 沒作用". Tapping a tab
    // inside the presentation moved the tab bar's own highlight and changed
    // nothing below it.
    //
    // The cause is not the tabs. `normalForm: this` hands the presentation a
    // `DashboardCardTemplate` that the element *above* the card already built,
    // with the selected index baked into it. The element that watches the index
    // is outside the dialog's tree, so the provider write lands, the tile's copy
    // of the card rebuilds, and the dialog's copy — which is a widget, not an
    // element of that build — cannot. Everything a card reads from a provider is
    // frozen the same way: its interval menu, its loading badge, its live
    // numbers.
    //
    // So the presentation has to build the card *widget* itself, and the fix is
    // to publish that widget where the presentation can reach it.

    testWidgets('a tab tapped in the presentation changes what it shows',
        (tester) async {
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        cardHeight: 120,
        normalHeight: 392,
        card: const _LiveTabbedCard(),
        open: true,
      );

      expect(
        find.text(_kTabA),
        findsOneWidget,
        reason: 'the presentation opens on the tab the card was showing',
      );

      await tester.tap(find.text('B'));
      await settleIgnoringAnimations(tester);

      expect(
        find.text(_kTabB),
        findsOneWidget,
        reason: 'the tab bar in the presentation is the only way to reach this '
            "card's other tabs — a tab that moves its own highlight and leaves "
            'the content behind is worse than no tab bar at all',
      );
      expect(find.text(_kTabA), findsNothing);
    });

    testWidgets('and the same tap works on the card at normal density',
        (tester) async {
      // The control that makes the test above about the presentation. Without
      // it, a fixture whose tabs never worked anywhere would fail identically
      // and point at the wrong file.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 600,
        cardHeight: 392,
        density: CardDensity.normal,
        card: const _LiveTabbedCard(),
      );

      expect(find.text(_kTabA), findsOneWidget);

      await tester.tap(find.text('B'));
      await settleIgnoringAnimations(tester);

      expect(find.text(_kTabB), findsOneWidget);
      expect(find.text(_kTabA), findsNothing);
    });

    testWidgets('a form with nothing published still opens', (tester) async {
      // `CardPopupForm` is reachable without a host above it — a shared block
      // under test, a card built outside the factory — and there the widget it
      // was handed is all there is. It must still be presented, because the
      // alternative is a tap that opens an empty box.
      await tester.pumpWidget(
        ProviderScope(
          child: Portal(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: _lightTheme(),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 150,
                    // The box is the only height on offer here — nothing
                    // published a declaration — so it is also the height the
                    // presented card is laid out in, and it has to be one the
                    // card fits in for this test to be about the fallback.
                    height: 240,
                    child: CardPopupForm(
                      title: _kTitle,
                      value: _kValue,
                      normalForm: _card(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await settleIgnoringAnimations(tester);

      await tester.tap(find.byType(CardPopupForm));
      await settleIgnoringAnimations(tester);

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text(_kNormalOnly), findsOneWidget);
    });
  });

  group('the presented form and the screen', () {
    testWidgets('a card that declares more than the screen has gets the screen',
        (tester) async {
      // The declaration is what the card needs, not what the device has, and the
      // two heights this ticket started feeding it are larger than the one it
      // replaced: a card declaring five grid rows is 664px, which is taller than
      // a landscape phone's whole viewport. Presented at its declared height it
      // would run off the bottom of the screen — the presentation has to be the
      // smaller of what the card asked for and what there is.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        cardHeight: 120,
        normalHeight: 2000,
        open: true,
      );

      expect(
        _presentedFormHeight(tester, AppDialog),
        _kScreenHeight - kCardPresentationInset * 2,
        reason: 'the presentation cannot be taller than the screen that has to '
            'show it, whatever the card declares',
      );
    });

    testWidgets('and a card that fits is not capped', (tester) async {
      // The control: a cap applied unconditionally would shrink every card to
      // the viewport and read as green above.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        cardHeight: 120,
        normalHeight: 392,
        open: true,
      );

      expect(_presentedFormHeight(tester, AppDialog), 392);
    });
  });

  group('the popup tile label', () {
    // Reported from the built app: "popup layout 預設給 2 寬吧 字都看不到". A picked
    // tile is two columns wide by design (#1299) — the pick is what pins it — so
    // the label is what has to change: one ellipsized `titleMedium` line at
    // 122px showed "Network St…", "System Stat…", "Community…", which is not a
    // value the user can read at a glance and is the whole promise of the form.

    testWidgets('is read whole at the tile width, not ellipsized',
        (tester) async {
      // The title is the label here because it is the longest thing the tile can
      // be asked to show — a card with no declared value falls back to it, and
      // the values themselves are shorter (`12 online`, `3/3`, an IP address).
      await _pump(
        tester,
        screenWidth: 320,
        cardWidth: _kPickedTileWidth,
        cardHeight: 120,
        card: _card(popupValue: null, title: 'Network Status'),
      );

      final label =
          tester.renderObject<RenderParagraph>(find.text('Network Status'));
      expect(
        label.didExceedMaxLines,
        isFalse,
        reason: 'the label is the only thing on the tile and the tile is the '
            'only thing on screen for this card — a clipped one leaves the user '
            'guessing which card they are looking at',
      );
    });

    testWidgets('and a value too long for two lines still fits the tile',
        (tester) async {
      // The bound on the other side: smaller type and a second line are room to
      // spend, not room to overflow. The longest German value on the shortest
      // tile the grid produces.
      final incidents = await _pump(
        tester,
        screenWidth: 320,
        cardWidth: _kPickedTileWidth,
        cardHeight: 120,
        card: _card(
          title: 'Angeschlossene Geräte im Heimnetzwerk',
          popupValue: '128 Geräte derzeit online im Netzwerk',
        ),
      );

      expect(incidents, isEmpty, reason: incidents.join('\n'));
    });
  });

  group('a screen too narrow for the dialog', () {
    /// The narrowest screen that can host the presentation with its inset intact,
    /// and one pixel less. Composed from the two constants rather than written as
    /// 448, so the pair below keeps straddling the boundary if either moves.
    const fits = kCardPresentationWidth + kCardPresentationInset * 2;

    testWidgets('uses a fullscreen sheet instead', (tester) async {
      // 320px is the supported floor: a screen that cannot hold the dialog at
      // all. The sheet spends nothing on inset, so the card gets all 320.
      final incidents = await _pump(
        tester,
        screenWidth: 320,
        cardWidth: 150,
        normalAbove: 400,
        open: true,
      );

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(AppDialog), findsNothing);
      expect(find.text(_kNormalOnly), findsOneWidget);
      expect(incidents, isEmpty, reason: incidents.join('\n'));
    });

    testWidgets('and the sheet gives the card the whole screen',
        (tester) async {
      // The whole reason to switch: if the sheet were not wider than what the
      // screen can offer a dialog, the switch would be decoration.
      await _pump(
        tester,
        screenWidth: 320,
        cardWidth: 150,
        normalAbove: 400,
        open: true,
      );

      expect(_presentedFormWidth(tester, AppBottomSheet), 320);
    });

    testWidgets('one pixel short of hosting the dialog is still a sheet',
        (tester) async {
      // `normalAbove: null` on both sides of the boundary, because the card's
      // declaration has no say in this any more: what decides is whether the
      // screen can seat the presentation's own width.
      await _pump(
        tester,
        screenWidth: fits - 1,
        cardWidth: 150,
        normalAbove: null,
        open: true,
      );

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(AppDialog), findsNothing);
    });

    testWidgets('and the narrowest screen that can host it gets the dialog',
        (tester) async {
      // The positive control for the line above: without it the sheet could be
      // the only branch and every assertion above would still pass.
      await _pump(
        tester,
        screenWidth: fits,
        cardWidth: 150,
        normalAbove: null,
        open: true,
      );

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.byType(AppBottomSheet), findsNothing);
      expect(
        _presentedFormWidth(tester, AppDialog),
        kCardPresentationWidth,
        reason: 'at the boundary the card gets the full width, not a squeezed '
            'one — being squeezed is what the sheet exists to avoid',
      );
    });

    testWidgets('a screen wide enough keeps the dialog', (tester) async {
      // The control: the sheet must be the narrow-screen branch, not the branch.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        normalAbove: 400,
        open: true,
      );

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.byType(AppBottomSheet), findsNothing);
    });
  });

  group('keyboard', () {
    testWidgets('the popup form opens on Enter after Tab', (tester) async {
      // AC: reachable by keyboard. It is the only route to this card's content,
      // so a pointer-only tap target would put it out of reach entirely.
      await _pump(tester, screenWidth: 1200, cardWidth: 150);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleIgnoringAnimations(tester);

      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text(_kNormalOnly), findsOneWidget);
    });

    testWidgets('the dialog dismisses on Escape', (tester) async {
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        open: true,
      );
      expect(find.byType(AppDialog), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleIgnoringAnimations(tester);

      expect(find.byType(AppDialog), findsNothing);
      expect(find.byType(CardPopupForm), findsOneWidget);
    });
  });

  group('the 200px threshold', () {
    test('is one named constant', () {
      // AC: "changeable in one place". The form does not carry its own copy.
      expect(kPopupBelow, 200.0);
    });
  });

  group('the presentation width', () {
    test('is one named constant', () {
      // The behaviour tests above read the constant, so this is the one place
      // the number itself is written down — deliberately, because everything
      // else about the presentation follows from it and only its floor is
      // derived (it must clear every threshold a spec declares, which
      // `dashboard_card_popup_overflow_test.dart` pins). 400 is also `ui_kit`'s
      // own dialog width, so the presentation is the standard size rather than a
      // bespoke one.
      expect(kCardPresentationWidth, 400.0);
    });
  });

  group('a threshold set too low', () {
    // #1240 AC 4: "the gate fails when a threshold is set too low — verified by
    // deliberately lowering one." Exercised on `_overflowingCard` rather than on
    // a registered card because #1240's re-measurement found all 18 clean at
    // every width the grid produces: no threshold any of them could declare
    // produces an overflow for the gate to catch. What the pair below shows is
    // the mechanism's half of the claim — that the density selection, not the
    // probe, is what decides whether the overflowing form is on screen — and it
    // is the same overflow report `dashboard_card_overflow_test.dart` asserts on.
    //
    // 191px is the narrowest width the grid produces, and both cases pump it; the
    // only difference is the number the card declares.
    List<OverflowIncident> significant(List<OverflowIncident> incidents) =>
        incidents.where((i) => i.pixels > 2.0).toList();

    testWidgets(
        'leaves the card in the form that overflows, and it is reported',
        (tester) async {
      // 150 < 191, so the card claims to be whole at a width it is not: density
      // selects normal and the 400px child overflows the 191px cell.
      final incidents = await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 191,
        normalAbove: 150,
        density: null,
        card: _overflowingCard(),
      );

      expect(
        find.byType(CardPopupForm),
        findsNothing,
        reason: 'a threshold below the pumped width selects the normal form — '
            'that is what makes the threshold too low',
      );
      expect(significant(incidents), isNotEmpty);
    });

    testWidgets('and the same card is clean once the threshold is honest',
        (tester) async {
      // The control. Without it the test above passes on a card that overflows
      // in every form, which would prove nothing about the threshold.
      final incidents = await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 191,
        normalAbove: 400,
        density: null,
        card: _overflowingCard(),
      );

      expect(find.byType(CardPopupForm), findsOneWidget);
      expect(significant(incidents), isEmpty);
    });
  });
}
