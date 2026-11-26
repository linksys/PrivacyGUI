import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/mac_address_clone_settings.dart';

const _cloned = <String, dynamic>{
  'isMACAddressCloneEnabled': true,
  'macAddress': 'AA:BB:CC:DD:EE:FF',
};

void main() {
  test('reads a cloned MAC address', () {
    final settings = MACAddressCloneSettings.fromMap(_cloned);

    expect(settings.isMACAddressCloneEnabled, isTrue);
    expect(settings.macAddress, 'AA:BB:CC:DD:EE:FF');
  });

  test('writes clone off with no address', () {
    final settings = MACAddressCloneSettings.fromMap(
        const {'isMACAddressCloneEnabled': false});

    expect(settings.macAddress, isNull);
    expect(settings.toMap(), {'isMACAddressCloneEnabled': false});
  });

  test('survives a trip through JSON text', () {
    final settings = MACAddressCloneSettings.fromMap(_cloned);

    expect(MACAddressCloneSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    final settings = MACAddressCloneSettings.fromMap(_cloned);

    expect(settings.copyWith(isMACAddressCloneEnabled: false).macAddress,
        'AA:BB:CC:DD:EE:FF');
    expect(settings.copyWith(macAddress: '11:22:33:44:55:66').macAddress,
        '11:22:33:44:55:66');
    expect(settings.copyWith(), settings);
  });
}
