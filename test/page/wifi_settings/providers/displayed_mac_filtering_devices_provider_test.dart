import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
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

void main() {
  late ProviderContainer container;
  late MockWifiSettingsService mockService;

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
          deviceListProvider.overrideWith(() =>
              _MockDeviceListNotifier(const DeviceListState(devices: []))),
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
      const testDevice = DeviceListItem(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        name: 'TestDevice',
        isWired: false,
      );

      container = ProviderContainer(
        overrides: [
          wifiSettingsServiceProvider.overrideWithValue(mockService),
          deviceListProvider.overrideWith(() => _MockDeviceListNotifier(
              const DeviceListState(devices: [testDevice]))),
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
      const wirelessDevice = DeviceListItem(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        name: 'WirelessDevice',
        isWired: false,
      );
      const wiredDevice = DeviceListItem(
        macAddress: '11:22:33:44:55:66',
        name: 'WiredDevice',
        isWired: true,
      );

      container = ProviderContainer(
        overrides: [
          wifiSettingsServiceProvider.overrideWithValue(mockService),
          deviceListProvider.overrideWith(() => _MockDeviceListNotifier(
              const DeviceListState(devices: [wirelessDevice, wiredDevice]))),
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

      // Verify only wireless device is passed
      verify(() => mockService.getFilteredDeviceList(
            allDevices: [wirelessDevice],
            macAddresses: any(named: 'macAddresses'),
            bssidList: any(named: 'bssidList'),
          )).called(1);
    });

    test('returns service result', () {
      const expectedDevice = DeviceListItem(
        macAddress: 'AA:BB:CC:DD:EE:FF',
        name: 'Device1',
      );

      container = ProviderContainer(
        overrides: [
          wifiSettingsServiceProvider.overrideWithValue(mockService),
          deviceListProvider.overrideWith(() =>
              _MockDeviceListNotifier(const DeviceListState(devices: []))),
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

// Mock notifiers for providers
class _MockDeviceListNotifier extends DeviceListNotifier {
  final DeviceListState _state;

  _MockDeviceListNotifier(this._state);

  @override
  DeviceListState build() => _state;
}

class _MockWifiBundleNotifier extends WifiBundleNotifier {
  final WifiBundleState _state;

  _MockWifiBundleNotifier(this._state);

  @override
  WifiBundleState build() => _state;
}
