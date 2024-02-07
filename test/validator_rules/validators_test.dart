import 'package:linksys_app/validator_rules/validators.dart';
import 'package:test/test.dart';

void main() {
  group('test email validator', () {
    test('general case', () async {
      final validator = EmailValidator();
      expect(validator.validate('austin.chang@linksys.com'), true);
    });
    test('email with +', () async {
      final validator = EmailValidator();
      expect(validator.validate('austin.chang+123@linksys.com'), true);
    });
    test('fail case #1', () async {
      final validator = EmailValidator();
      expect(validator.validate('austin.chang @linksys.com'), false);
    });
  });

  group('test complex password validator', () {
    test('success case', () async {
      final validator = ComplexPasswordValidator();
      expect(validator.validate('Linksys123!'), true);
    });
    test('all alphabets #1', () async {
      const input = 'ThisisaPassword';
      final validator = ComplexPasswordValidator();
      expect(validator.validate(input), false);
      final detail = validator.validateDetail(input, onlyFailed: true);
      expect(detail.length, 2);
    });
    test('all alphabets #2', () async {
      const input = 'alllowwercase';
      final validator = ComplexPasswordValidator();
      expect(validator.validate(input), false);
      final detail = validator.validateDetail(input, onlyFailed: true);
      expect(detail.length, 3);
    });
    test('all alphabets #3', () async {
      const input = 'ALLUPPERCASE';
      final validator = ComplexPasswordValidator();
      expect(validator.validate(input), false);
      final detail = validator.validateDetail(input, onlyFailed: true);
      expect(detail.length, 3);
    });
  });

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
  });

  group('IpAddressLocalValidator', () {
    test('router ip 192.168.1.1 and subnet mask 255.255.255.0', () async {
      final validator = IpAddressLocalValidator('192.168.1.1', '255.255.255.0');

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
      final validator = IpAddressLocalValidator('192.168.1.1', '255.255.0.0');

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
}
