import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_safety/providers/_providers.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/config.dart';
import '../../../../common/screen.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/safe_browsing_test_state.dart';

// View ID: ISAF
// Implementation: lib/page/instant_safety/views/instant_safety_view.dart
// Summary:
// - ISAF-OFF: Safe browsing switch disabled and layout verified.
// - ISAF-ON-FORTINET: Enabled state showing Fortinet provider option.
// - ISAF-ON-OPENDNS: Enabled state showing OpenDNS provider option.

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockInstantSafetyNotifier.fetch()).thenAnswer(
        (_) async => InstantSafetyState.fromMap(instantSafetyTestState1));
  });

  Future<BuildContext> pumpView(
    WidgetTester tester,
    LocalizedScreen screen, {
    InstantSafetyState? state,
  }) async {
    when(testHelper.mockInstantSafetyNotifier.build()).thenReturn(
        state ?? InstantSafetyState.fromMap(instantSafetyTestState1));
    return testHelper.pumpShellView(
      tester,
      child: const InstantSafetyView(),
      locale: screen.locale,
      config: LinksysRouteConfig(column: ColumnGrid(column: 9, centered: true)),
    );
  }

  // Test ID: ISAF-OFF
  testLocalizationsV2(
    'instant safety view - safe browsing off',
    (tester, screen) async {
      final context = await pumpView(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.text(loc.instantSafety), findsWidgets);
      expect(find.byType(AppSwitch), findsOneWidget);
    },
    screens: responsiveAllScreens,
    goldenFilename: 'ISAF-OFF_01_layout',
    helper: testHelper,
  );

  // Test ID: ISAF-ON-FORTINET
  testLocalizationsV2(
    'instant safety view - safe browsing enabled Fortinet provider',
    (tester, screen) async {
      final context = await pumpView(
        tester,
        screen,
        state: InstantSafetyState.fromMap(instantSafetyTestState2),
      );
      final loc = testHelper.loc(context);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(find.text(loc.provider), findsOneWidget);
      expect(find.text(loc.fortinetSecureDns), findsOneWidget);
    },
    screens: responsiveAllScreens,
    goldenFilename: 'ISAF-ON_01_fortinet',
    helper: testHelper,
  );

  // Test ID: ISAF-ON-OPENDNS
  testLocalizationsV2(
    'instant safety view - safe browsing enabled openDNS provider',
    (tester, screen) async {
      final context = await pumpView(
        tester,
        screen,
        state: InstantSafetyState.fromMap(instantSafetyTestState3),
      );
      final loc = testHelper.loc(context);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(find.text(loc.provider), findsOneWidget);
      expect(find.text(loc.openDNS), findsOneWidget);
    },
    screens: responsiveAllScreens,
    goldenFilename: 'ISAF-ON_01_openDNS',
    helper: testHelper,
  );
}
