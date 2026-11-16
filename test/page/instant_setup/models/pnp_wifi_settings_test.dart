import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';

/// The two Wi-Fi networks the PnP wizard's setting steps edit (#1511 P4): what
/// an edit may change, and what only the router read decides.
void main() {
  PnpWifiBand band(int i, String ssid, {String password = 'BandPass1'}) =>
      PnpWifiBand(
        bandName: 'Band $i',
        frequency: '${i}GHz',
        ssid: ssid,
        password: password,
        ssidInstancePath: 'Device.WiFi.SSID.$i.',
        accessPointInstancePath: 'Device.WiFi.AccessPoint.$i.',
        radioPath: 'Device.WiFi.Radio.$i.',
      );

  final splitMain = PnpMainWifiSettings(
    ssid: 'Home',
    password: 'HomePass1',
    ssidInstancePaths: const ['Device.WiFi.SSID.1.', 'Device.WiFi.SSID.2.'],
    accessPointInstancePaths: const [
      'Device.WiFi.AccessPoint.1.',
      'Device.WiFi.AccessPoint.2.',
    ],
    bands: [band(1, 'Home-2G'), band(2, 'Home-5G')],
    splitMode: true,
  );

  final splitGuest = PnpGuestWifiSettings(
    enabled: true,
    ssid: 'Home-guest',
    password: 'GuestPass1',
    ssidInstancePaths: const ['Device.WiFi.SSID.3.'],
    accessPointInstancePaths: const ['Device.WiFi.AccessPoint.3.'],
    bands: [band(3, 'Guest-2G'), band(4, 'Guest-5G')],
    splitMode: true,
  );

  group('PnpMainWifiSettings', () {
    test(
        'copyWith edits the name and password, and keeps what the read '
        'decided', () {
      final edited = splitMain.copyWith(ssid: 'New', password: 'NewPass1');

      expect(edited.ssid, 'New');
      expect(edited.password, 'NewPass1');
      expect(edited.ssidInstancePaths, splitMain.ssidInstancePaths);
      expect(
          edited.accessPointInstancePaths, splitMain.accessPointInstancePaths);
      expect(edited.bands, splitMain.bands);
      expect(edited.splitMode, isTrue,
          reason: 'decided by the read, never by an edit');
    });

    test('copyWith with nothing is the same network', () {
      expect(splitMain.copyWith(), splitMain);
    });

    test('withBand edits only the band at that SSID row', () {
      final edited = splitMain.withBand('Device.WiFi.SSID.2.',
          ssid: 'Renamed-5G', password: 'Other5678');

      expect(edited.bands[0], splitMain.bands[0]);
      expect(edited.bands[1].ssid, 'Renamed-5G');
      expect(edited.bands[1].password, 'Other5678');
      expect(edited.bands[1].ssidInstancePath, 'Device.WiFi.SSID.2.');
      expect(edited.ssid, splitMain.ssid,
          reason: 'a band edit leaves the unified fields alone');
      expect(edited.splitMode, isTrue);
    });

    test('withBand on a row it does not have changes nothing', () {
      expect(splitMain.withBand('Device.WiFi.SSID.9.', ssid: 'X'), splitMain);
    });

    test('two reads with the same values are equal, and an edit is not', () {
      expect(splitMain.copyWith(ssid: 'Home'), splitMain);
      expect(splitMain.copyWith(ssid: 'Other'), isNot(splitMain));
      expect(splitMain.withBand('Device.WiFi.SSID.1.', password: 'x'),
          isNot(splitMain));
    });
  });

  group('PnpGuestWifiSettings', () {
    test(
        'copyWith edits enabled, name and password, and keeps what the read '
        'decided', () {
      final edited =
          splitGuest.copyWith(enabled: false, ssid: 'G', password: 'GPass123');

      expect(edited.enabled, isFalse);
      expect(edited.ssid, 'G');
      expect(edited.password, 'GPass123');
      expect(edited.ssidInstancePaths, splitGuest.ssidInstancePaths);
      expect(
          edited.accessPointInstancePaths, splitGuest.accessPointInstancePaths);
      expect(edited.bands, splitGuest.bands);
      expect(edited.splitMode, isTrue);
    });

    test('withBand edits only the band at that SSID row, and keeps enabled',
        () {
      final edited = splitGuest
          .copyWith(enabled: false)
          .withBand('Device.WiFi.SSID.3.', ssid: 'Guest-2G-new');

      expect(edited.bands[0].ssid, 'Guest-2G-new');
      expect(edited.bands[1], splitGuest.bands[1]);
      expect(edited.enabled, isFalse);
    });

    test('turning the guest network off is an edit', () {
      expect(splitGuest.copyWith(enabled: false), isNot(splitGuest));
    });
  });

  group('PnpWizardData', () {
    test('a router with no guest SSID has no guest network', () {
      final read = PnpWizardData(main: splitMain);

      expect(read.guest, isNull);
      expect(read, isNot(PnpWizardData(main: splitMain, guest: splitGuest)));
    });
  });
}
