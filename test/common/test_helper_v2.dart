// ignore_for_file: invalid_use_of_visible_for_overriding_member

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/vpn/models/vpn_models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/cloud/providers/geolocation/geolocation_state.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/services/firmware_update_service.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/dhcp_reservations_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_state.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_state.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';
import 'package:privacy_gui/page/instant_admin/services/manual_firmware_update_service.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/external_device_detail_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/external_device_detail_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/_providers.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_troubleshooter_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/services/pnp_isp_service.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_state.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/route/route_model.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/localization/localization_hook.dart' as hook;

// Import test data (Keep existing imports)
import '../test_data/dhcp_reservations_test_state.dart';
import '../test_data/instant_verify_test_state.dart';
import '../test_data/power_table_test_state.dart';
import '../test_data/wifi_bundle_test_state.dart';
import 'di.dart';
import 'screen.dart';
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
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import '../test_data/_index.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

class TestHelperV2 {
  // Define Mocks using mocktail classes defined at the bottom of this file
  late MockAdministrationSettingsNotifier mockAdministrationSettingsNotifier;
  late MockAppsAndGamingViewNotifier mockAppsAndGamingViewNotifier;
  late MockDDNSNotifier mockDDNSNotifier;
  late MockSinglePortForwardingListNotifier mockSinglePortForwardingListNotifier;
  late MockSinglePortForwardingRuleNotifier mockSinglePortForwardingRuleNotifier;
  late MockPortRangeForwardingListNotifier mockPortRangeForwardingListNotifier;
  late MockPortRangeForwardingRuleNotifier mockPortRangeForwardingRuleNotifier;
  late MockPortRangeTriggeringListNotifier mockPortRangeTriggeringListNotifier;
  late MockPortRangeTriggeringRuleNotifier mockPortRangeTriggeringRuleNotifier;
  late MockDMZSettingsNotifier mockDMZSettingsNotifier;
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
  late MockWifiBundleNotifier mockWiFiBundleNotifier;
  late MockDeviceListNotifier mockDeviceListNotifier;
  late MockServiceHelper mockServiceHelper;
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
  late MockPnpNotifier mockPnpNotifier;
  late MockPnpTroubleshooterNotifier mockPnpTroubleshooterNotifier;
  late MockInstantVerifyNotifier mockInstantVerifyNotifier;
  late MockAddNodesNotifier mockAddNodesNotifier;
  late MockNodeDetailNotifier mockNodeDetailNotifier;
  late MockPnpIspSettingsNotifier mockPnpIspSettingsNotifier;
  late MockPnpIspService mockPnpIspService;
  late MockPnpService mockPnpService;
  late MockFirmwareUpdateService mockFirmwareUpdateService;
  late MockManualFirmwareUpdateService mockManualFirmwareUpdateService;

  // Screen Size
  LocalizedScreen? current;

  // Animation control
  bool disableAnimations = true;

  AppLocalizations loc(BuildContext context) {
    return hook.loc(context);
  }

  void setup() {
    _registerFallbacks();

    mockAdministrationSettingsNotifier = MockAdministrationSettingsNotifier();
    mockAppsAndGamingViewNotifier = MockAppsAndGamingViewNotifier();
    mockDDNSNotifier = MockDDNSNotifier();
    mockSinglePortForwardingListNotifier = MockSinglePortForwardingListNotifier();
    mockSinglePortForwardingRuleNotifier = MockSinglePortForwardingRuleNotifier();
    mockPortRangeForwardingRuleNotifier = MockPortRangeForwardingRuleNotifier();
    mockPortRangeForwardingListNotifier = MockPortRangeForwardingListNotifier();
    mockPortRangeTriggeringListNotifier = MockPortRangeTriggeringListNotifier();
    mockPortRangeTriggeringRuleNotifier = MockPortRangeTriggeringRuleNotifier();
    mockDMZSettingsNotifier = MockDMZSettingsNotifier();
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
    mockWiFiBundleNotifier = MockWifiBundleNotifier();
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
    mockPnpNotifier = MockPnpNotifier();
    mockPnpTroubleshooterNotifier = MockPnpTroubleshooterNotifier();
    mockInstantVerifyNotifier = MockInstantVerifyNotifier();
    mockAddNodesNotifier = MockAddNodesNotifier();
    mockNodeDetailNotifier = MockNodeDetailNotifier();
    mockPnpIspSettingsNotifier = MockPnpIspSettingsNotifier();
    mockPnpIspService = MockPnpIspService();
    mockPnpService = MockPnpService();
    mockFirmwareUpdateService = MockFirmwareUpdateService();
    mockManualFirmwareUpdateService = MockManualFirmwareUpdateService();

    SharedPreferences.setMockInitialValues({});
    _setupPackageInfoMock();
    _setupServiceHelper();
    _setupDefaultData();
  }

