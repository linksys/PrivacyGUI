import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/pwa/pwa_install_service.dart';
import 'package:privacy_gui/page/components/pwa/install_prompt_banner.dart';
import 'package:privacy_gui/page/components/pwa/ios_install_instruction_sheet.dart';
import 'package:privacy_gui/page/components/pwa/mac_safari_install_instruction_sheet.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../common/config.dart'; // Added for responsiveMobileScreens

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
  group('InstallPromptBanner Golden Tests', () {
    // 1. Native Install Mode (Android/Chrome)
    testLocalizations(
      'install_prompt_banner_native',
      (tester, locale) async {
        await tester.pumpWidget(
          testableSingleRoute(
            child: const Scaffold(
              body: Column(
                children: [
                  InstallPromptBanner(),
                ],
              ),
            ),
            locale: locale,
            overrides: [
              pwaInstallServiceProvider
                  .overrideWith(() => FakePwaInstallService(PwaMode.native)),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();
      },
      screens: [
        responsiveMobileScreens.first,
      ],
      onCompleted: (tester) async {},
    );

    // 2. iOS Mode
    testLocalizations(
      'install_prompt_banner_ios',
      (tester, locale) async {
        await tester.pumpWidget(
          testableSingleRoute(
            child: const Scaffold(
              body: Column(
                children: [
                  InstallPromptBanner(),
                ],
              ),
            ),
            locale: locale,
            overrides: [
              pwaInstallServiceProvider
                  .overrideWith(() => FakePwaInstallService(PwaMode.ios)),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        // Tap verify iOS sheet
        await tester.tap(find.byKey(const Key('pwa_install_button')).first);

        // Explicitly pump frames to allow bottom sheet animation to run
        for (int i = 0; i < 5; i++) {
          await tester.pump();
        }

        expect(find.byType(IosInstallInstructionSheet), findsOneWidget);
      },
      screens: [
        responsiveMobileScreens.first,
      ],
      onCompleted: (tester) async {},
    );

    // 3. MacOS Mode
    testLocalizations(
      'install_prompt_banner_mac',
      (tester, locale) async {
        await tester.pumpWidget(
          testableSingleRoute(
            child: const Scaffold(
              body: Column(
                children: [
                  InstallPromptBanner(),
                ],
              ),
            ),
            locale: locale,
            overrides: [
              pwaInstallServiceProvider
                  .overrideWith(() => FakePwaInstallService(PwaMode.mac)),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        // Tap verify Mac sheet
        await tester.tap(find.byKey(const Key('pwa_install_button')).first);

        // Explicitly pump frames to allow bottom sheet animation to run
        for (int i = 0; i < 5; i++) {
          await tester.pump();
        }

        expect(find.byType(MacSafariInstallInstructionSheet), findsOneWidget);
      },
      screens: [
        // Use desktop size for Mac test
        responsiveDesktopScreens.first,
      ],
      onCompleted: (tester) async {},
    );
  });
}
