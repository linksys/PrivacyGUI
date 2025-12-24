import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';

/// View ID: PNPNI
/// Implementation file under test: lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart
///
/// | Test ID          | Description                                           |
/// | :--------------- | :---------------------------------------------------- |
/// | `PNPNI-NO_SSID`  | Verifies the view when no SSID is provided.           |
/// | `PNPNI-HAS_SSID` | Verifies the view when a specific SSID is provided.   |
void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    when(testHelper.mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  // Test ID: PNPNI-NO_SSID
  testLocalizations(
    'Verify the no internet connection view without a specific SSID',
    (tester, localizedScreen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const PnpNoInternetConnectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
      );

      // Verify title and description
      expect(find.text(testHelper.loc(context).noInternetConnectionTitle),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).noInternetConnectionDescription),
          findsOneWidget);

      // Verify icon
      expect(find.byIcon(AppFontIcons.publicOff), findsOneWidget);

      // Verify action cards
      expect(
          find.text(
              testHelper.loc(context).pnpNoInternetConnectionRestartModem),
          findsOneWidget);
      expect(
          find.text(
              testHelper.loc(context).pnpNoInternetConnectionRestartModemDesc),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpNoInternetConnectionEnterISP),
          findsOneWidget);
      expect(
          find.text(
              testHelper.loc(context).pnpNoInternetConnectionEnterISPDesc),
          findsOneWidget);

      // Verify buttons
      expect(find.text(testHelper.loc(context).logIntoRouter), findsOneWidget);
      expect(find.text(testHelper.loc(context).tryAgain), findsOneWidget);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNPNI-NO_SSID_01_initial_state',
  );

  // Test ID: PNPNI-HAS_SSID
  testLocalizations(
    'Verify the no internet connection view with a specific SSID',
    (tester, localizedScreen) async {
      const ssid = 'AwesomeSSID';
      final context = await testHelper.pumpView(
        tester,
        child: const PnpNoInternetConnectionView(
          args: {'ssid': ssid},
        ),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
      );

      // Verify title and description
      expect(
          find.text(
              testHelper.loc(context).noInternetConnectionWithSSIDTitle(ssid)),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).noInternetConnectionDescription),
          findsOneWidget);

      // Verify icon
      expect(find.byIcon(AppFontIcons.publicOff), findsOneWidget);

      // Verify action cards
      expect(
          find.text(
              testHelper.loc(context).pnpNoInternetConnectionRestartModem),
          findsOneWidget);
      expect(
          find.text(
              testHelper.loc(context).pnpNoInternetConnectionRestartModemDesc),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpNoInternetConnectionEnterISP),
          findsOneWidget);
      expect(
          find.text(
              testHelper.loc(context).pnpNoInternetConnectionEnterISPDesc),
          findsOneWidget);

      // Verify buttons
      expect(find.text(testHelper.loc(context).logIntoRouter), findsOneWidget);
      expect(find.text(testHelper.loc(context).tryAgain), findsOneWidget);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNPNI-HAS_SSID_01_initial_state',
  );
}
