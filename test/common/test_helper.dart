import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_state.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_state.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/external_device_detail_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/external_device_detail_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/_index.dart';
import '../mocks/connectivity_notifier_mocks.dart';
import '../mocks/dhcp_reservations_notifier_mocks.dart';
import '../mocks/instant_verify_notifier_mocks.dart';
import '../mocks/manual_firmware_update_notifier_mocks.dart';
import '../mocks/pnp_notifier_mocks.dart' as Mock;
import '../mocks/power_table_notifier_mocks.dart';
import '../mocks/static_routing_rule_notifier_mocks.dart';
import '../test_data/instant_verify_test_state.dart';
import '../test_data/power_table_test_state.dart';
import 'di.dart';
import 'testable_router.dart';

import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_provider.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import '../test_data/_index.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

class TestHelper {
  late MockAdministrationSettingsNotifier mockAdministrationSettingsNotifier;
  late MockAppsAndGamingViewNotifier mockAppsAndGamingViewNotifier;
  late MockDDNSNotifier mockDDNSNotifier;
  late MockSinglePortForwardingListNotifier
      mockSinglePortForwardingListNotifier;
  late MockSinglePortForwardingRuleNotifier
      mockSinglePortForwardingRuleNotifier;
  late MockPortRangeForwardingListNotifier mockPortRangeForwardingListNotifier;
  late MockPortRangeForwardingRuleNotifier mockPortRangeForwardingRuleNotifier;
  late MockPortRangeTriggeringListNotifier mockPortRangeTriggeringListNotifier;
  late MockPortRangeTriggeringRuleNotifier mockPortRangeTriggeringRuleNotifier;
  late MockDMZSettingNotifier mockDMZSettingNotifier;
  late MockDashboardHomeNotifier mockDashboardHomeNotifier;
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;
  late MockFirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;
  late MockInstantTopologyNotifier mockInstantTopologyNotifier;
  late MockGeolocationNotifier mockGeolocationNotifer;
  late MockNodeLightSettingsNotifier mockNodeLightSettingsNotifier;
  late MockPollingNotifier mockPollingNotifier;
  late MockVPNNotifier mockVPNNotifier;
  late MockWifiListNotifier mockWiFiListNotifier;
  late MockWifiAdvancedSettingsNotifier mockWiFiAdvancedSettingsNotifier;
  late MockWiFiViewNotifier mockWiFiViewNotifier;
  late MockDeviceListNotifier mockDeviceListNotifier;
  late ServiceHelper mockServiceHelper;
  late MockHealthCheckProvider mockHealthCheckProvider;
  late MockFirewallNotifier mockFirewallNotifier;
  late MockIpv6PortServiceListNotifier mockIpv6PortServiceListNotifier;
  late MockIpv6PortServiceRuleNotifier mockIpv6PortServiceRuleNotifier;
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;
  late MockDHCPReservationsNotifier mockDHCPReservationsNotifier;
  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;
  late MockStaticRoutingNotifier mockStaticRoutingNotifier;
  late MockStaticRoutingRuleNotifier mockStaticRoutingRuleNotifier;
  late MockAuthNotifier mockAuthNotifier;
  late MockInstantSafetyNotifier mockInstantSafetyNotifier;
  late MockConnectivityNotifier mockConnectivityNotifier;
  late MockRouterPasswordNotifier mockRouterPasswordNotifier;
  late MockTimezoneNotifier mockTimezoneNotifier;
  late MockPowerTableNotifier mockPowerTableNotifier;
  late MockManualFirmwareUpdateNotifier mockManualFirmwareUpdateNotifier;
  late MockExternalDeviceDetailNotifier mockExternalDeviceDetailNotifier;
  late MockDeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late Mock.MockPnpNotifier mockPnpNotifier;
  late MockPnpTroubleshooterNotifier mockPnpTroubleshooterNotifier;
  late MockInstantVerifyNotifier mockInstantVerifyNotifier;
  late MockAddNodesNotifier mockAddNodesNotifier;
  late MockNodeDetailNotifier mockNodeDetailNotifier;

