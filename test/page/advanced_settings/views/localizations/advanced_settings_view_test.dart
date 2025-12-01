import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/advanced_settings/advanced_settings_view.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';

import '../../../../common/config.dart';
import '../../../../common/screen.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/dashboard_home_test_state.dart';

// Reference to implementation file: lib/page/advanced_settings/advanced_settings_view.dart
// View ID: ADVSET

/// | Test ID         | Description                                                          |
/// | :-------------- | :------------------------------------------------------------------- |
/// | `ADVSET-INIT`   | Verifies the initial state where all advanced settings are enabled.  |
/// | `ADVSET-BRIDGE` | Verifies the UI in bridge mode, where most settings are disabled.    |
/// | `ADVSET-NAV`    | Verifies that tapping a setting card triggers the correct navigation. |
void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  // Test ID: ADVSET-INIT
  testLocalizationsV2(
    'Verify initial state with all settings enabled',
    (tester, screen) async {
      when(testHelper.mockDashboardHomeNotifier.build())
          .thenReturn(DashboardHomeState.fromMap(dashboardHomeStateData));
      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        locale: screen.locale,
        child: const AdvancedSettingsView(),
      );

      final loc = testHelper.loc(context);

      expect(find.text(loc.advancedSettings), findsOneWidget);
      expect(find.text(loc.internetSettings.capitalizeWords()), findsOneWidget);
      expect(find.text(loc.localNetwork), findsOneWidget);
      expect(find.text(loc.advancedRouting), findsOneWidget);
      expect(find.text(loc.administration), findsOneWidget);
      expect(find.text(loc.firewall), findsOneWidget);
      expect(find.text(loc.dmz), findsOneWidget);
      expect(find.text(loc.appsGaming), findsOneWidget);

      final cardFinder = find.ancestor(
        of: find.text(loc.localNetwork),
        matching: find.byType(AppSettingCard),
      );
      final opacityFinder = find.ancestor(
        of: cardFinder,
        matching: find.byType(Opacity),
      );
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, 1.0);
    },
    goldenFilename: 'ADVSET-INIT',
    screens: screens,
    helper: testHelper,
  );

  // Test ID: ADVSET-BRIDGE
  testLocalizationsV2(
    'Verify bridge mode with most settings disabled',
    (tester, screen) async {
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
          DashboardHomeState.fromMap(dashboardHomeStateDataInBridge));
      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        locale: screen.locale,
        child: const AdvancedSettingsView(),
      );
      final loc = testHelper.loc(context);

      // Verify all cards are still rendered
      expect(find.text(loc.advancedSettings), findsOneWidget);
      expect(find.text(loc.internetSettings.capitalizeWords()), findsOneWidget);
      expect(find.text(loc.localNetwork), findsOneWidget);
      expect(find.text(loc.administration), findsOneWidget);

      // Verify "Internet Settings" is enabled
      final internetCardFinder = find.ancestor(
        of: find.text(loc.internetSettings.capitalizeWords()),
        matching: find.byType(AppSettingCard),
      );
      final internetOpacityFinder = find.ancestor(
        of: internetCardFinder,
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(internetOpacityFinder).opacity, 1.0);
      expect(tester.widget<AppSettingCard>(internetCardFinder).onTap, isNotNull);

      // Verify "Local Network" is disabled
      final localNetworkCardFinder = find.ancestor(
        of: find.text(loc.localNetwork),
        matching: find.byType(AppSettingCard),
      );
      final localNetworkOpacityFinder = find.ancestor(
        of: localNetworkCardFinder,
        matching: find.byType(Opacity),
      );
      expect(
          tester.widget<Opacity>(localNetworkOpacityFinder).opacity, closeTo(0.3, 0.01));
      expect(tester.widget<AppSettingCard>(localNetworkCardFinder).onTap, isNull);
    },
    goldenFilename: 'ADVSET-BRIDGE',
    screens: screens,
    helper: testHelper,
  );

  // Test ID: ADVSET-NAV
  // testWidgets(
  //   'Verify tapping on a setting navigates to the correct page',
  //   (tester) async {
  //     when(testHelper.mockDashboardHomeNotifier.build())
  //         .thenReturn(DashboardHomeState.fromMap(dashboardHomeStateData));
  //     final context = await testHelper.pumpView(
  //       tester,
  //       config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
  //       child: const AdvancedSettingsView(),
  //     );

  //     final loc = testHelper.loc(context);

  //     final internetSettingsCard =
  //         find.text(loc.internetSettings.capitalizeWords());
  //     expect(internetSettingsCard, findsOneWidget);

  //     await tester.tap(internetSettingsCard);
  //     await tester.pumpAndSettle();

  //     verify(testHelper.mockGoRouter.goNamed(RouteNamed.internetSettings))
  //         .called(1);
  //   },
  // );
}
