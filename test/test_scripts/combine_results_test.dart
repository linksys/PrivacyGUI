import 'package:flutter_test/flutter_test.dart';

import '../../test_scripts/combine_results.dart';

/// Guards the arithmetic behind the report's Test Summary panel, which on the
/// 2026-08-28 dev run showed Total 14716 against Pass 13572 with zero failures
/// (#1404), and which counted a golden that never ran as one that passed (#1405).
void main() {
  Map<String, dynamic> record(Object? result, {bool skipped = false}) => {
        'id': 6,
        'name': ' admin - menu - phone480 - nl (variant: Linux)',
        'locale': 'nl',
        'deviceType': 'phone480',
        'tsName': 'admin-menu',
        if (result != null) 'result': result,
        if (skipped) 'skipped': true,
      };

  group('computeCounting', () {
    test('counts pass and fail by the result strings the golden CI keys off',
        () {
      final counting = computeCounting([
        record('success'),
        record('success'),
        record('error'),
      ]);

      expect(counting,
          {'success': 2, 'fail': 1, 'skipped': 0, 'incomplete': 0, 'total': 3});
      // #1404's invariant, in the only shape where it can hold: every record ran.
      // Once a run holds a skip or a record that never reported, Total is larger
      // than Pass + Fail by design — that is #1405's own bucket, and reading the
      // difference as a defect is what the two extra tiles exist to prevent.
      expect(counting['total'], counting['success']! + counting['fail']!);
    });

    test('counts a skipped golden as skipped, not as a pass', () {
      final counting = computeCounting([
        record('success'),
        // What the reporter actually emits for a skip: `result` normalised to
        // 'success' for backwards compatibility, with the truth in the separate
        // field the parser now copies onto the record. Reading `result` alone is
        // what made a golden that stopped running read as green (#1405).
        record('success', skipped: true),
      ]);

      expect(counting,
          {'success': 1, 'fail': 0, 'skipped': 1, 'incomplete': 0, 'total': 2});
    });

    test('counts a test that never reported as incomplete, not as a pass', () {
      final counting = computeCounting([
        record('success'),
        record(null),
      ]);

      // The distinction the previous filter erased: it dropped every record
      // without a result, so a suite killed mid-run improved the numbers.
      expect(counting,
          {'success': 1, 'fail': 0, 'skipped': 0, 'incomplete': 1, 'total': 2});
    });

    test('keeps total equal to the sum of the buckets for any result string',
        () {
      // `'failure'` is unreachable for a golden case — every one is a
      // `testWidgets`, where flutter_test reports both a failed `expect` and a
      // thrown exception as `'error'`. It is here to pin down that an
      // unrecognised result still cannot escape the total, rather than to widen
      // `fail`, which CI cross-checks against its own `'error'` count.
      final counting = computeCounting([
        record('success'),
        record('error'),
        record('failure'),
        record(null),
        record('success', skipped: true),
      ]);

      expect(counting,
          {'success': 1, 'fail': 1, 'skipped': 1, 'incomplete': 2, 'total': 5});
    });

    test('is all zeroes for a run that produced no records', () {
      expect(computeCounting([]), {
        'success': 0,
        'fail': 0,
        'skipped': 0,
        'incomplete': 0,
        'total': 0,
      });
    });
  });
}
