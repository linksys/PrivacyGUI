import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';

import '../../../mocks/test_data/ddns_test_data.dart';

void main() {
  // 1.0's `util.isValidHostName`, which the router's updater applies as
  // `ddns_valid_hostname` (feed_usp patch 9000, read on 2.0.4.26110110).
  group('isValidDdnsHostname', () {
    for (final name in [
      'home.example.net',
      'myhost',
      'a',
      '123.example.com',
      'my-host.no-ip.org',
      'A1.B2.C3',
      '${'a' * 63}.com',
    ]) {
      test('accepts "$name"', () => expect(isValidDdnsHostname(name), isTrue));
    }

    for (final (name, why) in [
      ('', 'empty'),
      ('.example.com', 'a leading dot is an empty label'),
      ('example.com.', 'a trailing dot is an empty label'),
      ('example..com', 'a doubled dot is an empty label'),
      ('-host.example.com', 'a label starting with -'),
      ('host-.example.com', 'a label ending with -'),
      ('my_host.example.com', '_ is not a host name character'),
      ('my host.example.com', 'a space'),
      ('host/example', '/'),
      ('${'a' * 64}.com', 'a label of 64 characters'),
    ]) {
      test('refuses "$name" ($why)',
          () => expect(isValidDdnsHostname(name), isFalse));
    }

    test('accepts 255 characters and refuses 256', () {
      // Four labels of 63 and a dot between each: 255 characters.
      final longest = List.filled(4, 'a' * 63).join('.');
      expect(longest.length, 255);
      expect(isValidDdnsHostname(longest), isTrue);
      expect(isValidDdnsHostname('$longest' 'a'), isFalse);
    });
  });

  group('isValidDdnsCredential', () {
    test('refuses an empty value', () {
      expect(isValidDdnsCredential(''), isFalse);
    });

    test('accepts 256 bytes and refuses 257', () {
      expect(isValidDdnsCredential('a' * 256), isTrue);
      expect(isValidDdnsCredential('a' * 257), isFalse);
    });

    test('counts UTF-8 bytes, not characters', () {
      // The stricter reading of the setter's 256 (see isValidDdnsCredential):
      // 86 three-byte characters are 258 bytes, though only 86 characters.
      expect(isValidDdnsCredential('密' * 85), isTrue);
      expect(isValidDdnsCredential('密' * 86), isFalse);
    });

    test('keeps quotes and backslashes, which the router stores intact', () {
      expect(isValidDdnsCredential(r'pa"ss\'), isTrue);
    });
  });

  group('invalidDdnsFields', () {
    test('"Disabled" checks nothing', () {
      expect(invalidDdnsFields(DdnsTestData.settings()), isEmpty);
    });

    test(
        'a provider with every field empty and no stored account fails all '
        'three', () {
      final settings =
          DdnsTestData.settings(providerPath: DdnsTestData.noIpPath);

      expect(invalidDdnsFields(settings),
          {DdnsField.username, DdnsField.password, DdnsField.hostname});
    });

    test('an empty password is allowed when the router holds an account', () {
      expect(invalidDdnsFields(DdnsTestData.configuredSettings()), isEmpty);
    });

    test('a typed password is checked even with an account stored', () {
      final settings = DdnsTestData.configuredSettings(password: 'x' * 257);

      expect(invalidDdnsFields(settings), {DdnsField.password});
    });

    test('a badly formed host name fails only the host name', () {
      final settings =
          DdnsTestData.configuredSettings(hostname: 'my_host.example.net');

      expect(invalidDdnsFields(settings), {DdnsField.hostname});
    });

    test('an emptied user name fails it, and then needs a password', () {
      final settings = DdnsTestData.configuredSettings(username: '');

      expect(invalidDdnsFields(settings),
          {DdnsField.username, DdnsField.password});
    });

    // The stored password belongs to the stored account. Kept for a new
    // provider or a new user name, the router would send it for an account
    // it does not belong to.
    test('a new provider needs its password typed', () {
      final settings = DdnsTestData.configuredSettings(
          providerPath: DdnsTestData.dynDnsPath);

      expect(invalidDdnsFields(settings), {DdnsField.password});
    });

    test('a new user name needs its password typed', () {
      final settings =
          DdnsTestData.configuredSettings(username: 'bob@example.com');

      expect(invalidDdnsFields(settings), {DdnsField.password});
      expect(
          invalidDdnsFields(DdnsTestData.configuredSettings(
              username: 'bob@example.com', password: 'secret')),
          isEmpty);
    });

    test('a new host name on the stored account keeps the stored password', () {
      final settings =
          DdnsTestData.configuredSettings(hostname: 'other.example.net');

      expect(invalidDdnsFields(settings), isEmpty);
    });
  });

  // ddns-scripts' `send_update` check with `upd_privateip` 0, as shipped.
  group('isPrivateIpv4Address', () {
    for (final address in [
      '0.1.2.3',
      '10.0.0.1',
      '100.64.0.1',
      '100.127.255.254',
      '127.0.0.1',
      '169.254.10.20',
      '172.16.0.1',
      '172.31.255.254',
      '192.168.1.1',
    ]) {
      test('$address is private',
          () => expect(isPrivateIpv4Address(address), isTrue));
    }

    for (final address in [
      '8.8.8.8',
      '100.63.255.255',
      '100.128.0.1',
      '172.15.0.1',
      '172.32.0.1',
      '192.169.0.1',
      '203.0.113.7',
    ]) {
      test('$address is public',
          () => expect(isPrivateIpv4Address(address), isFalse));
    }

    for (final value in ['', 'not an address', '10.0.0', '2001:db8::1']) {
      test('"$value" is not an IPv4 address, so not private',
          () => expect(isPrivateIpv4Address(value), isFalse));
    }
  });
}
