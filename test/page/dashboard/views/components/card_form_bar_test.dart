@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/all_widget_specs_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/selected_card_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/card_form_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// #1299 AC 4 — the control that makes a form selectable, and the cards it is
/// offered for.
///
/// The control is a row in the edit-mode toolbar acting on the card the user
/// selected in the grid. Two placements were tried and rejected before it:
///
/// * On the card. A spike result, not a taste call —
///   `test/page/dashboard/views/density_control_gesture_spike_test.dart` shows
///   that edit mode's `AbsorbPointer` swallows anything drawn inside a card, and
///   that hoisting a control above it arms a drag on desktop which
///   `cancelInteraction()` does not stop.
/// * In the layout settings dialog, which is where it first shipped. It asked the
///   user to find the card they were looking at in a list of every card's name, in
///   a dialog covering the grid they were looking at it in.
///
/// "Edit mode only" needs no assertion here and no guard in the widget: the row is
/// built inside `if (isEditMode)` in `usp_sliver_dashboard_view.dart`. What is
/// asserted here is the part that can silently drift: **which selection produces a
/// picker**, which forms it offers, and whether picking one reaches the controller.
///
/// The mirror that carries the grid's selection into
/// [selectedCardIdProvider] is asserted in
/// `test/page/dashboard/providers/usp_layout_controller_selection_test.dart`; this
/// file drives the real controller, so the two meet at the real beacon rather than
/// at a stub.
///
/// ## Mutation table
///
/// Each row is one edit to the real source, run against this file. Two rows sit in
/// `usp_layout_controller.dart` rather than in the widget: what "the selection" is
/// is decided there, and this file is where the consequence shows.
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | card_form_bar | drop the `options.isNotEmpty` guard | stats_panel gets a picker with one entry |
/// | 2 | card_form_bar | `context.currentMaxColumns` → a hard-coded 12 | the mobile-breakpoint pick reads as normal |
/// | 3 | card_form_bar | `value: selected` → `value: CardDensity.normal` | 2 — picking popup, and the pick it shows |
/// | 4 | usp_layout_controller | `_publishSelection` takes the first of the set instead of requiring one | two cards selected shows a picker |
/// | 5 | card_form_bar | `onChanged` drops the `density == selected` early return | **survived** — equivalent, see below |
/// | 6 | card_form_bar | drop the grid-membership check | **survived** — the check was then deleted, see below |
///
/// ### Row 5, the equivalent mutation
///
/// Re-picking the form a card is already in is refused twice: here, and inside
/// `setCardForm`, which keeps the box it recorded on the way into popup rather than
/// overwriting it with the 2x1 tile. Removing *this* guard changes nothing
/// observable — the second call produces the same layout — so the row is an
/// equivalent mutation, and the guard is a saved pref write rather than the thing
/// protecting the restore. That invariant is stated where it is decided, in
/// `usp_card_form_persistence_test.dart` ("picking popup twice still restores the
/// first box, not the tile"), whose ledger row for the inner guard does kill.
///
/// ### Row 6, the branch that could not run
///
/// The row is kept because it is the reason the code no longer has the branch. The
/// first version of the widget checked the selected id against the ids on the grid
/// before naming it, and no test could kill dropping that check — including the
/// removal test below, which passes either way. The cause: every removal path ends
/// in `DashboardController.removeItems`, which calls `clearSelection()` itself, so
/// a selected id that is not on the grid is not a reachable state. The check was
/// deleted rather than left as an untested branch, and the removal test stays to
/// pin the behaviour it was guessing at.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// Desktop, so `context.currentMaxColumns` is 12 — the slot count a fresh
/// controller starts on, which is what makes a pick made here readable here.
const _desktopSurface = Size(1280, 900);

