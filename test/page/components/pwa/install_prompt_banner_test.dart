import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/pwa/pwa_install_service.dart';
import 'package:privacy_gui/page/components/pwa/install_prompt_banner.dart';
import 'package:privacy_gui/page/components/pwa/ios_install_instruction_sheet.dart';
import 'package:privacy_gui/page/components/pwa/mac_safari_install_instruction_sheet.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';

/// View ID: PWAB
/// Implementation file under test: lib/page/components/pwa/install_prompt_banner.dart
///
/// This file contains screenshot tests for the `InstallPromptBanner` widget,
/// iOS and Mac instruction sheets, covering various `PwaMode` states.
///
/// | Test ID           | Description                                                     |
/// | :---------------- | :-------------------------------------------------------------- |
/// | `PWAB-NATIVE`     | Verifies banner display in native install mode (Android/Chrome) |
/// | `PWAB-IOS_BNR`    | Verifies banner display in iOS mode (banner only + with sheet)  |
/// | `PWAB-MAC_BNR`    | Verifies banner display in Mac mode (banner only + with sheet)  |
/// | `PWAB-IOS_SHT`    | Verifies iOS install instruction sheet standalone display       |
/// | `PWAB-MAC_SHT`    | Verifies Mac Safari install instruction sheet standalone display|

