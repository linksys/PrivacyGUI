import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspValue', () {
    test('should be instantiated with correct value and type', () {
      final stringValue = UspValue('hello', UspValueType.string);
      expect(stringValue.value, 'hello');
      expect(stringValue.type, UspValueType.string);

      final intValue = UspValue(123, UspValueType.int);
      expect(intValue.value, 123);
      expect(intValue.type, UspValueType.int);

      final boolValue = UspValue(true, UspValueType.boolean);
      expect(boolValue.value, true);
      expect(boolValue.type, UspValueType.boolean);
    });

    test(
      'equality operator should return true for UspValue objects with same value and type',
      () {
        final value1 = UspValue('test', UspValueType.string);
        final value2 = UspValue('test', UspValueType.string);
        expect(value1 == value2, isTrue);
      },
    );

    test(
      'equality operator should return false for UspValue objects with different values',
      () {
        final value1 = UspValue('test1', UspValueType.string);
        final value2 = UspValue('test2', UspValueType.string);
        expect(value1 == value2, isFalse);
      },
    );

    test(
      'equality operator should return false for UspValue objects with different types',
      () {
        final value1 = UspValue('test', UspValueType.string);
        final value2 = UspValue('test', UspValueType.int);
        expect(value1 == value2, isFalse);
      },
    );

    test('hashCode should be consistent for equal objects', () {
      final value1 = UspValue('test', UspValueType.string);
      final value2 = UspValue('test', UspValueType.string);
      expect(value1.hashCode, value2.hashCode);
    });

    test('hashCode should be different for unequal objects', () {
      final value1 = UspValue('test1', UspValueType.string);
      final value2 = UspValue('test2', UspValueType.string);
      expect(value1.hashCode == value2.hashCode, isFalse);
    });

    test('toString returns a correct string representation', () {
      final value = UspValue('hello', UspValueType.string);
      expect(
        value.toString(),
        'UspValue{value: hello, type: UspValueType.string}',
      );
    });
  });
}
