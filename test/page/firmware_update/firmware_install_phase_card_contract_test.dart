// The set of phases `FirmwareInstallPhaseCard` draws, measured on both pages.
//
// #1549 split one firmware page into two and moved the six install phases into a
// shared card. `FirmwareInstallPhaseCard.phases` documents itself as "the
// contract" between that card and the two pages' `switch`es — but a `const Set`
// no code reads is not a contract, it is a comment with braces. This file is what
// makes it one.
//
// The drift it catches is one no compiler can: both pages switch exhaustively over
// `FirmwareUpdatePhase`, so a twelfth phase reds all three files. What stays green
// is moving an *existing* phase into a page's delegating group without adding an
// arm to the card — the page then renders a card that draws nothing, which is
// invisible in a diff and blank on screen. That is exactly the shape of #1497's
// regression: a phase machine dropped along with a mode-gated entry point, and
// every test still passing because they all pumped `idle`.
//
// Both pages at all eleven phases, because "the same install looks the same
// whichever page started it" is the claim the split rests on, and it is only worth
// anything if the phases the *other* page owns are pinned as well.
//
// Not tagged `ui`: gated in `run_tests.sh` (the repo's only CI test job).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_view.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

void main() {
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'PrivacyGUI',
            'packageName': 'com.linksys.privacygui',
            'version': '0.0.0',
            'buildNumber': '0',
          };
        }
        return null;
      },
    );
  });

  Widget host(Widget view, FirmwareUpdateState state) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...firmwareUpdateOverrides(
          updateState: state,
          banksData: testBanksData,
          systemInfoData: testSystemInfoData,
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            LinksysRoute(
              path: '/',
              name: 'test_root',
              builder: (context, state) => view,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pump(
      WidgetTester tester, Widget view, FirmwareUpdateState state) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(view, state));
    // Pump frames rather than settle: several phases animate an indeterminate
    // loader, which never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  final pages = <String, Widget>{
    'the manual page': const FirmwareUpdateView(),
    'the OTA page': const FirmwareOtaView(),
  };

  group('FirmwareInstallPhaseCard.phases is the set both pages delegate', () {
    for (final phase in FirmwareUpdatePhase.values) {
      final delegated = FirmwareInstallPhaseCard.handles(phase);
      for (final entry in pages.entries) {
        testWidgets(
            '${entry.key} in $phase '
            '${delegated ? 'delegates to' : 'does not draw'} the shared card',
            (tester) async {
          await pump(
            tester,
            entry.value,
            FirmwareUpdateState(
              phase: phase,
              activeBank: testActiveBank,
              targetBank: testAvailableBank,
            ),
          );

          expect(
            find.byType(FirmwareInstallPhaseCard),
            delegated ? findsOneWidget : findsNothing,
            reason: delegated
                ? '$phase is in `FirmwareInstallPhaseCard.phases`, so this page '
                    'must hand it to the shared card rather than draw its own'
                : '$phase is not in `FirmwareInstallPhaseCard.phases`, and the '
                    'card draws nothing for it — a page that delegates it '
                    'renders an empty card, which is the silent half of #1497',
          );
        });
      }
    }
  });

  test('the drawn set is the six phases an install actually passes through',
      () {
    // The set spelled out against the enum rather than read back from itself, so
    // that widening it is a decision recorded here as well as in the widget. The
    // three it must not contain are the two entry-point phases and the terminal
    // pair's predecessor list — i.e. everything a page still owns.
    expect(FirmwareInstallPhaseCard.phases, {
      FirmwareUpdatePhase.triggering,
      FirmwareUpdatePhase.installing,
      FirmwareUpdatePhase.rebooting,
      FirmwareUpdatePhase.verifying,
      FirmwareUpdatePhase.done,
      FirmwareUpdatePhase.failed,
    });
    for (final phase in const [
      FirmwareUpdatePhase.idle,
      FirmwareUpdatePhase.checkingOta,
      FirmwareUpdatePhase.picking,
      FirmwareUpdatePhase.validating,
      FirmwareUpdatePhase.uploading,
    ]) {
      expect(FirmwareInstallPhaseCard.handles(phase), isFalse,
          reason: '$phase belongs to an entry point, not to an install');
    }
  });
}
