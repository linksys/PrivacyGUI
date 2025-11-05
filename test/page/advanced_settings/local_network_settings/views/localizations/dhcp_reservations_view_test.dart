import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/dashboard_manager_test_state.dart';
import '../../../../../test_data/dhcp_reservations_test_state.dart';
import '../../../../../test_data/wifi_bundle_test_state.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();

    final settings = WifiBundleSettings.fromMap(
        wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(
        wifiBundleTestState['status'] as Map<String, dynamic>);
    final wifiInitialState = WifiBundleState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );
    when(testHelper.mockWiFiBundleNotifier.build()).thenReturn(wifiInitialState);
    when(testHelper.mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));
  });

  testLocalizations(
    'DHCP reservations - Empty',
    (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - No reserved',
    (tester, locale) async {
      when(testHelper.mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - 1 reserved',
    (tester, locale) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(reserved: true)
      ]);
      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - 2 reserved',
    (tester, locale) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(reserved: true),
        state.settings.current.reservations[1].copyWith(reserved: true),
      ]);
      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - all reserved',
    (tester, locale) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        ...state.settings.current.reservations
            .map((e) => e.copyWith(reserved: true)),
      ]);
      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - mobile filter',
    (tester, locale) async {
      when(testHelper.mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );

      final filterBtnFinder = find.byIcon(LinksysIcons.filter);
      await tester.tap(filterBtnFinder.first);
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
    ],
  );

  testLocalizations(
    'DHCP reservations - add reservation',
    (tester, locale) async {
      when(testHelper.mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );

      final addBtnFinder = find.byIcon(LinksysIcons.add);
      await tester.tap(addBtnFinder.first);
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - edit reservation',
    (tester, locale) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(reserved: true)
      ]);
      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );

      final editBtnFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editBtnFinder.first);
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - can not be added state',
    (tester, locale) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(reserved: true)
      ]);
      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );

      final editBtnFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editBtnFinder.first);
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - can not be added state',
    (tester, locale) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);

      when(testHelper.mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: state.settings.current,
              current: state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(
          reserved: true,
          data: state.settings.current.reservations.first.data
              .copyWith(ipAddress: "10.175.1.144"),
        ),
        state.settings.current.reservations[1],
      ]))));

      when(testHelper.mockDHCPReservationsNotifier
              .isConflict(state.settings.current.reservations[1]))
          .thenAnswer((invocation) => true);

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const DHCPReservationsView(),
      );
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );
}
