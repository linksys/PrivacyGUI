import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/wirless_connection.dart';

/// The `wireless` part of a `GetNetworkConnections2` entry, as JSON text, for
/// a Wi-Fi 7 laptop that reports its rates and MLO.
const _laptopText = '''
{
  "bssid": "30:23:03:2E:AF:F0",
  "isGuest": false,
  "radioID": "RADIO_5GHz",
  "band": "5GHz",
  "signalDecibels": -51,
  "txRate": 1201,
  "rxRate": 960,
  "isMLOCapable": true
}
''';

/// The same for an older phone on the guest network, with no rates.
const _phoneText = '''
{"bssid": "36:23:03:2E:AF:F0", "isGuest": true, "band": "2.4GHz", "signalDecibels": -70}
''';

void main() {
  test('reads a link with its rates and MLO', () {
    final link = WirelessConnection.fromJson(_laptopText);

    expect(link.bssid, '30:23:03:2E:AF:F0');
    expect(link.isGuest, isFalse);
    expect(link.radioID, 'RADIO_5GHz');
    expect(link.band, '5GHz');
    expect(link.signalDecibels, -51);
    expect((link.txRate, link.rxRate, link.isMLOCapable), (1201, 960, true));
  });

  test('reads a link without them, and writes it back without them', () {
    final link = WirelessConnection.fromJson(_phoneText);

    expect((link.radioID, link.txRate, link.rxRate, link.isMLOCapable),
        (null, null, null, null));
    expect(link.toMap(), {
      'bssid': '36:23:03:2E:AF:F0',
      'isGuest': true,
      'band': '2.4GHz',
      'signalDecibels': -70,
    });
  });

  test('survives a trip through JSON text', () {
    final link = WirelessConnection.fromJson(_laptopText);

    expect(WirelessConnection.fromJson(link.toJson()), link);
    expect(link, isNot(WirelessConnection.fromJson(_phoneText)));
  });

  test('copyWith changes only what it names', () {
    final link = WirelessConnection.fromJson(_laptopText);

    final weaker = link.copyWith(signalBecibels: -80, txRate: 600);
    expect(link.copyWith(), link);

    expect((weaker.signalDecibels, weaker.txRate), (-80, 600));
    expect(weaker.rxRate, 960);
    expect(weaker.copyWith(signalBecibels: -51, txRate: 1201), link);
  });
}
