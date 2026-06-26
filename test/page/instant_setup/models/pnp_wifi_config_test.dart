import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';

void main() {
  group('PnpWifiConfig — reconnectSsid', () {
    test('returns ssid in unified mode (no mainBands)', () {
      final config = PnpWifiConfig(
        ssid: 'MyWiFi',
        password: 'pass123',
        originalSsid: 'OldWiFi',
        originalPassword: 'oldpass',
      );

      expect(config.reconnectSsid, 'MyWiFi');
    });

    test('returns ssid when mainBands has single entry (not split mode)', () {
      final config = PnpWifiConfig(
        ssid: 'MyWiFi',
        password: 'pass123',
        originalSsid: 'OldWiFi',
        originalPassword: 'oldpass',
        mainBands: [
          PnpWifiBand(
            bandName: '2.4 GHz',
            frequency: '2.4GHz',
            ssid: 'Band-SSID',
            password: 'bandpass',
            originalSsid: 'Band-SSID',
            originalPassword: 'bandpass',
            ssidInstancePath: 'Device.WiFi.SSID.1.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.1.',
            radioPath: 'Device.WiFi.Radio.1.',
          ),
        ],
      );

      // Single band = not split mode, returns unified ssid
      expect(config.isSplitMode, isFalse);
      expect(config.reconnectSsid, 'MyWiFi');
    });

    test('returns first dirty band ssid in split mode', () {
      final config = PnpWifiConfig(
        ssid: 'UnifiedSSID', // Not updated in split mode
        password: 'unifiedpass',
        originalSsid: 'UnifiedSSID',
        originalPassword: 'unifiedpass',
        mainBands: [
          PnpWifiBand(
            bandName: '2.4 GHz',
            frequency: '2.4GHz',
            ssid: 'SSID-2G',
            password: 'pass2g',
            originalSsid: 'SSID-2G',
            originalPassword: 'pass2g',
            ssidInstancePath: 'Device.WiFi.SSID.1.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.1.',
            radioPath: 'Device.WiFi.Radio.1.',
          ),
          PnpWifiBand(
            bandName: '5 GHz',
            frequency: '5GHz',
            ssid: 'NewSSID-5G', // Changed
            password: 'pass5g',
            originalSsid: 'SSID-5G', // Different original = split mode
            originalPassword: 'pass5g',
            ssidInstancePath: 'Device.WiFi.SSID.2.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.2.',
            radioPath: 'Device.WiFi.Radio.2.',
          ),
        ],
      );

      expect(config.isSplitMode, isTrue);
      // First dirty band is 5GHz (ssid changed)
      expect(config.reconnectSsid, 'NewSSID-5G');
    });

    test('returns first band ssid in split mode when no bands are dirty', () {
      // Split mode is determined by originalSsid differences, not current ssid.
      // To have split mode with no dirty bands, current values must match originals.
      final config = PnpWifiConfig(
        ssid: 'UnifiedSSID',
        password: 'unifiedpass',
        originalSsid: 'UnifiedSSID',
        originalPassword: 'unifiedpass',
        mainBands: [
          PnpWifiBand(
            bandName: '2.4 GHz',
            frequency: '2.4GHz',
            ssid: 'SSID-2G', // Same as original
            password: 'pass2g',
            originalSsid: 'SSID-2G',
            originalPassword: 'pass2g',
            ssidInstancePath: 'Device.WiFi.SSID.1.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.1.',
            radioPath: 'Device.WiFi.Radio.1.',
          ),
          PnpWifiBand(
            bandName: '5 GHz',
            frequency: '5GHz',
            ssid: 'SSID-5G', // Same as original
            password: 'pass5g',
            originalSsid: 'SSID-5G', // Different from first band = split mode
            originalPassword: 'pass5g',
            ssidInstancePath: 'Device.WiFi.SSID.2.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.2.',
            radioPath: 'Device.WiFi.Radio.2.',
          ),
        ],
      );

      expect(config.isSplitMode, isTrue);
      expect(config.mainBands.any((b) => b.isDirty), isFalse);
      // No bands dirty, returns first band ssid
      expect(config.reconnectSsid, 'SSID-2G');
    });
  });

  group('PnpWifiConfig — reconnectPassword', () {
    test('returns password in unified mode', () {
      final config = PnpWifiConfig(
        ssid: 'MyWiFi',
        password: 'pass123',
        originalSsid: 'OldWiFi',
        originalPassword: 'oldpass',
      );

      expect(config.reconnectPassword, 'pass123');
    });

    test('returns first dirty band password in split mode', () {
      final config = PnpWifiConfig(
        ssid: 'UnifiedSSID',
        password: 'unifiedpass',
        originalSsid: 'UnifiedSSID',
        originalPassword: 'unifiedpass',
        mainBands: [
          PnpWifiBand(
            bandName: '2.4 GHz',
            frequency: '2.4GHz',
            ssid: 'SSID-2G',
            password: 'newpass2g', // Changed
            originalSsid: 'SSID-2G',
            originalPassword: 'pass2g', // Different original
            ssidInstancePath: 'Device.WiFi.SSID.1.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.1.',
            radioPath: 'Device.WiFi.Radio.1.',
          ),
          PnpWifiBand(
            bandName: '5 GHz',
            frequency: '5GHz',
            ssid: 'SSID-5G',
            password: 'pass5g',
            originalSsid: 'OtherSSID-5G', // Different original = split mode
            originalPassword: 'pass5g',
            ssidInstancePath: 'Device.WiFi.SSID.2.',
            accessPointInstancePath: 'Device.WiFi.AccessPoint.2.',
            radioPath: 'Device.WiFi.Radio.2.',
          ),
        ],
      );

      expect(config.isSplitMode, isTrue);
      // First dirty band is 2.4GHz (password changed)
      expect(config.reconnectPassword, 'newpass2g');
    });
  });
}
