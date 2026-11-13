import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/all_widget_specs_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/settings/usp_layout_settings_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// #1312: the layout settings panel names cards in the user's language.
///
/// Japanese, with Network Topology taken off the grid so it is offered for
/// re-adding. Its name is the card's own title key, `networkTopology`, which
/// `app_ja.arb` translates as "ネットワークトポロジー".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPanel(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The built-in specs only, so the package-widget loader (HTTP) is never
    // constructed.
    final container = ProviderContainer(overrides: [
      allWidgetSpecsProvider.overrideWithValue(UspWidgetSpecs.all),
    ]);
    addTearDown(container.dispose);

    container.read(uspSliverDashboardControllerProvider);
    await container.read(uspLayoutPreferencesProvider.notifier).initialized;
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.runAsync(() => container
        .read(uspSliverDashboardControllerProvider.notifier)
        .removeWidget('topology'));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        // Flat: the default style animates its borders, so nothing settles.
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (c) =>
              CustomDesignTheme.fromJson({'style': 'flat'}),
        ),
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: UspLayoutSettingsPanel(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('lists a card by its name in the user language', (tester) async {
    await pumpPanel(tester);

    expect(find.text('ネットワークトポロジー'), findsOneWidget);
    expect(find.text('Network Topology'), findsNothing);
  });

  testWidgets('says which card was added in the user language', (tester) async {
    await pumpPanel(tester);

    final row = find.ancestor(
      of: find.text('ネットワークトポロジー'),
      matching: find.byType(ListTile),
    );
    await tester
        .tap(find.descendant(of: row, matching: find.byType(AppIconButton)));
    // addWidget persists the layout before the snackbar is shown, and the
    // preferences write needs real async time.
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // `app_ja.arb`: addedWidgetNamed is "{name} を追加しました".
    expect(find.text('ネットワークトポロジー を追加しました'), findsOneWidget,
        reason: 'A localized frame around the English "Network Topology" is '
            'the half-translated sentence #1312 removes.');
  });
}
