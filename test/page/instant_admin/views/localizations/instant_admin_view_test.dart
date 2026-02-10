import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_admin/_instant_admin.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/config.dart';
import '../../../../common/screen.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/power_table_test_state.dart';
import '../../../../test_data/timezone_test_state.dart';

// View ID: IADM
// Implementation: lib/page/instant_admin/views/instant_admin_view.dart
// Summary:
// - IADM-BASE: Render default cards (password, firmware, timezone) with CTA.
// - IADM-PASSWORD: Launch router password modal from card.
// - IADM-TIMEZONE: Standalone timezone editor shows switch + list.
// - IADM-TRANSMIT_CARD: Transmit region card appears when selectable.
// - IADM-TRANSMIT_DIALOG: Region picker dialog lists supported countries.

final _timezoneScreens = [
  ...responsiveMobileScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 3780),
  ),
  ...responsiveDesktopScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 3780),
  ),
];
final _transmitScreens = [
  ...responsiveMobileScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 2040),
  ),
  ...responsiveDesktopScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 2040),
  ),
];

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockRouterPasswordNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
    });
    when(testHelper.mockTimezoneNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
      return TimezoneState.fromMap(timezoneTestState);
    });
  });

  Future<BuildContext> pumpInstantAdmin(
    WidgetTester tester,
    LocalizedScreen screen,
  ) {
    return testHelper.pumpView(
      tester,
      child: const InstantAdminView(),
      locale: screen.locale,
    );
  }

  // Test ID: IADM-BASE
  testThemeLocalizations(
    'instant admin view - base layout',
    (tester, screen) async {
      final context = await pumpInstantAdmin(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.text(loc.instantAdmin), findsOneWidget);
      expect(find.text(loc.routerPassword), findsWidgets);
      expect(find.text(loc.autoFirmwareUpdate), findsOneWidget);
      expect(find.text(loc.timezone), findsOneWidget);
    },
    screens: responsiveAllScreens,
    goldenFilename: 'IADM-BASE_01_layout',
    helper: testHelper,
  );

  // Test ID: IADM-PASSWORD
  testThemeLocalizations(
    'instant admin view - router password modal',
    (tester, screen) async {
      final context = await pumpInstantAdmin(tester, screen);
      final loc = testHelper.loc(context);

      await tester.tap(find.byIcon(AppFontIcons.edit));
      await tester.pumpAndSettle();
      expect(find.text(loc.routerPassword), findsWidgets);
      final newPasswordField = find.byKey(const Key('newPasswordField'));
      final confirmPasswordField =
          find.byKey(const Key('confirmPasswordField'));
      final hintField = find.byKey(const Key('hintTextField'));

      expect(newPasswordField, findsOneWidget);
      expect(confirmPasswordField, findsOneWidget);
      expect(hintField, findsOneWidget);
      await testHelper.takeScreenshot(
        tester,
        'IADM-PASSWORD_01_modal',
      );

      await tester.enterText(newPasswordField, 'Linksys123!');
      await tester.enterText(confirmPasswordField, 'Linksys123');
      if (hintField.evaluate().isNotEmpty) {
        await tester.enterText(hintField, 'Linksys');
      }
      await tester.pumpAndSettle();
    },
    screens: responsiveAllScreens,
    goldenFilename: 'IADM-PASSWORD_02_input',
    helper: testHelper,
  );

  // Test ID: IADM-TIMEZONE
  testThemeLocalizations(
    'instant admin view - timezone detail view',
    (tester, screen) async {
      when(testHelper.mockTimezoneNotifier.build()).thenReturn(
        TimezoneState.fromMap(timezoneTestState),
      );

      final context = await testHelper.pumpView(
        tester,
        child: const TimezoneView(),
        locale: screen.locale,
      );
      final loc = testHelper.loc(context);
      await tester.pumpAndSettle();

      expect(find.text(loc.timezone), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
      expect(find.byType(AppCard), findsWidgets);
    },
    screens: _timezoneScreens,
    goldenFilename: 'IADM-TIMEZONE_01_view',
    helper: testHelper,
  );

  // Test ID: IADM-TRANSMIT_CARD
  testThemeLocalizations(
    'instant admin view - transmit region card visible',
    (tester, screen) async {
      when(testHelper.mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: true),
      );

      final context = await pumpInstantAdmin(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.transmitRegion), findsOneWidget);
    },
    screens: responsiveAllScreens,
    goldenFilename: 'IADM-TRANSMIT_CARD_01_card',
    helper: testHelper,
  );

  // Test ID: IADM-TRANSMIT_DIALOG
  testThemeLocalizations(
    'instant admin view - transmit region picker dialog',
    (tester, screen) async {
      when(testHelper.mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: true),
      );

      final context = await pumpInstantAdmin(tester, screen);
      final loc = testHelper.loc(context);
      final cardFinder = find.ancestor(
        of: find.text(loc.transmitRegion),
        matching: find.byType(AppCard),
      );
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(find.text(loc.transmitRegion), findsWidgets);
      expect(find.byType(ListTile), findsWidgets);
    },
    screens: _transmitScreens,
    goldenFilename: 'IADM-TRANSMIT_DIALOG_01_dialog',
    helper: testHelper,
  );
}
