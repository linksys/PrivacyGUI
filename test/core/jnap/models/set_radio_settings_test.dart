import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/set_radio_settings.dart';

/// `SetRadioSettings` input for one band.
const _input = <String, dynamic>{
  'radios': [
    {
      'radioID': 'RADIO_5GHz',
      'settings': {
        'isEnabled': true,
        'mode': '802.11mixed',
        'ssid': 'Home',
        'broadcastSSID': true,
        'channelWidth': 'Auto',
        'channel': 0,
        'security': 'WPA3-Personal',
        'wpaPersonalSettings': {'passphrase': 'p@ssw0rd'},
      },
    },
  ],
};

void main() {
  group('SetRadioSettings', () {
    test('reads the input and writes it back unchanged', () {
      expect(SetRadioSettings.fromMap(_input).toMap(), _input);
    });

    test('survives a trip through JSON text', () {
      final settings = SetRadioSettings.fromMap(_input);

      expect(SetRadioSettings.fromJson(settings.toJson()), settings);
    });

    test('copyWith changes only what it names', () {
      final settings = SetRadioSettings.fromMap(_input);

      expect(settings.copyWith(radios: const []).radios, isEmpty);
      expect(settings.copyWith(), settings);
    });
  });

  group('NewRadioSettings', () {
    final band = NewRadioSettings.fromMap(
        (_input['radios'] as List).single as Map<String, dynamic>);

    test('survives a trip through JSON text', () {
      expect(NewRadioSettings.fromJson(band.toJson()), band);
    });

    test('copyWith changes only what it names', () {
      final moved = band.copyWith(radioID: 'RADIO_6GHz');

      expect(moved.radioID, 'RADIO_6GHz');
      expect(moved.settings, isA<RouterRadioSettings>());
      expect(moved.copyWith(radioID: 'RADIO_5GHz'), band);
    });
  });
}
