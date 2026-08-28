import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../test_scripts/test_result_parser.dart';

/// Guards the parser against re-emitting the phantom rows behind #1404.
///
/// The event streams below are trimmed copies of what `flutter test
/// --file-reporter json` really writes for a group that declares `tearDownAll`,
/// including the `hidden: true` / `result: "success"` combination on the virtual
/// test, which is the pairing that made these records look like ordinary passes
/// to everything except the `hidden` flag.
void main() {
  const suitePath =
      '/Users/x/PrivacyGUI/test/golden_test/page/admin/localizations/admin_test.dart';

  Map<String, dynamic> newTestResult() => {
        'counting': {'total': 0, 'success': 0, 'fail': 0},
      };

  void replay(
      Map<String, dynamic> testResult, List<Map<String, dynamic>> events) {
    for (final event in events) {
      handleTestRecord(jsonEncode(event), testResult);
    }
  }

  List<Map<String, dynamic>> testsOfGroup(
    Map<String, dynamic> testResult,
    int groupID,
  ) {
    final suites = testResult['suites'] as List<Map<String, dynamic>>;
    final groups = suites.single['groups'] as List<Map<String, dynamic>>;
    final group = groups.firstWhere((g) => g['id'] == groupID);
    return (group['tests'] as List<Map<String, dynamic>>?) ?? [];
  }

  group('handleTestRecord', () {
    test('drops the virtual test that package:test hides for tearDownAll', () {
      final testResult = newTestResult();

      replay(testResult, [
        {
          'suite': {'id': 0, 'platform': 'vm', 'path': suitePath}
        },
        {
          'group': {'id': 2, 'suiteID': 0, 'name': '', 'testCount': 2}
        },
        {
          'group': {
            'id': 3,
            'suiteID': 0,
            'parentID': 2,
            'name': 'admin golden tests',
            'testCount': 1,
          }
        },
        {
          'test': {
            'id': 4,
            'suiteID': 0,
            'groupIDs': [2, 3],
            'name':
                'admin golden tests admin - menu - phone480 - nl (variant: Linux)',
            'metadata': {'skip': false, 'skipReason': null},
          }
        },
        {
          'test': {
            'id': 5,
            'suiteID': 0,
            'groupIDs': [2, 3],
            'name': 'admin golden tests (tearDownAll)',
            'metadata': {'skip': false, 'skipReason': null},
          }
        },
        {'testID': 4, 'result': 'success', 'hidden': false, 'skipped': false},
        {'testID': 5, 'result': 'success', 'hidden': true, 'skipped': false},
      ]);

      // Both groups, because the test branch files a record under every group ID
      // the test carries and the root group is only pruned later, on stream end.
      for (final groupID in [2, 3]) {
        final tests = testsOfGroup(testResult, groupID);
        expect(tests, hasLength(1), reason: 'group $groupID');
        expect(tests.single['id'], 4);
        expect(tests.single['result'], 'success');
        expect(tests.single['locale'], 'nl');
      }
    });

    test('keeps a real case that started and never reported a result', () {
      // What a suite killed mid-run leaves behind. It must survive as evidence;
      // `computeCounting` reports it as incomplete rather than as a pass.
      final testResult = newTestResult();

      replay(testResult, [
        {
          'suite': {'id': 0, 'platform': 'vm', 'path': suitePath}
        },
        {
          'group': {'id': 2, 'suiteID': 0, 'name': '', 'testCount': 1}
        },
        {
          'test': {
            'id': 4,
            'suiteID': 0,
            'groupIDs': [2],
            'name': 'admin - menu - phone480 - nl (variant: Linux)',
            'metadata': {'skip': false, 'skipReason': null},
          }
        },
      ]);

      final tests = testsOfGroup(testResult, 2);
      expect(tests, hasLength(1));
      expect(tests.single.containsKey('result'), isFalse);
    });
  });

  group('removeTestRecords', () {
    test('removes the record from every group it was filed under', () {
      final testResult = {
        'suites': <Map<String, dynamic>>[
          {
            'id': 0,
            'groups': <Map<String, dynamic>>[
              {
                'id': 2,
                'tests': <Map<String, dynamic>>[
                  {'id': 4},
                  {'id': 5},
                ],
              },
              {
                'id': 3,
                'tests': <Map<String, dynamic>>[
                  {'id': 5},
                ],
              },
            ],
          },
        ],
      };

      removeTestRecords(5, testResult);

      final groups = (testResult['suites'] as List)[0]['groups']
          as List<Map<String, dynamic>>;
      expect((groups[0]['tests'] as List).map((t) => t['id']), [4]);
      expect(groups[1]['tests'], isEmpty);
    });

    test('is a no-op on a stream that produced no suites yet', () {
      final testResult = <String, dynamic>{'counting': {}};

      expect(() => removeTestRecords(5, testResult), returnsNormally);
    });
  });
}
