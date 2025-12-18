import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/page/components/composed/app_switch_trigger_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/local_network_settings_state.dart';

// View ID: LNS
// Implementation file under test: lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart
///
/// | Test ID             | Description                                                                 |
/// | :------------------ | :-------------------------------------------------------------------------- |
/// | `LNS-HOSTNAME`      | Verifies the initial state of the Host Name tab.                            |
/// | `LNS-HOSTNAME_ERR`  | Verifies the Host Name tab with a validation error.                         |
/// | `LNS-IP`            | Verifies the LAN IP Address tab.                                            |
/// | `LNS-IP_ERR`        | Verifies the LAN IP Address tab with a validation error.                    |
/// | `LNS-DHCP`          | Verifies the DHCP Server tab.                                               |
/// | `LNS-DHCP_ERR`      | Verifies the DHCP Server tab with a validation error.                       |
/// | `LNS-DHCP_IP_ERR`   | Verifies the DHCP Server tab with an IP range error.                        |
/// | `LNS-DHCP_OFF`      | Verifies the DHCP Server tab when DHCP is disabled.                         |
/// | `LNS-DIRTY_NAV`     | Verifies the save changes dialog appears when navigating away with unsaved changes. |
///
void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    when(testHelper.mockLocalNetworkSettingsNotifier.fetch(forceRemote: true))
        .thenAnswer((_) async =>
            LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
  });

  // Test ID: LNS-HOSTNAME
  testLocalizationsV2(
    'Verifies the initial state of the Host Name tab',
    (tester, screen) async {
      when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).localNetwork), findsOneWidget);
      expect(find.byKey(const Key('hostNameTextField')), findsOneWidget);
      expect(
          tester
              .widget<TextField>(find.descendant(
                  of: find.byKey(const Key('hostNameTextField')),
                  matching: find.byType(TextField)))
              .controller
              ?.text,
          mockLocalNetworkSettings2['hostName']);
    },
    screens: screens,
    goldenFilename: 'LNS-HOSTNAME-01-initial_state',
  );

  // Test ID: LNS-HOSTNAME_ERR
  testLocalizationsV2(
    'Verifies the Host Name tab with a validation error',
    (tester, screen) async {
      final errorState =
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsErrorState)
              .copyWith(
        status: LocalNetworkStatus.fromMap(mockLocalNetworkErrorStatus)
            .copyWith(hasErrorOnHostNameTab: true),
      );
      when(testHelper.mockLocalNetworkSettingsNotifier.build())
          .thenReturn(errorState);

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      final hostNameTab =
          find.widgetWithText(Tab, testHelper.loc(context).hostName);
      expect(
          find.descendant(
              of: hostNameTab, matching: find.byIcon(AppFontIcons.error)),
          findsOneWidget);
      expect(
          tester
              .widget<TextField>(find.descendant(
                  of: find.byKey(const Key('hostNameTextField')),
                  matching: find.byType(TextField)))
              .decoration
              ?.errorText,
          isNotNull);
    },
    screens: screens,
    goldenFilename: 'LNS-HOSTNAME_ERR-01-error_state',
  );

  // Test ID: LNS-IP
  testLocalizationsV2(
    'Verifies the LAN IP Address tab',
    (tester, screen) async {
      when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      await tester.tap(find.text(testHelper.loc(context).lanIPAddress));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lanIpAddressTextField')), findsOneWidget);
      expect(find.byKey(const Key('lanSubnetMaskTextField')), findsOneWidget);

      expect(
          tester
              .widget<AppIpv4TextField>(
                  find.byKey(const Key('lanIpAddressTextField')))
              .controller
              ?.text,
          mockLocalNetworkSettings2['ipAddress']);
      expect(
          tester
              .widget<AppIpv4TextField>(
                  find.byKey(const Key('lanSubnetMaskTextField')))
              .controller
              ?.text,
          mockLocalNetworkSettings2['subnetMask']);
    },
    screens: screens,
    goldenFilename: 'LNS-IP-01-ip_address_tab',
  );

  // Test ID: LNS-IP_ERR
  testLocalizationsV2(
    'Verifies the LAN IP Address tab with a validation error',
    (tester, screen) async {
      final errorState =
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsErrorState)
              .copyWith(
        status: LocalNetworkStatus.fromMap(mockLocalNetworkErrorStatus)
            .copyWith(hasErrorOnIPAddressTab: true),
      );
      when(testHelper.mockLocalNetworkSettingsNotifier.build())
          .thenReturn(errorState);

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      await tester.tap(find.text(testHelper.loc(context).lanIPAddress));
      await tester.pumpAndSettle();

      final ipAddressTab =
          find.widgetWithText(Tab, testHelper.loc(context).lanIPAddress);
      expect(
          find.descendant(
              of: ipAddressTab, matching: find.byIcon(AppFontIcons.error)),
          findsOneWidget);
      expect(
          tester
              .widget<TextField>(find
                  .descendant(
                      of: find.byKey(const Key('lanIpAddressTextField')),
                      matching: find.byType(TextField))
                  .first)
              .decoration
              ?.errorText,
          isNotNull);
    },
    screens: screens,
    goldenFilename: 'LNS-IP_ERR-01-ip_error_state',
  );

  // Test ID: LNS-DHCP
  testLocalizationsV2(
    'Verifies the DHCP Server tab',
    (tester, screen) async {
      when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      await tester.tap(find.text(testHelper.loc(context).dhcpServer));
      await tester.pumpAndSettle();

      expect(find.byType(DHCPServerView), findsOneWidget);
      // Verify switch is on
      expect(
          tester
              .widget<AppSwitchTriggerTile>(
                  find.byKey(const Key('dhcpServerSwitch')))
              .value,
          isTrue);
      expect(find.byKey(const Key('startIpAddressTextField')), findsOneWidget);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
    goldenFilename: 'LNS-DHCP-01-dhcp_server_tab',
  );

  // Test ID: LNS-DHCP_ERR
  testLocalizationsV2(
    'Verifies the DHCP Server tab with a validation error',
    (tester, screen) async {
      final errorState =
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsErrorState)
              .copyWith(
        status: LocalNetworkStatus.fromMap(mockLocalNetworkErrorStatus)
            .copyWith(hasErrorOnDhcpServerTab: true),
      );
      when(testHelper.mockLocalNetworkSettingsNotifier.build())
          .thenReturn(errorState);

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      await tester.tap(find.text(testHelper.loc(context).dhcpServer));
      await tester.pumpAndSettle();

      final dhcpTab =
          find.widgetWithText(Tab, testHelper.loc(context).dhcpServer);
      expect(
          find.descendant(
              of: dhcpTab, matching: find.byIcon(AppFontIcons.error)),
          findsOneWidget);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
    goldenFilename: 'LNS-DHCP_ERR-01-dhcp_error_state',
  );

  // Test ID: LNS-DHCP_IP_ERR
  testLocalizationsV2(
    'Verifies the DHCP Server tab with an IP range error',
    (tester, screen) async {
      final errorState =
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsErrorState)
              .copyWith(
        status:
            LocalNetworkStatus.fromMap(mockLocalNetworkErrorStatus).copyWith(
          errorTextMap: {"startIpAddress": "startIpAddressRange"},
          hasErrorOnDhcpServerTab: true,
        ),
      );
      when(testHelper.mockLocalNetworkSettingsNotifier.build())
          .thenReturn(errorState);

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      await tester.tap(find.text(testHelper.loc(context).dhcpServer));
      await tester.pumpAndSettle();

      expect(
          tester
              .widget<TextField>(find
                  .descendant(
                      of: find.byKey(const Key('startIpAddressTextField')),
                      matching: find.byType(TextField))
                  .first)
              .decoration
              ?.errorText,
          isNotNull);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
    goldenFilename: 'LNS-DHCP_IP_ERR-01-ip_range_error',
  );

  // Test ID: LNS-DHCP_OFF
  testLocalizationsV2(
    'Verifies the DHCP Server tab when DHCP is disabled',
    (tester, screen) async {
      final original = LocalNetworkSettings.fromMap(mockLocalNetworkSettings);
      final current = original.copyWith(isDHCPEnabled: false);
      final offState =
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState)
              .copyWith(
        settings: Preservable(original: original, current: current),
      );
      when(testHelper.mockLocalNetworkSettingsNotifier.build())
          .thenReturn(offState);

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      await tester.tap(find.text(testHelper.loc(context).dhcpServer));
      await tester.pumpAndSettle();

      expect(
          tester
              .widget<AppSwitchTriggerTile>(
                  find.byKey(const Key('dhcpServerSwitch')))
              .value,
          isFalse);
      expect(find.byKey(const Key('startIpAddressTextField')), findsNothing);
      expect(find.byKey(const Key('maxUsersTextField')), findsNothing);
      expect(find.byKey(const Key('clientLeaseTimeTextField')), findsNothing);
      expect(find.byIcon(AppFontIcons.chevronRight), findsNothing);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
    goldenFilename: 'LNS-DHCP_OFF-01-dhcp_disabled',
  );

  // Test ID: LNS-DIRTY_NAV
  testLocalizationsV2(
    'Verifies save dialog on navigation when dirty',
    (tester, screen) async {
      final original = LocalNetworkSettings.fromMap(mockLocalNetworkSettings);
      final current = original.copyWith(firstIPAddress: "10.11.1.15");
      final dirtyState =
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState)
              .copyWith(
        settings: Preservable(original: original, current: current),
      );

      when(testHelper.mockLocalNetworkSettingsNotifier.build())
          .thenReturn(dirtyState);
      when(testHelper.mockLocalNetworkSettingsNotifier.isDirty())
          .thenReturn(true);

      final context = await testHelper.pumpView(tester,
          child: const LocalNetworkSettingsView(), locale: screen.locale);
      await tester.pumpAndSettle();

      await tester.tap(find.text(testHelper.loc(context).dhcpServer));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppFontIcons.chevronRight).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
          find.text('${testHelper.loc(context).saveChanges}?'), findsOneWidget);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
    goldenFilename: 'LNS-DIRTY_NAV-01-save_dialog',
  );
}
