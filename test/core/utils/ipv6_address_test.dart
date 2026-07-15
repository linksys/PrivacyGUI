import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';

void main() {
  group('classifyIpv6Scope', () {
    test('link-local fe80::/10 → linkLocal', () {
      expect(
          classifyIpv6Scope('fe80::7612:13ff:fe21:5394'), Ipv6Scope.linkLocal);
      expect(classifyIpv6Scope('fe80:0000:0000:0000:139f:b9c2:6598:5d1e'),
          Ipv6Scope.linkLocal);
      // febf is the top of the fe80::/10 range.
      expect(classifyIpv6Scope('febf::1'), Ipv6Scope.linkLocal);
    });

    test('global unicast 2000::/3 → global', () {
      expect(classifyIpv6Scope('2401:e180:8801:d79d:7612:13ff:fe21:5394'),
          Ipv6Scope.global);
      expect(classifyIpv6Scope('2401:e180:8831:505f::1'), Ipv6Scope.global);
      expect(classifyIpv6Scope('2001:db8::1'), Ipv6Scope.global);
      // 3fff is the top of the 2000::/3 range.
      expect(classifyIpv6Scope('3fff::1'), Ipv6Scope.global);
    });

    test('unique local fc00::/7 → uniqueLocal', () {
      expect(classifyIpv6Scope('fc00::1'), Ipv6Scope.uniqueLocal);
      expect(classifyIpv6Scope('fd12:3456::1'), Ipv6Scope.uniqueLocal);
    });

    test('non-classifiable / malformed → other', () {
      expect(classifyIpv6Scope(''), Ipv6Scope.other);
      expect(classifyIpv6Scope('   '), Ipv6Scope.other);
      expect(classifyIpv6Scope('192.168.1.1'), Ipv6Scope.other);
      expect(classifyIpv6Scope('::1'), Ipv6Scope.other); // loopback
      expect(classifyIpv6Scope('ff02::1'), Ipv6Scope.other); // multicast
      expect(classifyIpv6Scope('not-an-ip'), Ipv6Scope.other);
    });

    test('handles zone id and prefix length suffixes', () {
      expect(classifyIpv6Scope('fe80::1%eth0'), Ipv6Scope.linkLocal);
      expect(classifyIpv6Scope('2401:e180::1/64'), Ipv6Scope.global);
    });
  });

  group('isGlobalUnicastIpv6', () {
    test('true only for global unicast', () {
      expect(isGlobalUnicastIpv6('2401:e180:8801:d79d::1'), isTrue);
      expect(isGlobalUnicastIpv6('fe80::1'), isFalse);
      expect(isGlobalUnicastIpv6('fc00::1'), isFalse);
      expect(isGlobalUnicastIpv6(''), isFalse);
    });
  });

  group('preferGlobalIpv6First', () {
    test('surfaces global unicast ahead of link-local (issue #1128 case)', () {
      // Exact ordering from the #1128 diagnostic log
      // (Device.IP.Interface.2.IPv6Address.1..4).
      final input = [
        'fe80::7612:13ff:fe21:5394', // instance 1 — link-local (the bug)
        '2401:e180:8831:505f::1', // instance 2 — global
        '2401:e180:8831:505f:7612:13ff:fe21:5394', // instance 3 — global
        '2401:e180:8801:d79d:7612:13ff:fe21:5394', // instance 4 — global (WAN)
      ];

      final result = preferGlobalIpv6First(input);

      // First address must now be a global unicast, not the link-local.
      expect(isGlobalUnicastIpv6(result.first), isTrue);
      expect(result.first, '2401:e180:8831:505f::1');
      // Link-local sinks to the end.
      expect(result.last, 'fe80::7612:13ff:fe21:5394');
    });

    test('is stable within a scope (preserves instance order)', () {
      final input = [
        '2401:e180:8831:505f::1',
        '2401:e180:8831:505f:7612:13ff:fe21:5394',
        '2401:e180:8801:d79d:7612:13ff:fe21:5394',
      ];
      // All global → order unchanged.
      expect(preferGlobalIpv6First(input), input);
    });

    test('orders global > ULA > link-local > other', () {
      final input = [
        'fe80::1', // link-local
        'ff02::1', // other (multicast)
        'fc00::1', // ULA
        '2001:db8::1', // global
      ];
      expect(preferGlobalIpv6First(input),
          ['2001:db8::1', 'fc00::1', 'fe80::1', 'ff02::1']);
    });

    test('empty input returns empty', () {
      expect(preferGlobalIpv6First(const []), isEmpty);
    });
  });
}
