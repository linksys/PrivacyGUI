import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:privacy_gui/page/components/styled/general_settings_widget/language_tile.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/test_responsive_widget.dart';
import '../../../common/config.dart';

import '../../../common/test_helper.dart';

final _topBarScreens = [
  ...responsiveMobileScreens.map((e) => e.copyWith(height: 1600)).toList(),
  ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1600)).toList()
];

// Reference to Implementation File: lib/page/components/aligned_top_bar.dart
// View ID: GENSET
/// | Test ID             | Description                                                                 |
/// | :------------------ | :-------------------------------------------------------------------------- |
/// | `GENSET-SYS_LOGGED` | Verifies General Settings popup with system theme when logged in.           |
/// | `GENSET-LGT_LOGGED` | Verifies General Settings popup with light theme when logged in.            |
/// | `GENSET-DRK_LOGGED` | Verifies General Settings popup with dark theme when logged in.             |
/// | `GENSET-SYS_GUEST`  | Verifies General Settings popup with system theme when guest (not logged in).|
/// | `GENSET-LGT_GUEST`  | Verifies General Settings popup with light theme when guest.                |
/// | `GENSET-DRK_GUEST`  | Verifies General Settings popup with dark theme when guest.                 |
/// | `GENSET-LANG_SEL`   | Verifies Language Selection modal traversal.                                |

void main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  // Test ID: GENSET-SYS_LOGGED
  testLocalizations(
    'General Settings - popup with system theme when logged in',
    (tester, screen) async {
      testHelper.disableAnimations = false;
      await testHelper.pumpView(
        tester,
        navigatorKey: GlobalKey<NavigatorState>(),
        themeMode: ThemeMode.system,
        overrides: [
          appSettingsProvider.overrideWith(
              () => MockAppSettingsNotifier(AppSettings(locale: screen.locale)))
        ],
        child: UiKitPageView(
          child: (context, constraints) => Center(),
        ),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(AppFontIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      await testHelper.takeScreenshot(tester, 'GENSET-SYS_LOGGED-01-popup');
    },
    helper: testHelper,
  );

  // Test ID: GENSET-LGT_LOGGED
  testLocalizations(
    'General Settings - popup with light theme when logged in',
    (tester, screen) async {
      testHelper.disableAnimations = false;
      await testHelper.pumpView(
        tester,
        navigatorKey: GlobalKey<NavigatorState>(),
        themeMode: ThemeMode.light,
        overrides: [
          appSettingsProvider
              .overrideWith(() => MockAppSettingsNotifier(AppSettings(
                    themeMode: ThemeMode.light,
                    locale: screen.locale,
                  ))),
        ],
        child: UiKitPageView(
          child: (context, constraints) => Center(),
        ),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(AppFontIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      await testHelper.takeScreenshot(tester, 'GENSET-LGT_LOGGED-01-popup');
    },
    helper: testHelper,
  );

  // Test ID: GENSET-DRK_LOGGED
  testLocalizations(
    'General Settings - popup with dark theme when logged in',
    (tester, screen) async {
      testHelper.disableAnimations = false;
      await testHelper.pumpView(
        tester,
        navigatorKey: GlobalKey<NavigatorState>(),
        themeMode: ThemeMode.dark,
        overrides: [
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.dark, locale: screen.locale))),
        ],
        child: UiKitPageView(
          child: (context, constraints) => Center(),
        ),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.local));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(AppFontIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      await testHelper.takeScreenshot(tester, 'GENSET-DRK_LOGGED-01-popup');
    },
    helper: testHelper,
  );

  // Test ID: GENSET-SYS_GUEST
  testLocalizations(
    'General Settings - popup with system theme when not log in yet',
    (tester, screen) async {
      testHelper.disableAnimations = false;
      await testHelper.pumpView(
        tester,
        navigatorKey: GlobalKey<NavigatorState>(),
        themeMode: ThemeMode.system,
        overrides: [
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.system, locale: screen.locale))),
        ],
        child: UiKitPageView(
          child: (context, constraints) => Center(),
        ),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pump(Duration(
          seconds:
              10)); // Keep original delay logic? maybe shorten if robust. Keeping for safety.

      final settingsFinder = find.byIcon(AppFontIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      await testHelper.takeScreenshot(tester, 'GENSET-SYS_GUEST-01-popup');
    },
    helper: testHelper,
  );

  // Test ID: GENSET-LGT_GUEST
  testLocalizations(
    'General Settings - popup with light theme when not log in yet',
    (tester, screen) async {
      testHelper.disableAnimations = false;
      await testHelper.pumpView(
        tester,
        navigatorKey: GlobalKey<NavigatorState>(),
        themeMode: ThemeMode.light,
        overrides: [
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.light, locale: screen.locale))),
        ],
        child: UiKitPageView(
          child: (context, constraints) => Center(),
        ),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(AppFontIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      await testHelper.takeScreenshot(tester, 'GENSET-LGT_GUEST-01-popup');
    },
    helper: testHelper,
  );

  // Test ID: GENSET-DRK_GUEST
  testLocalizations(
    'General Settings - popup with dark theme when not log in yet',
    (tester, screen) async {
      testHelper.disableAnimations = false;
      await testHelper.pumpView(
        tester,
        navigatorKey: GlobalKey<NavigatorState>(),
        themeMode: ThemeMode.dark,
        overrides: [
          appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
              AppSettings(themeMode: ThemeMode.dark, locale: screen.locale))),
        ],
        child: UiKitPageView(
          child: (context, constraints) => Center(),
        ),
      );
      testHelper.mockAuthNotifier.state =
          const AsyncData(AuthState(loginType: LoginType.none));
      await tester.pumpAndSettle();

      final settingsFinder = find.byIcon(AppFontIcons.person);
      await tester.tap(settingsFinder);
      await tester.pumpAndSettle();

      await testHelper.takeScreenshot(tester, 'GENSET-DRK_GUEST-01-popup');
    },
    helper: testHelper,
  );

  // Test ID: GENSET-LANG_SEL
  testLocalizations('General Settings - Language selection dialog',
      (tester, screen) async {
    testHelper.disableAnimations = false;
    await testHelper.pumpView(
      tester,
      navigatorKey: GlobalKey<NavigatorState>(),
      overrides: [
        appSettingsProvider.overrideWith(() => MockAppSettingsNotifier(
            AppSettings(themeMode: ThemeMode.dark, locale: screen.locale))),
      ],
      child: UiKitPageView(
        child: (context, constraints) => Center(),
      ),
    );
    testHelper.mockAuthNotifier.state =
        const AsyncData(AuthState(loginType: LoginType.none));
    await tester.pumpAndSettle();

    // Open General Settings popup
    final settingsFinder = find.byIcon(AppFontIcons.person);
    await tester.tap(settingsFinder);
    await tester.pumpAndSettle();

    // Tap LanguageTile to open language selection dialog
    final localeTileFinder = find.byType(LanguageTile);
    expect(localeTileFinder, findsOneWidget);
    await tester.tap(localeTileFinder);
    await tester.pumpAndSettle();

    // Capture the language selection dialog
    await testHelper.takeScreenshot(tester, 'GENSET-LANG_SEL-01-dialog');
  }, screens: _topBarScreens, helper: testHelper);
}

class MockAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings? init;
  MockAppSettingsNotifier(this.init) : super();
  @override
  AppSettings build() => init ?? const AppSettings();
}
