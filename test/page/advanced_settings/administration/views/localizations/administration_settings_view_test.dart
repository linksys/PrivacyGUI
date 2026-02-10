import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/page/components/composed/app_switch_trigger_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/administration_settings_test_state.dart';

// View ID: ADMIN
// Implementation file under test: lib/page/advanced_settings/administration/views/administration_settings_view.dart
///
/// | Test ID         | Description                                                      |
/// | :-------------- | :--------------------------------------------------------------- |
/// | `ADMIN-INIT`    | Verifies the initial state of the administration settings view.  |
/// | `ADMIN-NO_WIFI` | Verifies the view when wireless management is not supported.     |
/// | `ADMIN-UPNP_OFF`| Verifies the view when UPnP is disabled.                         |
///
void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  // Test ID: ADMIN-INIT
  testThemeLocalizations(
    'Verifies the initial state of the administration settings view',
    (tester, screen) async {
      when(testHelper.mockAdministrationSettingsNotifier.build()).thenReturn(
          AdministrationSettingsState.fromMap(administrationSettingsTestState));

      final context = await testHelper.pumpView(tester,
          child: const AdministrationSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text(testHelper.loc(context).administration), findsOneWidget);

      // Verify sections are present
      expect(find.byKey(const Key('wirelessManagementSwitch')), findsOneWidget);
      expect(find.byKey(const Key('upnpSwitch')), findsOneWidget);
      expect(find.byKey(const Key('upnpConfigureCheckbox')), findsOneWidget);
      expect(find.byKey(const Key('upnpDisableWANAccessCheckbox')),
          findsOneWidget);
      expect(find.byKey(const Key('algSwitch')), findsOneWidget);
      expect(find.byKey(const Key('expressForwardingSwitch')), findsOneWidget);

      // Verify values
      final state =
          AdministrationSettingsState.fromMap(administrationSettingsTestState);
      expect(
        tester
            .widget<AppSwitchTriggerTile>(
                find.byKey(const Key('wirelessManagementSwitch')))
            .value,
        state.current.managementSettings.canManageWirelessly,
      );
      expect(
        tester
            .widget<AppSwitchTriggerTile>(find.byKey(const Key('upnpSwitch')))
            .value,
        state.current.isUPnPEnabled,
      );
      expect(
        tester
            .widget<AppCheckbox>(find.byKey(const Key('upnpConfigureCheckbox')))
            .value,
        state.current.canUsersConfigure,
      );
      expect(
        tester
            .widget<AppCheckbox>(
                find.byKey(const Key('upnpDisableWANAccessCheckbox')))
            .value,
        state.current.canUsersDisableWANAccess,
      );
      expect(
        tester
            .widget<AppSwitchTriggerTile>(find.byKey(const Key('algSwitch')))
            .value,
        state.current.enabledALG,
      );
      expect(
        tester
            .widget<AppSwitchTriggerTile>(
                find.byKey(const Key('expressForwardingSwitch')))
            .value,
        state.current.enabledExpressForwarfing,
      );
    },
    screens: screens,
    goldenFilename: 'ADMIN-INIT-01-initial_state',
  );

  // Test ID: ADMIN-NO_WIFI
  testThemeLocalizations(
    'Verifies the view when wireless management is not allowed',
    (tester, screen) async {
      final state =
          AdministrationSettingsState.fromMap(administrationSettingsTestState);
      final settings =
          state.current.copyWith(canDisAllowLocalMangementWirelessly: false);
      when(testHelper.mockAdministrationSettingsNotifier.build()).thenReturn(
          state.copyWith(
              settings: Preservable(original: settings, current: settings)));

      final context = await testHelper.pumpView(tester,
          child: const AdministrationSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text(testHelper.loc(context).administration), findsOneWidget);

      // Verify wireless management section is NOT present
      expect(find.byKey(const Key('wirelessManagementSwitch')), findsNothing);

      // Verify other sections are present
      expect(find.byKey(const Key('upnpSwitch')), findsOneWidget);
      expect(find.byKey(const Key('algSwitch')), findsOneWidget);
      expect(find.byKey(const Key('expressForwardingSwitch')), findsOneWidget);
    },
    screens: screens,
    goldenFilename: 'ADMIN-NO_WIFI-01-no_wireless_management',
  );

  // Test ID: ADMIN-UPNP_OFF
  testThemeLocalizations(
    'Verifies the view when UPnP is disabled',
    (tester, screen) async {
      final stateMap =
          Map<String, dynamic>.from(administrationSettingsTestState);
      final state = AdministrationSettingsState.fromMap(stateMap);
      final updatedState = state.copyWith(
          settings: state.settings.copyWith(
              current: state.settings.current.copyWith(isUPnPEnabled: false)));

      when(testHelper.mockAdministrationSettingsNotifier.build())
          .thenReturn(updatedState);

      final context = await testHelper.pumpView(tester,
          child: const AdministrationSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text(testHelper.loc(context).administration), findsOneWidget);

      // Verify UPnP switch is off
      final upnpSwitch = tester
          .widget<AppSwitchTriggerTile>(find.byKey(const Key('upnpSwitch')));
      expect(upnpSwitch.value, isFalse);

      // Verify UPnP-dependent checkboxes are NOT present
      expect(find.byKey(const Key('upnpConfigureCheckbox')), findsNothing);
      expect(
          find.byKey(const Key('upnpDisableWANAccessCheckbox')), findsNothing);
    },
    screens: screens,
    goldenFilename: 'ADMIN-UPNP_OFF-01-upnp_disabled',
  );
}
