@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
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
const String _kCardId = 'connected_devices';
const String _kTitle = 'Connected Devices';
const String _kValue = '12 online';

/// Text that appears in the *normal* form only. The single most important
/// assertion in this file is about where this string is and is not: below 200px
/// the card must not be rendering its full content, and after a tap it must be.
const String _kNormalOnly = 'normal-form-only-content';
const Key _kLeadingKey = Key('popup-leading');

ThemeData _lightTheme() => ThemeJsonConfig.defaultConfig().createLightTheme();

/// Horizontal space `AppDialog` spends on its own chrome, from the theme — the
/// same source production reads. Hardcoding 48 here would make the test agree
/// with a number rather than with the dialog.
double _dialogChromeOf(ThemeData theme) {
  final style = theme.extension<AppDesignTheme>()!.dialogStyle;
  return style.padding.horizontal + style.containerStyle.borderWidth * 2;
}

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
  CardDensity? density = CardDensity.popup,
  Widget? card,
  bool open = false,
}) {
  final surface = Size(screenWidth, 800);
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

/// Width the card's normal form was actually given inside [ancestor].
double _presentedFormWidth(WidgetTester tester, Type ancestor) => tester
    .getSize(
      find.descendant(
        of: find.byType(ancestor),
        matching: find.byType(DashboardCardTemplate),
      ),
    )
    .width;

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

    testWidgets('the form gets the width the card declares it needs',
        (tester) async {
      // 1200px screen, so the fit width is what binds rather than the screen.
      await _pump(
        tester,
        screenWidth: 1200,
        cardWidth: 150,
        normalAbove: 400,
        open: true,
      );

      expect(
        _presentedFormWidth(tester, AppDialog),
        400,
        reason: 'a card that declares it is whole above 400px must be given '
            '400px, or the dialog reproduces the overflow it came from',
      );
    });

    testWidgets('with no declared fit width the form gets all the dialog has',
        (tester) async {
      // Overflow is monotonic in width, so with nothing to aim at the widest
      // available is the safest.
      final theme = _lightTheme();
      await _pump(
        tester,
        screenWidth: 600,
        cardWidth: 150,
        normalAbove: null,
        open: true,
      );

      expect(
        _presentedFormWidth(tester, AppDialog),
        600 - kCardPresentationInset * 2 - _dialogChromeOf(theme),
      );
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

  group('a screen too narrow for the dialog', () {
    testWidgets('uses a fullscreen sheet instead', (tester) async {
      // 320px is the supported floor, and a card declaring 400 cannot be shown
      // whole in a dialog there: the dialog spends part of that 320 on inset and
      // padding. The sheet spends none of it.
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

    testWidgets('and the sheet is wider than the dialog could have been',
        (tester) async {
      // The whole reason to switch: if the sheet were not wider, the switch
      // would be decoration.
      final theme = _lightTheme();
      await _pump(
        tester,
        screenWidth: 320,
        cardWidth: 150,
        normalAbove: 400,
        open: true,
      );

      final sheetWidth = _presentedFormWidth(tester, AppBottomSheet);
      expect(
        sheetWidth,
        greaterThan(320 - kCardPresentationInset * 2 - _dialogChromeOf(theme)),
      );
      expect(sheetWidth, lessThanOrEqualTo(320));
    });

    testWidgets(
        'is not about small screens — a wide card gets a sheet at 600px',
        (tester) async {
      // The rule is a relationship, not a breakpoint: a card asking for 2000px
      // cannot be shown whole in a dialog on a 600px screen either, so it gets
      // the sheet too. Written after the first draft of this file asserted "the
      // dialog never grows past the screen" here and found no dialog at all —
      // the presentation squeezes nothing, it switches.
      await _pump(
        tester,
        screenWidth: 600,
        cardWidth: 150,
        normalAbove: 2000,
        open: true,
      );

      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byType(AppDialog), findsNothing);
      expect(
        _presentedFormWidth(tester, AppBottomSheet),
        600,
        reason: 'the sheet gives the card the whole screen — the most this '
            'device has for a card that wants more than it has',
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
