
import 'package:linksys_moab/util/validator.dart';
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
}
