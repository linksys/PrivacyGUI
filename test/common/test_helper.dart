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
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/_index.dart';
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
      ];

  Future<void> pumpView(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
    LinksysRouteConfig? config,
  }) async {
    await tester.pumpWidget(
      testableSingleRoute(
        config: config ?? LinksysRouteConfig(column: ColumnGrid(column: 9)),
        locale: locale,
        overrides: [...defaultOverrides, ...overrides],
        child: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Pump a widget with a shell widget
  Future<void> pumpShellView(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
    LinksysRouteConfig? config,
  }) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        config: config ?? LinksysRouteConfig(column: ColumnGrid(column: 9)),
        locale: locale,
        overrides: [...defaultOverrides, ...overrides],
        child: child,
      ),
    );
    await tester.pumpAndSettle();
  }
}
