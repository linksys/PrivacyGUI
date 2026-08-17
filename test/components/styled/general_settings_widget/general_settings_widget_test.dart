@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/language_tile.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/theme_mode_tile.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/supported_locales_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Coverage for the language picker's visibility in an English-only build, the
/// flavour `tools/locale_strip.dart` produces.
///
/// A build stripped to one language pack has nothing to pick between, so the
/// picker must not be offered — and because the parent wraps it in a fixed-height
/// SizedBox, the tile cannot hide itself without leaving a 44px hole in the popup.
/// The decision therefore belongs to the parent, which is what these tests pin.
void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    final config = ThemeJsonConfig.defaultConfig();
    if (!getIt.isRegistered<ThemeJsonConfig>()) {
      getIt.registerSingleton<ThemeJsonConfig>(config);
    }
    // GeneralSettingsWidget reads the dark theme out of getIt for its icon
    // colour, so the host has to provide one.
    if (!getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
      getIt.registerSingleton<ThemeData>(
        config.createDarkTheme(),
        instanceName: 'darkThemeData',
      );
    }
  });

  Widget buildHost({List<Locale>? supportedLocales}) {
    // Portal: AppPopupButton renders its content through flutter_portal.
    return Portal(
      child: ProviderScope(
        overrides: [
          if (supportedLocales != null)
            supportedLocalesProvider.overrideWithValue(supportedLocales),
        ],
        child: MaterialApp(
          theme: GetIt.instance.get<ThemeData>(instanceName: 'darkThemeData'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          // The same list the provider is overridden with, so `Localizations`
          // and the widget cannot disagree about which build this is. They did:
          // the host always offered all 26 while the override said one, and the
          // tests passed only because they assert on `locale_item_*` keys rather
          // than on rendered strings.
          supportedLocales:
              supportedLocales ?? AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: GeneralSettingsWidget(),
          ),
        ),
      ),
    );
  }

  /// Opens the settings popup, which is where the language picker lives.
  Future<void> openPopup(WidgetTester tester) async {
    await tester.tap(find.byType(Icon).first);
    await tester.pumpAndSettle();
  }

  testWidgets('offers the language picker when the build ships several locales',
      (tester) async {
    await tester.pumpWidget(buildHost(
      supportedLocales: const [Locale('en'), Locale('ja')],
    ));

    await openPopup(tester);

    expect(find.byType(LanguageTile), findsOneWidget);
  });

  testWidgets('omits the language picker when the build ships one locale',
      (tester) async {
    await tester.pumpWidget(buildHost(
      supportedLocales: const [Locale('en')],
    ));

    await openPopup(tester);

    expect(find.byType(LanguageTile), findsNothing);
  });

  testWidgets('keeps the rest of the popup when the language picker is omitted',
      (tester) async {
    // Guards against the omission taking a sibling with it: everything below the
    // picker still has to be reachable in an English-only build.
    await tester.pumpWidget(buildHost(
      supportedLocales: const [Locale('en')],
    ));

    await openPopup(tester);

    expect(find.byType(ThemeModeTile), findsOneWidget);
  });

  testWidgets('offers the picker by default, for the retail build',
      (tester) async {
    // No override: the widget falls back to what the build actually compiled,
    // which is every language pack that survived the strip.
    //
    // The precondition is asserted rather than branched on. Written as a
    // conditional (`length > 1 ? findsOneWidget : findsNothing`) this test could
    // not fail — run against a stripped tree it asserted the opposite of its own
    // name and still passed.
    expect(
      AppLocalizations.supportedLocales.length,
      greaterThan(1),
      reason: 'this test covers the retail build; run it on an unstripped tree '
          '(dart run tools/locale_strip.dart restore)',
    );

    await tester.pumpWidget(buildHost());

    await openPopup(tester);

    expect(find.byType(LanguageTile), findsOneWidget);
  });

  testWidgets('lists only the locales the build shipped', (tester) async {
    // The visibility gate and the picker's contents have to come from the same
    // place. They did not: the gate was injectable while the list was read from
    // the compile-time static, so a two-locale build would have shown the tile
    // and then offered all 26 — and no test could see it, because asserting on
    // visibility alone gave more confidence than it covered.
    await tester.pumpWidget(buildHost(
      supportedLocales: const [Locale('en'), Locale('ja')],
    ));

    await openPopup(tester);
    await tester.tap(find.byType(LanguageTile));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('locale_item_en')), findsOneWidget);
    expect(find.byKey(const Key('locale_item_ja')), findsOneWidget);
    expect(find.byKey(const Key('locale_item_fr')), findsNothing);
    expect(find.byKey(const Key('locale_item_zh-TW')), findsNothing);
  });
}
