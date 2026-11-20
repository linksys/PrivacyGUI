import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/validator_rules/lan_host_ipv4.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

void main() {
  const lanIp = '192.168.1.1';
  const lanMask = '255.255.255.0';

  group('lanHostIpv4Problem', () {
    LanHostIpv4Problem? check(String ip, {bool withLan = true}) =>
        lanHostIpv4Problem(ip,
            lanIp: withLan ? lanIp : null,
            lanSubnetMask: withLan ? lanMask : null);

    test('a malformed address is a format problem', () {
      for (final ip in ['', 'abc', '192.168.1', '192.168.1.256', ' 1.2.3.4']) {
        expect(check(ip), LanHostIpv4Problem.format, reason: ip);
      }
    });

    test('0.0.0.0 and the other reserved ranges are reserved', () {
      for (final ip in [
        '0.0.0.0',
        '0.1.2.3',
        '127.0.0.1',
        '224.0.0.1',
        '255.255.255.255',
      ]) {
        expect(check(ip), LanHostIpv4Problem.reserved, reason: ip);
      }
    });

    test('outside the LAN, or the router itself, is not a LAN host', () {
      for (final ip in ['10.0.0.5', '192.168.2.10', '192.168.1.1']) {
        expect(check(ip), LanHostIpv4Problem.notLanHost, reason: ip);
      }
    });

    test('a LAN host has no problem', () {
      expect(check('192.168.1.50'), isNull);
    });

    test('the checks run in order: format, reserved, LAN', () {
      // 0.0.0.0 is outside the LAN too, but it is reported as reserved.
      expect(check('0.0.0.0'), LanHostIpv4Problem.reserved);
    });

    test('without a LAN, the LAN check does not run', () {
      expect(check('10.0.0.5', withLan: false), isNull);
      expect(check('0.0.0.0', withLan: false), LanHostIpv4Problem.reserved);
    });

    test('an empty or malformed LAN is no LAN, not one that refuses all', () {
      for (final (ip, mask) in [
        ('', ''),
        ('192.168.1.1', ''),
        ('', '255.255.255.0'),
        ('192.168.1', '255.255.255.0'),
        ('192.168.1.1', '255.0.255.0'),
      ]) {
        expect(lanHostIpv4Problem('10.0.0.5', lanIp: ip, lanSubnetMask: mask),
            isNull,
            reason: '$ip/$mask');
      }
    });
  });

  group('isUsableHostIpv4', () {
    test('a host address is usable', () {
      expect(isUsableHostIpv4('192.168.1.60'), isTrue);
      expect(isUsableHostIpv4('10.0.0.5'), isTrue);
    });

    test('0.0.0.0, a reserved range or a malformed value is not', () {
      for (final ip in ['0.0.0.0', '127.0.0.1', '', 'n/a']) {
        expect(isUsableHostIpv4(ip), isFalse, reason: ip);
      }
    });
  });

  group('hostIpv4OrEmpty', () {
    test('keeps a host address, trimmed', () {
      expect(hostIpv4OrEmpty('192.168.1.60'), '192.168.1.60');
      expect(hostIpv4OrEmpty(' 192.168.1.60 '), '192.168.1.60');
    });

    test('turns 0.0.0.0, absence and junk into no address', () {
      for (final raw in ['0.0.0.0', null, '', '   ', 'n/a', '127.0.0.1']) {
        expect(hostIpv4OrEmpty(raw), '', reason: '$raw');
      }
    });
  });

  group('LanHostIpv4Problem.messageKey', () {
    test('names the ARB key of each message', () {
      expect(LanHostIpv4Problem.format.messageKey, 'invalidIpv4Format');
      expect(LanHostIpv4Problem.reserved.messageKey, 'reservedIpNotAllowed');
      expect(LanHostIpv4Problem.notLanHost.messageKey, 'invalidIpAddress');
    });
  });

  group('Ipv4CidrRule', () {
    final rule = Ipv4CidrRule();

    test('accepts an IPv4 range with a prefix of 0 to 32', () {
      for (final v in [
        '10.0.0.0/8',
        '192.168.1.0/24',
        '203.0.113.7/32',
        '0.0.0.0/0'
      ]) {
        expect(rule.validate(v), isTrue, reason: v);
      }
    });

    test('refuses anything else', () {
      for (final v in [
        '',
        'abc',
        '10.0.0.0',
        '10.0.0.0/',
        '/8',
        '10.0.0.0/33',
        '10.0.0.0/-1',
        '10.0.0.0/08x',
        '10.0.0/8',
        '10.0.0.256/8',
        '10.0.0.0/8/8',
        ' 10.0.0.0/8',
        '10.0.0.0/8 ',
      ]) {
        expect(rule.validate(v), isFalse, reason: v);
      }
    });
  });
}
