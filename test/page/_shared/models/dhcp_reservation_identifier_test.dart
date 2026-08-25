import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';

DhcpReservationUIModel _reservation({
  String? instancePath,
  String mac = 'AA:BB:CC:DD:EE:FF',
}) {
  return DhcpReservationUIModel(
    instancePath: instancePath,
    mac: mac,
    ip: '192.168.1.100',
    enable: true,
  );
}

final _kebabRegex = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

void main() {
  group('DhcpReservationUIModel.identifierKey', () {
    test('slugifies an uppercase colon-bearing MAC into kebab-case', () {
      // AA:BB:CC:DD:EE:FF -> aa-bb-cc-dd-ee-ff (constitution §16.3 kebab MUST).
      expect(
        _reservation(mac: 'AA:BB:CC:DD:EE:FF').identifierKey,
        'aa-bb-cc-dd-ee-ff',
      );
    });

    test('is idempotent for an already-lowercase MAC', () {
      // The ctor uppercases MAC, so a lowercase input normalizes identically.
      expect(
        _reservation(mac: 'aa:bb:cc:dd:ee:ff').identifierKey,
        'aa-bb-cc-dd-ee-ff',
      );
    });

    test('output matches the kebab-case identifier regex for a normal MAC', () {
      expect(
        _kebabRegex
            .hasMatch(_reservation(mac: 'AA:BB:CC:11:22:33').identifierKey),
        isTrue,
      );
    });

    test('empty MAC falls back to the trailing instance number', () {
      // Production emits DOT-TERMINATED instance paths
      // (`final p = '$basePath$id.'` in dhcp_reservations.g.dart:69), so the
      // fixture must carry the trailing '.' the app actually reaches.
      expect(
        _reservation(
                mac: '',
                instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.2.')
            .identifierKey,
        '2',
      );
    });

    test(
        'empty MAC + dot-terminated paths at distinct instances do NOT collide',
        () {
      // §16.3 deterministic fallback chain: two empty-name rows at different
      // instances must yield different keys.
      final k1 = _reservation(
              mac: '',
              instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.')
          .identifierKey;
      final k2 = _reservation(
              mac: '',
              instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.2.')
          .identifierKey;
      expect(k1, '1');
      expect(k2, '2');
      expect(k1 == k2, isFalse);
    });

    test('empty MAC + degenerate dot-terminated path falls back to "unnamed"',
        () {
      // A path with no parseable instance number ahead of the trailing dot
      // (or a double-dot) has no discriminating tier and shares the sentinel.
      expect(
        _reservation(mac: '', instancePath: 'Device.NAT.PortMapping.')
            .identifierKey,
        'unnamed',
      );
      expect(
        _reservation(mac: '', instancePath: 'Device.NAT.PortMapping.2..')
            .identifierKey,
        'unnamed',
      );
    });

    test('empty MAC with no instance path falls back to a non-empty literal',
        () {
      final key = _reservation(mac: '', instancePath: null).identifierKey;
      expect(key, isNotEmpty);
      expect(key, 'unnamed');
    });

    test('empty MAC never yields a degenerate/colliding key', () {
      // A blank MAC must not collapse to '' (which would collide across rows).
      expect(_reservation(mac: '   ').identifierKey, isNotEmpty);
      expect(
          _kebabRegex.hasMatch(_reservation(mac: '   ').identifierKey), isTrue);
    });
  });
}
