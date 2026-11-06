import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';

import '../../../test_data/dashboard_manager_test_state.dart';

void main() {
  // The router broadcasts _VelopSetup4C4 on every band, WPA2/WPA3 mixed.
  final managerState = DashboardManagerState.fromMap(dashboardManagerTestState);
  final radios = managerState.mainRadios;

  // The shape a DashboardWiFiItem map had before it carried a security mode
  // and broadcast setting, as cached state may still hold.
  const legacyMap = {
    'ssid': 'Linksys03041',
    'password': '7sVzt65hf@',
    'radios': ['RADIO_2.4GHz'],
    'isGuest': false,
    'isEnabled': true,
    'numOfConnectedDevices': 2,
  };

  List<RouterRadio> withSettings({String? security, bool? broadcastSSID}) => [
        for (final radio in radios)
          radio.copyWith(
            settings: radio.settings.copyWith(
              security: security,
              broadcastSSID: broadcastSSID,
            ),
          ),
      ];

  // Share WiFi hands out the same code a WiFi Settings save does, so it has to
  // follow the band's security mode and broadcast setting too.
  group('DashboardWiFiItem.qrCredential', () {
    test('a WPA network shares a WPA code with its password', () {
      final item = DashboardWiFiItem.fromMainRadios(radios, 0);

      expect(
        item.qrCredential.generate(),
        'WIFI:S:_VelopSetup4C4;P:9pe0a3rpwc;T:WPA;H:false;;',
      );
    });

    test('an open network shares a code that joins without a password', () {
      final item =
          DashboardWiFiItem.fromMainRadios(withSettings(security: 'None'), 0);

      expect(
        item.qrCredential.generate(),
        'WIFI:S:_VelopSetup4C4;T:nopass;H:false;;',
      );
    });

    test('a network that hides its name shares a code marked hidden', () {
      final item = DashboardWiFiItem.fromMainRadios(
          withSettings(broadcastSSID: false), 0);

      expect(
        item.qrCredential.generate(),
        'WIFI:S:_VelopSetup4C4;P:9pe0a3rpwc;T:WPA;H:true;;',
      );
    });

    // A mode newer firmware may report must not fail the dashboard; it shares
    // a WPA code, as every main network did before.
    test('a security mode the app does not know shares a WPA code', () {
      final item = DashboardWiFiItem.fromMainRadios(
          withSettings(security: 'Some-Future-Mode'), 0);

      expect(item.securityType, isNull);
      expect(
        item.qrCredential.generate(),
        'WIFI:S:_VelopSetup4C4;P:9pe0a3rpwc;T:WPA;H:false;;',
      );
    });

    test('the guest network keeps its WPA code', () {
      final item =
          DashboardWiFiItem.fromGuestRadios(managerState.guestRadios, 0);

      expect(item.isGuest, isTrue);
      expect(
        item.qrCredential.generate(),
        'WIFI:S:_VelopSetup4C4-123-guest;P:BeMyGuest;T:WPA;H:false;;',
      );
    });
  });

  group('DashboardWiFiItem map', () {
    test('keeps the security mode and broadcast setting through a round trip',
        () {
      final item = DashboardWiFiItem.fromMainRadios(
          withSettings(security: 'WPA3-Personal', broadcastSSID: false), 3);

      final fromMap = DashboardWiFiItem.fromMap(item.toMap());
      expect(fromMap.securityType, WifiSecurityType.wpa3Personal);
      expect(fromMap.isBroadcast, isFalse);
      expect(fromMap, item);
      expect(DashboardWiFiItem.fromJson(item.toJson()), item);
    });

    test('reads a map without the new fields as a broadcasting WPA network',
        () {
      final item = DashboardWiFiItem.fromMap(legacyMap);

      expect(item.securityType, isNull);
      expect(item.isBroadcast, isTrue);
      expect(
        item.qrCredential.generate(),
        'WIFI:S:Linksys03041;P:7sVzt65hf@;T:WPA;H:false;;',
      );
    });

    test('reads a security mode it does not know as unknown', () {
      final item = DashboardWiFiItem.fromMap(
          const {...legacyMap, 'securityType': 'Some-Future-Mode'});

      expect(item.securityType, isNull);
    });
  });
}
