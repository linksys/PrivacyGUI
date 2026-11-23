import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';

/// One radio of `GetRadioInfo` output, secured with WPA2/WPA3.
const _wpaRadio = <String, dynamic>{
  'radioID': 'RADIO_2.4GHz',
  'physicalRadioID': 'ath0',
  'bssid': '00:11:22:33:44:55',
  'band': '2.4GHz',
  'supportedModes': ['802.11bgn', '802.11mixed'],
  'defaultMixedMode': '802.11mixed',
  'supportedChannelsForChannelWidths': [
    {
      'channelWidth': 'Auto',
      'channels': [0, 1, 6, 11]
    },
  ],
  'supportedSecurityTypes': ['None', 'WPA2/WPA3-Mixed-Personal'],
  'maxRADIUSSharedKeyLength': 64,
  'settings': {
    'isEnabled': true,
    'mode': '802.11mixed',
    'ssid': 'Home',
    'broadcastSSID': true,
    'channelWidth': 'Auto',
    'channel': 0,
    'security': 'WPA2/WPA3-Mixed-Personal',
    'wpaPersonalSettings': {'passphrase': 'p@ssw0rd'},
  },
};

/// Radio settings for each of the other two ways a band can be secured.
const _wepSettings = <String, dynamic>{
  'isEnabled': true,
  'mode': '802.11an',
  'ssid': 'Old',
  'broadcastSSID': false,
  'channelWidth': 'Standard',
  'channel': 36,
  'security': 'WEP',
  'wepSettings': {
    'encryption': '64-bit',
    'key1': 'A1B2C3D4E5',
    'key2': '',
    'key3': '',
    'key4': '',
    'txKey': 1,
  },
};
const _enterpriseSettings = <String, dynamic>{
  'isEnabled': true,
  'mode': '802.11mixed',
  'ssid': 'Office',
  'broadcastSSID': true,
  'channelWidth': 'Auto',
  'channel': 0,
  'security': 'WPA2-Enterprise',
  'wpaEnterpriseSettings': {
    'radiusServer': '192.168.1.5',
    'radiusPort': 1812,
    'sharedKey': 'radius-secret',
  },
};

void main() {
  group('GetRadioInfo', () {
    const output = <String, dynamic>{
      'isBandSteeringSupported': true,
      'radios': [_wpaRadio],
    };

    test('reads the router output and writes it back unchanged', () {
      expect(GetRadioInfo.fromMap(output).toMap(), output);
    });

    test('survives a trip through JSON text', () {
      final info = GetRadioInfo.fromMap(output);

      expect(GetRadioInfo.fromJson(info.toJson()), info);
    });

    test('copyWith changes only what it names', () {
      final info = GetRadioInfo.fromMap(output);

      final changed = info.copyWith(isBandSteeringSupported: false);

      expect(changed.isBandSteeringSupported, isFalse);
      expect(changed.radios, info.radios);
      expect(changed.copyWith(isBandSteeringSupported: true), info);
    });
  });

  group('RouterRadio', () {
    test('reads the fields the Wi-Fi page builds on', () {
      final radio = RouterRadio.fromMap(_wpaRadio);

      expect(radio.maxRadiusSharedKeyLength, 64);
      expect(radio.supportedChannelsForChannelWidths.single.channels,
          [0, 1, 6, 11]);
      expect(radio.settings.wpaPersonalSettings?.passphrase, 'p@ssw0rd');
    });

    test('accepts a radio with no default mixed mode', () {
      final output = Map.of(_wpaRadio)..remove('defaultMixedMode');

      expect(RouterRadio.fromMap(output).defaultMixedMode, isNull);
    });

    test('survives a trip through JSON text', () {
      final radio = RouterRadio.fromMap(_wpaRadio);

      expect(RouterRadio.fromJson(radio.toJson()), radio);
    });

    test('copyWith changes only what it names', () {
      final radio = RouterRadio.fromMap(_wpaRadio);

      final moved = radio.copyWith(bssid: '66:77:88:99:AA:BB');

      expect(moved.bssid, '66:77:88:99:AA:BB');
      expect(moved.copyWith(bssid: '00:11:22:33:44:55'), radio);
    });
  });

  group('RouterRadioSettings', () {
    for (final MapEntry(key: security, value: settings) in {
      'WPA personal': _wpaRadio['settings'] as Map<String, dynamic>,
      'WEP': _wepSettings,
      'WPA enterprise': _enterpriseSettings,
    }.entries) {
      test('$security: writes back only the key settings it was given', () {
        expect(RouterRadioSettings.fromMap(settings).toMap(), settings);
      });
    }

    test('survives a trip through JSON text', () {
      final settings = RouterRadioSettings.fromMap(_enterpriseSettings);

      expect(RouterRadioSettings.fromJson(settings.toJson()), settings);
    });

    test('copyWith changes only what it names', () {
      final settings = RouterRadioSettings.fromMap(_wepSettings);

      final renamed = settings.copyWith(ssid: 'New', channel: 40);

      expect(renamed.ssid, 'New');
      expect(renamed.channel, 40);
      expect(renamed.copyWith(ssid: 'Old', channel: 36), settings);
    });
  });

  group('key settings', () {
    final wep = WepSettings.fromMap(
        _wepSettings['wepSettings'] as Map<String, dynamic>);
    final enterprise = WpaEnterpriseSettings.fromMap(
        _enterpriseSettings['wpaEnterpriseSettings'] as Map<String, dynamic>);
    const personal = WpaPersonalSettings(passphrase: 'p@ssw0rd');

    test('survive a trip through JSON text', () {
      expect(WepSettings.fromJson(wep.toJson()), wep);
      expect(WpaEnterpriseSettings.fromJson(enterprise.toJson()), enterprise);
      expect(WpaPersonalSettings.fromJson(personal.toJson()), personal);
    });

    test('copyWith changes only what it names', () {
      expect(wep.copyWith(txKey: 2).txKey, 2);
      expect(wep.copyWith(txKey: 2).key1, 'A1B2C3D4E5');
      expect(enterprise.copyWith(radiusPort: 1645).radiusPort, 1645);
      expect(enterprise.copyWith(radiusPort: 1645).sharedKey, 'radius-secret');
      expect(personal.copyWith(passphrase: 'other').passphrase, 'other');
    });
  });

  group('SupportedChannelsForChannelWidths', () {
    const width = SupportedChannelsForChannelWidths(
        channelWidth: 'Wide', channels: [0, 36, 44]);

    test('survives a trip through JSON text', () {
      expect(SupportedChannelsForChannelWidths.fromJson(width.toJson()), width);
    });

    test('copyWith changes only what it names', () {
      expect(
          width.copyWith(channels: [0]),
          const SupportedChannelsForChannelWidths(
              channelWidth: 'Wide', channels: [0]));
    });
  });
}
