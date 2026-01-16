import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/models/device_list_item.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/displayed_mac_filtering_devices_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_settings_service.dart';
import 'package:privacy_gui/providers/preservable.dart';

class MockWifiSettingsService extends Mock implements WifiSettingsService {}

// Mock notifiers for providers
class _MockDeviceManagerNotifier extends DeviceManagerNotifier {
  final DeviceManagerState _state;

  _MockDeviceManagerNotifier(this._state);

  @override
  DeviceManagerState build() => _state;
}

class _MockWifiBundleNotifier extends WifiBundleNotifier {
  final WifiBundleState _state;

  _MockWifiBundleNotifier(this._state);

  @override
  WifiBundleState build() => _state;
}

void main() {
  late ProviderContainer container;
  late MockWifiSettingsService mockService;

  // Helper to create LinksysDevice for mocking deviceManagerProvider
  LinksysDevice createLinksysDevice({
    required String macAddress,
    required String name,
    required bool isWired,
  }) {
    // Mimic the minimal properties needed by the provider
    // connectionType: 'wired' or 'wireless' (convention used in LinksysDevice)
    // isOnline logic typically checks for existence of connections or similar property
    // For this test, we assume connectionType logic is sufficient based on provider implementation

    // Construct a minimal LinksysDevice map and use fromMap, or manual constructor if public
    // LinksysDevice constructor is public.
    return LinksysDevice(
      connections: const [],
      properties: const [],
      unit: const RawDeviceUnit(serialNumber: '', firmwareVersion: ''),
      deviceID: macAddress, // Use MAC as ID for simplicity
      maxAllowedProperties: 10,
      model: const RawDeviceModel(
          deviceType: 'Computer', // Required
          modelDescription: '',
          hardwareVersion: '',
          manufacturer: '',
          modelNumber: ''),
      isAuthority: false,
      lastChangeRevision: 1,
      friendlyName: name,
      knownMACAddresses: [macAddress],
      connectionType: isWired ? 'wired' : 'wireless',
    );
  }

  WiFiItem createWifiItem() {
    return const WiFiItem(
      radioID: WifiRadioBand.radio_5_1,
      ssid: 'TestNetwork',
      password: 'password123',
      securityType: WifiSecurityType.wpa2Personal,
      wirelessMode: WifiWirelessMode.ac,
      channelWidth: WifiChannelWidth.auto,
      channel: 36,
      isBroadcast: true,
      isEnabled: true,
      availableSecurityTypes: [WifiSecurityType.wpa2Personal],
      availableWirelessModes: [WifiWirelessMode.ac],
      availableChannels: {},
      numOfDevices: 5,
    );
  }

  GuestWiFiItem createGuestItem() {
    return const GuestWiFiItem(
      isEnabled: false,
      ssid: 'Guest',
      password: 'secret',
      numOfDevices: 0,
    );
  }

  WiFiListSettings createWifiListSettings() {
    return WiFiListSettings(
      mainWiFi: [createWifiItem()],
      guestWiFi: createGuestItem(),
      simpleModeWifi: createWifiItem(),
    );
  }

  WifiBundleState createWifiBundleState({
    List<String> denyMacAddresses = const [],
    List<String> bssids = const [],
  }) {
    final settings = WifiBundleSettings(
      wifiList: createWifiListSettings(),
      advanced: const WifiAdvancedSettingsState(),
      privacy: InstantPrivacySettings(
        mode: MacFilterMode.deny,
        macAddresses: const [],
        denyMacAddresses: denyMacAddresses,
        maxMacAddresses: 32,
        bssids: bssids,
      ),
    );
    final status = WifiBundleStatus(
      wifiList: const WiFiListStatus(),
      privacy: InstantPrivacyStatus.init(),
    );
    return WifiBundleState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );
  }

  setUpAll(() {
    registerFallbackValue(<DeviceListItem>[]);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockService = MockWifiSettingsService();
  });

  tearDown(() {
    container.dispose();
  });

  group('macFilteringDeviceListProvider', () {
    test('returns empty list when no devices and no mac addresses', () {
      container = ProviderContainer(
        overrides: [
          wifiSettingsServiceProvider.overrideWithValue(mockService),
          deviceManagerProvider.overrideWith(
              () => _MockDeviceManagerNotifier(const DeviceManagerState())),
          wifiBundleProvider.overrideWith(
              () => _MockWifiBundleNotifier(createWifiBundleState())),
        ],
      );

      when(() => mockService.getFilteredDeviceList(
            allDevices: any(named: 'allDevices'),
            macAddresses: any(named: 'macAddresses'),
            bssidList: any(named: 'bssidList'),
          )).thenReturn([]);

      final result = container.read(macFilteringDeviceListProvider);

      expect(result, isEmpty);
    });

    test('calls service with correct parameters', () {
      final testDevice = createLinksysDevice(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        name: 'TestDevice',
        isWired: false,
      );

      container = ProviderContainer(
        overrides: [
          wifiSettingsServiceProvider.overrideWithValue(mockService),
          deviceManagerProvider.overrideWith(() => _MockDeviceManagerNotifier(
              DeviceManagerState(deviceList: [testDevice]))),
          wifiBundleProvider
              .overrideWith(() => _MockWifiBundleNotifier(createWifiBundleState(
                    denyMacAddresses: ['11:22:33:44:55:66'],
                    bssids: ['77:88:99:AA:BB:CC'],
                  ))),
        ],
      );

      when(() => mockService.getFilteredDeviceList(
            allDevices: any(named: 'allDevices'),
            macAddresses: any(named: 'macAddresses'),
            bssidList: any(named: 'bssidList'),
          )).thenReturn([]);

      container.read(macFilteringDeviceListProvider);

      verify(() => mockService.getFilteredDeviceList(
            allDevices: any(named: 'allDevices'),
            macAddresses: ['11:22:33:44:55:66'],
            bssidList: ['77:88:99:AA:BB:CC'],
          )).called(1);
    });

    test('filters out wired devices', () {
      final wirelessDevice = createLinksysDevice(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        name: 'WirelessDevice',
        isWired: false,
      );
      final wiredDevice = createLinksysDevice(
        macAddress: '11:22:33:44:55:66',
        name: 'WiredDevice',
        isWired: true,
      );

      container = ProviderContainer(
        overrides: [
          wifiSettingsServiceProvider.overrideWithValue(mockService),
          deviceManagerProvider.overrideWith(() => _MockDeviceManagerNotifier(
              DeviceManagerState(deviceList: [wirelessDevice, wiredDevice]))),
          wifiBundleProvider.overrideWith(
              () => _MockWifiBundleNotifier(createWifiBundleState())),
        ],
      );

      when(() => mockService.getFilteredDeviceList(
            allDevices: any(named: 'allDevices'),
            macAddresses: any(named: 'macAddresses'),
            bssidList: any(named: 'bssidList'),
          )).thenReturn([]);

      container.read(macFilteringDeviceListProvider);

      // capture the argument passed to allDevices
      final captured = verify(() => mockService.getFilteredDeviceList(
            allDevices: captureAny(named: 'allDevices'),
            macAddresses: any(named: 'macAddresses'),
            bssidList: any(named: 'bssidList'),
          )).captured;

      final passedDevices = captured.first as List<DeviceListItem>;
      expect(passedDevices.length, 1);
      expect(passedDevices.first.name, 'WirelessDevice');
      expect(passedDevices.first.macAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('returns service result', () {
      const expectedDevice = DeviceListItem(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        name: 'Device1',
      );

      container = ProviderContainer(
        overrides: [
          wifiSettingsServiceProvider.overrideWithValue(mockService),
          deviceManagerProvider.overrideWith(
              () => _MockDeviceManagerNotifier(const DeviceManagerState())),
          wifiBundleProvider.overrideWith(
              () => _MockWifiBundleNotifier(createWifiBundleState())),
        ],
      );

      when(() => mockService.getFilteredDeviceList(
            allDevices: any(named: 'allDevices'),
            macAddresses: any(named: 'macAddresses'),
            bssidList: any(named: 'bssidList'),
          )).thenReturn([expectedDevice]);

      final result = container.read(macFilteringDeviceListProvider);

      expect(result, hasLength(1));
      expect(result.first.macAddress, 'AA:BB:CC:DD:EE:FF');
    });
  });
}
