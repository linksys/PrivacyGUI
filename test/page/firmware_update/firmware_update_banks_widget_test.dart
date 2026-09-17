import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_view.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// The banks card is the one place the ota row is visually indistinguishable
/// from a bank: `_BankRow` prints whatever version the row carries next to a
/// slot badge. Both ACs here are only reachable at the widget layer — the filter
/// lives in the provider, but "how many rows did the card draw" and "what does
/// an empty version look like" are properties of the card.
///
/// The card is shared by both firmware pages, so the second group pumps the OTA one
/// through the same fixture. Same widget, and the filter matters more there: the
/// version being *offered* is on that page, one card below the slots.
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

  Widget wrapBanks(
    FirmwareBanksData banksData, {
    Widget page = const FirmwareUpdateView(),
    FirmwareUpdateState? updateState,
  }) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => page,
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...firmwareUpdateOverrides(
          updateState: updateState ?? idleNoFileState,
          banksData: banksData,
          systemInfoData: testSystemInfoData,
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    FirmwareBanksData banksData, {
    Widget page = const FirmwareUpdateView(),
    FirmwareUpdateState? updateState,
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester
        .pumpWidget(wrapBanks(banksData, page: page, updateState: updateState));
    await tester.pumpAndSettle();
  }

  group('firmware banks card on a three-instance router', () {
    testWidgets('draws 2 rows, not 3', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, testThreeInstanceBanksData);

      expect(find.bySemanticsIdentifier('firmware-bank-1'), findsOneWidget);
      expect(find.bySemanticsIdentifier('firmware-bank-2'), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('firmware-bank-3'),
        findsNothing,
        reason: 'the ota instance is not a slot the router can boot from — '
            'drawing it as slot 3 claims hardware that does not exist',
      );

      handle.dispose();
    });

    testWidgets('never prints the upgradeable version as a bank version',
        (tester) async {
      await pumpPage(tester, testThreeInstanceBanksData);

      expect(
        find.text(testOtaInstance.version),
        findsNothing,
        reason: 'this page reads the version the router *has*; the version it '
            'could update to belongs to the check card',
      );
    });

    testWidgets('a physical bank with no readable version still renders',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, testThreeInstanceBanksData);

      // The spare NAND bank reports Available=1 with Version=''. The row must
      // stay legible rather than collapsing to a blank line next to its badge.
      final row = find.bySemanticsIdentifier('firmware-bank-2');
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('(empty)')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('a router reporting only the ota row shows no banks',
        (tester) async {
      // Not "loading" and not two blank slots: the card has a dedicated empty
      // string for "the router reported no banks", and after filtering that is
      // exactly the state.
      await pumpPage(
        tester,
        const FirmwareBanksData(banks: [testOtaInstance]),
      );

      expect(find.bySemanticsIdentifier('firmware-bank-3'), findsNothing);
      expect(find.text('No firmware banks reported by router'), findsOneWidget);
    });
  });

  /// The same card, on the OTA page (#1551).
  ///
  /// Worth pumping twice rather than trusting the extraction, because the card takes
  /// plain values and the two pages compute them differently: this page passes
  /// `physicalBanks` and a `banksUnreadable` of its own, so a page wired to `banks`
  /// instead would draw a third slot here and nowhere else. The last test is the one
  /// that could only fail here — it is this page that knows the incoming version.
  group('the same banks card on the ota page', () {
    testWidgets('draws the router the page is about', (tester) async {
      await pumpPage(tester, testThreeInstanceBanksData,
          page: const FirmwareOtaView());

      // Before this card the OTA page named no firmware at all — you pressed
      // Update Now without being told what was running.
      expect(find.text(testSystemInfoModel.modelName), findsOneWidget);
      expect(find.text(testSystemInfoModel.serialNumber), findsOneWidget);
    });

    testWidgets('draws 2 rows here too, not 3', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, testThreeInstanceBanksData,
          page: const FirmwareOtaView());

      expect(find.bySemanticsIdentifier('firmware-bank-1'), findsOneWidget);
      expect(find.bySemanticsIdentifier('firmware-bank-2'), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('firmware-bank-3'),
        findsNothing,
        reason:
            'the ota row is the version being offered one card below — drawing '
            'it as a slot claims the router already holds it',
      );

      handle.dispose();
    });

    testWidgets('the offered version never lands on the standby slot',
        (tester) async {
      final handle = tester.ensureSemantics();
      // The state that offers the install, so the same version string is on screen
      // twice over: once as the offer, and never as a slot's contents. A router-side
      // install does land in this slot, but not until the flash completes.
      await pumpPage(
        tester,
        testThreeInstanceBanksData,
        page: const FirmwareOtaView(),
        updateState: otaUpdateAvailableState,
      );

      final standby = find.bySemanticsIdentifier('firmware-bank-2');
      expect(
        find.descendant(
            of: standby, matching: find.text(testOtaInstance.version)),
        findsNothing,
      );
      expect(
        find.descendant(of: standby, matching: find.text('(empty)')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });
}