/// Mobile: `currentMaxColumns` 4, matching [UspLayoutEnvelope.mobileSlotCount].
const _mobileSurface = Size(500, 900);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Boots the row over a real layout controller.
  ///
  /// [allWidgetSpecsProvider] is overridden with the built-in specs so the
  /// package-widget loader — which reaches for `apps.json` over HTTP — is never
  /// constructed. It contributes nothing to this ticket: a package widget has no
  /// `WidgetSpec` in [UspWidgetSpecs], so `selectableForms` returns nothing for it
  /// and it is never offered a form.
  Future<ProviderContainer> pumpBar(
    WidgetTester tester, {
    Size surface = _desktopSurface,
  }) async {
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      allWidgetSpecsProvider.overrideWithValue(UspWidgetSpecs.all),
    ]);
    addTearDown(container.dispose);

    container.read(uspSliverDashboardControllerProvider);
    await container.read(uspLayoutPreferencesProvider.notifier).initialized;
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _testTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CardFormBar()),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  DashboardController controllerOf(ProviderContainer container) =>
      container.read(uspSliverDashboardControllerProvider);

  /// Selects [cardId] the way a tap on the card does, then lets the mirror land.
  Future<void> select(
    WidgetTester tester,
    ProviderContainer container,
    String cardId, {
    bool multi = false,
  }) async {
    controllerOf(container).toggleSelection(cardId, multi: multi);
    await tester.pumpAndSettle();
  }

  final picker = find.byWidgetPredicate((widget) =>
      widget is AppDropdown<CardDensity> &&
      widget.identifier == 'card-form-picker');

  AppDropdown<CardDensity> readPicker(WidgetTester tester) =>
      tester.widget<AppDropdown<CardDensity>>(picker);

  Finder promptText(WidgetTester tester) =>
      find.text(AppLocalizations.of(tester.element(find.byType(CardFormBar)))!
          .cardFormSelectPrompt);

  /// The layout item for [cardId], straight off the controller.
  Map readItem(ProviderContainer container, String cardId) => controllerOf(
        container,
      ).exportLayout().firstWhere((e) => (e as Map)['id'] == cardId) as Map;

  group('which selection produces a picker', () {
    testWidgets('nothing selected shows what to do instead', (tester) async {
      await pumpBar(tester);

      expect(picker, findsNothing);
      expect(promptText(tester), findsOneWidget,
          reason: 'The row keeps its place in the column when empty rather '
              'than appearing on selection: a row that came and went would '
              'shove the grid down by its own height on every card tap.');
    });

    testWidgets('selecting a card names it and offers its forms',
        (tester) async {
      final container = await pumpBar(tester);
      await select(tester, container, 'device_info');

      expect(picker, findsOneWidget);
      expect(find.text('Device Info'), findsOneWidget,
          reason: 'The row has to say which card it is about — the grid border '
              'says it too, but the border is off-screen as soon as the user '
              'scrolls.');
    });

    testWidgets('two cards selected reads as no selection', (tester) async {
      final container = await pumpBar(tester);
      await select(tester, container, 'device_info');
      await select(tester, container, 'lan_info', multi: true);

      expect(controllerOf(container).selectedItemIds.value, hasLength(2));
      expect(picker, findsNothing,
          reason: 'A form is picked per card, so "the selection" has to be one '
              'card. Reshaping whichever card happens to be first in the set '
              'would be a guess at which one the user meant.');
      expect(promptText(tester), findsOneWidget);
    });

    testWidgets('stats_panel is named but offered nothing', (tester) async {
      final container = await pumpBar(tester);
      await select(tester, container, 'stats_panel');

      expect(picker, findsNothing,
          reason: 'It is the one card excluded from the popup form (it is the '
              'full-width hero row, which has no icon-and-one-value reading) '
              'and it declares no compact threshold. A picker whose only entry '
              'is the form the card is already in cannot do anything.');
      expect(find.text('Stats Panel'), findsOneWidget,
          reason: 'Naming it without a picker reads as "selected, nothing to '
              'choose". Falling back to the prompt would read as "your tap did '
              'not register".');
    });

    testWidgets('a card removed while still selected reads as no selection',
        (tester) async {
      final container = await pumpBar(tester);
      await select(tester, container, 'lan_info');
      expect(picker, findsOneWidget);

      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .removeWidget('lan_info');
      await tester.pumpAndSettle();

      expect(picker, findsNothing,
          reason:
              'A pick for a card that is not placed anywhere has nothing to '
              'apply to — `removeWidget` drops the stored pick for the same '
              'reason. What makes it hold is the package: `removeItems` clears '
              'the selection, so the mirror publishes null and the row falls '
              'back to the prompt without checking anything itself.');
    });

    testWidgets('the options offered are the forms the card actually built',
        (tester) async {
      final container = await pumpBar(tester);

      await select(tester, container, 'device_info');
      expect(
        readPicker(tester).items,
        [CardDensity.normal, CardDensity.compact, CardDensity.popup],
        reason: 'device_info declares normalAbove: 262, so it has a compact '
            'form.',
      );

      await select(tester, container, 'topology');
      expect(
        readPicker(tester).items,
        [CardDensity.normal, CardDensity.popup],
        reason: 'topology declares no threshold, so no compact form was ever '
            'built for it. #1299 is explicit that building the other twelve is '
            'out of scope — so the picker must not offer a form that does not '
            'exist.',
      );
    });
  });

  group('the picker reflects and writes the pick', () {
    testWidgets('with no pick stored it reads normal', (tester) async {
      final container = await pumpBar(tester);
      await select(tester, container, 'device_info');

      expect(readPicker(tester).value, CardDensity.normal,
          reason: 'Normal is the absence of a pick rather than a stored value, '
              'so an untouched card and a card explicitly set back to normal '
              'have to read the same.');
    });

    testWidgets('picking popup collapses the card and locks it',
        (tester) async {
      final container = await pumpBar(tester);
      await select(tester, container, 'device_info');
      final before = readItem(container, 'device_info');
      expect(before['w'], greaterThan(UspWidgetSpecs.popupColumns));

      readPicker(tester).onChanged!(CardDensity.popup);
      await tester.pumpAndSettle();

      expect(
        container
            .read(cardFormsProvider)
            .densityFor(UspLayoutEnvelope.desktopSlotCount, 'device_info'),
        CardDensity.popup,
      );
      final after = readItem(container, 'device_info');
      expect(after['w'], UspWidgetSpecs.popupColumns);
      expect(after['isResizable'], isFalse);
      expect(readPicker(tester).value, CardDensity.popup,
          reason: 'The row rebuilds off cardFormsProvider, so it has to show '
              'the pick it just made without being reopened.');
    });

    testWidgets('going back to normal restores the box it collapsed',
        (tester) async {
      final container = await pumpBar(tester);
      await select(tester, container, 'device_info');
      final originalW = readItem(container, 'device_info')['w'];

      readPicker(tester).onChanged!(CardDensity.popup);
      await tester.pumpAndSettle();
      readPicker(tester).onChanged!(CardDensity.normal);
      await tester.pumpAndSettle();

      expect(readItem(container, 'device_info')['w'], originalW,
          reason: 'AC 9. The size is recorded on the way into popup, because '
              'once the handles are gone no gesture could recover it.');
      expect(readItem(container, 'device_info')['isResizable'], isNot(isFalse));
    });

    testWidgets('re-picking the form the card is already in does nothing',
        (tester) async {
      final container = await pumpBar(tester);
      await select(tester, container, 'device_info');

      readPicker(tester).onChanged!(CardDensity.popup);
      await tester.pumpAndSettle();
      final afterFirst = readItem(container, 'device_info');

      // What this pins is the *outcome*: a second pick of the same form leaves
      // the card byte-identical. It does not pin this row's early return —
      // measured, that guard is an equivalent mutation, because `setCardForm` is
      // idempotent on its own (mutation table, row 6).
      readPicker(tester).onChanged!(CardDensity.popup);
      await tester.pumpAndSettle();

      expect(readItem(container, 'device_info'), afterFirst);
    });

    testWidgets('the pick it shows is the one for the breakpoint on screen',
        (tester) async {
      final container = await pumpBar(tester, surface: _mobileSurface);
      controllerOf(container).setSlotCount(UspLayoutEnvelope.mobileSlotCount);
      await tester.pumpAndSettle();

      // A pick stored on mobile only — the desktop grid has none.
      container.read(cardFormsProvider.notifier).state =
          CardForms.empty.withChoice(
        UspLayoutEnvelope.mobileSlotCount,
        'device_info',
        const CardFormChoice(density: CardDensity.popup),
      );
      await select(tester, container, 'device_info');

      expect(readPicker(tester).value, CardDensity.popup,
          reason: 'Picks are per breakpoint (#1294 keeps each breakpoint\'s '
              'layout to itself, and a form is part of that layout). Reading '
              'the desktop slot count here would show normal on a phone that '
              'is rendering a popup.');
    });
  });
}
