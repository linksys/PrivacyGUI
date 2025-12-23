import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:test/test.dart';

void main() {
  group('IpAddressNoReservedRule', () {
    late IpAddressNoReservedRule rule;

    setUp(() {
      rule = IpAddressNoReservedRule();
    });

    test('should accept valid public IPv4 addresses', () {
      final validAddresses = [
        '192.168.1.1',
        '10.0.0.1',
        '172.16.0.1',
        '8.8.8.8',
        '203.0.113.1',
      ];

      for (final address in validAddresses) {
        expect(rule.validate(address), isTrue,
            reason: 'Should accept $address');
      }
    });

    test('should reject invalid IPv4 format', () {
      final invalidFormats = [
        '256.1.1.1', // Octet > 255
        '192.168.1', // Only 3 octets
        '192.168.1.1.1', // 5 octets
        '192.168.1.x', // Contains non-numeric
        '192.168.1.', // Trailing dot
        '.192.168.1.1', // Leading dot
        '', // Empty string
        ' ', // Whitespace
      ];

      for (final address in invalidFormats) {
        expect(rule.validate(address), isFalse,
            reason: 'Should reject invalid format: $address');
      }
    });

    test('should reject 0.0.0.0/8 (Unspecified/Current Network)', () {
      final zeroNetworkAddresses = [
        '0.0.0.0', // Network address
        '0.1.2.3', // Any address in 0.0.0.0/8
        '0.255.255.255', // Last in 0.0.0.0/8
      ];

      for (final address in zeroNetworkAddresses) {
        expect(rule.validate(address), isFalse,
            reason: 'Should reject 0.0.0.0/8 address: $address');
      }
    });

    test('should reject 127.0.0.0/8 (Loopback)', () {
      final loopbackAddresses = [
        '127.0.0.1', // Common loopback
        '127.1.2.3', // Any in 127.0.0.0/8
        '127.255.255.255', // Last in 127.0.0.0/8
      ];

      for (final address in loopbackAddresses) {
        expect(rule.validate(address), isFalse,
            reason: 'Should reject loopback address: $address');
      }
    });

    test('should reject 224.0.0.0/4 (Multicast)', () {
      final multicastAddresses = [
        '224.0.0.1', // Start of 224.0.0.0/4
        '230.1.2.3', // Any in 224.0.0.0/4
        '239.255.255.255', // End of 224.0.0.0/4
      ];

      for (final address in multicastAddresses) {
        expect(rule.validate(address), isFalse,
            reason: 'Should reject multicast address: $address');
      }
    });

    test('should reject 255.255.255.255 (Limited Broadcast)', () {
      expect(rule.validate('255.255.255.255'), isFalse,
          reason: 'Should reject limited broadcast address');
    });

    test('should reject non-IPv4 addresses', () {
      final nonIPv4Addresses = [
        '2001:0db8:85a3:0000:0000:8a2e:0370:7334', // IPv6
        'not.an.ip.address',
        '12345',
        '192.168.1.1.1',
      ];

      for (final address in nonIPv4Addresses) {
        expect(rule.validate(address), isFalse,
            reason: 'Should reject non-IPv4 address: $address');
      }
    });
  });

  group('Test ComplexPasswordValidator', () {
    test('validate method - strong password', () {
      final validator = ComplexPasswordValidator();
      const strongPassword = 'P@ssw0rd123!';
      expect(validator.validate(strongPassword), true);
    });

    test('validate method - weak password', () {
      final validator = ComplexPasswordValidator();
      const weakPassword = 'password123';
      expect(validator.validate(weakPassword), false);
    });

    test('validate method - empty password', () {
      final validator = ComplexPasswordValidator();
      expect(validator.validate(''), false);
    });

    test('validateDetail method - strong password', () {
      final validator = ComplexPasswordValidator();
      const strongPassword = 'P@ssw0rd123!';
      final validationDetails = validator.validateDetail(strongPassword);
      expect(validationDetails, {
        'RequiredRule': true,
        'LengthRule': true,
        'HybridCaseRule': true,
        'DigitalCheckRule': true,
        'SpecialCharCheckRule': true
      });
    });

    test('validateDetail method - weak password', () {
      final validator = ComplexPasswordValidator();
      const weakPassword = 'password123';
      final validationDetails = validator.validateDetail(weakPassword);
      expect(validationDetails, {
        'RequiredRule': true,
        'LengthRule': true,
        'HybridCaseRule': false,
        'DigitalCheckRule': true,
        'SpecialCharCheckRule': false
      });
    });

    test('validateDetail method - empty password', () {
      final validator = ComplexPasswordValidator();
      final validationDetails = validator.validateDetail('');
      expect(validationDetails, {
        'RequiredRule': false,
        'LengthRule': false,
        'HybridCaseRule': false,
        'DigitalCheckRule': false,
        'SpecialCharCheckRule': false
      });
    });
  });

  group('IPv6Rule', () {
    late IPv6Rule rule;

    setUp(() {
      rule = IPv6Rule();
    });

    test('should have the correct name property', () {
      expect(rule.name, 'IPv6Rule');
    });

    group('Valid IPv6 Addresses', () {
      test('should return true for a standard full IPv6 address', () {
        expect(
            rule.validate('2001:0db8:85a3:0000:0000:8a2e:0370:7334'), isTrue);
      });

      test('should return true for an address with compressed zeros (::)', () {
        expect(rule.validate('2001:0db8:85a3::8a2e:0370:7334'), isTrue);
      });

      test('should return true for an address starting with a double colon',
          () {
        expect(rule.validate('::1'), isTrue);
      });

      test('should return true for an address ending with a double colon', () {
        expect(rule.validate('2001:db8:a0b:12f0::'), isTrue);
      });

      test('should return true for an address with leading zeros in a group',
          () {
        expect(
            rule.validate('2001:0db8:0000:0000:0000:0000:0000:0001'), isTrue);
      });

      test('should return true for an address with uppercase letters', () {
        expect(rule.validate('2001:DB8:85A3::8A2E:370:7334'), isTrue);
      });

      test('should return true for a link-local address', () {
        expect(rule.validate('fe80::1ff:fe23:4567:890a'), isTrue);
      });

      test('should return true for a link-local address with a zone index', () {
        expect(rule.validate('fe80::1ff:fe23:4567:890a%eth0'), isTrue);
      });

      test('should return true for an IPv4-mapped IPv6 address', () {
        expect(rule.validate('::ffff:192.0.2.128'), isTrue);
      });

      test('should return true for an IPv4-embedded IPv6 address', () {
        expect(rule.validate('2001:db8::192.168.0.1'), isTrue);
      });
    });

    group('Invalid IPv6 Addresses', () {
      test('should return false for an address with more than 8 groups', () {
        expect(rule.validate('2001:0db8:85a3:0000:0000:8a2e:0370:7334:1234'),
            isFalse);
      });

      test('should return false for an address with invalid characters', () {
        expect(
            rule.validate('2001:0db8:85a3:000g:0000:8a2e:0370:7334'), isFalse);
      });

      test('should return false for a group with more than 4 hex digits', () {
        expect(
            rule.validate('2001:0db8:85a3:00000:0000:8a2e:0370:7334'), isFalse);
      });

      test('should return false for an address with more than one double colon',
          () {
        expect(rule.validate('2001::85a3::8a2e'), isFalse);
      });

      test('should return false for an incomplete address', () {
        expect(rule.validate('2001:0db8:85a3:0000:0000:8a2e:0370'), isFalse);
      });

      test('should return false for an address with triple colons', () {
        expect(rule.validate('2001:::8a2e'), isFalse);
      });

      test('should return false for an invalid IPv4 part in a mapped address',
          () {
        expect(rule.validate('::ffff:192.0.2.256'), isFalse);
      });

      test('should return false for an empty string', () {
        expect(rule.validate(''), isFalse);
      });

      test('should return false for a random string', () {
        expect(rule.validate('not an ip address'), isFalse);
      });

      test('should return false for an address ending with a colon', () {
        expect(rule.validate('2001:db8:a0b:12f0:'), isFalse);
      });

      test(
          'should return false for an address starting with a colon but not a double colon',
          () {
        expect(rule.validate(':2001:db8:a0b:12f0::'), isFalse);
      });

      test('should return false for the unspecified address (::)', () {
        // This is by implementation
        expect(rule.validate('::'), isFalse);
      });
    });
  });
  group('Test EmailValidator', () {
    test('validate method - valid email', () {
      final validator = EmailValidator();
      const validEmail = 'johndoe@example.com';
      expect(validator.validate(validEmail), true);
    });

    test('validate method - invalid email (missing domain)', () {
      final validator = EmailValidator();
      const invalidEmail = 'johndoe';
      expect(validator.validate(invalidEmail), false);
    });

    test('validate method - invalid email (missing local part)', () {
      final validator = EmailValidator();
      const invalidEmail = '@example.com';
      expect(validator.validate(invalidEmail), false);
    });

    test('validate method - empty email', () {
      final validator = EmailValidator();
      expect(validator.validate(''), false);
    });

    test('validateDetail method - valid email', () {
      final validator = EmailValidator();
      const validEmail = 'johndoe@example.com';
      final validationDetails = validator.validateDetail(validEmail);
      expect(validationDetails, {
        'RequiredRule': true,
        'EmailRule': true,
      });
    });

    test('validateDetail method - valid email with +', () {
      final validator = EmailValidator();
      const validEmail = 'johndoe+123@example.com';
      final validationDetails = validator.validateDetail(validEmail);
      expect(validationDetails, {
        'RequiredRule': true,
        'EmailRule': true,
      });
    });

    test('validateDetail method - invalid email (missing domain)', () {
      final validator = EmailValidator();
      const invalidEmail = 'johndoe';
      final validationDetails = validator.validateDetail(invalidEmail);
      expect(validationDetails, {
        'RequiredRule': true,
        'EmailRule': false,
      });
    });

    test('validateDetail method - invalid email (missing local part)', () {
      final validator = EmailValidator();
      const invalidEmail = '@example.com';
      final validationDetails = validator.validateDetail(invalidEmail);
      expect(validationDetails, {
        'RequiredRule': true,
        'EmailRule': false,
      });
    });

    test('validateDetail method - empty email', () {
      final validator = EmailValidator();
      final validationDetails = validator.validateDetail('');
      expect(validationDetails, {
        'RequiredRule': false,
        'EmailRule': false,
      });
    });
  });

  group('Test SubnetMaskValidator', () {
    test('validate method - valid subnet mask', () {
      final validator = SubnetMaskValidator();
      const validMask = '255.255.255.128'; // 24-bit subnet mask
      expect(validator.validate(validMask), true);
    });

    test('validate method - invalid subnet mask (missing octet)', () {
      final validator = SubnetMaskValidator();
      const invalidMask = '255.255.255';
      expect(validator.validate(invalidMask), false);
    });

    test('validate method - invalid subnet mask (invalid octet value)', () {
      final validator = SubnetMaskValidator();
      const invalidMask = '256.255.255.128';
      expect(validator.validate(invalidMask), false);
    });

    test('validate method - invalid subnet mask (out of range prefix length)',
        () {
      final validator = SubnetMaskValidator(min: 16, max: 24);
      const invalidMask1 = '255.0.0.0'; // 8-bit mask (below min)
      const invalidMask2 = '255.255.255.224'; // 27-bit mask (above max)
      expect(validator.validate(invalidMask1), false);
      expect(validator.validate(invalidMask2), false);
    });

    test('validate method - invalid subnet mask (leading whitespace)', () {
      final validator = SubnetMaskValidator();
      const invalidMask = ' 255.255.255.128';
      expect(validator.validate(invalidMask), false);
    });

    test('validate method - empty subnet mask', () {
      final validator = SubnetMaskValidator();
      expect(validator.validate(''), false);
    });

    test('validateDetail method - valid subnet mask', () {
      final validator = SubnetMaskValidator();
      const validMask = '255.255.255.128';
      final validationDetails = validator.validateDetail(validMask);
      expect(validationDetails, {
        'RequiredRule': true,
        'NoSurroundWhitespaceRule': true,
        'SubnetMaskRule': true,
        'IpAddressHasFourOctetsRule': true
      });
    });

    test('validateDetail method - invalid subnet mask (missing octet)', () {
      final validator = SubnetMaskValidator();
      const invalidMask = '255.255.255';
      final validationDetails = validator.validateDetail(invalidMask);
      expect(validationDetails, {
        'RequiredRule': true,
        'NoSurroundWhitespaceRule': true,
        'SubnetMaskRule': false, // Fails SubnetMaskRule
        'IpAddressHasFourOctetsRule': false // Fails IpAddressHasFourOctetsRule
      });
    });

    test('validate method - invalid subnet mask (leading whitespace)', () {
      final validator = SubnetMaskValidator();
      const invalidMask = ' 255.255.255.128';
      final validationDetails = validator.validateDetail(invalidMask);
      expect(validationDetails, {
        'RequiredRule': true,
        'NoSurroundWhitespaceRule': false, // Fails NoSurroundWhitespaceRule
        'SubnetMaskRule': true,
        'IpAddressHasFourOctetsRule': true
      });
    });

    test('validateDetail method - empty subnet mask', () {
      final validator = SubnetMaskValidator();
      final validationDetails = validator.validateDetail('');
      expect(validationDetails, {
        'RequiredRule': false,
        'NoSurroundWhitespaceRule':
            true, // Still passes NoSurroundWhitespaceRule
        'SubnetMaskRule': false,
        'IpAddressHasFourOctetsRule': false
      });
    });
  });

  group('Test IpAddressValidator', () {
    test('validate - valid IP address', () {
      final validator = IpAddressValidator();
      expect(validator.validate('192.168.1.1'), true);
      expect(validator.validate('10.0.0.1'), true);
      expect(validator.validate('255.255.255.254'), true);
    });

    test('validate - empty IP address', () {
      final validator = IpAddressValidator();
      expect(validator.validate(''), false);
    });

    test('validate - invalid IP address', () {
      final validator = IpAddressValidator();
      expect(validator.validate('invalid'), false);
      expect(validator.validate(''), false);
      expect(validator.validate('1.2.3.4.5'), false);
      expect(validator.validate('256.256.256.256'), false);
      expect(validator.validate('255.255.255.255'), false);
      expect(validator.validate('0.0.0.0'), false);
      expect(validator.validate('127.0.0.1'), false);
    });

    test('validateDetail - valid IP address', () {
      final validator = IpAddressValidator();
      final results = validator.validateDetail('192.168.1.1');
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], true);
      expect(results['IpAddressNoReservedRule'], true);
      expect(results['IpAddressRule'], true);
    });

    test('validateDetail - invalid IP address', () {
      final validator = IpAddressValidator();
      final results = validator.validateDetail('invalid');
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], false);
      expect(results['IpAddressNoReservedRule'],
          false); // not violated in this case
      expect(results['IpAddressRule'], false);
    });

    test('validateDetail - onlyFailed', () {
      final validator = IpAddressValidator();
      final results = validator.validateDetail(
        '255.255.255.256',
        onlyFailed: true,
      );
      expect(results.length, equals(2));
      expect(results['IpAddressRule'], isFalse);
      expect(results['IpAddressNoReservedRule'], isFalse);
    });
  });

  group('Test IpAddressRequiredValidator', () {
    late IpAddressRequiredValidator validator;

    setUp(() {
      validator = IpAddressRequiredValidator();
    });

    test('validate - valid IP address', () {
      expect(validator.validate("192.168.1.1"), true);
      expect(validator.validate("10.0.0.1"), true);
    });

    test('validate - empty string', () {
      expect(validator.validate(''), false);
    });

    test('validate - string with whitespace', () {
      expect(validator.validate(" 192.168.1.1 "), false);
    });

    test('validate - invalid IP format', () {
      expect(validator.validate("invalid"), false);
      expect(validator.validate("192.168.1"), false);
      expect(validator.validate("256.256.256.256"), false);
    });

    test('validate - reserved IP addresses', () {
      expect(validator.validate("0.0.0.0"), false);
      expect(validator.validate("127.0.0.1"), false);
      expect(validator.validate("255.255.255.255"), false);
    });

    test('validateDetail - empty string', () {
      final results = validator.validateDetail('');
      expect(results, {
        'RequiredRule': false,
        'NoSurroundWhitespaceRule': true,
        'IpAddressHasFourOctetsRule': false,
        'IpAddressNoReservedRule': false,
        'IpAddressRule': false,
      });
    });

    test('validateDetail - invalid IP format', () {
      final results = validator.validateDetail("invalid");
      expect(results, {
        'RequiredRule': true,
        'NoSurroundWhitespaceRule': true,
        'IpAddressHasFourOctetsRule': false,
        'IpAddressNoReservedRule': false,
        'IpAddressRule': false,
      });
    });

    test('validateDetail - reserved IP address', () {
      final results = validator.validateDetail("0.0.0.0");
      expect(results, {
        'RequiredRule': true,
        'NoSurroundWhitespaceRule': true,
        'IpAddressHasFourOctetsRule': true,
        'IpAddressNoReservedRule': false,
        'IpAddressRule': true,
      });
    });

    test('validateDetail - valid IP address', () {
      final results = validator.validateDetail("192.168.1.1");
      expect(results, {
        'RequiredRule': true,
        'NoSurroundWhitespaceRule': true,
        'IpAddressHasFourOctetsRule': true,
        'IpAddressNoReservedRule': true,
        'IpAddressRule': true,
      });
    });

    test('validateDetail - onlyFailed', () {
      final results = validator.validateDetail("127.0.0.1", onlyFailed: true);
      expect(results.length, 1);
      expect(results['IpAddressNoReservedRule'], false);
    });
  });

  group('Test IpAddressAsLocalIpValidator', () {
    late IpAddressAsLocalIpValidator validator;
    const String routerIp = "192.168.1.1";
    const String subnetMask = "255.255.255.0";

    setUp(() {
      validator = IpAddressAsLocalIpValidator(routerIp, subnetMask);
    });

    test('validate - empty string', () {
      expect(validator.validate(''), false);
    });

    test('validate - string with whitespace', () {
      expect(validator.validate(" 192.168.1.2 "), false);
    });

    test('validate - invalid IP format', () {
      expect(validator.validate("invalid"), false);
      expect(validator.validate("192.168.1"), false);
      expect(validator.validate("256.256.256.256"), false);
    });

    test('validate - reserved IP addresses', () {
      expect(validator.validate("0.0.0.0"), false);
      expect(validator.validate("127.0.0.1"), false);
      expect(validator.validate("255.255.255.255"), false);
    });

    test('validate - same as router IP', () {
      expect(validator.validate(routerIp), false);
    });

    test('validate - valid IP on the same subnet', () {
      expect(validator.validate("192.168.1.2"), true);
      expect(validator.validate("192.168.1.254"), true);
    });

    test('validate - invalid IP on a different subnet', () {
      expect(validator.validate("10.0.0.1"), false);
    });

    test('validateDetail - empty string', () {
      final results = validator.validateDetail('');
      expect(results.length, 7);
      expect(results['RequiredRule'], false);
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], false);
      expect(results['IpAddressNoReservedRule'], false);
      expect(results['IpAddressRule'], false);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], false);
      expect(results['NotRouterIpAddressRule'], true);
    });

    test('validateDetail - invalid IP format', () {
      final results = validator.validateDetail('invalid');
      expect(results.length, 7);
      expect(results['RequiredRule'], true);
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], false);
      expect(results['IpAddressNoReservedRule'], false);
      expect(results['IpAddressRule'], false);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], false);
      expect(results['NotRouterIpAddressRule'], true);
    });

    test('validateDetail - reserved IP address', () {
      final results = validator.validateDetail("0.0.0.0");
      expect(results.length, 7);
      expect(results['RequiredRule'], true);
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], true);
      expect(results['IpAddressNoReservedRule'], false);
      expect(results['IpAddressRule'], true);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], false);
      expect(results['NotRouterIpAddressRule'], true);
    });

    test('validateDetail - same as router IP', () {
      final results = validator.validateDetail(routerIp);
      expect(results.length, 7);
      expect(results['RequiredRule'], true);
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], true);
      expect(results['IpAddressNoReservedRule'], true);
      expect(results['IpAddressRule'], true);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], true);
      expect(results['NotRouterIpAddressRule'], false);
    });

    test('validateDetail - valid IP on the same subnet', () {
      final results = validator.validateDetail("192.168.1.2", onlyFailed: true);
      expect(results.isEmpty, true);
    });

    test('validateDetail - invalid IP on a different subnet', () {
      final results = validator.validateDetail("10.0.0.1", onlyFailed: true);
      expect(results.length, 1);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], false);
    });
  });

  group('Test IpAddressAsNewRouterIpValidator', () {
    late IpAddressAsNewRouterIpValidator validator;
    const String routerIp = "192.168.1.1";
    const String subnetMask = "255.255.255.0";

    setUp(() {
      validator = IpAddressAsNewRouterIpValidator(routerIp, subnetMask);
    });

    test('validate - empty string', () {
      expect(validator.validate(''), false);
    });

    test('validate - string with whitespace', () {
      expect(validator.validate(" 192.168.1.2 "), false);
    });

    test('validate - invalid IP format', () {
      expect(validator.validate("invalid"), false);
      expect(validator.validate("192.168.1"), false);
      expect(validator.validate("256.256.256.256"), false);
    });

    test('validate - reserved IP addresses', () {
      expect(validator.validate("0.0.0.0"), false);
      expect(validator.validate("127.0.0.1"), false);
      expect(validator.validate("255.255.255.255"), false);
    });

    test('validate - same as current router IP', () {
      expect(validator.validate(routerIp), true);
    });

    test('validate - IP on the same subnet', () {
      expect(validator.validate("192.168.1.2"), true);
      expect(validator.validate("192.168.1.254"), true);
    });

    test('validate - valid IP on a different subnet', () {
      expect(validator.validate("10.0.0.1"), false);
      expect(validator.validate("172.16.0.2"), false);
    });

    test('validateDetail - empty string', () {
      final results = validator.validateDetail('');
      expect(results.length, 6);
      expect(results['RequiredRule'], false);
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], false);
      expect(results['IpAddressNoReservedRule'], false);
      expect(results['IpAddressRule'], false);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], false);
    });

    test('validateDetail - invalid IP format', () {
      final results = validator.validateDetail('invalid');
      expect(results.length, 6);
      expect(results['RequiredRule'], true);
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], false);
      expect(results['IpAddressNoReservedRule'], false);
      expect(results['IpAddressRule'], false);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], false);
    });

    test('validateDetail - reserved IP address', () {
      final results = validator.validateDetail("0.0.0.0");
      expect(results.length, 6);
      expect(results['RequiredRule'], true);
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], true);
      expect(results['IpAddressNoReservedRule'], false);
      expect(results['IpAddressRule'], true);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], false);
    });

    test('validateDetail - same as current router IP', () {
      final results = validator.validateDetail(routerIp);
      expect(results.length, 6);
      expect(results['RequiredRule'], true);
      expect(results['NoSurroundWhitespaceRule'], true);
      expect(results['IpAddressHasFourOctetsRule'], true);
      expect(results['IpAddressNoReservedRule'], true);
      expect(results['IpAddressRule'], true);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], true);
    });

    test('validateDetail - IP on the same subnet', () {
      final results = validator.validateDetail('192.168.1.2', onlyFailed: true);
      expect(results.isEmpty, true);
    });

    test('validateDetail - valid IP on a different subnet', () {
      final results = validator.validateDetail('10.0.0.1', onlyFailed: true);
      expect(
          results['HostValidForGivenRouterIPAddressAndSubnetMaskRule'], false);
    });
  });

  group('Test MaxUsersValidator', () {
    late MaxUsersValidator validator;
    const int maxUsers = 10;

    setUp(() {
      validator = MaxUsersValidator(maxUsers);
    });

    test('validate - empty string', () {
      expect(validator.validate(''), false);
    });

    test('validate - string with characters', () {
      expect(validator.validate("a"), false);
    });

    test('validate - negative number', () {
      expect(validator.validate("-1"), false);
    });

    test('validate - zero number', () {
      expect(validator.validate("0"), false);
    });

    test('validate - exceeding max users', () {
      expect(validator.validate("${maxUsers + 1}"), false);
    });

    test('validate - valid numbers', () {
      expect(validator.validate("1"), true);
      expect(validator.validate(maxUsers.toString()), true);
    });

    test('validateDetail - empty string', () {
      final results = validator.validateDetail('');
      expect(results.length, 2);
      expect(results['RequiredRule'], false);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - string with characters', () {
      final results = validator.validateDetail('a');
      expect(results.length, 2);
      expect(results['RequiredRule'], true);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - negative number', () {
      final results = validator.validateDetail('-1');
      expect(results.length, 2);
      expect(results['RequiredRule'], true);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - zero number', () {
      final results = validator.validateDetail('0');
      expect(results.length, 2);
      expect(results['RequiredRule'], true);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - exceeding max users', () {
      final results = validator.validateDetail("${maxUsers + 1}");
      expect(results.length, 2);
      expect(results['RequiredRule'], true);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - valid numbers', () {
      final results = validator.validateDetail(
        "1",
        onlyFailed: true,
      );
      expect(results.isEmpty, true);

      final results2 = validator.validateDetail(
        maxUsers.toString(),
        onlyFailed: true,
      );
      expect(results2.isEmpty, true);
    });
  });

  group('Test DhcpClientLeaseTimeValidator', () {
    late DhcpClientLeaseTimeValidator validator;
    const int minLeaseTime = 60;
    const int maxLeaseTime = 86400;

    setUp(() {
      validator = DhcpClientLeaseTimeValidator(minLeaseTime, maxLeaseTime);
    });

    test('validate - empty string', () {
      expect(validator.validate(''), false);
    });

    test('validate - string with characters', () {
      expect(validator.validate('abc'), false);
    });

    test('validate - negative number', () {
      expect(validator.validate('-1'), false);
    });

    test('validate - number less than min lease time', () {
      expect(validator.validate('${minLeaseTime - 1}'), false);
    });

    test('validate - number exceeding max lease time', () {
      expect(validator.validate('${maxLeaseTime + 1}'), false);
    });

    test('validate - valid numbers', () {
      expect(validator.validate(minLeaseTime.toString()), true);
      expect(validator.validate(maxLeaseTime.toString()), true);
      expect(validator.validate('3600'), true); // One hour
    });

    test('validateDetail - empty string', () {
      final results = validator.validateDetail('');
      expect(results.length, 2);
      expect(results['RequiredRule'], false);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - string with characters', () {
      final results = validator.validateDetail('abc');
      expect(results.length, 2);
      expect(results['RequiredRule'], true);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - negative number', () {
      final results = validator.validateDetail('-1');
      expect(results.length, 2);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - number less than min lease time', () {
      final results = validator.validateDetail('${minLeaseTime - 1}');
      expect(results.length, 2);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - number exceeding max lease time', () {
      final results = validator.validateDetail('${maxLeaseTime + 1}');
      expect(results.length, 2);
      expect(results['IntegerRule'], false);
    });

    test('validateDetail - valid numbers', () {
      final results = validator.validateDetail(
        minLeaseTime.toString(),
        onlyFailed: true,
      );
      expect(results.isEmpty, true);

      final results2 = validator.validateDetail(
        maxLeaseTime.toString(),
        onlyFailed: true,
      );
      expect(results2.isEmpty, true);

      final results3 = validator.validateDetail(
        '3600', // One hour
        onlyFailed: true,
      );
      expect(results3.isEmpty, true);
    });
  });

  group('MAC address test', () {
    test('test reserved MAC address - 11:11:11:11:11:11', () {
      final rule = MACAddressWithReservedRule();
      final isValid = rule.validate('11:11:11:11:11:11');

      expect(isValid, isFalse);
    });

    test('test reserved MAC address - FF:FF:FF:FF:FF:FF', () {
      final rule = MACAddressWithReservedRule();
      final isValid = rule.validate('FF:FF:FF:FF:FF:FF');

      expect(isValid, isFalse);
    });

    test('test reserved MAC address - 01:00:5E:00:00:01', () {
      final rule = MACAddressWithReservedRule();
      final isValid = rule.validate('01:00:5E:00:00:01');

      expect(isValid, isFalse);
    });

    test('test valid MAC address - 66:DF:21:26:32:85', () {
      final rule = MACAddressWithReservedRule();
      final isValid = rule.validate('66:DF:21:26:32:85');

      expect(isValid, isTrue);
    });

    test('test valid MAC address - 58:A0:23:9B:78:64', () {
      final rule = MACAddressWithReservedRule();
      final isValid = rule.validate('58:A0:23:9B:78:64');

      expect(isValid, isTrue);
    });
  });

  // Test result tracking
  final Map<String, Map<String, dynamic>> _testResults = {};

  // Helper to track test results
  void _trackTestResult(String group, String testName, bool passed,
      String address, String? expectedType,
      {String? description}) {
    if (!_testResults.containsKey(group)) {
      _testResults[group] = {
        'total': 0,
        'passed': 0,
        'failed': 0,
        'details': <Map<String, dynamic>>[],
      };
    }

    final result = {
      'testName': testName,
      'address': address,
      'passed': passed,
      'expectedType': expectedType,
      if (description != null) 'description': description,
    };

    _testResults[group]!['total']++;
    if (passed) {
      _testResults[group]!['passed']++;
    } else {
      _testResults[group]!['failed']++;
    }
    _testResults[group]!['details'].add(result);
  }

  // Print test summary
  void _printTestSummary() {
    print('\n\n=== IPv6 Validation Test Summary ===\n');

    int totalTests = 0;
    int totalPassed = 0;
    int totalFailed = 0;

    _testResults.forEach((group, data) {
      print('\n=== $group ===');
      print(
          'Total: ${data['total']} | Passed: ${data['passed']} | Failed: ${data['failed']}');

      // Print failed tests if any
      final failedTests =
          (data['details'] as List).where((t) => !t['passed']).toList();
      if (failedTests.isNotEmpty) {
        print('\nFailed Tests:');
        for (var test in failedTests) {
          print('  - ${test['testName']}');
          print('    Address: ${test['address']}');
          print('    Expected: ${test['expectedType']}');
          if (test['description'] != null) {
            print('    Description: ${test['description']}');
          }
        }
      }

      // Print all test cases with descriptions
      print('\nTest Cases:');
      for (var test in data['details']) {
        final status = test['passed'] ? '✓' : '✗';
        print('  $status ${test['testName']}');
        print('    Address: ${test['address']}');
        print('    Expected: ${test['expectedType']}');
        if (test['description'] != null) {
          print('    Description: ${test['description']}');
        }
        print('    Status: ${test['passed'] ? 'PASSED' : 'FAILED'}');
      }

      totalTests += data['total'] as int;
      totalPassed += data['passed'] as int;
      totalFailed += data['failed'] as int;
    });

    print('\n=== Overall Summary ===');
    print('Total Tests: $totalTests');
    print('Passed: $totalPassed');
    print('Failed: $totalFailed');
    print(
        'Success Rate: ${((totalPassed / totalTests) * 100).toStringAsFixed(2)}%');
    print('\nTest completed at: ${DateTime.now()}');
  }

  group('IPv6WithReservedRule', () {
    // Add teardown to print summary after all tests
    tearDownAll(() {
      _printTestSummary();
    });

    // Helper function to run multiple invalid test cases
    void _runInvalidTestCases(List<String> addresses, String description) {
      for (var address in addresses) {
        test('should reject $description: $address', () {
          final rule = IPv6WithReservedRule();
          final isValid = rule.validate(address);
          final testName = 'Reject $description: $address';
          final passed = isValid == false;
          _trackTestResult('Invalid Address: $description', testName, passed,
              address, 'Should be rejected as $description',
              description: description);
          expect(isValid, isFalse,
              reason:
                  'Expected $address to be rejected as it is a $description address');
        });
      }
    }

    // Test valid global unicast IPv6 addresses (2000::/3)
    group('valid global unicast IPv6 addresses (2000::/3)', () {
      final testCases = [
        // Standard global unicast addresses
        '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
        '2001:db8::1',
        '2a02:c00::1',
        '3000::1',
        '2400:cb00:2049:1::a29f:1806',
        '2606:4700:4700::1111',
        '2a03:2880:f12f:83:face:b00c::25de',
        // Edge cases within global unicast range
        '2000::1', // Start of 2000::/3
        '3fff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', // End of 2000::/3
        // Various valid formats
        '2001:db8:1234:5678:9abc:def0:1234:5678',
        '2001:db8:1234:5678:9abc:def0:1234::',
        '2001:db8:1234:5678:9abc:def0::',
        '2001:db8:1234:5678:9abc::',
        '2001:db8:1234:5678::',
        '2001:db8:1234::',
        '2001:db8::',
      ];

      for (var address in testCases) {
        test('should accept valid global unicast address: $address', () {
          final rule = IPv6WithReservedRule();
          final isValid = rule.validate(address);
          final testName = 'Valid Global Unicast: $address';
          final passed = isValid == true;
          _trackTestResult('Valid Global Unicast', testName, passed, address,
              'Valid Global Unicast',
              description:
                  'Should be accepted as a valid global unicast IPv6 address');
          expect(isValid, isTrue,
              reason:
                  'Expected $address to be a valid global unicast IPv6 address');
        });
      }
    });

    // Test invalid IPv6 addresses that violate the rules
    group('invalid IPv6 addresses - reserved/special ranges', () {
      // Loopback addresses (::1/128)
      group('loopback addresses', () {
        final testCases = [
          '::1',
          '0:0:0:0:0:0:0:1',
        ];
        _runInvalidTestCases(testCases, 'loopback');
      });

      // Link-local addresses (fe80::/10)
      group('link-local addresses (fe80::/10)', () {
        final testCases = [
          'fe80::1',
          'fe80::1234:5678',
          'fe80:0000:0000:0000:0000:0000:0000:0001',
          'febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff', // End of fe80::/10
        ];
        _runInvalidTestCases(testCases, 'link-local');
      });

      // Unique Local Addresses (fc00::/7)
      group('unique local addresses (fc00::/7)', () {
        final testCases = [
          'fc00::1',
          'fd00::1',
          'fd12:3456:789a:1::1',
          'fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', // End of fd00::/8
        ];
        _runInvalidTestCases(testCases, 'ULA');
      });

      // Multicast addresses (ff00::/8)
      group('multicast addresses (ff00::/8)', () {
        final testCases = [
          'ff00::1',
          'ff02::1',
          'ff0f:ffff:ffff:ffff:ffff:ffff:ffff:ffff', // End of ff00::/8
        ];
        _runInvalidTestCases(testCases, 'multicast');
      });

      // Unspecified/undefined addresses (::/128 and 0::/96)
      group('unspecified/undefined addresses', () {
        final testCases = [
          '::',
          '0:0:0:0:0:0:0:0',
          '0:0:0:0:0:0:0:0',
          '::0',
          '0::0',
          '0:0:0:0:0:0:0:0:0',
        ];
        _runInvalidTestCases(testCases, 'unspecified/undefined');
      });

      // Unallocated address space (e.g., ffff::/16)
      group('unallocated/reserved address space', () {
        final testCases = [
          'ffff::1',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
          '100::',
          '1::',
          '1::1',
          // 3FFE::/16 (6bone) - deprecated IPv6 testing network
          '3ffe::1',
          '3ffe:0101:0101:0101:0101:0101:0101:0101',
          '3ffe:ffff:ffff:ffff:ffff:ffff:ffff:ffff', // End of 3ffe::/16 (6bone)
          // Other reserved ranges
          '5f00::',
          '5fff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
        ];
        _runInvalidTestCases(testCases, 'unallocated/reserved');
      });

      // IPv4-mapped and IPv4-compatible addresses
      group('IPv4-mapped and IPv4-compatible addresses', () {
        final testCases = [
          '::ffff:192.168.1.1',
          '::192.168.1.1',
          '::ffff:0:192.168.1.1',
          '::ffff:c0a8:0101', // Same as ::ffff:192.168.1.1
        ];
        _runInvalidTestCases(testCases, 'IPv4-mapped/compatible');
      });

      // Invalid formats and non-IPv6 addresses
      group('invalid formats and non-IPv6 addresses', () {
        final testCases = [
          '',
          'not_an_ipv6',
          '192.168.1.1',
          '2001:db8::1/64',
          '2001:db8::1:g',
          '2001:db8::1::1', // Double ::
          '2001:db8:1:2:3:4:5:6:7', // Too many segments
          '2001:db8:1:2:3', // Too few segments
        ];
        _runInvalidTestCases(testCases, 'invalid format');
      });
    });

    test('test valid IPv6 address - 2001:db8::', () {
      final rule = IPv6WithReservedRule();
      final isValid = rule.validate('2001:db8::');

      expect(isValid, isTrue);
    });

    test('test valid IPv6 address - 2001:db8::1', () {
      final rule = IPv6WithReservedRule();
      final isValid = rule.validate('2001:db8::1');

      expect(isValid, isTrue);
    });
  });