  void setup() {
    mockAdministrationSettingsNotifier = MockAdministrationSettingsNotifier();
    mockAppsAndGamingViewNotifier = MockAppsAndGamingViewNotifier();
    mockDDNSNotifier = MockDDNSNotifier();
    mockSinglePortForwardingListNotifier =
        MockSinglePortForwardingListNotifier();
    mockSinglePortForwardingRuleNotifier =
        MockSinglePortForwardingRuleNotifier();
    mockPortRangeForwardingRuleNotifier = MockPortRangeForwardingRuleNotifier();
    mockPortRangeForwardingListNotifier = MockPortRangeForwardingListNotifier();
    mockPortRangeTriggeringListNotifier = MockPortRangeTriggeringListNotifier();
    mockPortRangeTriggeringRuleNotifier = MockPortRangeTriggeringRuleNotifier();
    mockDMZSettingNotifier = MockDMZSettingNotifier();
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockInstantTopologyNotifier = MockInstantTopologyNotifier();
    mockGeolocationNotifer = MockGeolocationNotifier();
    mockNodeLightSettingsNotifier = MockNodeLightSettingsNotifier();
    mockPollingNotifier = MockPollingNotifier();
    mockVPNNotifier = MockVPNNotifier();
    mockWiFiListNotifier = MockWifiListNotifier();
    mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();
    mockWiFiViewNotifier = MockWiFiViewNotifier();
    mockDeviceListNotifier = MockDeviceListNotifier();
    mockHealthCheckProvider = MockHealthCheckProvider();
    mockFirewallNotifier = MockFirewallNotifier();
    mockIpv6PortServiceListNotifier = MockIpv6PortServiceListNotifier();
    mockIpv6PortServiceRuleNotifier = MockIpv6PortServiceRuleNotifier();
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
    mockDHCPReservationsNotifier = MockDHCPReservationsNotifier();
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
    mockStaticRoutingNotifier = MockStaticRoutingNotifier();
    mockStaticRoutingRuleNotifier = MockStaticRoutingRuleNotifier();
    mockAuthNotifier = MockAuthNotifier();
    mockInstantSafetyNotifier = MockInstantSafetyNotifier();
    mockConnectivityNotifier = MockConnectivityNotifier();
    mockRouterPasswordNotifier = MockRouterPasswordNotifier();
    mockTimezoneNotifier = MockTimezoneNotifier();
    mockPowerTableNotifier = MockPowerTableNotifier();
    mockManualFirmwareUpdateNotifier = MockManualFirmwareUpdateNotifier();
    mockExternalDeviceDetailNotifier = MockExternalDeviceDetailNotifier();
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockPnpNotifier = Mock.MockPnpNotifier();
    mockPnpTroubleshooterNotifier = MockPnpTroubleshooterNotifier();
    mockInstantVerifyNotifier = MockInstantVerifyNotifier();
    mockAddNodesNotifier = MockAddNodesNotifier();
    mockNodeDetailNotifier = MockNodeDetailNotifier();
    SharedPreferences.setMockInitialValues({});

    _setupServiceHelper();
    _setupDefaultData();
  }

  void _setupServiceHelper() {
    mockDependencyRegister();
    mockServiceHelper = getIt.get<ServiceHelper>();
    when(mockServiceHelper.isSupportGuestNetwork()).thenReturn(true);
    when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
    when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
    when(mockServiceHelper.isSupportVPN()).thenReturn(false);
    when(mockServiceHelper.isSupportHealthCheck()).thenReturn(true);
    when(mockServiceHelper.isSupportClientDeauth()).thenReturn(true);
  }

