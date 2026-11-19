import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'measure_report.dart';

/// Builds the `tests.json` events of one run, one run per locale as in CI.
class _Run {
  final events = <Map<String, Object?>>[];
  var _nextId = 1;

  /// A test that ended with [result], after reporting [error].
  void ended(
    String name,
    String result, {
    String? error,
    bool hidden = false,
    bool skipped = false,
    List<String> printed = const [],
  }) {
    final id = _nextId++;
    events.add({
      'type': 'testStart',
      'test': {'id': id, 'name': name, 'suiteID': 0},
      'time': 0,
    });
    for (final message in printed) {
      events.add({'type': 'print', 'testID': id, 'message': message});
    }
    if (error != null) {
      events.add({'type': 'error', 'testID': id, 'error': error});
    }
    events.add({
      'type': 'testDone',
      'testID': id,
      'result': result,
      'skipped': skipped,
      'hidden': hidden,
      'time': 10,
    });
  }

  final _suiteIds = <String, int>{};

  _Run() {
    _suiteId('x/x_view_test.dart');
  }

  int _suiteId(String suite) => _suiteIds.putIfAbsent(suite, () {
        events.add({
          'type': 'suite',
          'suite': {
            'id': _suiteIds.length,
            'path': '/runner/work/app/test/page/$suite',
          },
        });
        return _suiteIds.length;
      });

  /// The run's last event: the whole run took [ms], loading included.
  void done(int ms) => events.add({'type': 'done', 'success': false, 'time': ms});

  /// A measured variant that took [ms] and found [incidents].
  void measured(
    String locale,
    String size, {
    List<Map<String, Object?>> incidents = const [],
    int ms = 100,
    String caseName = 'X view',
    String suite = 'x/x_view_test.dart',
    double measuredHeight = 720,
    bool threw = false,
  }) {
    final suiteId = _suiteId(suite);
    final id = _nextId++;
    final [width, height] = size.contains('x')
        ? size.split('x').map(double.parse).toList()
        : [double.parse(size), measuredHeight];
    final record = {
      'case': caseName,
      'locale': locale,
      'size': size,
      'width': width,
      'height': height,
      'threw': threw,
      'incidents': incidents,
    };
    events
      ..add({
        'type': 'testStart',
        'test': {
          'id': id,
          'name': '$caseName ($size $locale)',
          'suiteID': suiteId,
        },
        'time': 1000 * id,
      })
      ..add({
        'type': 'print',
        'testID': id,
        'message': '[layout-measure] ${jsonEncode(record)}',
      })
      ..add({
        'type': 'testDone',
        'testID': id,
        'result': 'success',
        'skipped': false,
        'hidden': false,
        'time': 1000 * id + ms,
      });
  }
}

Map<String, Object?> overflow(String site, double pixels) =>
    {'pixels': pixels, 'side': 'right', 'widget': 'Row', 'site': site};

