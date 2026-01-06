// ignore_for_file: invalid_use_of_visible_for_overriding_member
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_service.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';

class MockWifiSettingsService extends Mock implements WifiSettingsService {}

class FakeLinksysDevice extends Fake implements LinksysDevice {}

class MockDashboardManagerNotifier extends Notifier<DashboardManagerState>
    with Mock
    implements DashboardManagerNotifier {}

class MockDashboardHomeNotifier extends Notifier<DashboardHomeState>
    with Mock
    implements DashboardHomeNotifier {}

class MockDeviceManagerNotifier extends Notifier<DeviceManagerState>
    with Mock
    implements DeviceManagerNotifier {}

class MockRouterRepository extends Mock implements RouterRepository {}

class MockServiceHelper extends Mock implements ServiceHelper {}

void main() {
  late MockWifiSettingsService mockWifiSettingsService;
  late MockDashboardManagerNotifier mockDashboardManagerNotifier;
  late MockDashboardHomeNotifier mockDashboardHomeNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockRouterRepository mockRouterRepository;
  late ProviderContainer container;

  setUp(() {
    // Mock Init
    mockWifiSettingsService = MockWifiSettingsService();
    mockDashboardManagerNotifier = MockDashboardManagerNotifier();
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockRouterRepository = MockRouterRepository();

    // Stub ServiceHelper
    final helper = MockServiceHelper();
    when(() => helper.isSupportGuestNetwork()).thenReturn(true);
    when(() => helper.isSupportTopologyOptimization()).thenReturn(true);
    when(() => helper.isSupportIPTv()).thenReturn(true);
    when(() => helper.isSupportMLO()).thenReturn(true);
    when(() => helper.isSupportDFS()).thenReturn(true);
    when(() => helper.isSupportAirtimeFairness()).thenReturn(true);
    when(() => helper.isSupportGetSTABSSID()).thenReturn(true);
    GetIt.I.registerSingleton<ServiceHelper>(helper);

    // Register fallback values
    registerFallbackValue(FakeLinksysDevice());
    registerFallbackValue(MockServiceHelper());
    registerFallbackValue(const WifiAdvancedSettingsState());
    registerFallbackValue(InstantPrivacySettings.init());
    registerFallbackValue(WiFiListSettings(
      mainWiFi: const [],
      guestWiFi: const GuestWiFiItem(
          isEnabled: false, ssid: '', password: '', numOfDevices: 0),
      isSimpleMode: true,
      simpleModeWifi: WiFiItem.fromMap(const {
        'channel': 0,
        'isBroadcast': false,
        'isEnabled': false,
        'numOfDevices': 0,
      }),
    ));

    // Default Stubs
    when(() => mockDashboardManagerNotifier.build())
        .thenReturn(const DashboardManagerState());
    when(() => mockDashboardHomeNotifier.build())
        .thenReturn(const DashboardHomeState());
    when(() => mockDeviceManagerNotifier.build())
        .thenReturn(const DeviceManagerState());
    when(() => mockDeviceManagerNotifier.getBandConnectedBy(any()))
        .thenReturn('');

    // Stub for createInitialWifiListSettings (added for refactored build() method)
    when(() => mockWifiSettingsService.createInitialWifiListSettings(
          mainRadios: any(named: 'mainRadios'),
          isGuestNetworkEnabled: any(named: 'isGuestNetworkEnabled'),
          guestSSID: any(named: 'guestSSID'),
          guestPassword: any(named: 'guestPassword'),
          mainWifiDevices: any(named: 'mainWifiDevices'),
          guestWifiDevicesCount: any(named: 'guestWifiDevicesCount'),
          getBandConnectedBy: any(named: 'getBandConnectedBy'),
        )).thenReturn(WiFiListSettings(
      mainWiFi: const [],
      guestWiFi: const GuestWiFiItem(
          isEnabled: false, ssid: '', password: '', numOfDevices: 0),
      isSimpleMode: true,
      simpleModeWifi: WiFiItem.fromMap(const {
        'channel': 0,
        'isBroadcast': false,
        'isEnabled': false,
        'numOfDevices': 0,
      }),
    ));

    container = ProviderContainer(
      overrides: [
        wifiSettingsServiceProvider.overrideWithValue(mockWifiSettingsService),
        dashboardManagerProvider
            .overrideWith(() => mockDashboardManagerNotifier),
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        routerRepositoryProvider.overrideWithValue(mockRouterRepository),
      ],
    );
  });

  tearDown(() {
    GetIt.I.reset();
  });

  void seedWithRadios() {
    final radios = [
      RouterRadio(
          radioID: 'RADIO_2.4GHz',
          physicalRadioID: '1',
          bssid: '00:00:00:00:00:01',
          band: '2.4GHz',
          supportedModes: const [], // Empty to avoid crash
          supportedChannelsForChannelWidths: const [],
          supportedSecurityTypes: [WifiSecurityType.wpa2Personal.value],
          maxRadiusSharedKeyLength: 64,
          settings: RouterRadioSettings(
              isEnabled: true,
              mode: WifiWirelessMode.mixed.value,
              ssid: 'Test 2.4',
              broadcastSSID: true,
              channelWidth: 'Auto',
              channel: 6,
              security: WifiSecurityType.wpa2Personal.value)),
      RouterRadio(
          radioID: 'RADIO_5GHz',
          physicalRadioID: '2',
          bssid: '00:00:00:00:00:02',
          band: '5GHz',
          supportedModes: const [],
          supportedChannelsForChannelWidths: const [],
          supportedSecurityTypes: [WifiSecurityType.wpa2Personal.value],
          maxRadiusSharedKeyLength: 64,
          settings: RouterRadioSettings(
              isEnabled: true,
              mode: WifiWirelessMode.mixed.value,
              ssid: 'Test 5',
              broadcastSSID: true,
              channelWidth: 'Auto',
              channel: 36,
              security: WifiSecurityType.wpa2Personal.value)),
    ];
    when(() => mockDashboardManagerNotifier.build())
        .thenReturn(DashboardManagerState(mainRadios: radios));

    // Create WiFiItems matching the seeded radios for the mock
    final wifiItems = [
      WiFiItem.fromMap(const {
        'radioID': 'RADIO_2.4GHz',
        'ssid': 'Test 2.4',
        'password': '',
        'securityType': 'WPA2-Personal',
        'wirelessMode': '802.11mixed',
        'channelWidth': 'Auto',
        'channel': 6,
        'isBroadcast': true,
        'isEnabled': true,
        'numOfDevices': 0,
      }),
      WiFiItem.fromMap(const {
        'radioID': 'RADIO_5GHz',
        'ssid': 'Test 5',
        'password': '',
        'securityType': 'WPA2-Personal',
        'wirelessMode': '802.11mixed',
        'channelWidth': 'Auto',
        'channel': 36,
        'isBroadcast': true,
        'isEnabled': true,
        'numOfDevices': 0,
      }),
    ];

    // Stub createInitialWifiListSettings to return the matching WiFiItems
    when(() => mockWifiSettingsService.createInitialWifiListSettings(
          mainRadios: any(named: 'mainRadios'),
          isGuestNetworkEnabled: any(named: 'isGuestNetworkEnabled'),
          guestSSID: any(named: 'guestSSID'),
          guestPassword: any(named: 'guestPassword'),
          mainWifiDevices: any(named: 'mainWifiDevices'),
          guestWifiDevicesCount: any(named: 'guestWifiDevicesCount'),
          getBandConnectedBy: any(named: 'getBandConnectedBy'),
        )).thenReturn(WiFiListSettings(
      mainWiFi: wifiItems,
      guestWiFi: const GuestWiFiItem(
          isEnabled: false, ssid: '', password: '', numOfDevices: 0),
      isSimpleMode: true,
      simpleModeWifi: wifiItems.first,
    ));

    // Re-create container to pick up new stub
    container = ProviderContainer(
      overrides: [
        wifiSettingsServiceProvider.overrideWithValue(mockWifiSettingsService),
        dashboardManagerProvider
            .overrideWith(() => mockDashboardManagerNotifier),
        dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        routerRepositoryProvider.overrideWithValue(mockRouterRepository),
      ],
    );
    // Trigger build
    container.read(wifiBundleProvider);
  }

  test('performFetch delegates to WifiSettingsService', () async {
    final initialSettings = WifiBundleSettings(
      wifiList: WiFiListSettings(
          mainWiFi: const [],
          guestWiFi: const GuestWiFiItem(
              isEnabled: false, ssid: '', password: '', numOfDevices: 0),
          isSimpleMode: true,
          simpleModeWifi: WiFiItem.fromMap(const {
            'channel': 0,
            'isBroadcast': true,
            'isEnabled': true,
            'numOfDevices': 0,
          })),
      advanced: const WifiAdvancedSettingsState(),
      privacy: InstantPrivacySettings.init(),
    );
    final initialStatus = WifiBundleStatus(
      wifiList: const WiFiListStatus(canDisableMainWiFi: false),
      privacy: InstantPrivacyStatus.init(),
    );

    when(() => mockWifiSettingsService.fetchBundleSettings(
          serviceHelper: any(named: 'serviceHelper'),
          forceRemote: any(named: 'forceRemote'),
          mainWifiDevices: any(named: 'mainWifiDevices'),
          guestWifiDevices: any(named: 'guestWifiDevices'),
          allDevices: any(named: 'allDevices'),
          isLanConnected: any(named: 'isLanConnected'),
          getBandConnectedBy: any(named: 'getBandConnectedBy'),
        )).thenAnswer((_) async => (initialSettings, initialStatus));

    await container.read(wifiBundleProvider.notifier).performFetch();

    verify(() => mockWifiSettingsService.fetchBundleSettings(
          serviceHelper: any(named: 'serviceHelper'),
          forceRemote: any(named: 'forceRemote'),
          mainWifiDevices: any(named: 'mainWifiDevices'),
          guestWifiDevices: any(named: 'guestWifiDevices'),
          allDevices: any(named: 'allDevices'),
          isLanConnected: any(named: 'isLanConnected'),
          getBandConnectedBy: any(named: 'getBandConnectedBy'),
        )).called(1);
  });

  test('performSave delegates to WifiSettingsService', () async {
    container.listen(wifiBundleProvider, (_, __) {});

    when(() => mockWifiSettingsService.saveAdvancedSettings(
          settings: any(named: 'settings'),
          serviceHelper: any(named: 'serviceHelper'),
        )).thenAnswer((_) async {});

    container.read(wifiBundleProvider.notifier).setIptvEnabled(true);
    await container.read(wifiBundleProvider.notifier).performSave();

    verify(() => mockWifiSettingsService.saveAdvancedSettings(
          settings: any(named: 'settings'),
          serviceHelper: any(named: 'serviceHelper'),
        )).called(1);
  });

  group('WifiBundleNotifier Setters', () {
    test('setIptvEnabled', () {
      container.read(wifiBundleProvider.notifier).setIptvEnabled(true);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .advanced
              .isIptvEnabled,
          true);
    });

    test('setClientSteeringEnabled', () {
      container
          .read(wifiBundleProvider.notifier)
          .setClientSteeringEnabled(true);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .advanced
              .isClientSteeringEnabled,
          true);
    });

    test('setNodesSteeringEnabled', () {
      container.read(wifiBundleProvider.notifier).setNodesSteeringEnabled(true);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .advanced
              .isNodesSteeringEnabled,
          true);
    });

    test('setMLOEnabled', () {
      container.read(wifiBundleProvider.notifier).setMLOEnabled(true);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .advanced
              .isMLOEnabled,
          true);
    });

    test('setDFSEnabled', () {
      container.read(wifiBundleProvider.notifier).setDFSEnabled(true);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .advanced
              .isDFSEnabled,
          true);
    });

    test('setAirtimeFairnessEnabled', () {
      container
          .read(wifiBundleProvider.notifier)
          .setAirtimeFairnessEnabled(true);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .advanced
              .isAirtimeFairnessEnabled,
          true);
    });

    test('setSimpleMode', () {
      container.read(wifiBundleProvider.notifier).setSimpleMode(false);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .wifiList
              .isSimpleMode,
          false);
    });

    test('setSimpleModeWifi', () {
      final item = WiFiItem.fromMap(const {
        'ssid': 'newSimple',
        'password': 'pass',
        'securityType': 'WPA3-Personal',
        'channel': 0,
        'isBroadcast': true,
        'isEnabled': true,
        'numOfDevices': 0
      });
      container.read(wifiBundleProvider.notifier).setSimpleModeWifi(item);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .wifiList
              .simpleModeWifi
              .ssid,
          'newSimple');
    });

    test('setWiFiSSID (Guest)', () {
      container
          .read(wifiBundleProvider.notifier)
          .setWiFiSSID('GuestSSID', null);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .wifiList
              .guestWiFi
              .ssid,
          'GuestSSID');
    });

    test('setWiFiSSID (Main)', () {
      seedWithRadios();
      container
          .read(wifiBundleProvider.notifier)
          .setWiFiSSID('Main2.4', WifiRadioBand.radio_24);
      final list =
          container.read(wifiBundleProvider).settings.current.wifiList.mainWiFi;
      final item = list.firstWhere((e) => e.radioID == WifiRadioBand.radio_24);
      expect(item.ssid, 'Main2.4');
    });

    test('setWiFiPassword (Guest)', () {
      container
          .read(wifiBundleProvider.notifier)
          .setWiFiPassword('GuestPass', null);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .wifiList
              .guestWiFi
              .password,
          'GuestPass');
    });

    test('setWiFiPassword (Main)', () {
      seedWithRadios();
      container
          .read(wifiBundleProvider.notifier)
          .setWiFiPassword('MainPass', WifiRadioBand.radio_5_1);
      final list =
          container.read(wifiBundleProvider).settings.current.wifiList.mainWiFi;
      final item = list.firstWhere((e) => e.radioID == WifiRadioBand.radio_5_1);
      expect(item.password, 'MainPass');
    });

    test('setWiFiEnabled (Guest)', () {
      container.read(wifiBundleProvider.notifier).setWiFiEnabled(true, null);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .wifiList
              .guestWiFi
              .isEnabled,
          true);
    });

    test('setWiFiEnabled (Main)', () {
      seedWithRadios();
      container
          .read(wifiBundleProvider.notifier)
          .setWiFiEnabled(false, WifiRadioBand.radio_24);
      final list =
          container.read(wifiBundleProvider).settings.current.wifiList.mainWiFi;
      final item = list.firstWhere((e) => e.radioID == WifiRadioBand.radio_24);
      expect(item.isEnabled, false);
    });

    test('setWiFiSecurityType', () {
      seedWithRadios();
      container.read(wifiBundleProvider.notifier).setWiFiSecurityType(
          WifiSecurityType.wpa2Personal, WifiRadioBand.radio_24);
      final list =
          container.read(wifiBundleProvider).settings.current.wifiList.mainWiFi;
      final item = list.firstWhere((e) => e.radioID == WifiRadioBand.radio_24);
      expect(item.securityType, WifiSecurityType.wpa2Personal);
    });

    test('setWiFiMode', () {
      seedWithRadios();
      container
          .read(wifiBundleProvider.notifier)
          .setWiFiMode(WifiWirelessMode.a, WifiRadioBand.radio_24);
      final list =
          container.read(wifiBundleProvider).settings.current.wifiList.mainWiFi;
      final item = list.firstWhere((e) => e.radioID == WifiRadioBand.radio_24);
      expect(item.wirelessMode, WifiWirelessMode.a);
    });

    test('setEnableBoardcast', () {
      seedWithRadios();
      container
          .read(wifiBundleProvider.notifier)
          .setEnableBoardcast(false, WifiRadioBand.radio_24);
      final list =
          container.read(wifiBundleProvider).settings.current.wifiList.mainWiFi;
      final item = list.firstWhere((e) => e.radioID == WifiRadioBand.radio_24);
      expect(item.isBroadcast, false);
    });

    test('setChannel', () {
      seedWithRadios();
      container
          .read(wifiBundleProvider.notifier)
          .setChannel(6, WifiRadioBand.radio_24);
      final list =
          container.read(wifiBundleProvider).settings.current.wifiList.mainWiFi;
      final item = list.firstWhere((e) => e.radioID == WifiRadioBand.radio_24);
      expect(item.channel, 6);
    });

    // --- Privacy Setters ---
    test('setMacFilterMode', () {
      container
          .read(wifiBundleProvider.notifier)
          .setMacFilterMode(MacFilterMode.allow);
      expect(container.read(wifiBundleProvider).settings.current.privacy.mode,
          MacFilterMode.allow);
    });

    test('setMacFilterSelection (Deny)', () {
      container
          .read(wifiBundleProvider.notifier)
          .setMacFilterSelection(['AA:AA:AA:AA:AA:AA'], true);
      final privacy =
          container.read(wifiBundleProvider).settings.current.privacy;
      expect(privacy.denyMacAddresses.contains('AA:AA:AA:AA:AA:AA'), true);
      expect(privacy.macAddresses.isEmpty, true);
    });

    test('setMacFilterSelection (Allow)', () {
      container
          .read(wifiBundleProvider.notifier)
          .setMacFilterSelection(['AA:AA:AA:AA:AA:AA'], false);
      final privacy =
          container.read(wifiBundleProvider).settings.current.privacy;
      expect(privacy.macAddresses.contains('AA:AA:AA:AA:AA:AA'), true);
      expect(privacy.denyMacAddresses.isEmpty, true);
    });

    test('removeMacFilterSelection (Deny)', () {
      container
          .read(wifiBundleProvider.notifier)
          .setMacFilterSelection(['AA:AA:AA:AA:AA:AA'], true);
      container
          .read(wifiBundleProvider.notifier)
          .removeMacFilterSelection(['AA:AA:AA:AA:AA:AA'], true);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .privacy
              .denyMacAddresses
              .isEmpty,
          true);
    });

    test('setMacAddressList', () {
      container
          .read(wifiBundleProvider.notifier)
          .setMacAddressList(['11:11:11:11:11:11']);
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .privacy
              .denyMacAddresses
              .first,
          '11:11:11:11:11:11');
    });

    test('saveToggleEnabled', () async {
      container.listen(wifiBundleProvider, (_, __) {});
      when(() => mockWifiSettingsService.saveWifiListSettings(any(), any()))
          .thenAnswer((_) async {});

      // Stub fetchBundleSettings because saveToggleEnabled calls performFetch
      final initialSettings = WifiBundleSettings(
        wifiList: WiFiListSettings(
            mainWiFi: const [],
            guestWiFi: const GuestWiFiItem(
                isEnabled: true,
                ssid: 'guest',
                password: 'pass',
                numOfDevices: 0),
            isSimpleMode: true,
            simpleModeWifi: WiFiItem.fromMap(const {
              'channel': 0,
              'isBroadcast': false,
              'isEnabled': false,
              'numOfDevices': 0
            })),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );
      final initialStatus = WifiBundleStatus(
        wifiList: const WiFiListStatus(canDisableMainWiFi: false),
        privacy: InstantPrivacyStatus.init(),
      );
      when(() => mockWifiSettingsService.fetchBundleSettings(
            serviceHelper: any(named: 'serviceHelper'),
            forceRemote: any(named: 'forceRemote'),
            mainWifiDevices: any(named: 'mainWifiDevices'),
            guestWifiDevices: any(named: 'guestWifiDevices'),
            allDevices: any(named: 'allDevices'),
            isLanConnected: any(named: 'isLanConnected'),
            getBandConnectedBy: any(named: 'getBandConnectedBy'),
          )).thenAnswer((_) async => (initialSettings, initialStatus));

      await container
          .read(wifiBundleProvider.notifier)
          .saveToggleEnabled(radios: null, enabled: true);

      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .wifiList
              .guestWiFi
              .isEnabled,
          true);
      verify(() => mockWifiSettingsService.saveWifiListSettings(any(), any()))
          .called(1);
    });

    // --- Setters Tests ---
    group('Setters', () {
      setUp(() async {
        final wifiItem = WiFiItem.fromMap(const {
          'radioID': 'RADIO_2.4GHz',
          'band': '2.4GHz',
          'ssid': 'test',
          'password': 'password',
          'securityType': 'WPA2-Personal',
          'channel': 6,
          'isBroadcast': true,
          'isEnabled': true,
          'numOfDevices': 0,
          'mode': '802.11mixed',
          'channelWidth': 'Standard'
        }).copyWith(availableChannels: {
          WifiChannelWidth.wide20: [1, 6, 11]
        });

        final settings = WiFiListSettings(
            mainWiFi: [wifiItem],
            guestWiFi: const GuestWiFiItem(
                isEnabled: false, ssid: 'guest', password: '', numOfDevices: 0),
            isSimpleMode: true,
            simpleModeWifi: wifiItem);

        const advanced = WifiAdvancedSettingsState();
        final privacy = InstantPrivacySettings.init();

        container.listen(wifiBundleProvider, (_, __) {});
        final notifier = container.read(wifiBundleProvider.notifier);

        when(() => mockWifiSettingsService.fetchBundleSettings(
                serviceHelper: any(named: 'serviceHelper'),
                mainWifiDevices: any(named: 'mainWifiDevices'),
                guestWifiDevices: any(named: 'guestWifiDevices'),
                allDevices: any(named: 'allDevices'),
                isLanConnected: any(named: 'isLanConnected'),
                getBandConnectedBy: any(named: 'getBandConnectedBy')))
            .thenAnswer((_) async => (
                  WifiBundleSettings(
                      wifiList: settings, advanced: advanced, privacy: privacy),
                  WifiBundleStatus(
                      wifiList: const WiFiListStatus(canDisableMainWiFi: true),
                      privacy: InstantPrivacyStatus.init())
                ));

        await notifier.performFetch();
      });

      test('setWiFiEnabled updates specific band', () {
        final notifier = container.read(wifiBundleProvider.notifier);
        notifier.setWiFiEnabled(false, WifiRadioBand.radio_24);
        final state = container.read(wifiBundleProvider);
        expect(state.settings.current.wifiList.mainWiFi.first.isEnabled, false);
      });

      test('setWiFiSecurityType updates security type', () {
        final notifier = container.read(wifiBundleProvider.notifier);
        notifier.setWiFiSecurityType(
            WifiSecurityType.wpa3Personal, WifiRadioBand.radio_24);
        final state = container.read(wifiBundleProvider);
        expect(state.settings.current.wifiList.mainWiFi.first.securityType,
            WifiSecurityType.wpa3Personal);
      });

      test('setWiFiMode updates wireless mode', () {
        final notifier = container.read(wifiBundleProvider.notifier);
        notifier.setWiFiMode(WifiWirelessMode.n, WifiRadioBand.radio_24);
        final state = container.read(wifiBundleProvider);
        expect(state.settings.current.wifiList.mainWiFi.first.wirelessMode,
            WifiWirelessMode.n);
      });

      test('setEnableBoardcast updates broadcast', () {
        final notifier = container.read(wifiBundleProvider.notifier);
        notifier.setEnableBoardcast(false, WifiRadioBand.radio_24);
        final state = container.read(wifiBundleProvider);
        expect(
            state.settings.current.wifiList.mainWiFi.first.isBroadcast, false);
      });

      test('setChannelWidth updates width', () {
        final notifier = container.read(wifiBundleProvider.notifier);
        notifier.setChannelWidth(
            WifiChannelWidth.wide20, WifiRadioBand.radio_24);
        final state = container.read(wifiBundleProvider);
        expect(state.settings.current.wifiList.mainWiFi.first.channel, 6);
      });

      test('setChannel updates channel', () {
        final notifier = container.read(wifiBundleProvider.notifier);
        notifier.setChannel(11, WifiRadioBand.radio_24);
        final state = container.read(wifiBundleProvider);
        expect(state.settings.current.wifiList.mainWiFi.first.channel, 11);
      });

      test('setChannelWidth when channel not in new list picks first', () {
        // First set up a situation where the current channel is NOT in the new width's channel list
        final notifier = container.read(wifiBundleProvider.notifier);
        // Current channel is 6.  Set available channels such that 6 is NOT in another width.
        // The mock wifiItem has availableChannels: {WifiChannelWidth.wide20: [1, 6, 11]}
        // We need to add another width where 6 is NOT in the list
        // For now, this test documents that the channel doesn't change when it IS in the list.
        notifier.setChannel(
            99, WifiRadioBand.radio_24); // set to an unavailable channel
        notifier.setChannelWidth(
            WifiChannelWidth.wide20, WifiRadioBand.radio_24);
        final state = container.read(wifiBundleProvider);
        // If 99 is not in [1, 6, 11], it should pick the first (1)
        expect(state.settings.current.wifiList.mainWiFi.first.channel, 1);
      });
    });

    test('saveToggleEnabled with radios list', () async {
      seedWithRadios();
      container.listen(wifiBundleProvider, (_, __) {});
      when(() => mockWifiSettingsService.saveWifiListSettings(any(), any()))
          .thenAnswer((_) async {});

      await container.read(wifiBundleProvider.notifier).saveToggleEnabled(
          radios: ['RADIO_2.4GHz', 'RADIO_5GHz'], enabled: false);

      final mainWiFi =
          container.read(wifiBundleProvider).settings.current.wifiList.mainWiFi;
      expect(mainWiFi.every((e) => !e.isEnabled), true);
    });

    test('removeMacFilterSelection with Allow mode', () {
      container
          .read(wifiBundleProvider.notifier)
          .setMacFilterSelection(['AA:BB:CC:DD:EE:FF'], false); // Allow mode
      container.read(wifiBundleProvider.notifier).removeMacFilterSelection(
          ['AA:BB:CC:DD:EE:FF'], false); // Remove from Allow
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .privacy
              .macAddresses
              .isEmpty,
          true);
    });

    test('performFetch with updateStatusOnly=true', () async {
      container.listen(wifiBundleProvider, (_, __) {});

      final newStatus = WifiBundleStatus(
        wifiList: const WiFiListStatus(canDisableMainWiFi: true),
        privacy: InstantPrivacyStatus.init(),
      );
      final newSettings = WifiBundleSettings(
        wifiList: WiFiListSettings(
            mainWiFi: const [],
            guestWiFi: const GuestWiFiItem(
                isEnabled: false,
                ssid: 'updated',
                password: '',
                numOfDevices: 0),
            isSimpleMode: true,
            simpleModeWifi: WiFiItem.fromMap(const {
              'channel': 0,
              'isBroadcast': false,
              'isEnabled': false,
              'numOfDevices': 0
            })),
        advanced: const WifiAdvancedSettingsState(),
        privacy: InstantPrivacySettings.init(),
      );

      when(() => mockWifiSettingsService.fetchBundleSettings(
            serviceHelper: any(named: 'serviceHelper'),
            forceRemote: any(named: 'forceRemote'),
            mainWifiDevices: any(named: 'mainWifiDevices'),
            guestWifiDevices: any(named: 'guestWifiDevices'),
            allDevices: any(named: 'allDevices'),
            isLanConnected: any(named: 'isLanConnected'),
            getBandConnectedBy: any(named: 'getBandConnectedBy'),
          )).thenAnswer((_) async => (newSettings, newStatus));

      final oldSettings = container
          .read(wifiBundleProvider)
          .settings
          .current
          .wifiList
          .guestWiFi
          .ssid;

      await container
          .read(wifiBundleProvider.notifier)
          .performFetch(updateStatusOnly: true);

      // Settings should NOT be updated (still old)
      expect(
          container
              .read(wifiBundleProvider)
              .settings
              .current
              .wifiList
              .guestWiFi
              .ssid,
          oldSettings);
      // But status should be updated
      expect(
          container.read(wifiBundleProvider).status.wifiList.canDisableMainWiFi,
          true);
    });

    test('performSave saves privacy when changed', () async {
      container.listen(wifiBundleProvider, (_, __) {});
      when(() => mockWifiSettingsService.savePrivacySettings(
            settings: any(named: 'settings'),
            nodeDevices: any(named: 'nodeDevices'),
          )).thenAnswer((_) async {});

      container
          .read(wifiBundleProvider.notifier)
          .setMacFilterMode(MacFilterMode.deny);
      await container.read(wifiBundleProvider.notifier).performSave();

      verify(() => mockWifiSettingsService.savePrivacySettings(
            settings: any(named: 'settings'),
            nodeDevices: any(named: 'nodeDevices'),
          )).called(1);
    });

    test('performSave saves wifiList when changed', () async {
      seedWithRadios();
      container.listen(wifiBundleProvider, (_, __) {});
      when(() => mockWifiSettingsService.saveWifiListSettings(any(), any()))
          .thenAnswer((_) async {});

      container
          .read(wifiBundleProvider.notifier)
          .setWiFiSSID('NewSSID', WifiRadioBand.radio_24);
      await container.read(wifiBundleProvider.notifier).performSave();

      verify(() => mockWifiSettingsService.saveWifiListSettings(any(), any()))
          .called(1);
    });

    test('preservableWifiSettingsProvider returns notifier', () {
      final notifier = container.read(preservableWifiSettingsProvider);
      expect(notifier, isA<WifiBundleNotifier>());
    });
  });
}
