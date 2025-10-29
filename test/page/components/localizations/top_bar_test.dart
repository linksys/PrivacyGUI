import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/language_tile.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacy_gui/page/login/views/login_local_view.dart';

import '../../../common/test_responsive_widget.dart';
import '../../../common/config.dart';
import '../../../common/test_helper.dart';

final _topBarScreens = [
  ...responsiveMobileScreens.map((e) => e.copyWith(height: 1600)).toList(),
  ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1600)).toList()
];

void main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  testLocalizations(
    'General Settings - popup with system theme when logged in',
    (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        themeMode: ThemeMode.system,
        overrides: [
          appSettingsProvider.overrideWith(
              () => MockAppSettingsNotifier(AppSettings(locale: locale)))
        ],
        child: const LoginLocalView(),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'General Settings - popup with light theme when logged in',
    (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        themeMode: ThemeMode.light,
        overrides: [
          appSettingsProvider
              .overrideWith(() => MockAppSettingsNotifier(AppSettings(
                    themeMode: ThemeMode.light,
                    locale: locale,
                  ))),
        ],
        child: const LoginLocalView(),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'General Settings - popup with dark theme when logged in',
    (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        themeMode: ThemeMode.dark,
        overrides: [
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.dark, locale: locale))),
        ],
        child: const LoginLocalView(),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'General Settings - popup with system theme when not log in yet',
    (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        themeMode: ThemeMode.system,
        overrides: [
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.system, locale: locale))),
        ],
        child: const LoginLocalView(),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'General Settings - popup with light theme when not log in yet',
    (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        themeMode: ThemeMode.light,
        overrides: [
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.light, locale: locale))),
        ],
        child: const LoginLocalView(),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'General Settings - popup with dark theme when not log in yet',
    (tester, locale) async {
      await testHelper.pumpShellView(
        tester,
        themeMode: ThemeMode.dark,
        overrides: [
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.dark, locale: locale))),
        ],
        child: const LoginLocalView(),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations('General Settings - Language selection modal',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      themeMode: ThemeMode.dark,
      overrides: [
        appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
            AppSettings(themeMode: ThemeMode.dark, locale: locale))),
      ],
      child: const LoginLocalView(),
    );
    testHelper.mockAuthNotifier.state =
        const AsyncData(AuthState(loginType: LoginType.none));
    await tester.pumpAndSettle();

    final settingsFinder = find.byIcon(LinksysIcons.person);
    await tester.tap(settingsFinder);
    await tester.pumpAndSettle();
    final localeTileFinder = find.byType(LanguageTile);
    await tester.tap(localeTileFinder);
    await tester.pumpAndSettle();
  }, screens: _topBarScreens);
}

class MockAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings? init;
  MockAppSettingsNotifier(this.init) : super();
  @override
  AppSettings build() => init ?? const AppSettings();
}