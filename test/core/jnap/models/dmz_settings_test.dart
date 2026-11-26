import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';

/// `GetDMZSettings` output, the legacy JNAP reference's sample.
const _output = <String, dynamic>{
  'isDMZEnabled': true,
  'sourceRestriction': {
    'firstIPAddress': '192.168.10.1',
    'lastIPAddress': '192.168.11.1',
  },
  'destinationIPAddress': '192.168.1.200',
};

void main() {
  test('reads a DMZ with a source range and a server address', () {
    final settings = DMZSettings.fromMap(_output);

    expect(settings.isDMZEnabled, isTrue);
    expect(settings.sourceRestriction?.firstIPAddress, '192.168.10.1');
    expect(settings.sourceRestriction?.lastIPAddress, '192.168.11.1');
    expect(settings.destinationIPAddress, '192.168.1.200');
    expect(settings.destinationMACAddress, isNull);
  });

  test('reads a source restriction of one address as a range of one', () {
    final restriction =
        DMZSourceRestriction.fromMap(const {'firstIPAddress': '192.0.2.5'});

    expect(restriction.lastIPAddress, '192.0.2.5');
  });

  test('writes every field, null where unused', () {
    expect(DMZSettings.fromMap(_output).toMap(), {
      ..._output,
      'destinationMACAddress': null,
    });
  });

  test('survives a trip through JSON text', () {
    final settings = DMZSettings.fromMap(_output);

    expect(DMZSettings.fromJson(settings.toJson()), settings);
    expect(DMZSourceRestriction.fromJson(settings.sourceRestriction!.toJson()),
        settings.sourceRestriction);
  });

  test('copyWith can clear what it names', () {
    final settings = DMZSettings.fromMap(_output);

    final toMac = settings.copyWith(
      sourceRestriction: () => null,
      destinationIPAddress: () => null,
      destinationMACAddress: () => 'AA:BB:CC:DD:EE:01',
    );

    expect(
        toMac,
        const DMZSettings(
          isDMZEnabled: true,
          destinationMACAddress: 'AA:BB:CC:DD:EE:01',
        ));
    expect(settings.copyWith(isDMZEnabled: false).sourceRestriction,
        settings.sourceRestriction);
  });

  test('copyWith of a source restriction changes only what it names', () {
    const restriction = DMZSourceRestriction(
        firstIPAddress: '192.0.2.1', lastIPAddress: '192.0.2.9');

    expect(
        restriction.copyWith(lastIPAddress: '192.0.2.20'),
        const DMZSourceRestriction(
            firstIPAddress: '192.0.2.1', lastIPAddress: '192.0.2.20'));
    expect(restriction.copyWith(), restriction);
  });
}
