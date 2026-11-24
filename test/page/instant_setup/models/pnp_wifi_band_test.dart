import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';

/// The key a band's E2E hooks carry (constitution Article XVI §16.3): from the
/// band's data, with a fixed fallback chain, never from its place in a list.
void main() {
  PnpWifiBand band({String frequency = '', String path = ''}) => PnpWifiBand(
        bandName: 'band',
        frequency: frequency,
        ssid: 's',
        password: 'p',
        ssidInstancePath: path,
        accessPointInstancePath: '',
        radioPath: '',
      );

  test('a band is keyed by its frequency, slugged', () {
    expect(pnpBandIdentifierKey(band(frequency: '2.4GHz')), '2-4ghz');
    expect(pnpBandIdentifierKey(band(frequency: '5GHz')), '5ghz');
    expect(pnpBandIdentifierKey(band(frequency: '6GHz')), '6ghz');
  });

  test('with no frequency, by its SSID row\'s instance number', () {
    expect(pnpBandIdentifierKey(band(path: 'Device.WiFi.SSID.3.')), '3');
    expect(pnpBandIdentifierKey(band(path: 'Device.WiFi.SSID.12')), '12');
  });

  test('with neither, a fixed word, so the hook still exists', () {
    expect(pnpBandIdentifierKey(band()), 'unnamed');
  });

  test('a unified network\'s one set of fields is `all`', () {
    expect(pnpBandIdentifierKey(null), 'all');
  });
}
