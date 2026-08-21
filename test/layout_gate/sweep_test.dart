@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/app_test_fonts.dart';
import '../util/overflow_baseline.dart';
import 'sweep.dart';

/// The sweep runner's oracle (#1342).
///
/// Tagged `layout-gate` and **not** `overflow`, for the reason
/// `dart_test.yaml` gives: the second tag selects the four sweeps, and this file
/// is a framework self-test, next to `ratchet_test.dart` and
/// `overflow_probe_test.dart` rather than inside the pre-commit sweep set.
///
/// What it exists to prove is the part of #1342 that a baseline diff cannot see.
/// `./tool/overflow_baseline.sh check chrome` proves the chrome port measures the
/// same 1,248 coordinates it did before; it says nothing about *why* they were
/// still measured. These cases pin that: the identity the framework keys on, the
/// grouping policy §6 froze, and the three invariants of architecture doc §3.4 —
/// each one exercised rather than asserted in a comment, because a framework
/// whose invariants are only documented is how the gate ends up "faster, quieter,
/// blinder" (§9.3).
void main() {
  setUpAll(() async {
    // The invariant tests below measure real overflow in pixels, so the Ahem
    // placeholder font would make every number fiction. They pump no text today
    // and would pass without this; loading it keeps the file honest if one ever
    // does.
    await loadAppFonts();
  });

  group('cell identity', () {
    test('names the family, then the axes in order, then the locale last', () {
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final id = overflowSweepCellId(
        family,
        _cell(
            axes: const {'screen_px': '640'}, locale: const Locale('zh', 'TW')),
      );

      expect(id, 'fake|screen_px=640|locale=zh_TW');
    });

    test('is the same string the baseline record is keyed on', () {
      // The one identity, single-sourced. The runner uses it for the
      // `KeyedSubtree` (invariant 1) *and* hands it to the collector as the
      // baseline coordinate, so a port cannot make the freshness key and the
      // dataset key drift apart — which is exactly how a re-keyed cell reads as
      // 1,248 coordinates lost and 1,248 found (`overflow_baselines.md` §2).
      final family = _FakeFamily(axisNames: const ['screen_px', 'mode']);
      final cell = _cell(
        axes: const {'screen_px': '320', 'mode': 'editing'},
        locale: const Locale('pl'),
      );

      expect(
        overflowSweepCellId(family, cell),
        overflowBaselineCellId(overflowSweepBaselineCell(family, cell)),
      );
    });

    test('spells the locale the way every other sweep does', () {
      // `zh_TW`, not `zh-TW` — the sixteenth family difference #1356 closed. The
      // runner reaches `localeTag()` rather than `Locale.toLanguageTag()`, and
      // this is the case that fails if someone "simplifies" it back.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final cell = _cell(
        axes: const {'screen_px': '320'},
        locale: const Locale('zh', 'TW'),
      );

      expect(overflowSweepCellId(family, cell), endsWith('|locale=zh_TW'));
    });

    test('the coordinate label names the non-locale axes only', () {
      final cell = _cell(
        axes: const {'screen_px': '640', 'mode': 'viewing_local'},
        locale: const Locale('fr'),
      );

      expect(
        overflowSweepCoordinateLabel(cell),
        'screen_px=640 mode=viewing_local',
      );
    });
  });

  group('grouping policy', () {
    // §6, decided 2026-08-20 and frozen: group by every axis except locale, and
    // loop locale inside one test.
    test('one group per non-locale coordinate, locale inside it', () {
      final grouped = groupOverflowSweepCells([
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('pl')),
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('pl')),
      ]);

      expect(grouped.keys, ['screen_px=320', 'screen_px=768']);
      expect(grouped.values.map((cells) => cells.length), [2, 2]);
    });

    test('keeps the family\'s enumeration order', () {
      // Declaration order is the family's, not alphabetical: the test report
      // reads in the order the sweep sweeps, which is how a porter finds the
      // width they are looking at.
      final grouped = groupOverflowSweepCells([
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
      ]);

      expect(grouped.keys, ['screen_px=768', 'screen_px=320']);
    });

    test('a locale interleaved across coordinates still groups by coordinate',
        () {
      // The family is free to enumerate locale-major; the policy is not.
      final grouped = groupOverflowSweepCells([
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('pl')),
        _cell(axes: const {'screen_px': '768'}, locale: const Locale('pl')),
      ]);

      expect(grouped.keys, ['screen_px=320', 'screen_px=768']);
      expect(
        grouped['screen_px=320']!.map((c) => c.locale.languageCode),
        ['en', 'pl'],
      );
    });
  });

  group('group and test names', () {
    test('the first axis names the group and the rest name the test', () {
      // §5 contract 1: `run_overflow_test.sh --name "$CARD_ID"` is an unanchored
      // substring match against the full name, so the first axis has to be the
      // *enclosing group* for `card=lan_info` to keep resolving after the port.
      final names = overflowSweepNames(_cell(
        axes: const {'card': 'lan_info', 'px': '191', 'tab': '0'},
        locale: const Locale('en'),
      ));

      expect(names.group, 'card=lan_info');
      expect(names.test, 'px=191 tab=0 lays out cleanly in every locale');
    });

    test('an axis value containing a space stays whole in the group name', () {
      // The names used to be recovered by splitting the coordinate label on
      // spaces, which named the group after the first *word* of a value. Nothing
      // forbids a spaced value — `chrome.header`'s mode axis read
      // `mode=viewing, local (3 actions)` until #1356, and only the id was made
      // prose-free — so the split would have collapsed two coordinates into one
      // group and broken contract 1 silently.
      final names = overflowSweepNames(_cell(
        axes: const {'card': 'network health', 'px': '191'},
        locale: const Locale('en'),
      ));

      expect(names.group, 'card=network health');
      expect(names.test, startsWith('px=191'));
    });

    test('a family with no axes is still declarable', () {
      // The count test is what reports "this family declares no axes", so the
      // sweep has to survive *declaring* one — a throw while naming groups
      // aborts the whole suite at load and the report never runs.
      final names = overflowSweepNames(
        _cell(axes: const {}, locale: const Locale('en')),
      );

      expect(names.group, '(no axes)');
      expect(names.test, 'lays out cleanly in every locale');
    });
  });

  group('enumeration integrity', () {
    // What the pinned cell count cannot see on its own. After the regrouping a
    // family reports 12 tests where it used to report 312, so "deliberately
    // regrouped" and "stopped enumerating" look identical (§6) — the literal
    // count closes the first hole and these three close the ones underneath it.
    test('a conforming enumeration reports nothing', () {
      final family = _FakeFamily(axisNames: const [
        'screen_px'
      ], cells: [
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('pl')),
      ]);

      expect(overflowSweepEnumerationProblems(family, family.enumerateCells()),
          isEmpty);
    });

    test('a cell that does not carry the declared axes is named', () {
      final family = _FakeFamily(axisNames: const [
        'screen_px',
        'mode'
      ], cells: [
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
      ]);

      expect(
        overflowSweepEnumerationProblems(family, family.enumerateCells())
            .join('\n'),
        allOf(contains('screen_px, mode'), contains('screen_px')),
      );
    });

    test('axes in the wrong order are named, because the id is ordered', () {
      // Not pedantry: the cell id is the axes in insertion order, so a family
      // that swaps two axes renames every cell it enumerates and the baseline
      // diff reports its whole coverage lost.
      final family = _FakeFamily(axisNames: const [
        'screen_px',
        'mode'
      ], cells: [
        _cell(
          axes: const {'mode': 'editing', 'screen_px': '320'},
          locale: const Locale('en'),
        ),
      ]);

      expect(overflowSweepEnumerationProblems(family, family.enumerateCells()),
          isNotEmpty);
    });

    test('two cells with one id are named, because one of them is not measured',
        () {
      // The count says 2 and the coverage is 1: the second pump overwrites the
      // first's row in the dataset and its `KeyedSubtree` key, so it is measured
      // in name only.
      final family = _FakeFamily(axisNames: const [
        'screen_px'
      ], cells: [
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
        _cell(axes: const {'screen_px': '320'}, locale: const Locale('en')),
      ]);

      expect(
        overflowSweepEnumerationProblems(family, family.enumerateCells())
            .join('\n'),
        contains('fake|screen_px=320|locale=en'),
      );
    });

    test('declaring locale as an axis is named', () {
      // Locale is a field on the cell and the runner's inner loop, so a family
      // that also declares it as an axis would have it twice in the id.
      final family = _FakeFamily(axisNames: const ['screen_px', 'locale']);

      expect(
        overflowSweepEnumerationProblems(family, family.enumerateCells())
            .join('\n'),
        contains('locale'),
      );
    });

    test('a family with no axes at all is named', () {
      // Every axis except locale becomes the grouping, so a family with none
      // has no group to hang a test on — and §5 contract 1 has nothing to
      // resolve `--name "$CARD_ID"` against.
      final family = _FakeFamily(axisNames: const []);

      expect(overflowSweepEnumerationProblems(family, family.enumerateCells()),
          isNotEmpty);
    });
  });

  group('failure aggregation', () {
    test('names the locale count and every failing locale', () {
      final reason = overflowSweepFailureReason(
        familyName: 'chrome.top_bar',
        coordinateLabel: 'screen_px=640',
        failures: const ['pl: +47.0px right', 'fi: +12.0px right'],
        threwCount: 0,
      );

      expect(reason, contains('chrome.top_bar'));
      expect(reason, contains('overflowed at screen_px=640'));
      expect(reason, contains('in 2 locale(s)'));
      expect(reason, contains('pl: +47.0px right'));
      expect(reason, contains('fi: +12.0px right'));
    });

    test('says a cell threw rather than calling it an overflow', () {
      // "overflowed at 640px in 1 locale(s)" would be a lie about a cell whose
      // tree never finished building, and the two are remediated differently.
      final reason = overflowSweepFailureReason(
        familyName: 'chrome.header',
        coordinateLabel: 'screen_px=320 mode=editing',
        failures: const ['ru: threw Bad state: no fixture'],
        threwCount: 1,
      );

      expect(reason, contains('overflowed or threw'));
      expect(reason, contains('1 threw'));
      expect(reason, contains('ru: threw Bad state: no fixture'));
    });
  });

  group('measuring one cell', () {
    testWidgets('reports the overflow the cell produced, with its site',
        (tester) async {
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '100'},
          locale: const Locale('en'),
          surfaceSize: const Size(100, 200),
          build: () => _overflowingRow(childWidth: 300),
        ),
      );

      expect(verdict.error, isNull);
      expect(verdict.significant, hasLength(1));
      expect(verdict.significant.single.pixels, closeTo(200, 1));
      expect(verdict.significant.single.side, 'right');
      // The join key #1338 added, read off the same incident — proof the runner
      // reports through the one parser rather than re-reading the string.
      expect(verdict.significant.single.site, contains('sweep_test.dart'));
    });

    testWidgets('a cell that fits is measured and reports nothing',
        (tester) async {
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '400'},
          locale: const Locale('en'),
          surfaceSize: const Size(400, 200),
          build: () => _overflowingRow(childWidth: 100),
        ),
      );

      expect(verdict.failed, isFalse);
      expect(verdict.incidents, isEmpty);
    });

    testWidgets('holds an incident under tolerance without failing on it',
        (tester) async {
      // Recorded, not significant: the baseline dataset keeps every incident so
      // that loosening the filter cannot look like fixing a layout
      // (`overflow_baseline.dart`'s record builder), while the gate's verdict
      // still comes from `kOverflowTolerancePx`.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '100'},
          locale: const Locale('en'),
          surfaceSize: const Size(100, 200),
          build: () => _overflowingRow(childWidth: 101),
        ),
      );

      expect(verdict.incidents, hasLength(1));
      expect(verdict.incidents.single.pixels, closeTo(1, 0.01));
      expect(verdict.significant, isEmpty);
      expect(verdict.failed, isFalse);
    });

    testWidgets('INVARIANT 1: the same shape overflows again in the same test',
        (tester) async {
      // Flutter reports each `RenderFlex`'s overflow once per render-object
      // lifetime, so two pumps of one shape inside one `testWidgets` measure
      // the second cell as clean unless something forces a fresh subtree. That
      // is the trap the whole locale inner loop sits on, and the framework's
      // `KeyedSubtree(key: ValueKey(cell.key))` is what disarms it.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      Future<OverflowCellVerdict> measure(String locale) => measureOverflowCell(
            tester,
            family: family,
            cell: _cell(
              axes: const {'screen_px': '100'},
              locale: Locale(locale),
              surfaceSize: const Size(100, 200),
              build: () => _overflowingRow(childWidth: 300),
            ),
          );

      final first = await measure('en');
      final second = await measure('pl');

      expect(first.significant, hasLength(1));
      expect(second.significant, hasLength(1),
          reason: 'the second cell must get its own render objects');
      expect(second.cellId, isNot(first.cellId));
    });

    testWidgets(
        'INVARIANT 3: a settled-cell hook that throws is that cell\'s failure',
        (tester) async {
      var settled = 0;
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onSettled: (tester, cell) async {
          settled++;
          if (cell.locale.languageCode == 'ru') {
            throw StateError('unreadable at ${cell.axes['screen_px']}');
          }
        },
      );
      Future<OverflowCellVerdict> measure(String locale) => measureOverflowCell(
            tester,
            family: family,
            cell: _cell(
              axes: const {'screen_px': '400'},
              locale: Locale(locale),
              surfaceSize: const Size(400, 200),
              build: () => _overflowingRow(childWidth: 100),
            ),
          );

      final thrown = await measure('ru');
      final next = await measure('fi');

      expect(thrown.error, isA<StateError>());
      expect(thrown.failed, isTrue);
      expect(thrown.summary, contains('threw'));
      expect(thrown.summary, contains('unreadable at 400'));
      expect(next.failed, isFalse,
          reason: 'one locale throwing must not take the next 25 with it');
      expect(settled, 2);
    });

    testWidgets(
        'INVARIANT 3: a host that throws while building is that cell\'s '
        'failure too', (tester) async {
      // The half of invariant 3 that no `catch` reaches. A build-phase error is
      // reported through `FlutterError.onError`, which `collector.dart` forwards
      // to the binding for anything that is not an overflow — so `pumpWidget`
      // returns normally, and before the runner claimed the pending exception
      // this cell's baseline row was written *unflagged*: measured-and-clean for
      // a tree that never built, which is the one reading
      // `overflow_baselines.md` §2 calls dangerous. The whole grouped test also
      // failed with a bare stack instead of the aggregated reason.
      //
      // That this test passes at all is the other half of the proof: an
      // untaken exception fails the test it happened in, so reaching the
      // assertions below means the runner cleared it.
      final family = _FakeFamily(axisNames: const ['screen_px']);
      Future<OverflowCellVerdict> measure(String locale,
              {required bool broken}) =>
          measureOverflowCell(
            tester,
            family: family,
            cell: _cell(
              axes: const {'screen_px': '400'},
              locale: Locale(locale),
              surfaceSize: const Size(400, 200),
              build: broken
                  ? _hostThatThrowsWhileBuilding
                  : () => _overflowingRow(childWidth: 100),
            ),
          );

      final broken = await measure('ru', broken: true);
      final next = await measure('fi', broken: false);

      expect(broken.error, isA<StateError>());
      expect(broken.failed, isTrue);
      expect(broken.summary, contains('no fixture'));
      expect(next.failed, isFalse,
          reason: 'the locales after a broken host must still be measured');
    });

    testWidgets('the settled-cell hook runs on the settled tree',
        (tester) async {
      // The hook is the readability slot, so it has to see the laid-out tree —
      // measured by finding a widget only the pumped host provides.
      Finder? seen;
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onSettled: (tester, cell) async {
          seen = find.byKey(const ValueKey('sweep-probe'));
          expect(seen!, findsOneWidget);
        },
      );

      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '400'},
          locale: const Locale('en'),
          surfaceSize: const Size(400, 200),
          build: () => _overflowingRow(childWidth: 100),
        ),
      );

      expect(seen, isNotNull);
      expect(verdict.failed, isFalse);
    });

    testWidgets('overflow raised inside the hook is still collected',
        (tester) async {
      // The hook runs inside the collector, which is what lets a family re-pump
      // (the card family's adjusted-screenshot capture does) and still have its
      // incidents attributed to the cell that produced them.
      final family = _FakeFamily(
        axisNames: const ['screen_px'],
        onSettled: (tester, cell) async {
          await tester
              .pumpWidget(_overflowingRow(childWidth: 300, tag: 'hook'));
          await tester.pump();
        },
      );

      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: _cell(
          axes: const {'screen_px': '100'},
          locale: const Locale('en'),
          surfaceSize: const Size(100, 200),
          build: () => _overflowingRow(childWidth: 100),
        ),
      );

      expect(verdict.significant, hasLength(1),
          reason: 'the hook pumped an overflowing tree inside the collector');
    });

    testWidgets('INVARIANT 2: the tree is laid out at the cell\'s surface',
        (tester) async {
      // Only half of invariant 2, and the half a test can see from inside its
      // own body: the surface the cell asked for is the surface the tree was
      // measured in. The *reset* is registered by `setLayoutSurface` and runs in
      // teardown, after every assertion here, so proving it needs a test that
      // outlives the one that set it — which `overflow_probe_test.dart` already
      // is, by reading the surface the *previous* test left behind (#1340).
      // Naming the restore in this test would be a green check for something it
      // never looks at.
      Size? seen;
      await measureOverflowCell(
        tester,
        family: _FakeFamily(
          axisNames: const ['screen_px'],
          onSettled: (tester, cell) async {
            seen = tester.view.physicalSize;
          },
        ),
        cell: _cell(
          axes: const {'screen_px': '640'},
          locale: const Locale('en'),
          surfaceSize: const Size(640, 480),
          build: () => _overflowingRow(childWidth: 10),
        ),
      );

      expect(seen, const Size(640, 480));
    });
  });
}