void main() {
  group('MeasureReport sizes', () {
    test('counts variants, the ones over 2px, and their sites per size', () {
      final en = _Run()
        ..measured('en', '905x720',
            incidents: [overflow('lib/page/x/x_view.dart:130', 429)])
        ..measured('en', '601x932');
      final de = _Run()
        ..measured('de', '905x720',
            incidents: [overflow('lib/page/x/x_view.dart:130', 429)])
        ..measured('de', '601x932',
            incidents: [overflow('lib/page/x/x_view.dart:40', 1.5)]);

      final report = MeasureReport.fromRuns([en.events, de.events]);

      expect(report.sizes.map((s) => s.size), ['601x932', '905x720']);
      final narrow = report.sizes.first;
      expect(narrow.variants, 2);
      expect(narrow.overflowing, 0, reason: '1.5px is within the tolerance');
      expect(narrow.sites, isEmpty);
      final edge = report.sizes.last;
      expect(edge.variants, 2);
      expect(edge.overflowing, 2);
      expect(edge.sites, {'lib/page/x/x_view.dart:130'});
    });

    test('groups by the requested size, whatever height each case had', () {
      final run = _Run()
        ..measured('en', '905', measuredHeight: 720)
        ..measured('en', '905', measuredHeight: 2480)
        ..measured('en', '1280x420');

      expect(
        {for (final s in MeasureReport.fromRuns([run.events]).sizes) s.size: s.variants},
        {'905': 2, '1280x420': 1},
      );
    });

    test('names the sites that no other size finds', () {
      // This is how a width earns its place in the gate.
      final run = _Run()
        ..measured('en', '601x932',
            incidents: [overflow('lib/page/x/shared.dart:9', 12)])
        ..measured('en', '905x720', incidents: [
          overflow('lib/page/x/shared.dart:9', 30),
          overflow('lib/page/x/x_view.dart:130', 429),
        ])
        ..measured('en', '1240x720');

      final [narrow, edge, wide] = MeasureReport.fromRuns([run.events]).sizes;

      expect(narrow.onlyHere, isEmpty);
      expect(edge.onlyHere, {'lib/page/x/x_view.dart:130'});
      expect(wide.onlyHere, isEmpty);
    });

    test('judges "only this size" per case, not per site', () {
      // A shared widget overflowing at 480 on one page must not hide that
      // only 905 finds it on another.
      final run = _Run()
        ..measured('en', '480',
            caseName: 'B view', incidents: [overflow('lib/shared.dart:9', 12)])
        ..measured('en', '905', caseName: 'B view')
        ..measured('en', '480', caseName: 'A view')
        ..measured('en', '905',
            caseName: 'A view', incidents: [overflow('lib/shared.dart:9', 30)]);

      final [narrow, edge] = MeasureReport.fromRuns([run.events]).sizes;

      expect(narrow.onlyHere, {'lib/shared.dart:9'});
      expect(edge.onlyHere, {'lib/shared.dart:9'});
    });

    test('counts the variants that threw, whose incidents are partial', () {
      final run = _Run()
        ..measured('en', '1280x420', threw: true)
        ..measured('en', '1280x420');

      expect(MeasureReport.fromRuns([run.events]).sizes.single.threw, 1);
    });
  });

  group('MeasureReport pages', () {
    test('gives each suite its variants, overflows, sites and locales', () {
      final en = _Run()
        ..measured('en', '905',
            suite: 'a/a_view_test.dart',
            incidents: [overflow('lib/page/a/a_view.dart:5', 40)])
        ..measured('en', '905', suite: 'b/b_view_test.dart');
      final de = _Run()
        ..measured('de', '905', suite: 'a/a_view_test.dart')
        ..measured('de', '905', suite: 'b/b_view_test.dart');

      final pages = MeasureReport.fromRuns([en.events, de.events]).pages;

      expect(pages.map((p) => p.suite),
          ['test/page/a/a_view_test.dart', 'test/page/b/b_view_test.dart']);
      final a = pages.first;
      expect((a.variants, a.overflowing), (2, 1));
      expect(a.sites, {'lib/page/a/a_view.dart:5'});
      expect(a.locales, {'en'});
      expect(pages.last.overflowing, 0);
    });
  });

  group('MeasureReport wall time', () {
    test("takes each locale's wall time from its run's done event", () {
      // Test times add up to more than the run when files run in parallel,
      // and leave out compiling and loading.
      final en = _Run()
        ..measured('en', '905', ms: 100)
        ..done(180000);

      expect(MeasureReport.fromRuns([en.events]).locales.single.wallMs, 180000);
    });
  });

  group('MeasureReport pages and time', () {
    final en = _Run()
      ..measured('en', '905x720', ms: 120, incidents: [
        overflow('lib/page/x/x_view.dart:130', 429),
      ])
      ..measured('en', '601x932', ms: 80);
    final de = _Run()
      ..measured('de', '905x720', ms: 200, incidents: [
        overflow('lib/page/x/x_view.dart:130', 431),
      ])
      ..measured('de', '601x932', ms: 100);
    final report = MeasureReport.fromRuns([en.events, de.events]);

    test('gives each site its page, sizes, locales and worst amount', () {
      final site = report.sites.single;

      expect(site.site, 'lib/page/x/x_view.dart:130');
      expect(site.suites, {'test/page/x/x_view_test.dart'});
      expect(site.sizes, {'905x720'});
      expect(site.locales, {'de', 'en'});
      expect(site.worstPixels, 431);
    });

    test('adds up the time per size and per locale', () {
      expect({for (final s in report.sizes) s.size: s.ms},
          {'601x932': 180, '905x720': 320});
      expect({for (final l in report.locales) l.locale: (l.variants, l.ms)},
          {'de': (2, 300), 'en': (2, 200)});
    });
  });

  group('MeasureReport.toMarkdown', () {
    test('renders the tables a person pastes into the issue', () {
      final en = _Run()
        ..measured('en', '905x720', ms: 120, incidents: [
          overflow('lib/page/x/x_view.dart:130', 429),
        ])
        ..measured('en', '601x932', ms: 80)
        ..ended('X view | broken (601x932 en)', 'error', error: 'Bad | state');
      final de = _Run()
        ..measured('de', '905x720', ms: 200, incidents: [
          overflow('lib/page/x/x_view.dart:130', 431),
        ]);

      final markdown = MeasureReport.fromRuns([en.events, de.events]).toMarkdown();

      expect(markdown, contains('| 905x720 | 2 | 2 | 1 | 1 | 0 | 0.3 s |'));
      expect(
        markdown,
        contains('| `lib/page/x/x_view.dart:130` | 431 px | 905x720 | all 2 '
            '| `test/page/x/x_view_test.dart` |'),
      );
      expect(markdown,
          contains('| `test/page/x/x_view_test.dart` | 3 | 2 | 1 | all 2 |'));
      expect(markdown, contains('| de | 1 | 1 | 0.2 s | – |'));
      expect(
        markdown,
        contains('| `test/page/x/x_view_test.dart` | X view \\| broken '
            '(601x932 en) | Bad \\| state |'),
      );
    });

    test('keeps a cell that holds a line break on one row', () {
      final run = _Run()..ended('loading a\nb', 'error', error: 'x');

      final markdown = MeasureReport.fromRuns([run.events]).toMarkdown();

      expect(markdown, contains('| loading a b | x |'));
    });
  });

  group('MeasureReport failures', () {
    test('lists the tests that failed for a reason other than an overflow', () {
      final run = _Run()
        ..ended('loading /runner/work/app/test/page/x/x_view_test.dart', 'success',
            hidden: true)
        ..ended('X view (905x720 en)', 'error',
            error: 'Bad state: No ProviderScope found\n#0 main.<fn>')
        ..ended('X view (601x932 en)', 'success', skipped: true)
        ..ended('Y view (601x932 en)', 'success');

      final failures = MeasureReport.fromRuns([run.events]).failures;

      expect(failures, hasLength(1));
      expect(failures.single.suite, 'test/page/x/x_view_test.dart');
      expect(failures.single.test, 'X view (905x720 en)');
      expect(failures.single.error, 'Bad state: No ProviderScope found');
    });

    test("names the framework's exception over its generic error", () {
      final run = _Run()
        ..ended('X view (1280x420 en)', 'error',
            error: 'Test failed. See exception logs above.\nThe test description was: x',
            printed: [
              '══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞═════\n'
                  'The following assertion was thrown running a test:\n'
                  'The finder "Found 0 widgets with type "AppDropdownButton"" '
                  '(used in a call to "tap()")\n'
                  'could not find any matching widgets.\n',
            ]);

      expect(
        MeasureReport.fromRuns([run.events]).failures.single.error,
        'The finder "Found 0 widgets with type "AppDropdownButton"" '
        '(used in a call to "tap()")',
      );
    });

    test('lists a suite that failed to load', () {
      final run = _Run()
        ..ended('loading /runner/work/app/test/page/x/x_view_test.dart', 'error',
            error: "Error: Undefined name 'loc'.\nmore");

      final failures = MeasureReport.fromRuns([run.events]).failures;

      expect(failures.single.error, "Error: Undefined name 'loc'.");
    });
  });
}
