@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/all_widget_specs_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/settings/usp_layout_settings_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// #1299 AC 4 — the control that makes a form selectable, and the cards it is
/// offered for.
///
/// The control lives in the layout settings panel rather than on the card, and
/// that placement is a spike result rather than a taste call: see
/// `test/page/dashboard/views/density_control_gesture_spike_test.dart`. This file
/// asserts what the panel does with it.
///
/// "Edit mode only" needs no assertion here and no guard in the widget: this panel
/// is only reachable from `_openLayoutSettings`, wired to a toolbar button that is
/// built inside `if (isEditMode)` (`usp_sliver_dashboard_view.dart:219`). Asserting
/// it in this file would mean pumping the whole dashboard view to observe a
/// property of a button that is not part of the panel.
///
/// What is asserted is the part that can silently drift: **which cards are
/// offered a choice**, and whether picking one reaches the controller.
///
/// ## Mutation table
///
/// Each row is one edit to `usp_layout_settings_panel.dart`, applied to the real
/// file and run against this file.
///
/// | # | mutation | killed by |
/// |---|---|---|
/// | 1 | drop the `options.isNotEmpty` filter | 2 — the row count, and stats_panel gets none |
/// | 2 | drop the `currentIds.contains(spec.id)` filter | a card that was removed from the dashboard gets none |
/// | 3 | `value: selected` → `value: CardDensity.normal` | picking popup collapses the card and locks it |
/// | 4 | `onChanged` drops the `density == selected` early return | **survived** — see below |
///
/// ### The survivor, and what it exposed
///
/// Re-picking the form a card is already in is refused twice: here, and inside
/// `setCardForm`, which keeps the box it recorded on the way into popup rather than
/// overwriting it with the 2x1 tile. Removing *this* guard changes nothing
/// observable — the second call produces the same layout — so the row is an
/// equivalent mutation, and the guard is a saved pref write rather than the thing
/// protecting the restore.
///
/// That is worth more than the row: the test below reads as though it were pinning
/// the restore, and it is not. The invariant is now stated where it is decided, in
/// `usp_card_form_persistence_test.dart` ("picking popup twice still restores the
/// first box, not the tile"), whose ledger row for the inner guard does kill.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Boots the panel over a real layout controller.
  ///
  /// [allWidgetSpecsProvider] is overridden with the built-in specs so the
  /// package-widget loader — which reaches for `apps.json` over HTTP — is never
  /// constructed. It contributes nothing to this ticket: a package widget has no
  /// `WidgetSpec` in [UspWidgetSpecs], so `selectableForms` returns nothing for it
  /// and it is never offered a form. That exclusion is asserted below rather than
  /// assumed.
  Future<ProviderContainer> pumpPanel(
    WidgetTester tester, {
    Map<String, Object> initialValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
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
        home: const Scaffold(body: UspLayoutSettingsPanel()),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  /// The form dropdown for [cardId], by the identifier the panel gives it.
  ///
  /// By identifier rather than by position: the panel lists cards in
  /// `UspWidgetSpecs.all` order, and a test that indexed into that list would
  /// start asserting about the wrong card the next time a spec is added.
  Finder dropdownFor(String cardId) => find.byWidgetPredicate((widget) =>
      widget is AppDropdown<CardDensity> &&
      widget.identifier == 'card-form-$cardId');

  AppDropdown<CardDensity> readDropdown(WidgetTester tester, String cardId) =>
      tester.widget<AppDropdown<CardDensity>>(dropdownFor(cardId));

  /// The layout item for [cardId], straight off the controller.
  Map readItem(ProviderContainer container, String cardId) => container
      .read(uspSliverDashboardControllerProvider)
      .exportLayout()
      .firstWhere((e) => (e as Map)['id'] == cardId) as Map;

  group('which cards are offered a form', () {
    testWidgets('every card that has a second form gets a dropdown',
        (tester) async {
      await pumpPanel(tester);

      // The default dashboard carries all 18 built-in cards, and 17 of them have
      // a popup form — so 17 rows. The number is asserted rather than derived
      // from `selectableForms` on purpose: deriving it would make the test agree
      // with the implementation by construction, and the one fact worth pinning
      // is that the excluded card is excluded.
      expect(
        find.byWidgetPredicate((w) => w is AppDropdown<CardDensity>),
        findsNWidgets(17),
      );
      expect(dropdownFor('device_info'), findsOneWidget);
    });

    testWidgets('stats_panel gets none — it has no second form to offer',
        (tester) async {
      await pumpPanel(tester);

      expect(dropdownFor('stats_panel'), findsNothing,
          reason: 'It is the one card excluded from the popup form (it is the '
              'full-width hero row, which has no icon-and-one-value reading) and '
              'it declares no compact threshold. Offering a dropdown whose only '
              'entry is the form the card is already in is a control that cannot '
              'do anything.');
    });

    testWidgets('a card that was removed from the dashboard gets none',
        (tester) async {
      final container = await pumpPanel(tester);
      expect(dropdownFor('lan_info'), findsOneWidget);

      await container
          .read(uspSliverDashboardControllerProvider.notifier)
          .removeWidget('lan_info');
      await tester.pumpAndSettle();

      expect(dropdownFor('lan_info'), findsNothing,
          reason: 'The list is of cards on the dashboard, not of cards that '
              'exist. A form for a card that is not placed anywhere would be a '
              'pick with nothing to apply to — and `removeWidget` drops the pick '
              'for the same reason.');
    });

    testWidgets('the options offered are the forms the card actually built',
        (tester) async {
      await pumpPanel(tester);

      expect(
        readDropdown(tester, 'device_info').items,
        [CardDensity.normal, CardDensity.compact, CardDensity.popup],
        reason: 'device_info declares normalAbove: 262, so it has a compact '
            'form.',
      );
      expect(
        readDropdown(tester, 'topology').items,
        [CardDensity.normal, CardDensity.popup],
        reason: 'topology declares no threshold, so no compact form was ever '
            'built for it. #1299 is explicit that building the other twelve is '
            'out of scope — so the menu must not offer a form that does not '
            'exist.',
      );
    });
  });

  group('the dropdown reflects and writes the pick', () {
    testWidgets('with no pick stored it reads normal', (tester) async {
      await pumpPanel(tester);

      expect(readDropdown(tester, 'device_info').value, CardDensity.normal,
          reason: 'Normal is the absence of a pick rather than a stored value, '
              'so an untouched card and a card explicitly set back to normal '
              'have to read the same.');
    });

    testWidgets('picking popup collapses the card and locks it',
        (tester) async {
      final container = await pumpPanel(tester);
      final before = readItem(container, 'device_info');
      expect(before['w'], greaterThan(UspWidgetSpecs.popupColumns));

      readDropdown(tester, 'device_info').onChanged!(CardDensity.popup);
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
      expect(readDropdown(tester, 'device_info').value, CardDensity.popup,
          reason:
              'The panel rebuilds off cardFormsProvider, so the control has '
              'to show the pick it just made without being reopened.');
    });

    testWidgets('going back to normal restores the box it collapsed',
        (tester) async {
      final container = await pumpPanel(tester);
      final originalW = readItem(container, 'device_info')['w'];

      readDropdown(tester, 'device_info').onChanged!(CardDensity.popup);
      await tester.pumpAndSettle();
      readDropdown(tester, 'device_info').onChanged!(CardDensity.normal);
      await tester.pumpAndSettle();

      expect(readItem(container, 'device_info')['w'], originalW,
          reason: 'AC 9. The size is recorded on the way into popup, because '
              'once the handles are gone no gesture could recover it.');
      expect(readItem(container, 'device_info')['isResizable'], isNot(isFalse));
    });

    testWidgets('re-picking the form the card is already in does nothing',
        (tester) async {
      final container = await pumpPanel(tester);

      readDropdown(tester, 'device_info').onChanged!(CardDensity.popup);
      await tester.pumpAndSettle();
      final afterFirst = readItem(container, 'device_info');

      // What this pins is the *outcome*: a second pick of the same form leaves the
      // card byte-identical. It does not pin the panel's early return — measured,
      // that guard is an equivalent mutation, because `setCardForm` is idempotent
      // on its own (mutation table, row 4). The restore itself is pinned in
      // `usp_card_form_persistence_test.dart`.
      readDropdown(tester, 'device_info').onChanged!(CardDensity.popup);
      await tester.pumpAndSettle();

      expect(readItem(container, 'device_info'), afterFirst);
    });
  });
}
