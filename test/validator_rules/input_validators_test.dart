import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:test/test.dart';

void main() {
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
          true); // not violated in this case
      expect(results['IpAddressRule'], false);
    });

    test('validateDetail - onlyFailed', () {
      final validator = IpAddressValidator();
      final results = validator.validateDetail(
        '255.255.255.256',
        onlyFailed: true,
      );
      expect(results.length, equals(1));
      expect(results['IpAddressRule'], isFalse);
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
        'IpAddressNoReservedRule': true,
        'IpAddressRule': false,
      });
    });

    test('validateDetail - invalid IP format', () {
      final results = validator.validateDetail("invalid");
      expect(results, {
        'RequiredRule': true,
        'NoSurroundWhitespaceRule': true,
        'IpAddressHasFourOctetsRule': false,
        'IpAddressNoReservedRule': true,
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
      expect(results['IpAddressNoReservedRule'], true);
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
      expect(results['IpAddressNoReservedRule'], true);
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
      expect(results['IpAddressNoReservedRule'], true);
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
      expect(results['IpAddressNoReservedRule'], true);
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
