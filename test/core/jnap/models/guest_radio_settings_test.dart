import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';

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

  /// `GetGuestRadioSettings` output with every optional field the router may
  /// send.
  const fullOutput = <String, dynamic>{
    'isGuestNetworkACaptivePortal': false,
    'isGuestNetworkEnabled': true,
    'maxSimultaneousGuests': 50,
    'maxSimultaneousGuestsLimit': 128,
    'guestPasswordRestrictions': {
      'minLength': 8,
      'maxLength': 63,
      'allowedCharacters': [
        {'lowCodepoint': 32, 'highCodepoint': 126},
      ],
    },
    'radios': [
      {
        'radioID': 'RADIO_2.4GHz',
        'isEnabled': true,
        'broadcastGuestSSID': true,
        'guestSSID': 'Guest',
        'guestPassword': 'legacy1',
        'guestWPAPassphrase': 'BeMyGuest',
        'canEnableRadio': true,
      },
    ],
  };

  group('GuestRadioSettings, every field', () {
    test('reads the router output and writes it back unchanged', () {
      expect(GuestRadioSettings.fromMap(fullOutput).toMap(), fullOutput);
    });

    test('survives a trip through JSON text', () {
      final settings = GuestRadioSettings.fromMap(fullOutput);

      expect(GuestRadioSettings.fromJson(settings.toJson()), settings);
    });

    test('copyWith changes only what it names', () {
      final settings = GuestRadioSettings.fromMap(fullOutput);

      final off = settings.copyWith(isGuestNetworkEnabled: false);

      expect(off.isGuestNetworkEnabled, isFalse);
      expect(off.copyWith(isGuestNetworkEnabled: true), settings);
    });

    test('reads the password rules', () {
      final rules =
          GuestRadioSettings.fromMap(fullOutput).guestPasswordRestrictions!;

      expect(rules.minLength, 8);
      expect(rules.allowedCharacters.single,
          const UnicodeRange(lowCodepoint: 32, highCodepoint: 126));
    });
  });

  group('SetGuestRadioSettings', () {
    test('writes back what the router reported, less the read-only fields', () {
      final settings = SetGuestRadioSettings.fromGuestRadioSettings(
          GuestRadioSettings.fromMap(fullOutput));

      expect(settings.toMap(), {
        'isGuestNetworkEnabled': true,
        'maxSimultaneousGuests': 50,
        'radios': fullOutput['radios'],
      });
    });

    test('copyWith changes only what it names', () {
      final settings = SetGuestRadioSettings.fromGuestRadioSettings(
          GuestRadioSettings.fromMap(fullOutput));

      final off = settings.copyWith(isGuestNetworkEnabled: false);

      expect(off.isGuestNetworkEnabled, isFalse);
      expect(off.radios, settings.radios);
      expect(off.copyWith(isGuestNetworkEnabled: true), settings);
    });
  });

  group('GuestRadioInfo', () {
    final radio = GuestRadioInfo.fromMap(
        (fullOutput['radios'] as List).first as Map<String, dynamic>);

    test('survives a trip through JSON text', () {
      expect(GuestRadioInfo.fromJson(radio.toJson()), radio);
    });

    test('leaves out the fields it has no value for', () {
      const bare = GuestRadioInfo(
        radioID: 'RADIO_5GHz',
        isEnabled: false,
        broadcastGuestSSID: false,
        guestSSID: 'Guest',
      );

      expect(bare.toMap(), {
        'radioID': 'RADIO_5GHz',
        'isEnabled': false,
        'broadcastGuestSSID': false,
        'guestSSID': 'Guest',
      });
    });

    test('copyWith changes only what it names', () {
      final renamed = radio.copyWith(guestSSID: 'Visitors');

      expect(renamed.guestSSID, 'Visitors');
      expect(renamed.copyWith(guestSSID: 'Guest'), radio);
    });
  });

  group('GuestPasswordRestriction and UnicodeRange', () {
    final rules = GuestPasswordRestriction.fromMap(
        fullOutput['guestPasswordRestrictions'] as Map<String, dynamic>);

    test('survive a trip through JSON text', () {
      expect(GuestPasswordRestriction.fromJson(rules.toJson()), rules);
      const range = UnicodeRange(lowCodepoint: 48, highCodepoint: 57);
      expect(UnicodeRange.fromJson(range.toJson()), range);
    });

    test('copyWith changes only what it names', () {
      expect(rules.copyWith(maxLength: 32).maxLength, 32);
      expect(rules.copyWith(maxLength: 32).minLength, 8);
      expect(
        const UnicodeRange(lowCodepoint: 48, highCodepoint: 57)
            .copyWith(highCodepoint: 70),
        const UnicodeRange(lowCodepoint: 48, highCodepoint: 70),
      );
    });
  });
}