  void _registerFallbacks() {
    registerFallbackValue(const AsyncLoading<dynamic>());
    registerFallbackValue(const AsyncData<dynamic>(null));
    registerFallbackValue(FakeLinksysDevice());
    registerFallbackValue(const ConnectivityInfo());
    registerFallbackValue(MockJNAPTransactionBuilder());
    registerFallbackValue(JNAPAction.getRadioInfo);
    registerFallbackValue(CacheLevel.noCache);
    registerFallbackValue(MockServiceHelper());
    registerFallbackValue(FakeVPNGatewaySettings());
    registerFallbackValue(FakeVPNUserCredentials());
    registerFallbackValue(FakeVPNServiceSetSettings());
  }

  void _setupPackageInfoMock() {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'Privacy GUI Test',
          'packageName': 'com.linksys.privacygui.test',
          'version': '2.0.0',
          'buildNumber': '1',
        };
      }
      return null;
    });
  }

  void _setupServiceHelper() {
    mockDependencyRegister();
    mockServiceHelper = MockServiceHelper();
    // In mocktail, we need to register the mock implementation manually if it's accessed via GetIt
    if (getIt.isRegistered<ServiceHelper>()) {
      getIt.unregister<ServiceHelper>();
    }
    getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

    when(() => mockServiceHelper.isSupportGuestNetwork()).thenReturn(true);
    when(() => mockServiceHelper.isSupportLedMode()).thenReturn(true);
    when(() => mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
    when(() => mockServiceHelper.isSupportVPN()).thenReturn(false);
    when(() => mockServiceHelper.isSupportHealthCheck()).thenReturn(true);
    when(() => mockServiceHelper.isSupportClientDeauth()).thenReturn(true);
  }

  void _setupDefaultData() {
    // MOCKTAIL SYNTAX: when(() => call).thenReturn(result)

    when(() => mockAdministrationSettingsNotifier.build()).thenReturn(
        AdministrationSettingsState.fromMap(administrationSettingsTestState));
    when(() => mockAdministrationSettingsNotifier.fetch())
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return AdministrationSettingsState.fromMap(
          administrationSettingsTestState);
    });

    when(() => mockAppsAndGamingViewNotifier.build())
        .thenReturn(AppsAndGamingViewState.fromMap(appsAndGamingTestState));
    
    when(() => mockDDNSNotifier.build())
        .thenReturn(DDNSState.fromMap(ddnsTestState));
    
    when(() => mockSinglePortForwardingListNotifier.build()).thenReturn(
        SinglePortForwardingListState.fromMap(
            singlePortForwardingListTestState));
    
    when(() => mockSinglePortForwardingRuleNotifier.build()).thenReturn(
        const SinglePortForwardingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    
    when(() => mockPortRangeForwardingRuleNotifier.build()).thenReturn(
        const PortRangeForwardingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    
    when(() => mockPortRangeForwardingListNotifier.build()).thenReturn(
        PortRangeForwardingListState.fromMap(portRangeForwardingListTestState));
    
    when(() => mockPortRangeTriggeringListNotifier.build()).thenReturn(
        PortRangeTriggeringListState.fromMap(portRangeTriggerListTestState));
    
    when(() => mockPortRangeTriggeringRuleNotifier.build())
        .thenReturn(const PortRangeTriggeringRuleState());
    
    when(() => mockDMZSettingsNotifier.build())
        .thenReturn(DMZSettingsState.fromMap(dmzSettingsTestState));
    
    when(() => mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomePinnacleTestState));
    
    when(() => mockDashboardManagerNotifier.build()).thenReturn(
        DashboardManagerState.fromMap(dashboardManagerPinnacleTestState));
    
    when(() => mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.fromMap(firmwareUpdateTestData));
    
    when(() => mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    
    when(() => mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    
    when(() => mockInstantTopologyNotifier.build())
        .thenReturn(TopologyTestData().testTopology2SlavesDaisyState);
    
    when(() => mockGeolocationNotifer.build()).thenAnswer(
        (_) async => GeolocationState.fromMap(geolocationTestState));
    
    when(() => mockNodeLightSettingsNotifier.build())
        .thenReturn(NodeLightSettings(isNightModeEnable: false));
    
    when(() => mockPollingNotifier.build()).thenReturn(
        CoreTransactionData(lastUpdate: 0, isReady: true, data: const {}));
    
    when(() => mockVPNNotifier.build()).thenReturn(VPNTestState.defaultState);

    final wifiBundleTestStateSettings = WifiBundleSettings.fromMap(
        wifiBundleTestState['settings'] as Map<String, dynamic>);
    final wifiBundleTestStateStatus = WifiBundleStatus.fromMap(
        wifiBundleTestState['status'] as Map<String, dynamic>);

    final wifiBundleTestStateInitialState = WifiBundleState(
      settings: Preservable(
          original: wifiBundleTestStateSettings,
          current: wifiBundleTestStateSettings),
      status: wifiBundleTestStateStatus,
    );

    when(() => mockWiFiBundleNotifier.build())
        .thenReturn(wifiBundleTestStateInitialState);
    when(() => mockWiFiBundleNotifier.isDirty()).thenReturn(false);

    when(() => mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(deviceListTestState));
    
    when(() => mockHealthCheckProvider.build())
        .thenReturn(HealthCheckState.fromJson(healthCheckStateSuccessGood));
    
    when(() => mockFirewallNotifier.build())
        .thenReturn(FirewallState.fromMap(firewallSettingsTestState));
    
    when(() => mockIpv6PortServiceListNotifier.build()).thenReturn(
        Ipv6PortServiceListState.fromMap(ipv6PortServiceListTestState));
    
    when(() => mockIpv6PortServiceRuleNotifier.build())
        .thenReturn(const Ipv6PortServiceRuleState());
    
    when(() => mockInternetSettingsNotifier.build())
        .thenReturn(InternetSettingsState.fromMap(internetSettingsStateDHCP));
    
    when(() => mockDHCPReservationsNotifier.build())
        .thenReturn(DHCPReservationState.fromMap(dhcpReservationTestState));
    
    when(() => mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    
    when(() => mockStaticRoutingNotifier.build())
        .thenReturn(StaticRoutingState.fromMap(staticRoutingTestStateEmpty));
    
    when(() => mockStaticRoutingRuleNotifier.build()).thenReturn(
        StaticRoutingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    
    when(() => mockAuthNotifier.build()).thenAnswer(
      (_) async => Future.value(AuthState(loginType: LoginType.local)),
    );

    when(() => mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState1));
    
    when(() => mockConnectivityNotifier.build()).thenReturn(ConnectivityState(
        hasInternet: true,
        connectivityInfo:
            ConnectivityInfo(routerType: RouterType.behindManaged)));
    
    when(() => mockRouterPasswordNotifier.build())
        .thenReturn(RouterPasswordState.fromMap(routerPasswordTestState1));
    
    when(() => mockTimezoneNotifier.build())
        .thenReturn(TimezoneState.fromMap(timezoneTestState));
    
    when(() => mockPowerTableNotifier.build()).thenReturn(
        PowerTableState.fromMap(powerTableTestState)
            .copyWith(isPowerTableSelectable: false));
    
    when(() => mockManualFirmwareUpdateNotifier.build())
        .thenReturn(ManualFirmwareUpdateState());
    
    when(() => mockExternalDeviceDetailNotifier.build())
        .thenReturn(ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
    
    when(() => mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    
    when(() => mockPnpTroubleshooterNotifier.build())
        .thenReturn(PnpTroubleshooterState());
    
    when(() => mockInstantVerifyNotifier.build())
        .thenReturn(InstantVerifyState.fromMap(instantVerifyTestState));
    
    when(() => mockAddNodesNotifier.build()).thenReturn(const AddNodesState());
    
    when(() => mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
    
    when(() => mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn12',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
        isUnconfigured: true));
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
        dmzSettingsProvider.overrideWith(() => mockDMZSettingsNotifier),
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
        wifiBundleProvider.overrideWith(() => mockWiFiBundleNotifier),
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
        healthCheckProvider.overrideWith(() => mockHealthCheckProvider),
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
        pnpIspSettingsProvider.overrideWith(() => mockPnpIspSettingsNotifier),
        pnpServiceProvider.overrideWithValue(mockPnpService),
        pnpIspServiceProvider.overrideWithValue(mockPnpIspService),
      ];

  // Helper methods for pumping widgets (Identical logic, just using the new mocks)

  Future<BuildContext> pumpRouter(
    WidgetTester tester,
    GoRouter router, {
    required Type baseViewType,
    List<Override> overrides = const [],
    bool forceOverride = false,
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.system,
    GlobalKey<NavigatorState>? navigatorKey,
    List<ImageProvider> preCacheImages = const [],
    List<String> preCacheCustomImages = const [],
  }) async {
    await tester.pumpWidget(testableRouter(
      router: router,
      overrides:
          forceOverride ? overrides : [...defaultOverrides, ...overrides],
      themeMode: themeMode,
      locale: locale,
      disableAnimations: disableAnimations,
    ));
    final context = tester.element(find.byType(baseViewType));
    await tester.runAsync(() async {
      for (final image in preCacheImages) {
        await precacheImage(image, context);
      }
      for (final image in preCacheCustomImages) {
        await precacheImage(DeviceImageHelper.getRouterImage(image), context);
      }
    });
    return context;
  }

  Future<BuildContext> pumpView(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
    bool forceOverride = false,
    Locale locale = const Locale('en'),
    LinksysRouteConfig? config,
    ThemeMode themeMode = ThemeMode.system,
    GlobalKey<NavigatorState>? navigatorKey,
    List<ImageProvider> preCacheImages = const [],
    List<String> preCacheCustomImages = const [],
  }) async {
    await tester.pumpWidget(
      testableSingleRoute(
        config: config ?? LinksysRouteConfig(column: ColumnGrid(column: 9)),
        locale: locale,
        overrides:
            forceOverride ? overrides : [...defaultOverrides, ...overrides],
        themeMode: themeMode,
        navigatorKey: navigatorKey,
        disableAnimations: disableAnimations,
        child: child,
      ),
    );
    final context = tester.element(find.byType(child.runtimeType));
    await tester.runAsync(() async {
      for (final image in preCacheImages) {
        await precacheImage(image, context);
      }
      for (final image in preCacheCustomImages) {
        await precacheImage(DeviceImageHelper.getRouterImage(image), context);
      }
    });
    return context;
  }

  Future<BuildContext> pumpShellView(
    WidgetTester tester, {
    required Widget child,
    List<Override> overrides = const [],
    bool forceOverride = false,
    Locale locale = const Locale('en'),
    LinksysRouteConfig? config,
    ThemeMode themeMode = ThemeMode.system,
    List<ImageProvider> preCacheImages = const [],
    List<String> preCacheCustomImages = const [],
  }) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        config: config ?? LinksysRouteConfig(column: ColumnGrid(column: 9)),
        locale: locale,
        themeMode: themeMode,
        disableAnimations: disableAnimations,
        overrides:
            forceOverride ? overrides : [...defaultOverrides, ...overrides],
        child: child,
      ),
    );
    final context = tester.element(find.byType(child.runtimeType));
    await tester.runAsync(() async {
      for (final image in preCacheImages) {
        await precacheImage(image, context);
      }
      for (final image in preCacheCustomImages) {
        await precacheImage(DeviceImageHelper.getRouterImage(image), context);
      }
    });
    return context;
  }

  Future takeScreenshot(WidgetTester tester, String filename) async {
    final actualFinder = find.byWidgetPredicate((w) => true).first;
    final name = current != null ? '$filename-${current!.toShort()}' : filename;
    await expectLater(actualFinder, matchesGoldenFile('goldens/$name.png'));
  }
}

