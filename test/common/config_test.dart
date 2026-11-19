import 'package:flutter_test/flutter_test.dart';

import 'config.dart';

void main() {
  group('parseScreens', () {
    test('reads widths, with a height where one is given', () {
      expect(parseScreens('480,905,1280x420'), [
        (width: 480.0, height: null),
        (width: 905.0, height: null),
        (width: 1280.0, height: 420.0),
      ]);
    });

    test('accepts the d<width> names and surrounding spaces', () {
      expect(parseScreens(' d744 , 1920 '), [
        (width: 744.0, height: null),
        (width: 1920.0, height: null),
      ]);
    });

    test('rejects a value it cannot read instead of falling back', () {
      // It used to map anything it did not know to 1440, so a run asked for
      // 905 measured 1440 and passed.
      for (final value in [
        '', 'abc', '480,', '480x', 'x420', '0', '480x0', //
        '00', '480x00', // a zero written with more digits
      ]) {
        expect(() => parseScreens(value), throwsFormatException,
            reason: '"$value"');
      }
    });
  });
}
