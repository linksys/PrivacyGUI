import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_automatic_settings.dart';

/// [value] as the router receives it: JSON on the wire.
Object? _wire(Object? value) => jsonDecode(jsonEncode(value));

/// The `ipv6AutomaticSettings` of `GetIPv6Settings`, with a manual tunnel.
const _manual6rd = <String, dynamic>{
  'isIPv6AutomaticEnabled': false,
  'ipv6rdTunnelMode': 'Manual',
  'ipv6rdTunnelSettings': {
    'prefix': '2001:db8::',
    'prefixLength': 32,
    'borderRelay': '192.0.2.1',
    'borderRelayPrefixLength': 0,
  },
};

void main() {
  test('reads a manual 6rd tunnel', () {
    final settings = IPv6AutomaticSettings.fromJson(_manual6rd);

    expect(settings.isIPv6AutomaticEnabled, isFalse);
    expect(settings.ipv6rdTunnelMode, 'Manual');
    expect(
        settings.ipv6rdTunnelSettings,
        const IPv6rdTunnelSettings(
          prefix: '2001:db8::',
          prefixLength: 32,
          borderRelay: '192.0.2.1',
          borderRelayPrefixLength: 0,
        ));
  });

  test('writes the tunnel it read', () {
    expect(
        _wire(IPv6AutomaticSettings.fromJson(_manual6rd).toJson()), _manual6rd);
  });

  test('writes automatic with no tunnel as the switch alone', () {
    final settings =
        IPv6AutomaticSettings.fromJson(const {'isIPv6AutomaticEnabled': true});

    expect(settings.ipv6rdTunnelSettings, isNull);
    expect(settings.toJson(), {'isIPv6AutomaticEnabled': true});
  });

  test('copyWith changes only what it names', () {
    final settings = IPv6AutomaticSettings.fromJson(_manual6rd);
    final tunnel = settings.ipv6rdTunnelSettings!;

    expect(
        settings
            .copyWith(
                isIPv6AutomaticEnabled: true, ipv6rdTunnelMode: 'Automatic')
            .ipv6rdTunnelMode,
        'Automatic');
    expect(settings.copyWith(), settings);
    expect(
        tunnel.copyWith(
            prefix: '2001:db8:1::',
            prefixLength: 48,
            borderRelay: '192.0.2.2',
            borderRelayPrefixLength: 8),
        const IPv6rdTunnelSettings(
          prefix: '2001:db8:1::',
          prefixLength: 48,
          borderRelay: '192.0.2.2',
          borderRelayPrefixLength: 8,
        ));
    expect(tunnel.copyWith(), tunnel);
  });
}
