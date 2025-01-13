import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/language_tile.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/_index.dart';
import '../../../mocks/mock_auth_notifier.dart';

void main() async {
  late AuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
  });

  testLocalizations(
    'General Settings - popup with system theme when logged in',
    (tester, locale) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.system,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(
                () => MockAppSettingsNotifier(AppSettings(locale: locale)))
          ],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) => const StyledAppPageView(
                      child: Center(),
                    ))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
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
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.light,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider
                .overrideWith(() => MockAppSettingsNotifier(AppSettings(
                      themeMode: ThemeMode.light,
                      locale: locale,
                    ))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) => const StyledAppPageView(
                      child: Center(),
                    ))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
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
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.dark,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
                AppSettings(themeMode: ThemeMode.dark, locale: locale))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) => const StyledAppPageView(
                      child: Center(),
                    ))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
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
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.system,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
                AppSettings(themeMode: ThemeMode.system, locale: locale))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) => const StyledAppPageView(
                      child: Center(),
                    ))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
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
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.light,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
                AppSettings(themeMode: ThemeMode.light, locale: locale))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) => const StyledAppPageView(
                      child: Center(),
                    ))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
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
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.dark,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
                AppSettings(themeMode: ThemeMode.dark, locale: locale))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(
                path: '/',
                builder: (context, state) => const StyledAppPageView(
                      child: Center(),
                    ))
          ], initialLocation: '/'),
        ),
      );
      mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(LinksysIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations('General Settings - Language selection modal',
      (tester, locale) async {
    final provider = ProviderContainer();

    await tester.pumpWidget(
      testableRouter(
        themeMode: ThemeMode.dark,
        provider: provider,
        overrides: [
          authProvider.overrideWith(() => mockAuthNotifier),
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.dark, locale: locale))),
        ],
        router: GoRouter(routes: [
          LinksysRoute(
              path: '/',
              builder: (context, state) => const StyledAppPageView(
                    child: Center(),
                  ))
        ], initialLocation: '/'),
      ),
    );
    mockAuthNotifier.state =
        const AsyncData(AuthState(loginType: LoginType.none));
    await tester.pumpAndSettle();

    final settingsFinder = find.byIcon(LinksysIcons.person);
    await tester.tap(settingsFinder);
    await tester.pumpAndSettle();
    final localeTileFinder = find.byType(LanguageTile);
    await tester.tap(localeTileFinder);
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1600)).toList(),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1600)).toList()
  ]);
}

class MockAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings? init;
  MockAppSettingsNotifier(this.init) : super();
  @override
  AppSettings build() => init ?? const AppSettings();
}