/*
  group('IpAddressLocalTestSubnetMaskValidator', () {
    test('router ip 192.168.1.1 and subnet mask 255.255.255.0', () async {
      final validator =
          IpAddressLocalTestSubnetMaskValidator('192.168.1.1', '255.255.255.0');
      for (int i = 1; i < 256; i++) {
        expect(validator.validate('192.168.1.$i'), true);
      }
      for (int i = 1; i < 256; i++) {
        expect(validator.validate('192.168.2.$i'), false);
      }

      expect(validator.validate(''), false);
      expect(validator.validate('abc'), false);
      expect(validator.validate('192.1'), false);
      expect(validator.validate('192.166.1.1'), false);
      expect(validator.validate('192.168.21.1'), false);
      expect(validator.validate('12.168.21.1'), false);
      expect(validator.validate('192.18.21.1'), false);
    });

    test('router ip 192.168.1.1 and subnet mask 255.255.0.0', () async {
      final validator =
          IpAddressLocalTestSubnetMaskValidator('192.168.1.1', '255.255.0.0');
      for (int i = 1; i < 256; i++) {
        expect(validator.validate('192.168.1.$i'), true);
      }
      for (int i = 1; i < 256; i++) {
        expect(validator.validate('192.168.2.$i'), true);
      }
      for (int i = 1; i < 256; i++) {
        for (int j = 1; j < 256; j++) {
          expect(validator.validate('192.168.$i.$j'), true);
        }
      }

      expect(validator.validate(''), false);
      expect(validator.validate('abc'), false);
      expect(validator.validate('192.1'), false);
      expect(validator.validate('192.166.1.1'), false);
      expect(validator.validate('192.168.21.1'), true);
      expect(validator.validate('12.168.21.1'), false);
      expect(validator.validate('192.18.21.1'), false);
    });

    test('router ip 192.168.1.1 and subnet mask 255.255.255.128', () async {
      final validator = IpAddressLocalTestSubnetMaskValidator(
          '192.168.1.1', '255.255.255.128');
      expect(validator.validate('192.168.1.124'), true);
      expect(validator.validate('192.168.1.244'), false);
      for (int i = 1; i < 256; i++) {
        expect(validator.validate('192.168.1.$i'), i < 128 ? true : false);
      }
    });
  });

  group('IpAddressAsLocalIpValidator', () {
    test('router ip 192.168.1.1 and subnet mask 255.255.255.0', () async {
      final validator = IpAddressAsLocalIpValidator('192.168.1.1', '255.255.255.0');

      expect(validator.validate('192.168.1.1'), false);

      for (int i = 2; i < 256; i++) {
        expect(validator.validate('192.168.1.$i'), true);
      }
      for (int i = 1; i < 256; i++) {
        expect(validator.validate('192.168.2.$i'), false);
      }

      expect(validator.validate(''), false);
      expect(validator.validate('abc'), false);
      expect(validator.validate('192.1'), false);
      expect(validator.validate('192.166.1.1'), false);
      expect(validator.validate('192.168.21.1'), false);
      expect(validator.validate('12.168.21.1'), false);
      expect(validator.validate('192.18.21.1'), false);
    });

    test('router ip 192.168.1.1 and subnet mask 255.255.0.0', () async {
      final validator = IpAddressAsLocalIpValidator('192.168.1.1', '255.255.0.0');

      expect(validator.validate('192.168.1.1'), false);

      for (int i = 2; i < 256; i++) {
        expect(validator.validate('192.168.1.$i'), true);
      }
      for (int i = 1; i < 256; i++) {
        expect(validator.validate('192.168.2.$i'), true);
      }
      for (int i = 1; i < 256; i++) {
        for (int j = 1; j < 256; j++) {
          expect(validator.validate('192.168.$i.$j'),
              i == 1 && j == 1 ? false : true);
        }
      }

      expect(validator.validate(''), false);
      expect(validator.validate('abc'), false);
      expect(validator.validate('192.1'), false);
      expect(validator.validate('192.166.1.1'), false);
      expect(validator.validate('192.168.21.1'), true);
      expect(validator.validate('12.168.21.1'), false);
      expect(validator.validate('192.18.21.1'), false);
    });
  });
  */
}
