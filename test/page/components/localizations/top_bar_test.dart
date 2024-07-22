import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mock_notifiers/mock_auth_notifier.dart';

void main() async {
  late AuthNotifier mockAuthNotifier;

  setUp(() {
    mockAuthNotifier = MockAuthNotifier();
  });

  testLocalizations(
    'Test top bar with popup with system theme when logged in',
    (tester, locale) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.system,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(() => AppSettingsNotifier())
          ],
          router: GoRouter(routes: [
            LinksysRoute(path: '/', builder: (context, state) => const Center())
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
    'Test top bar with popup with light theme when logged in',
    (tester, locale) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.light,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(
                () => MockAppSettingsNotifier(const AppSettings(themeMode: ThemeMode.light))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(path: '/', builder: (context, state) => const Center())
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
    'Test top bar with popup with dark theme when logged in',
    (tester, locale) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.dark,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(
                () => MockAppSettingsNotifier(const AppSettings(themeMode: ThemeMode.dark))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(path: '/', builder: (context, state) => const Center())
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
    'Test top bar with popup with system theme when not log in yet',
    (tester, locale) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.system,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(
                () => MockAppSettingsNotifier(const AppSettings(themeMode: ThemeMode.system))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(path: '/', builder: (context, state) => const Center())
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
    'Test top bar with popup with light theme when not log in yet',
    (tester, locale) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.light,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(
                () => MockAppSettingsNotifier(const AppSettings(themeMode: ThemeMode.light))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(path: '/', builder: (context, state) => const Center())
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
    'Test top bar with popup with dark theme when not log in yet',
    (tester, locale) async {
      final provider = ProviderContainer();

      await tester.pumpWidget(
        testableRouter(
          themeMode: ThemeMode.dark,
          provider: provider,
          overrides: [
            authProvider.overrideWith(() => mockAuthNotifier),
            appSettingsProvider.overrideWith(
                () => MockAppSettingsNotifier(const AppSettings(themeMode: ThemeMode.dark))),
          ],
          router: GoRouter(routes: [
            LinksysRoute(path: '/', builder: (context, state) => const Center())
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
}

class MockAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings? init;
  MockAppSettingsNotifier(this.init) : super();
  @override
  AppSettings build() => init ?? const AppSettings();
}
