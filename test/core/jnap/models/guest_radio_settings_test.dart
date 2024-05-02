import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';

void main() {
  group('Test GuestRadioSettings converter', () {
    testWidgets('Test convert from map to object', (tester) async {
      final map = {
        "isGuestNetworkACaptivePortal": false,
        "isGuestNetworkEnabled": false,
        "radios": [
          {
            "radioID": "RADIO_2-4GHz",
            "isEnabled": true,
            "broadcastGuestSSID": true,
            "guestSSID": "Linksys00040-guest",
            "guestWPAPassphrase": "BeMyGuest",
            "canEnableRadio": true
          },
          {
            "radioID": "RADIO_5GHz",
            "isEnabled": true,
            "broadcastGuestSSID": true,
            "guestSSID": "Linksys00040-guest",
            "guestWPAPassphrase": "BeMyGuest",
            "canEnableRadio": true
          }
        ]
      };
      final guestRadioSettings = GuestRadioSettings.fromMap(map);
      expect(guestRadioSettings, isA<GuestRadioSettings>());
      expect(guestRadioSettings.isGuestNetworkEnabled, false);
      expect(guestRadioSettings.isGuestNetworkACaptivePortal, false);
      expect(guestRadioSettings.guestPasswordRestrictions, isNull);
      expect(guestRadioSettings.maxSimultaneousGuests, isNull);
      expect(guestRadioSettings.maxSimultaneousGuestsLimit, isNull);
      expect(guestRadioSettings.radios.length, 2);

      expect(guestRadioSettings.radios[0].radioID, 'RADIO_2-4GHz');
      expect(guestRadioSettings.radios[0].isEnabled, true);
      expect(guestRadioSettings.radios[0].broadcastGuestSSID, true);
      expect(guestRadioSettings.radios[0].guestSSID, 'Linksys00040-guest');
      expect(guestRadioSettings.radios[0].guestWPAPassphrase, 'BeMyGuest');
      expect(guestRadioSettings.radios[0].canEnableRadio, true);

      expect(guestRadioSettings.radios[1].radioID, 'RADIO_5GHz');
      expect(guestRadioSettings.radios[1].isEnabled, true);
      expect(guestRadioSettings.radios[1].broadcastGuestSSID, true);
      expect(guestRadioSettings.radios[1].guestSSID, 'Linksys00040-guest');
      expect(guestRadioSettings.radios[1].guestWPAPassphrase, 'BeMyGuest');
      expect(guestRadioSettings.radios[1].canEnableRadio, true);
    });

    testWidgets('Test convert from obj to map', (tester) async {
      final map = {
        "isGuestNetworkACaptivePortal": false,
        "isGuestNetworkEnabled": false,
        "radios": [
          {
            "radioID": "RADIO_2-4GHz",
            "isEnabled": true,
            "broadcastGuestSSID": true,
            "guestSSID": "Linksys00040-guest",
            "guestWPAPassphrase": "BeMyGuest",
            "canEnableRadio": true
          },
          {
            "radioID": "RADIO_5GHz",
            "isEnabled": true,
            "broadcastGuestSSID": true,
            "guestSSID": "Linksys00040-guest",
            "guestWPAPassphrase": "BeMyGuest",
            "canEnableRadio": true
          }
        ]
      };
      final guestRadioSettings = GuestRadioSettings.fromMap(map);
      final guestRadioSettingsMap = guestRadioSettings.toMap();
      expect(guestRadioSettingsMap, isA<Map<String, dynamic>>());
      expect(guestRadioSettingsMap['isGuestNetworkEnabled'], false);
      expect(guestRadioSettingsMap['isGuestNetworkACaptivePortal'], false);
      expect(guestRadioSettingsMap['guestPasswordRestrictions'], isNull);
      expect(guestRadioSettingsMap['maxSimultaneousGuests'], isNull);
      expect(guestRadioSettingsMap['maxSimultaneousGuestsLimit'], isNull);
      expect(guestRadioSettingsMap['radios'].length, 2);

      expect(guestRadioSettingsMap['radios'][0]['radioID'], 'RADIO_2-4GHz');
      expect(guestRadioSettingsMap['radios'][0]['isEnabled'], true);
      expect(guestRadioSettingsMap['radios'][0]['broadcastGuestSSID'], true);
      expect(guestRadioSettingsMap['radios'][0]['guestSSID'],
          'Linksys00040-guest');
      expect(guestRadioSettingsMap['radios'][0]['guestWPAPassphrase'],
          'BeMyGuest');
      expect(guestRadioSettingsMap['radios'][0]['canEnableRadio'], true);

      expect(guestRadioSettingsMap['radios'][1]['radioID'], 'RADIO_5GHz');
      expect(guestRadioSettingsMap['radios'][1]['isEnabled'], true);
      expect(guestRadioSettingsMap['radios'][1]['broadcastGuestSSID'], true);
      expect(guestRadioSettingsMap['radios'][1]['guestSSID'],
          'Linksys00040-guest');
      expect(guestRadioSettingsMap['radios'][1]['guestWPAPassphrase'],
          'BeMyGuest');
      expect(guestRadioSettingsMap['radios'][1]['canEnableRadio'], true);
    });
  });
}
