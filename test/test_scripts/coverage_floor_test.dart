import 'dart:io';

import 'package:test/test.dart';

import '../../test_scripts/coverage_floor.dart';

void main() {
  group('readFloor', () {
    test('reads the one number among the comments', () {
      expect(readFloor('# The floor.\n#\n45.1\n'), 45.1);
    });

    test('turns down a file with no number, or with two', () {
      expect(() => readFloor('# Nothing here.\n'), throwsFormatException);
      expect(() => readFloor('45.1\n46.0\n'), throwsFormatException);
    });

    test('turns down a number outside 0 to 100', () {
      expect(() => readFloor('451\n'), throwsFormatException);
    });

    test('reads the floor committed in the repository', () {
      expect(readFloor(File(floorPath).readAsStringSync()),
          inInclusiveRange(0, 100));
    });
  });

  group('checkFloor', () {
    test('passes a total at the floor', () {
      // 378 of 1000 lines is exactly 37.8%.
      final check = checkFloor(covered: 378, lines: 1000, floor: 37.8);

      expect(check.passes, isTrue);
      expect(check.message, contains('37.80%'));
      expect(check.message, contains('at or above the floor of 37.8%'));
    });

    test('fails a total just under the floor', () {
      final check = checkFloor(covered: 3779, lines: 10000, floor: 37.8);

      expect(check.passes, isFalse);
      expect(check.message, contains('37.79%'));
      expect(check.message, contains('below the floor of 37.8%'));
      expect(check.message, contains(floorPath));
    });

    test('compares exactly, not as rounded for display', () {
      // 37.796% shows as 37.80% but is under 37.8%.
      expect(checkFloor(covered: 37796, lines: 100000, floor: 37.8).passes,
          isFalse);
    });
  });
}
