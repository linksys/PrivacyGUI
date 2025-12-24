import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/dhcp_reservations_test_state.dart';
import '../../../../../test_data/local_network_settings_state.dart';

// View ID: DHCPR
// Implementation file under test: lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_view.dart
///
/// | Test ID          | Description                                                          |
/// | :--------------- | :------------------------------------------------------------------- |
/// | `DHCPR-EMPTY`    | Verifies the view when there are no devices or reservations.         |
/// | `DHCPR-NO_RES`   | Verifies the view with a list of un-reserved devices.                |
/// | `DHCPR-SOME_RES` | Verifies the view with a mix of reserved and un-reserved devices.    |
/// | `DHCPR-ALL_RES`  | Verifies the view when all devices are reserved.                     |
/// | `DHCPR-CONFLICT` | Verifies the view when a device has a conflicting IP.                |
/// | `DHCPR-ADD_MODAL`| Verifies the "manually add reservation" dialog.                      |
/// | `DHCPR-EDIT_MODAL`| Verifies the "edit reservation" dialog.                              |
/// | `DHCPR-MOB_FILTER`| Verifies the device filter dialog on mobile.                         |
///
void main() {
  final testHelper = TestHelper();
  final screens = [
    ...responsiveMobileScreens,
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240))
  ];

  setUp(() {
    testHelper.setup();
    when(testHelper.mockLocalNetworkSettingsNotifier.fetch(forceRemote: true))
        .thenAnswer((_) async =>
            LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    when(testHelper.mockDeviceFilterConfigNotifier.initFilter())
        .thenAnswer((_) async => {});
    // Mock getBandConnectedBy to return proper band name instead of dummy string
    when(testHelper.mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  });

  // Test ID: DHCPR-EMPTY
  testLocalizations(
    'Verifies the view when there are no devices or reservations',
    (tester, screen) async {
      // Enable animations to allow UI to fully render
      testHelper.disableAnimations = false;
      when(testHelper.mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationEmptyState));

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpAndSettle();

      expect(
          find.text(testHelper.loc(context).dhcpReservations.capitalizeWords()),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).dhcpReservationDescption),
          findsOneWidget);
      // After UI Kit migration, Add button is now in menu, find by icon
      expect(find.byIcon(AppFontIcons.add), findsOneWidget);
      expect(find.text(testHelper.loc(context).nReservedAddresses(0)),
          findsOneWidget);
      expect(find.byType(AppListCard), findsNothing);
    },
    screens: screens,
    goldenFilename: 'DHCPR-EMPTY-01-initial_state',
  );

  // Test ID: DHCPR-NO_RES
  testLocalizations(
    'Verifies the view with a list of un-reserved devices',
    (tester, screen) async {
      when(testHelper.mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));
      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).nReservedAddresses(0)),
          findsOneWidget);
      expect(find.byType(AppListCard), findsWidgets);
      final firstCard =
          tester.widget<AppListCard>(find.byType(AppListCard).first);
      expect(firstCard.borderColor, Theme.of(context).colorScheme.outline);
      final checkbox = find
          .descendant(
              of: find.byWidget(firstCard), matching: find.byType(AppCheckbox))
          .evaluate()
          .single
          .widget as AppCheckbox;
      expect(checkbox.value, isFalse);
    },
    screens: screens,
    goldenFilename: 'DHCPR-NO_RES-01-initial_state',
  );

  // Test ID: DHCPR-SOME_RES
  testLocalizations(
    'Verifies the view with a mix of reserved and un-reserved devices',
    (tester, screen) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(reserved: true),
        state.settings.current.reservations[1].copyWith(reserved: true),
      ]);
      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(
          state.copyWith(
              settings: Preservable(original: settings, current: settings)));

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).nReservedAddresses(2)),
          findsOneWidget);
      expect(find.byType(Divider), findsAtLeast(1));

      final reservedCard =
          tester.widget<AppListCard>(find.byType(AppListCard).first);
      expect(reservedCard.borderColor, Theme.of(context).colorScheme.primary);
      final checkbox = find
          .descendant(
              of: find.byWidget(reservedCard),
              matching: find.byType(AppCheckbox))
          .evaluate()
          .single
          .widget as AppCheckbox;
      expect(checkbox.value, isTrue);
      expect(
          find.descendant(
              of: find.byWidget(reservedCard),
              matching: find.byIcon(AppFontIcons.edit)),
          findsOneWidget);
    },
    screens: screens,
    goldenFilename: 'DHCPR-SOME_RES-01-initial_state',
  );

  // Test ID: DHCPR-ALL_RES
  testLocalizations(
    'Verifies the view when all devices are reserved',
    (tester, screen) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(
        reservations: [
          ...state.settings.current.reservations
              .map((e) => e.copyWith(reserved: true)),
        ],
      );
      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(
          state.copyWith(
              settings: Preservable(original: settings, current: settings)));

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpAndSettle();

      final reservedCount = state.settings.current.reservations.length;
      expect(
          find.text(testHelper.loc(context).nReservedAddresses(reservedCount)),
          findsOneWidget);
      expect(find.byIcon(AppFontIcons.edit), findsNWidgets(reservedCount));
    },
    screens: screens,
    goldenFilename: 'DHCPR-ALL_RES-01-initial_state',
  );

  // Test ID: DHCPR-CONFLICT
  testLocalizations(
    'Verifies the view when a device has a conflicting IP',
    (tester, screen) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final conflictingItem = state.status.devices[1];

      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(state);
      when(testHelper.mockDHCPReservationsNotifier.isConflict(conflictingItem))
          .thenReturn(true);

      await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.ancestor(
          of: find.textContaining(conflictingItem.data.macAddress,
              findRichText: true),
          matching: find.byType(AppListCard));
      expect(cardFinder, findsOneWidget);

      final opacityFinder =
          find.ancestor(of: cardFinder, matching: find.byType(Opacity));
      expect(opacityFinder, findsOneWidget);
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, 0.5);
    },
    screens: screens,
    goldenFilename: 'DHCPR-CONFLICT-01-conflict_state',
  );

  // Test ID: DHCPR-ADD_MODAL
  testLocalizations(
    'Verifies the "manually add reservation" dialog',
    (tester, screen) async {
      // Enable animations to allow UI to fully render
      testHelper.disableAnimations = false;
      when(testHelper.mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpAndSettle();

      // Tap the menu button (Add icon) to open the modal
      await tester.tap(find.byIcon(AppFontIcons.add));
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).manuallyAddReservation),
          findsOneWidget);
      expect(find.byKey(const Key('deviceNameTextField')), findsOneWidget);
      expect(find.byKey(const Key('ipAddressTextField')), findsOneWidget);
      expect(find.byKey(const Key('macAddressTextField')), findsOneWidget);
      expect(find.byKey(const Key('alertPositiveButton')), findsOneWidget);
    },
    screens: screens,
    goldenFilename: 'DHCPR-ADD_MODAL-01-add_dialog',
  );

  // Test ID: DHCPR-EDIT_MODAL
  testLocalizations(
    'Verifies the "edit reservation" dialog',
    (tester, screen) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final itemToEdit =
          state.settings.current.reservations.first.copyWith(reserved: true);
      final settings =
          state.settings.current.copyWith(reservations: [itemToEdit]);
      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(
          state.copyWith(
              settings: Preservable(original: settings, current: settings)));

      final context = await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppFontIcons.edit).first);
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).edit), findsOneWidget);
      expect(find.text(testHelper.loc(context).update), findsOneWidget);

      // After UI Kit migration, device name field uses AppTextField (not AppTextFormField)
      final nameField = tester
          .widget<AppTextField>(find.byKey(const Key('deviceNameTextField')));
      expect(nameField.controller?.text, itemToEdit.data.description);

      final ipField = tester.widget<AppIpv4TextField>(
          find.byKey(const Key('ipAddressTextField')));
      expect(ipField.controller?.text, itemToEdit.data.ipAddress);

      // Use Key finder - more robust than type casting
      expect(find.byKey(const Key('macAddressTextField')), findsOneWidget);
    },
    screens: screens,
    goldenFilename: 'DHCPR-EDIT_MODAL-01-edit_dialog',
  );

  // Test ID: DHCPR-MOB_FILTER
  testLocalizations(
    'Verifies the device filter dialog on mobile',
    (tester, screen) async {
      when(testHelper.mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));

      await testHelper.pumpView(
        tester,
        locale: screen.locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpAndSettle();

      final filterBtnFinder = find.byIcon(AppFontIcons.filter);
      expect(filterBtnFinder, findsOneWidget);
      await tester.tap(filterBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byType(DevicesFilterWidget), findsOneWidget);
    },
    screens: responsiveMobileScreens,
    goldenFilename: 'DHCPR-MOB_FILTER-01-filter_dialog',
  );
}

final dhcpReservationEmptyState = {
  "settings": {
    "original": {
      "reservations": [],
    },
    "current": {
      "reservations": [],
    }
  },
  "status": {
    "additionalReservations": [],
    "devices": [],
  }
};