// =========================================================================
// MOCKTAIL CLASS DEFINITIONS
// =========================================================================
// These classes allow TestHelperV2 to work independently of generated mocks.
// In a real refactor, these should likely be in `test/mocks/mocktail_mocks.dart`
// =========================================================================

class MockServiceHelper extends Mock implements ServiceHelper {}

// --- Notifiers ---

// 1. AsyncNotifiers
class MockAuthNotifier extends AsyncNotifier<AuthState> with Mock implements AuthNotifier {}
class MockPollingNotifier extends AsyncNotifier<CoreTransactionData> with Mock implements PollingNotifier {}
class MockGeolocationNotifier extends AsyncNotifier<GeolocationState> with Mock implements GeolocationNotifier {}

// 2. AutoDisposeNotifiers
class MockDHCPReservationsNotifier extends AutoDisposeNotifier<DHCPReservationState> with Mock implements DHCPReservationsNotifier {}
class MockAddNodesNotifier extends AutoDisposeNotifier<AddNodesState> with Mock implements AddNodesNotifier {}
class MockManualFirmwareUpdateNotifier extends AutoDisposeNotifier<ManualFirmwareUpdateState> with Mock implements ManualFirmwareUpdateNotifier {}

// 3. Standard Notifiers
class MockAdministrationSettingsNotifier extends Notifier<AdministrationSettingsState> with Mock implements AdministrationSettingsNotifier {}
class MockAppsAndGamingViewNotifier extends Notifier<AppsAndGamingViewState> with Mock implements AppsAndGamingViewNotifier {}
class MockDDNSNotifier extends Notifier<DDNSState> with Mock implements DDNSNotifier {}
class MockSinglePortForwardingListNotifier extends Notifier<SinglePortForwardingListState> with Mock implements SinglePortForwardingListNotifier {}
class MockSinglePortForwardingRuleNotifier extends Notifier<SinglePortForwardingRuleState> with Mock implements SinglePortForwardingRuleNotifier {}
class MockPortRangeForwardingListNotifier extends Notifier<PortRangeForwardingListState> with Mock implements PortRangeForwardingListNotifier {}
class MockPortRangeForwardingRuleNotifier extends Notifier<PortRangeForwardingRuleState> with Mock implements PortRangeForwardingRuleNotifier {}
class MockPortRangeTriggeringListNotifier extends Notifier<PortRangeTriggeringListState> with Mock implements PortRangeTriggeringListNotifier {}
class MockPortRangeTriggeringRuleNotifier extends Notifier<PortRangeTriggeringRuleState> with Mock implements PortRangeTriggeringRuleNotifier {}
class MockDMZSettingsNotifier extends Notifier<DMZSettingsState> with Mock implements DMZSettingsNotifier {}
class MockDashboardHomeNotifier extends Notifier<DashboardHomeState> with Mock implements DashboardHomeNotifier {}
class MockDashboardManagerNotifier extends Notifier<DashboardManagerState> with Mock implements DashboardManagerNotifier {}
class MockFirmwareUpdateNotifier extends Notifier<FirmwareUpdateState> with Mock implements FirmwareUpdateNotifier {}
class MockDeviceManagerNotifier extends Notifier<DeviceManagerState> with Mock implements DeviceManagerNotifier {}
class MockInstantPrivacyNotifier extends Notifier<InstantPrivacyState> with Mock implements InstantPrivacyNotifier {}
class MockInstantTopologyNotifier extends Notifier<InstantTopologyState> with Mock implements InstantTopologyNotifier {}
class MockNodeLightSettingsNotifier extends Notifier<NodeLightSettings> with Mock implements NodeLightSettingsNotifier {}
class MockVPNNotifier extends Notifier<VPNState> with Mock implements VPNNotifier {}
class MockWifiBundleNotifier extends Notifier<WifiBundleState> with Mock implements WifiBundleNotifier {}
class MockDeviceListNotifier extends Notifier<DeviceListState> with Mock implements DeviceListNotifier {}
class MockHealthCheckProvider extends Notifier<HealthCheckState> with Mock implements HealthCheckProvider {}
class MockFirewallNotifier extends Notifier<FirewallState> with Mock implements FirewallNotifier {}
class MockIpv6PortServiceListNotifier extends Notifier<Ipv6PortServiceListState> with Mock implements Ipv6PortServiceListNotifier {}
class MockIpv6PortServiceRuleNotifier extends Notifier<Ipv6PortServiceRuleState> with Mock implements Ipv6PortServiceRuleNotifier {}
class MockInternetSettingsNotifier extends Notifier<InternetSettingsState> with Mock implements InternetSettingsNotifier {}
class MockLocalNetworkSettingsNotifier extends Notifier<LocalNetworkSettingsState> with Mock implements LocalNetworkSettingsNotifier {}
class MockStaticRoutingNotifier extends Notifier<StaticRoutingState> with Mock implements StaticRoutingNotifier {}
class MockStaticRoutingRuleNotifier extends Notifier<StaticRoutingRuleState> with Mock implements StaticRoutingRuleNotifier {}
class MockInstantSafetyNotifier extends Notifier<InstantSafetyState> with Mock implements InstantSafetyNotifier {}
class MockConnectivityNotifier extends Notifier<ConnectivityState> with Mock implements ConnectivityNotifier {}
class MockRouterPasswordNotifier extends Notifier<RouterPasswordState> with Mock implements RouterPasswordNotifier {}
class MockTimezoneNotifier extends Notifier<TimezoneState> with Mock implements TimezoneNotifier {}
class MockPowerTableNotifier extends Notifier<PowerTableState> with Mock implements PowerTableNotifier {}
class MockExternalDeviceDetailNotifier extends Notifier<ExternalDeviceDetailState> with Mock implements ExternalDeviceDetailNotifier {}
class MockDeviceFilterConfigNotifier extends Notifier<DeviceFilterConfigState> with Mock implements DeviceFilterConfigNotifier {}
class MockPnpNotifier extends Notifier<PnpState> with Mock implements PnpNotifier {}
class MockPnpTroubleshooterNotifier extends Notifier<PnpTroubleshooterState> with Mock implements PnpTroubleshooterNotifier {}
class MockInstantVerifyNotifier extends Notifier<InstantVerifyState> with Mock implements InstantVerifyNotifier {}
class MockNodeDetailNotifier extends Notifier<NodeDetailState> with Mock implements NodeDetailNotifier {}
class MockPnpIspSettingsNotifier extends Notifier<PnpIspSettingsStatus> with Mock implements PnpIspSettingsNotifier {}

// --- JNAP / Core Fakes & Mocks ---
class FakeLinksysDevice extends Fake implements LinksysDevice {
  @override
  String get deviceID => 'fake-device-id';
}

class MockJNAPTransactionBuilder extends Mock implements JNAPTransactionBuilder {}

class FakeVPNGatewaySettings extends Fake implements VPNGatewaySettings {}
class FakeVPNUserCredentials extends Fake implements VPNUserCredentials {}
class FakeVPNServiceSetSettings extends Fake implements VPNServiceSetSettings {}

// --- Services ---
class MockPnpService extends Mock implements PnpService {}
class MockPnpIspService extends Mock implements PnpIspService {}
class MockFirmwareUpdateService extends Mock implements FirmwareUpdateService {}
class MockManualFirmwareUpdateService extends Mock implements ManualFirmwareUpdateService {}
