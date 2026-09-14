import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
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

  Widget wrapBanks(FirmwareBanksData banksData) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const FirmwareUpdateView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...firmwareUpdateOverrides(
          updateState: idleNoFileState,
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
      WidgetTester tester, FirmwareBanksData banksData) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapBanks(banksData));
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
}
