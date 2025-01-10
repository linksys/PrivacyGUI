import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import '../../../../../common/config.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../mocks/dashboard_manager_notifier_mocks.dart';
import '../../../../../mocks/device_filter_config_notifier_mocks.dart';
import '../../../../../mocks/device_manager_notifier_mocks.dart';
import '../../../../../mocks/dhcp_reservations_notifier_mocks.dart';
import '../../../../../mocks/wifi_list_notifier_mocks.dart';
import '../../../../../test_data/dashboard_manager_test_state.dart';
import '../../../../../test_data/device_filter_config_test_state.dart';
import '../../../../../test_data/device_manager_test_state.dart';
import '../../../../../test_data/dhcp_reservations_test_state.dart';
import '../../../../../test_data/local_network_settings_state.dart';
import '../../../../../mocks/local_network_settings_notifier_mocks.dart';
import '../../../../../test_data/wifi_list_test_state.dart';

void main() {
  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;
  late MockDHCPReservationsNotifier mockDHCPReservationsNotifier;
  late MockDeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockWifiListNotifier mockWifiListNotifier;
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;

  setUp(() {
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
    mockDHCPReservationsNotifier = MockDHCPReservationsNotifier();
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockWifiListNotifier = MockWifiListNotifier();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();

    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockWifiListNotifier.build())
        .thenReturn(WiFiState.fromMap(wifiListTestState));
    when(mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));
    when(mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  });

  testLocalizations(
    'DHCP reservations - Empty',
    (tester, locale) async {
      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiListProvider.overrideWith(() => mockWifiListNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - No reserved',
    (tester, locale) async {
      when(mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));

      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiListProvider.overrideWith(() => mockWifiListNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - 1 reserved',
    (tester, locale) async {
      DHCPReservationState dhcpReservationState =
          DHCPReservationState.fromMap(dhcpReservationTestState);
      when(mockDHCPReservationsNotifier.build()).thenReturn(dhcpReservationState
          .copyWith(reservations: [
        dhcpReservationState.devices.first.copyWith(reserved: true)
      ]));

      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiListProvider.overrideWith(() => mockWifiListNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - 2 reserved',
    (tester, locale) async {
      DHCPReservationState dhcpReservationState =
          DHCPReservationState.fromMap(dhcpReservationTestState);
      when(mockDHCPReservationsNotifier.build())
          .thenReturn(dhcpReservationState.copyWith(reservations: [
        dhcpReservationState.devices[0].copyWith(reserved: true),
        dhcpReservationState.devices[1].copyWith(reserved: true)
      ]));

      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiListProvider.overrideWith(() => mockWifiListNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - all reserved',
    (tester, locale) async {
      DHCPReservationState dhcpReservationState =
          DHCPReservationState.fromMap(dhcpReservationTestState);
      when(mockDHCPReservationsNotifier.build()).thenReturn(
          dhcpReservationState.copyWith(
              reservations: dhcpReservationState.devices
                  .map((e) => e.copyWith(reserved: true))
                  .toList()));

      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiListProvider.overrideWith(() => mockWifiListNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );

  testLocalizations(
    'DHCP reservations - mobile filter',
    (tester, locale) async {
      when(mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));

      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiListProvider.overrideWith(() => mockWifiListNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);

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
      when(mockDHCPReservationsNotifier.build())
          .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));

      final widget = testableSingleRoute(
        overrides: [
          localNetworkSettingProvider
              .overrideWith(() => mockLocalNetworkSettingsNotifier),
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiListProvider.overrideWith(() => mockWifiListNotifier),
          dashboardManagerProvider
              .overrideWith(() => mockDashboardManagerNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);

      final addBtnFinder = find.byIcon(LinksysIcons.add);
      await tester.tap(addBtnFinder.first);
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1240)).toList()
    ],
  );
}
