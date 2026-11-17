import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_write.dart';

/// Which credentials the reconnect step and the completion screen show after a
/// save — moved here from `PnpWifiConfig` when #1511 P4 split it into drafts.
void main() {
  PnpWifiBand band(int n, String ssid, String password) => PnpWifiBand(
        bandName: n == 1 ? '2.4 GHz' : '5 GHz',
        frequency: n == 1 ? '2.4GHz' : '5GHz',
        ssid: ssid,
        password: password,
        ssidInstancePath: 'Device.WiFi.SSID.$n.',
        accessPointInstancePath: 'Device.WiFi.AccessPoint.$n.',
        radioPath: 'Device.WiFi.Radio.$n.',
      );

  PnpWifiWrite edit(PnpMainWifiSettings was, PnpMainWifiSettings now) =>
      PnpWifiWrite(main: Preservable(original: was, current: now));

  group('unified', () {
    const was = PnpMainWifiSettings(ssid: 'OldWiFi', password: 'oldpass');

    test('shows the one name and password as edited', () {
      final write =
          edit(was, was.copyWith(ssid: 'MyWiFi', password: 'pass123'));

      expect(write.reconnectSsid, 'MyWiFi');
      expect(write.reconnectPassword, 'pass123');
    });

    test('a single band is not split, so it shows the unified name', () {
      final one = PnpMainWifiSettings(
        ssid: 'OldWiFi',
        password: 'oldpass',
        bands: [band(1, 'Band-SSID', 'bandpass')],
      );

      expect(edit(one, one.copyWith(ssid: 'MyWiFi')).reconnectSsid, 'MyWiFi');
    });
  });

  group('split', () {
    final was = PnpMainWifiSettings(
      ssid: 'UnifiedSSID',
      password: 'unifiedpass',
      bands: [band(1, 'SSID-2G', 'pass2g'), band(2, 'SSID-5G', 'pass5g')],
      splitMode: true,
    );

    test('shows the first band whose name was edited', () {
      final write = edit(
        was,
        was.withBand('Device.WiFi.SSID.2.', ssid: 'NewSSID-5G'),
      );

      expect(write.reconnectSsid, 'NewSSID-5G');
      expect(write.reconnectPassword, 'pass5g');
    });

    test('a password edit counts as an edit to the band', () {
      final write = edit(
        was,
        was.withBand('Device.WiFi.SSID.2.', password: 'newpass5g'),
      );

      expect(write.reconnectSsid, 'SSID-5G');
      expect(write.reconnectPassword, 'newpass5g');
    });

    test('shows the first band when no band was edited', () {
      final write = edit(was, was);

      expect(write.reconnectSsid, 'SSID-2G');
      expect(write.reconnectPassword, 'pass2g');
    });
  });
}