/// A `Row` that overflows by `childWidth - surfaceWidth` and nothing else.
///
/// [tag] keys the tree so a caller can pump two of them; the runner keys the
/// subtree it wraps this in, which is what invariant 1's case measures.
Widget _overflowingRow({required double childWidth, String tag = 'cell'}) {
  return MaterialApp(
    key: ValueKey('sweep-host-$tag'),
    home: Scaffold(
      body: Row(
        children: [
          SizedBox(
            key: const ValueKey('sweep-probe'),
            width: childWidth,
            height: 10,
          ),
        ],
      ),
    ),
  );
}

/// A host that fails the way a real one does: during build, so the error goes to
/// `FlutterError.onError` and `pumpWidget` returns as if nothing happened.
///
/// A missing fixture, a provider whose override was dropped and a null-asserted
/// localisation all arrive here.
Widget _hostThatThrowsWhileBuilding() {
  return MaterialApp(
    home: Builder(builder: (_) => throw StateError('no fixture')),
  );
}

OverflowSweepCell _cell({
  required Map<String, Object?> axes,
  required Locale locale,
  Size surfaceSize = const Size(400, 800),
  Widget Function()? build,
}) {
  return OverflowSweepCell(
    axes: axes,
    locale: locale,
    surfaceSize: surfaceSize,
    build: build ?? () => const SizedBox.shrink(),
  );
}

class _FakeFamily implements OverflowSurfaceFamily {
  _FakeFamily({
    required this.axisNames,
    List<OverflowSweepCell>? cells,
    Future<void> Function(WidgetTester, OverflowSweepCell)? onSettled,
  })  : _cells = cells ?? const [],
        _onSettled = onSettled;

  final List<OverflowSweepCell> _cells;
  final Future<void> Function(WidgetTester, OverflowSweepCell)? _onSettled;

  @override
  String get name => 'fake';

  @override
  final List<String> axisNames;

  @override
  Iterable<OverflowSweepCell> enumerateCells() => _cells;

  @override
  Future<void> onCellSettled(
      WidgetTester tester, OverflowSweepCell cell) async {
    await _onSettled?.call(tester, cell);
  }
}
