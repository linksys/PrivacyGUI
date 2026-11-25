import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_automatic_settings.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_settings.dart';

/// [value] as the router receives it: JSON on the wire.
Object? _wire(Object? value) => jsonDecode(jsonEncode(value));

/// `GetIPv6Settings` output: automatic, with a manual 6rd tunnel.
const _output = <String, dynamic>{
  'wanType': 'Automatic',
  'duid': '00:02:03:09:05:05:00:11:22:33:44:55',
  'ipv6AutomaticSettings': {
    'isIPv6AutomaticEnabled': false,
    'ipv6rdTunnelMode': 'Manual',
    'ipv6rdTunnelSettings': {
      'prefix': '2001:db8::',
      'prefixLength': 32,
      'borderRelay': '192.0.2.1',
      'borderRelayPrefixLength': 0,
    },
  },
};

void main() {
  group('GetIPv6Settings', () {
    test('reads the connection type, the DUID and the 6rd tunnel', () {
      final settings = GetIPv6Settings.fromJson(_output);

      expect(settings.wanType, 'Automatic');
      expect(settings.duid, '00:02:03:09:05:05:00:11:22:33:44:55');
      expect(settings.ipv6AutomaticSettings?.ipv6rdTunnelMode, 'Manual');
      expect(settings.ipv6AutomaticSettings?.ipv6rdTunnelSettings?.borderRelay,
          '192.0.2.1');
    });

    test('reads a pass-through connection with no automatic settings', () {
      final settings = GetIPv6Settings.fromJson(
          const {'wanType': 'Pass-through', 'duid': '00:01'});

      expect(settings.ipv6AutomaticSettings, isNull);
    });

    test('writes the fields it read', () {
      expect(_wire(GetIPv6Settings.fromJson(_output).toJson()), _output);
    });

    test('copyWith changes only what it names', () {
      final settings = GetIPv6Settings.fromJson(_output);

      expect(
          settings.copyWith(wanType: 'Pass-through').wanType, 'Pass-through');
      expect(settings.copyWith(duid: '00:01').duid, '00:01');
      expect(settings.copyWith(), settings);
    });
  });

  group('SetIPv6Settings', () {
    test('writes the type and the automatic settings', () {
      const settings = SetIPv6Settings(
        wanType: 'Automatic',
        ipv6AutomaticSettings: IPv6AutomaticSettings(
          isIPv6AutomaticEnabled: true,
        ),
      );

      expect(_wire(settings.toJson()), {
        'wanType': 'Automatic',
        'ipv6AutomaticSettings': {'isIPv6AutomaticEnabled': true},
      });
    });

    test('writes a type with no automatic settings as the type alone', () {
      expect(const SetIPv6Settings(wanType: 'Pass-through').toJson(),
          {'wanType': 'Pass-through'});
    });

    test('reads back what it wrote', () {
      final settings = SetIPv6Settings.fromJson(
          (_wire(GetIPv6Settings.fromJson(_output).toJson())
              as Map<String, dynamic>)
            ..remove('duid'));

      expect(settings.wanType, 'Automatic');
      expect(settings.ipv6AutomaticSettings?.ipv6rdTunnelMode, 'Manual');
      expect(SetIPv6Settings.fromJson(const {'wanType': 'Pass-through'}),
          const SetIPv6Settings(wanType: 'Pass-through'));
    });

    test('copyWith changes only what it names', () {
      const settings = SetIPv6Settings(wanType: 'Automatic');

      expect(settings.copyWith(wanType: 'Pass-through'),
          const SetIPv6Settings(wanType: 'Pass-through'));
      expect(settings.copyWith(), settings);
    });
  });
}
