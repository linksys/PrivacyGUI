import 'package:flutter_test/flutter_test.dart';

import '../../test_scripts/combine_results.dart';

/// Guards the arithmetic behind the report's Test Summary panel, which on the
/// 2026-08-28 dev run showed Total 14716 against Pass 13572 with zero failures
/// (#1404).
void main() {
  Map<String, dynamic> record(Object? result) => {
        'id': 6,
        'name': ' admin - menu - phone480 - nl (variant: Linux)',
        'locale': 'nl',
        'deviceType': 'phone480',
        'tsName': 'admin-menu',
        if (result != null) 'result': result,
      };

  group('computeCounting', () {
    test('counts pass and fail by the result strings the golden CI keys off',
        () {
      final counting = computeCounting([
        record('success'),
        record('success'),
        record('error'),
      ]);

      expect(counting, {'success': 2, 'fail': 1, 'total': 3});
      // #1404's invariant: every record the parser hands over has a result, so
      // the record count and the buckets agree. The 2026-08-28 dev run failed
      // this by 1144.
      expect(counting['total'], counting['success']! + counting['fail']!);
    });

    test('never counts an unrecognised result as a pass or a fail', () {
      // `'failure'` is unreachable for a golden case — every one is a
      // `testWidgets`, where flutter_test reports both a failed `expect` and a
      // thrown exception as `'error'`. It is here to pin down that neither it nor
      // a resultless record widens `fail`, which CI cross-checks against its own
      // `'error'` count — while both stay in `total`, so losing records cannot
      // improve the numbers.
      final counting = computeCounting([
        record('success'),
        record('error'),
        record('failure'),
        record(null),
      ]);

      expect(counting, {'success': 1, 'fail': 1, 'total': 4});
    });

    test('is all zeroes for a run that produced no records', () {
      expect(computeCounting([]), {'success': 0, 'fail': 0, 'total': 0});
    });
  });
}