// Fake Service for testing
class FakePwaInstallService extends Notifier<PwaMode>
    implements PwaInstallService {
  final PwaMode initialMode;

  FakePwaInstallService(this.initialMode);

  @override
  PwaMode build() => initialMode;

  @override
  Future<void> dismiss() async {}

  @override
  Future<void> promptInstall() async {}

  @override
  bool get isIOS => initialMode == PwaMode.ios;

  @override
  bool get isMacSafari => initialMode == PwaMode.mac;

  @override
  bool get isStandalone => false;

  @override
  Future<bool> isDismissedRecently() async => false;
}

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  group('InstallPromptBanner Golden Tests', () {
    // Test ID: PWAB-NATIVE
    testThemeLocalizations(
      'Verify banner display in native install mode with dismiss button',
      (tester, locale) async {
        final context = await testHelper.pumpView(
          tester,
          child: const Scaffold(
            body: Column(
              children: [
                InstallPromptBanner(),
              ],
            ),
          ),
          locale: locale.locale,
          overrides: [
            pwaInstallServiceProvider
                .overrideWith(() => FakePwaInstallService(PwaMode.native)),
          ],
        );
        await tester.pumpAndSettle();

        // Verify banner is displayed
        expect(find.byType(InstallPromptBanner), findsOneWidget);
        expect(find.byKey(const Key('pwa_install_button')), findsOneWidget);
        expect(find.byKey(const Key('pwa_dismiss_button')), findsOneWidget);
        expect(
          find.text(testHelper.loc(context).pwaGetTheApp),
          findsOneWidget,
        );
        expect(
          find.text(testHelper.loc(context).pwaInstallDescription),
          findsOneWidget,
        );
      },
      screens: responsiveMobileScreens,
      helper: testHelper,
      goldenFilename: 'PWAB-NATIVE-01-banner',
    );

    // Test ID: PWAB-IOS_BNR
    testThemeLocalizations(
      'Verify iOS banner display and instruction sheet interaction',
      (tester, locale) async {
        final context = await testHelper.pumpView(
          tester,
          child: const Scaffold(
            body: Column(
              children: [
                InstallPromptBanner(),
              ],
            ),
          ),
          locale: locale.locale,
          overrides: [
            pwaInstallServiceProvider
                .overrideWith(() => FakePwaInstallService(PwaMode.ios)),
          ],
        );
        await tester.pumpAndSettle();

        // Verify banner is displayed
        expect(find.byType(InstallPromptBanner), findsOneWidget);
        expect(find.byKey(const Key('pwa_install_button')), findsOneWidget);
        expect(find.byKey(const Key('pwa_dismiss_button')), findsOneWidget);

        // Screenshot 1: Banner only (before opening sheet)
        await testHelper.takeScreenshot(tester, 'PWAB-IOS_BNR-01-banner');

        // Tap install button to show iOS instruction sheet
        await tester.tap(find.byKey(const Key('pwa_install_button')));
        await tester.pumpAndSettle();

        // Verify iOS instruction sheet is displayed
        expect(find.byType(IosInstallInstructionSheet), findsOneWidget);
        expect(
          find.text(testHelper.loc(context).pwaIosInstallTitle),
          findsOneWidget,
        );
      },
      screens: responsiveMobileScreens,
      helper: testHelper,
      goldenFilename: 'PWAB-IOS_BNR-02-with_sheet',
    );

    // Test ID: PWAB-MAC_BNR
    testThemeLocalizations(
      'Verify Mac banner display and instruction sheet interaction',
      (tester, locale) async {
        final context = await testHelper.pumpView(
          tester,
          child: const Scaffold(
            body: Column(
              children: [
                InstallPromptBanner(),
              ],
            ),
          ),
          locale: locale.locale,
          overrides: [
            pwaInstallServiceProvider
                .overrideWith(() => FakePwaInstallService(PwaMode.mac)),
          ],
        );
        await tester.pumpAndSettle();

        // Verify banner is displayed
        expect(find.byType(InstallPromptBanner), findsOneWidget);
        expect(find.byKey(const Key('pwa_install_button')), findsOneWidget);
        expect(find.byKey(const Key('pwa_dismiss_button')), findsOneWidget);

        // Screenshot 1: Banner only (before opening sheet)
        await testHelper.takeScreenshot(tester, 'PWAB-MAC_BNR-01-banner');

        // Tap install button to show Mac instruction sheet
        await tester.tap(find.byKey(const Key('pwa_install_button')));
        await tester.pumpAndSettle();

        // Verify Mac Safari instruction sheet is displayed
        expect(find.byType(MacSafariInstallInstructionSheet), findsOneWidget);
        expect(
          find.text(testHelper.loc(context).pwaMacInstallTitle),
          findsOneWidget,
        );
      },
      screens: responsiveDesktopScreens,
      helper: testHelper,
      goldenFilename: 'PWAB-MAC_BNR-02-with_sheet',
    );
  });

  group('iOS Install Instruction Sheet Golden Tests', () {
    // Test ID: PWAB-IOS_SHT
    testThemeLocalizations(
      'Verify iOS install instruction sheet standalone display',
      (tester, locale) async {
        final context = await testHelper.pumpView(
          tester,
          child: const Scaffold(
            body: IosInstallInstructionSheet(),
          ),
          locale: locale.locale,
        );
        await tester.pumpAndSettle();

        // Verify sheet content is displayed
        expect(find.byType(IosInstallInstructionSheet), findsOneWidget);
        expect(
          find.text(testHelper.loc(context).pwaIosInstallTitle),
          findsOneWidget,
        );
        expect(
          find.text(testHelper.loc(context).pwaIosInstallDescription),
          findsOneWidget,
        );
        expect(
          find.text(testHelper.loc(context).pwaIosStep1),
          findsOneWidget,
        );
        expect(
          find.text(testHelper.loc(context).pwaIosStep2),
          findsOneWidget,
        );
        // Verify step numbers
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        // Verify icons
        expect(find.byIcon(Icons.ios_share), findsOneWidget);
        expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      },
      screens: responsiveMobileScreens,
      helper: testHelper,
      goldenFilename: 'PWAB-IOS_SHT-01-standalone',
    );
  });

  group('Mac Safari Install Instruction Sheet Golden Tests', () {
    // Test ID: PWAB-MAC_SHT
    testThemeLocalizations(
      'Verify Mac Safari install instruction sheet standalone display',
      (tester, locale) async {
        final context = await testHelper.pumpView(
          tester,
          child: const Scaffold(
            body: MacSafariInstallInstructionSheet(),
          ),
          locale: locale.locale,
        );
        await tester.pumpAndSettle();

        // Verify sheet content is displayed
        expect(find.byType(MacSafariInstallInstructionSheet), findsOneWidget);
        expect(
          find.text(testHelper.loc(context).pwaMacInstallTitle),
          findsOneWidget,
        );
        expect(
          find.text(testHelper.loc(context).pwaMacInstallDescription),
          findsOneWidget,
        );
        expect(
          find.text(testHelper.loc(context).pwaMacStep1),
          findsOneWidget,
        );
        expect(
          find.text(testHelper.loc(context).pwaMacStep2),
          findsOneWidget,
        );
        // Verify step numbers
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        // Verify icons
        expect(find.byIcon(Icons.ios_share), findsOneWidget);
        expect(find.byIcon(Icons.dock), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      },
      screens: responsiveDesktopScreens,
      helper: testHelper,
      goldenFilename: 'PWAB-MAC_SHT-01-standalone',
    );
  });
}
