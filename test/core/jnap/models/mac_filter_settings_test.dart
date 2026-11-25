import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';

/// `GetMACFilterSettings` output.
const _output = <String, dynamic>{
  'macFilterMode': 'Allow',
  'maxMACAddresses': 32,
  'macAddresses': ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02'],
};

void main() {
  test('reads the mode, the limit and the listed addresses', () {
    final settings = MACFilterSettings.fromMap(_output);

    expect(settings.macFilterMode, 'Allow');
    expect(settings.maxMACAddresses, 32);
    expect(settings.macAddresses, ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']);
  });

  test('reads the same output from JSON text', () {
    final settings = MACFilterSettings.fromJson(
        '{"macFilterMode":"Deny","maxMACAddresses":32,"macAddresses":[]}');

    expect(
        settings,
        const MACFilterSettings(
            macFilterMode: 'Deny', maxMACAddresses: 32, macAddresses: []));
  });

  test('copyWith changes only what it names', () {
    final settings = MACFilterSettings.fromMap(_output);

    final changed = settings
        .copyWith(macFilterMode: 'Deny', maxMACAddresses: 16, macAddresses: []);

    expect(
        changed,
        const MACFilterSettings(
            macFilterMode: 'Deny', maxMACAddresses: 16, macAddresses: []));
    expect(settings.copyWith(), settings);
    expect(settings.toString(), contains('Allow'));
  });
}
