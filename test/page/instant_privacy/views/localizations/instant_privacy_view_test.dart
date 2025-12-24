import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/config.dart';
import '../../../../common/screen.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/device_list_test_state.dart';
import '../../../../test_data/instant_privacy_test_state.dart';

// View ID: IPRV
// Implementation: lib/page/instant_privacy/views/instant_privacy_view.dart
// Summary:
// - IPRV-BASE: Default disabled state with description and switch.
// - IPRV-WARNING: Deny mode shows MAC filtering warning card.
// - IPRV-ENABLED: Allowed mode lists devices and info card.
// - IPRV-ENABLE_MODAL: Turning on opens confirmation dialog.
// - IPRV-DISABLE_MODAL: Turning off shows warning dialog.
// - IPRV-DELETE: Removing another device opens delete confirmation.
// - IPRV-DELETE_SELF: Deleting current device shows self-alert.

final _allScreens = [
  ...responsiveMobileScreens.map((s) => s.copyWith(height: 1280)),
  ...responsiveDesktopScreens.map((s) => s.copyWith(height: 1080)),
];

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockInstantPrivacyNotifier.fetch(
      forceRemote: anyNamed('forceRemote'),
    )).thenAnswer(
        (_) async => InstantPrivacyState.fromMap(instantPrivacyTestState));
  });

  Future<BuildContext> pumpPrivacy(
    WidgetTester tester,
    LocalizedScreen screen, {
    InstantPrivacyState? state,
    DeviceListState? devices,
  }) {
    when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
      state ?? InstantPrivacyState.fromMap(instantPrivacyTestState),
    );
    when(testHelper.mockDeviceListNotifier.build()).thenReturn(
      devices ?? DeviceListState.fromMap(instantPrivacyDeviceListTestState),
    );
    return testHelper.pumpView(
      tester,
      child: const InstantPrivacyView(),
      locale: screen.locale,
    );
  }

  // Test ID: IPRV-BASE
  testLocalizations(
    'instant privacy view - disabled state',
    (tester, screen) async {
      final context = await pumpPrivacy(tester, screen);
      final loc = testHelper.loc(context);

      expect(find.text(loc.instantPrivacyDescription), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    },
    screens: _allScreens,
    goldenFilename: 'IPRV-BASE_01_layout',
    helper: testHelper,
  );

  // Test ID: IPRV-WARNING
  testLocalizations(
    'instant privacy view - mac filtering warning',
    (tester, screen) async {
      final context = await pumpPrivacy(
        tester,
        screen,
        state: InstantPrivacyState.fromMap(instantPrivacyDenyTestState),
      );
      final loc = testHelper.loc(context);
      expect(find.text(loc.macFilteringDisableWarning), findsOneWidget);
    },
    screens: _allScreens,
    goldenFilename: 'IPRV-WARNING_01_card',
    helper: testHelper,
  );

  // Test ID: IPRV-ENABLED
  testLocalizations(
    'instant privacy view - enabled device list',
    (tester, screen) async {
      final context = await pumpPrivacy(
        tester,
        screen,
        state: InstantPrivacyState.fromMap(instantPrivacyEnabledTestState),
      );
      final loc = testHelper.loc(context);

      expect(find.text(loc.theDevicesAllowedToConnect), findsOneWidget);
      expect(find.byIcon(AppFontIcons.delete), findsWidgets);
    },
    screens: _allScreens,
    goldenFilename: 'IPRV-ENABLED_01_devices',
    helper: testHelper,
  );

  // Test ID: IPRV-ENABLE_MODAL
  testLocalizations(
    'instant privacy view - enable confirmation dialog',
    (tester, screen) async {
      final context = await pumpPrivacy(tester, screen);
      final loc = testHelper.loc(context);

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(find.text(loc.turnOnInstantPrivacy), findsOneWidget);
    },
    screens: _allScreens,
    goldenFilename: 'IPRV-ENABLE_MODAL_01_dialog',
    helper: testHelper,
  );

  // Test ID: IPRV-DISABLE_MODAL
  testLocalizations(
    'instant privacy view - disable confirmation dialog',
    (tester, screen) async {
      final context = await pumpPrivacy(
        tester,
        screen,
        state: InstantPrivacyState.fromMap(instantPrivacyEnabledTestState),
      );
      final loc = testHelper.loc(context);

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(find.text(loc.turnOffInstantPrivacy), findsOneWidget);
    },
    screens: _allScreens,
    goldenFilename: 'IPRV-DISABLE_MODAL_01_dialog',
    helper: testHelper,
  );

  // Test ID: IPRV-DELETE
  testLocalizations(
    'instant privacy view - delete device confirmation',
    (tester, screen) async {
      final context = await pumpPrivacy(
        tester,
        screen,
        state: InstantPrivacyState.fromMap(instantPrivacyEnabledTestState),
      );
      final loc = testHelper.loc(context);

      final deleteButton = find.byIcon(AppFontIcons.delete).first;
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      expect(find.text(loc.deleteDevice), findsOneWidget);
      expect(find.text(loc.instantPrivacyDeleteDeviceDesc), findsOneWidget);
    },
    screens: _allScreens,
    goldenFilename: 'IPRV-DELETE_01_dialog',
    helper: testHelper,
  );

  // Test ID: IPRV-DELETE_SELF
  testLocalizations(
    'instant privacy view - delete self alert',
    (tester, screen) async {
      await pumpPrivacy(
        tester,
        screen,
        state: InstantPrivacyState.fromMap(instantPrivacyEnabledTestState),
      );
      final targetCard = find.ancestor(
        of: find.text('3C:22:FB:E4:4F:18'),
        matching: find.byType(AppCard),
      );
      await tester.scrollUntilVisible(targetCard, 100,
          scrollable: find.byType(Scrollable).last);
      final deleteSelf = find.descendant(
        of: targetCard,
        matching: find.byIcon(AppFontIcons.delete),
      );
      await tester.tap(deleteSelf.first);
      await tester.pumpAndSettle();
      final loc = testHelper.loc(
        tester.element(find.byType(InstantPrivacyView)),
      );
      expect(
          find.text(loc.instantPrivacyNotAllowDeleteCurrent), findsOneWidget);
    },
    screens: _allScreens,
    goldenFilename: 'IPRV-DELETE_SELF_01_dialog',
    helper: testHelper,
  );
}
