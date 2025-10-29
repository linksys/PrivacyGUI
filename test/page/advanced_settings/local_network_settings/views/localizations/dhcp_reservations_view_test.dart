import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import '../../../../../common/config.dart';
import '../../../../../common/di.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../mocks/dashboard_manager_notifier_mocks.dart';
import '../../../../../mocks/device_filter_config_notifier_mocks.dart';
import '../../../../../mocks/device_manager_notifier_mocks.dart';
import '../../../../../mocks/dhcp_reservations_notifier_mocks.dart';
import '../../../../../mocks/wifi_bundle_settings_notifier_mocks.dart';
import '../../../../../test_data/dashboard_manager_test_state.dart';
import '../../../../../test_data/device_filter_config_test_state.dart';
import '../../../../../test_data/device_manager_test_state.dart';
import '../../../../../test_data/dhcp_reservations_test_state.dart';
import '../../../../../test_data/local_network_settings_state.dart';
import '../../../../../mocks/local_network_settings_notifier_mocks.dart';
import '../../../../../test_data/wifi_bundle_test_state.dart';

void main() {
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;
  late MockDHCPReservationsNotifier mockDHCPReservationsNotifier;
  late MockDeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockWifiBundleNotifier mockWifiBundleNotifier;
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;

  setUp(() {
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
    mockDHCPReservationsNotifier = MockDHCPReservationsNotifier();
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockWifiBundleNotifier = MockWifiBundleNotifier();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();

    final settings = WifiBundleSettings.fromMap(
        wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(
        wifiBundleTestState['status'] as Map<String, dynamic>);
    final wifiInitialState = WifiBundleState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );
    when(mockWifiBundleNotifier.build()).thenReturn(wifiInitialState);

    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerChrry7TestState));
    when(mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  });

  final baseOverrides = [
    localNetworkSettingProvider
        .overrideWith(() => mockLocalNetworkSettingsNotifier),
    deviceFilterConfigProvider
        .overrideWith(() => mockDeviceFilterConfigNotifier),
    deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
    wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
    dashboardManagerProvider.overrideWith(() => mockDashboardManagerNotifier),
  ];

  testLocalizations(
    'DHCP reservations - Empty',
    (tester, locale) async {
      final widget = testableSingleRoute(
        overrides: baseOverrides,
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
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
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
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(reserved: true)
      ]);
      when(mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      final widget = testableSingleRoute(
        overrides: [
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
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
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(reserved: true),
        state.settings.current.reservations[1].copyWith(reserved: true),
      ]);
      when(mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      final widget = testableSingleRoute(
        overrides: [
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
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
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        ...state.settings.current.reservations
            .map((e) => e.copyWith(reserved: true)),
      ]);
      when(mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      final widget = testableSingleRoute(
        overrides: [
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
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
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
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
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
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

  testLocalizations(
    'DHCP reservations - edit reservation',
    (tester, locale) async {
      final state = DHCPReservationState.fromMap(dhcpReservationTestState);
      final settings = state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(reserved: true)
      ]);
      when(mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      final widget = testableSingleRoute(
        overrides: [
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);

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
      when(mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: settings, current: settings)));

      final widget = testableSingleRoute(
        overrides: [
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
        ],
        locale: locale,
        child: const DHCPReservationsView(),
      );
      await tester.pumpWidget(widget);

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

      when(mockDHCPReservationsNotifier.build()).thenReturn(state.copyWith(
          settings: Preservable(original: state.settings.current,
              current: state.settings.current.copyWith(reservations: [
        state.settings.current.reservations.first.copyWith(
          reserved: true,
          data: state.settings.current.reservations.first.data
              .copyWith(ipAddress: "10.175.1.144"),
        ),
        state.settings.current.reservations[1],
      ]))));

      when(mockDHCPReservationsNotifier
              .isConflict(state.settings.current.reservations[1]))
          .thenAnswer((invocation) => true);

      final widget = testableSingleRoute(
        overrides: [
          ...baseOverrides,
          dhcpReservationProvider
              .overrideWith(() => mockDHCPReservationsNotifier),
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
}