  void _setupDefaultData() {
    when(mockAdministrationSettingsNotifier.build()).thenReturn(
        AdministrationSettingsState.fromMap(administrationSettingsTestState));
    when(mockAdministrationSettingsNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return AdministrationSettingsState.fromMap(
          administrationSettingsTestState);
    });
    when(mockAppsAndGamingViewNotifier.build())
        .thenReturn(AppsAndGamingViewState.fromMap(const {}));
    when(mockDDNSNotifier.build()).thenReturn(DDNSState.fromMap(ddnsTestState));
    when(mockSinglePortForwardingListNotifier.build()).thenReturn(
        SinglePortForwardingListState.fromMap(
            singlePortForwardingListTestState));
    when(mockSinglePortForwardingRuleNotifier.build()).thenReturn(
        const SinglePortForwardingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    when(mockPortRangeForwardingRuleNotifier.build()).thenReturn(
        const PortRangeForwardingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    when(mockPortRangeForwardingListNotifier.build()).thenReturn(
        PortRangeForwardingListState.fromMap(portRangeForwardingListTestState));
    when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
        PortRangeTriggeringListState.fromMap(portRangeTriggerListTestState));
    when(mockPortRangeTriggeringRuleNotifier.build())
        .thenReturn(const PortRangeTriggeringRuleState());
    when(mockDMZSettingNotifier.build())
        .thenReturn(DMZSettingsState.fromMap(dmzSettingsTestState));
    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomePinnacleTestState));
    when(mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerPinnacleTestState));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantTopologyNotifier.build())
        .thenReturn(TopologyTestData().testTopology2SlavesDaisyState);
    when(mockGeolocationNotifer.build()).thenAnswer(
        (_) async => GeolocationState.fromMap(geolocationTestState));
    when(mockNodeLightSettingsNotifier.build())
        .thenReturn(NodeLightSettings(isNightModeEnable: false));
    when(mockPollingNotifier.build()).thenReturn(
        CoreTransactionData(lastUpdate: 0, isReady: true, data: const {}));
    when(mockVPNNotifier.build()).thenReturn(VPNTestState.defaultState);
    when(mockWiFiListNotifier.build())
        .thenReturn(WiFiState.fromMap(wifiListTestState));
    when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockWiFiViewNotifier.build()).thenReturn(WiFiViewState());
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(deviceListTestState));
    when(mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStateSuccessGood));
    when(mockFirewallNotifier.build())
        .thenReturn(FirewallState.fromMap(firewallSettingsTestState));
    when(mockIpv6PortServiceListNotifier.build()).thenReturn(
        Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState));
    when(mockIpv6PortServiceRuleNotifier.build())
        .thenReturn(const Ipv6PortServiceRuleState());
    when(mockInternetSettingsNotifier.build())
        .thenReturn(InternetSettingsState.fromMap(internetSettingsStateDHCP));
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    when(mockStaticRoutingNotifier.build())
        .thenReturn(StaticRoutingState.fromMap(staticRoutingEmptyState));
    when(mockStaticRoutingRuleNotifier.build()).thenReturn(
        StaticRoutingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    when(mockAuthNotifier.build()).thenAnswer(
      (_) async => Future.value(AuthState(loginType: LoginType.local)),
    );
    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState));
    when(mockConnectivityNotifier.build()).thenReturn(ConnectivityState(
        hasInternet: true,
        connectivityInfo:
            ConnectivityInfo(routerType: RouterType.behindManaged)));
    when(mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
    when(mockTimezoneNotifier.build())
        .thenReturn(TimezoneState.fromMap(timezoneTestState));
    when(mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: false));
    when(mockManualFirmwareUpdateNotifier.build())
        .thenReturn(ManualFirmwareUpdateState());
    when(mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    when(mockPnpTroubleshooterNotifier.build())
        .thenReturn(PnpTroubleshooterState());
    when(mockInstantVerifyNotifier.build())
        .thenReturn(InstantVerifyState.fromMap(instantVerifyTestState));
    when(mockAddNodesNotifier.build()).thenReturn(const AddNodesState());
    when(mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
  }

  List<Override> get defaultOverrides => [
        administrationSettingsProvider
            .overrideWith(() => mockAdministrationSettingsNotifier),
        appsAndGamingProvider.overrideWith(() => mockAppsAndGamingViewNotifier),
        ddnsProvider.overrideWith(() => mockDDNSNotifier),
        singlePortForwardingListProvider
            .overrideWith(() => mockSinglePortForwardingListNotifier),
        singlePortForwardingRuleProvider
            .overrideWith(() => mockSinglePortForwardingRuleNotifier),
        portRangeForwardingListProvider
            .overrideWith(() => mockPortRangeForwardingListNotifier),
        portRangeForwardingRuleProvider
            .overrideWith(() => mockPortRangeForwardingRuleNotifier),
        portRangeTriggeringListProvider
            .overrideWith(() => mockPortRangeTriggeringListNotifier),
        portRangeTriggeringRuleProvider
            .overrideWith(() => mockPortRangeTriggeringRuleNotifier),
        dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        dashboardManagerProvider
            .overrideWith(() => mockDashboardManagerNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
        instantTopologyProvider.overrideWith(() => mockInstantTopologyNotifier),
        geolocationProvider.overrideWith(() => mockGeolocationNotifer),
        nodeLightSettingsProvider
            .overrideWith(() => mockNodeLightSettingsNotifier),
        pollingProvider.overrideWith(() => mockPollingNotifier),
        vpnProvider.overrideWith(() => mockVPNNotifier),
        wifiListProvider.overrideWith(() => mockWiFiListNotifier),
        wifiAdvancedProvider
            .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
        wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
        deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        internetStatusProvider.overrideWith((ref) => InternetStatus.online),
        firewallProvider.overrideWith(() => mockFirewallNotifier),
        ipv6PortServiceListProvider
            .overrideWith(() => mockIpv6PortServiceListNotifier),
        ipv6PortServiceRuleProvider
            .overrideWith(() => mockIpv6PortServiceRuleNotifier),
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
        dhcpReservationProvider
            .overrideWith(() => mockDHCPReservationsNotifier),
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
        staticRoutingProvider.overrideWith(() => mockStaticRoutingNotifier),
        staticRoutingRuleProvider
            .overrideWith(() => mockStaticRoutingRuleNotifier),
        authProvider.overrideWith(() => mockAuthNotifier),
        instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
        connectivityProvider.overrideWith(() => mockConnectivityNotifier),
        routerPasswordProvider.overrideWith(() => mockRouterPasswordNotifier),
        timezoneProvider.overrideWith(() => mockTimezoneNotifier),
        powerTableProvider.overrideWith(() => mockPowerTableNotifier),
        manualFirmwareUpdateProvider
            .overrideWith(() => mockManualFirmwareUpdateNotifier),
        externalDeviceDetailProvider
            .overrideWith(() => mockExternalDeviceDetailNotifier),
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        pnpProvider.overrideWith(() => mockPnpNotifier),
        instantVerifyProvider.overrideWith(() => mockInstantVerifyNotifier),
        addNodesProvider.overrideWith(() => mockAddNodesNotifier),
        nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
      ];

  Future<void> pumpView(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
    LinksysRouteConfig? config,
    ThemeMode themeMode = ThemeMode.system,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    await tester.pumpWidget(
      testableSingleRoute(
        config: config ?? LinksysRouteConfig(column: ColumnGrid(column: 9)),
        locale: locale,
        overrides: [...defaultOverrides, ...overrides],
        themeMode: themeMode,
        navigatorKey: navigatorKey,
        child: child,
      ),
    );
    // await tester.pumpAndSettle();
  }

  /// Pump a widget with a shell widget
  Future<void> pumpShellView(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
    LinksysRouteConfig? config,
    ThemeMode themeMode = ThemeMode.system,
  }) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        config: config ?? LinksysRouteConfig(column: ColumnGrid(column: 9)),
        locale: locale,
        themeMode: themeMode,
        overrides: [...defaultOverrides, ...overrides],
        child: child,
      ),
    );
    // await tester.pumpAndSettle();
  }
}
