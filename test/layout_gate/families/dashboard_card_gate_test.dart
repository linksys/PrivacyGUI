@Tags(['layout-gate'])
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../util/dashboard/dashboard_card_probe.dart';
import '../incident.dart';
import '../ratchet.dart';
import '../sweep.dart';
import 'card_sweep_cell.dart';
import 'dashboard_card_family.dart';
import 'dashboard_card_gate.dart';
import 'forced_form_card_family.dart';
import 'popup_card_family.dart';

/// The card gate's oracle (#1343).
///
/// Tagged `layout-gate` and **not** `overflow`: like `sweep_test.dart` and
/// `ratchet_test.dart` this is a framework self-test, not one of the five sweeps
/// the narrower selector runs.
///
/// What it exists to prove is the half of #1343 a baseline diff cannot see.
/// `./tool/overflow_baseline.sh check card` proves the port measures the same
/// 1,917 coordinates; it says nothing about what the gate *does* with a
/// measurement, because the fixture is empty and the sweep is green — every
/// interesting branch of [CardSweepGate.judge] is unreachable on real data today.
/// Before #1343 those branches were file-private globals inside a 1,898-cell
/// suite and could not be reached from a test at all; the cases below are what
/// that refactor bought.
///
/// Synthetic incidents rather than pumped ones, deliberately: an incident is
/// [OverflowIncident]'s public const constructor away, and standing up a card that
/// genuinely overflows would mean shipping a broken widget to test the reporter.
void main() {
  // A real coordinate, so nothing here depends on a hand-made geometry: the same
  // spec, width case and row count the width family enumerates.
  final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == 'device_info');
  final widthCase = widthCasesFor(spec).first;

  CardSweepCell cellFor(String tag) => CardSweepCell(
        axes: {
          'card': spec.id,
          'width': widthCase.label,
          'px': widthCase.widthKey,
          'tab': 0,
        },
        locale: Locale(tag),
        cardId: spec.id,
        widthCase: widthCase,
        rows: spec.getConstraints(DisplayMode.normal).minHeightRows,
        tab: 0,
        tabCount: 1,
      );

  OverflowCellVerdict verdictWith(List<OverflowIncident> significant) =>
      OverflowCellVerdict(
        cellId: 'card.width|card=device_info|width=min|px=191|tab=0|locale=de',
        incidents: significant,
        significant: significant,
      );

  OverflowIncident incidentAt(String file, int line, double pixels) =>
      OverflowIncident(
        pixels: pixels,
        side: 'right',
        message: 'A RenderFlex overflowed by $pixels pixels on the right.',
        file: file,
        line: line,
        widget: 'Row',
      );

  /// One deferred site, at 41px, in German only.
  ///
  /// Built per test rather than shared: `consultCell` records what it was handed,
  /// because that ledger is what the closing dead-entry verdict is computed from.
  /// A ratchet reused across tests would carry the previous test's observations
  /// into this one's verdict.
  OverflowRatchet leasedRatchet() => OverflowRatchet.fromJson({
        'tracking': {'lib/x.dart:9': 'legend fix #1145'},
        'allowlist': {
          'lib/x.dart:9': {
            'locales': ['de'],
            'maxOverflowPx': 41,
          },
        },
      });

  group('the verdict for one cell', () {
    testWidgets('a clean cell has none, and is still counted', (tester) async {
      // The reason the hook fires on clean cells at all: this count is what
      // decides whether the run covered enough for the dead-entry verdict.
      final gate = CardSweepGate();

      final detail = await gate.judge(
        tester,
        cellFor('de'),
        verdictWith(const []),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'unreachable',
      );

      expect(detail, isNull);
      expect(gate.measuredCells, 1);
    });

    testWidgets('an unexempted overflow fails, with the paste-ready entry',
        (tester) async {
      // The gate's default state: an empty fixture blocks everything, and the
      // failure has to hand over the exact `file:line` key and ceiling — the
      // example is derived from the measurement so it cannot drift from what the
      // parser accepts.
      final gate = CardSweepGate();

      final detail = await gate.judge(
        tester,
        cellFor('de'),
        verdictWith([incidentAt('lib/x.dart', 9, 41.0)]),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'device_info overflows: $d.',
      );

      expect(detail, isNotNull);
      expect(detail, startsWith('device_info overflows: +41.0px right'));
      expect(detail, contains(kKnownOverflowsFixturePath));
      expect(detail,
          contains('"lib/x.dart:9": {"locales": ["de"], "maxOverflowPx": 41}'));
    });

    testWidgets('a leased site is tolerated, and says so out loud',
        (tester) async {
      // The ratchet's whole purpose, and the branch that made a family verdict
      // hook necessary: the overflow is real and the gate stays green.
      //
      // The print is asserted, not just the null: a null on its own is
      // indistinguishable from a clean cell, and this line is the only place a
      // tolerated overflow is ever visible — with the allowance beside it, because
      // "+25.9px, allowed 26.0px" and "+2.5px, allowed 26.0px" read identically
      // without it and the first is one shaping difference from failing CI.
      final gate = CardSweepGate()..ratchet = leasedRatchet();
      final printed = <String>[];

      final detail = await runZoned(
        () => gate.judge(
          tester,
          cellFor('de'),
          verdictWith([incidentAt('lib/x.dart', 9, 41.0)]),
          subject: 'device_info @min 191px tab0',
          failure: (d) => 'unreachable',
        ),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => printed.add(line),
        ),
      );

      expect(detail, isNull);
      expect(printed, hasLength(1));
      expect(printed.single, startsWith('KNOWN OVERFLOW (allowlisted) '));
      expect(printed.single, contains('device_info @min 191px tab0 de: '));
      expect(printed.single, contains('+41.0px right at lib/x.dart:9'));
      expect(printed.single, contains('(allowed up to 41.0px'));
      expect(printed.single, endsWith('legend fix #1145'),
          reason:
              'the tracking note is per site, and is why this is tolerated');
    });

    testWidgets('the lease is per locale, so another locale still fails',
        (tester) async {
      final gate = CardSweepGate()..ratchet = leasedRatchet();

      final detail = await gate.judge(
        tester,
        cellFor('fi'),
        verdictWith([incidentAt('lib/x.dart', 9, 41.0)]),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'device_info overflows: $d.',
      );

      expect(detail, contains('+41.0px right'));
      expect(detail, contains('"locales": ["fi"]'));
    });

    testWidgets('a cell may be part leased and part blocked', (tester) async {
      // Only possible since the key became a source location: the failure quotes
      // the new site — that is the work — and says the coordinate carries more, so
      // a one-incident message is not read as the whole story.
      final gate = CardSweepGate()..ratchet = leasedRatchet();

      final detail = await gate.judge(
        tester,
        cellFor('de'),
        verdictWith([
          incidentAt('lib/x.dart', 9, 41.0),
          incidentAt('lib/y.dart', 4, 12.0),
        ]),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'device_info overflows: $d.',
      );

      expect(detail, contains('+12.0px right'));
      expect(detail, contains('(plus 1 already allowlisted here)'));
      expect(detail, contains('"lib/y.dart:4"'));
      expect(detail, isNot(contains('"lib/x.dart:9": {')),
          reason: 'the leased site needs no new entry pasted for it');
    });

    testWidgets('overflowing past the ceiling is its own advice',
        (tester) async {
      // "Add the tag" is wrong advice for an entry that already names it: whoever
      // holds the failure would open the fixture, find the tag, and conclude the
      // gate is broken. What changed is the size.
      final gate = CardSweepGate()..ratchet = leasedRatchet();

      final detail = await gate.judge(
        tester,
        cellFor('de'),
        verdictWith([incidentAt('lib/x.dart', 9, 80.0)]),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'device_info overflows: $d.',
      );

      expect(detail, contains('Already allowlisted for "de"'));
      // The ceiling is quoted with its shaping tolerance, so 41.0px-allowed
      // against a +42.5px measurement cannot read as a breach of what the entry
      // literally says.
      expect(
        detail,
        contains('allowed up to 41.0px (+2.0px shaping tolerance), measured '
            '+80.0px'),
      );
    });
  });

  group('coverage arithmetic', () {
    test('a full run has no gaps, so the dead-entry check is live', () {
      // The pair the whole ratchet ledger rests on. `declare` is what the families
      // report at enumeration; `judge` is what counts measurements. Equal means
      // nothing narrowed the run, which is the only state in which an unused
      // allowlist entry may be called dead.
      final gate = CardSweepGate()
        ..declare('card.width', 1638)
        ..declare('card.normal_band', 208)
        ..declare('card.profile', 52);

      expect(gate.declaredCells, 1898);
      expect(gate.coverageGaps(), [
        '0 of 1898 declared cells were measured (a --name / -c filter, or a cell '
            'that threw before measuring)',
      ]);
    });

    test('declaring twice does not double the count', () {
      // A family that enumerated twice would otherwise report 3,276 declared cells
      // against 1,638 measured — a coverage gap invented by bookkeeping, which
      // would silently disable the dead-entry verdict on a complete run.
      final gate = CardSweepGate()
        ..declare('card.width', 1638)
        ..declare('card.width', 1638);

      expect(gate.declaredCells, 1638);
    });

    testWidgets('a --name filter is a gap, and it is only visible at the end',
        (tester) async {
      // The narrowing the suite cannot see any other way: `--name` is applied by
      // the test runner, so the declaration is complete and the measurements are
      // not. It is deliberately absent from `enumerationGaps` — at count-test time
      // nothing has been measured yet, and treating that as a filter would skip
      // the pin on every run.
      final gate = CardSweepGate()..declare('card.width', 1638);
      await gate.judge(
        tester,
        cellFor('de'),
        verdictWith(const []),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'unreachable',
      );

      expect(gate.enumerationGaps(), isEmpty,
          reason: 'this run set no LOCALE and no MIN_SCREEN');
      expect(gate.coverageGaps().single, contains('1 of 1638'));
    });
  });

  group('the declared form premise', () {
    // #1364. The premise `CardNormalBandFamily` used to assert in its hook body is
    // now a value on the cell, checked by [CardOverflowFamily.onCellSettled]. These
    // are the cases that make that enforceable rather than merely written down:
    // emptying either half — the check, or the declaration the check reads — has to
    // fail something here.
    //
    // The tree is a bare `CardDensityScope`, because that is all
    // [selectedCardDensity] reads. Standing up a real card in the wrong form would
    // mean moving a production threshold to test the harness.
    Future<void> pumpForm(WidgetTester tester, CardDensity density) =>
        tester.pumpWidget(
          CardDensityScope(density: density, child: const SizedBox()),
        );

    CardSweepCell premiseCell({CardDensity? expected}) => CardSweepCell(
          axes: {
            'card': spec.id,
            'width': widthCase.label,
            'px': widthCase.widthKey,
            'tab': 0,
          },
          locale: const Locale('de'),
          cardId: spec.id,
          widthCase: widthCase,
          rows: spec.getConstraints(DisplayMode.normal).minHeightRows,
          expectedDensity: expected,
          expectedDensityReason:
              expected == null ? null : 'the threshold is what puts it here',
        );

    /// The message [body] failed with, or a failure of our own if it passed.
    ///
    /// "It passed" is the mutation this whole group exists to catch, so it gets a
    /// sentence rather than an unexplained `throwsA` mismatch.
    Future<String> failureOf(Future<void> Function() body) async {
      try {
        await body();
      } on TestFailure catch (failure) {
        return failure.message ?? '';
      }
      fail('the declared premise was not checked: this cell asked for one form '
          'and was handed another, and onCellSettled returned normally');
    }

    testWidgets('a tree in another form fails, naming both and the reason',
        (tester) async {
      final family = _PremiseProbeFamily();
      await pumpForm(tester, CardDensity.compact);

      final message = await failureOf(
        () => family.onCellSettled(
            tester,
            premiseCell(
              expected: CardDensity.normal,
            )),
      );

      expect(message, contains('"device_info" @min 191px tab0'));
      expect(message, contains('declares expectedDensity CardDensity.normal'));
      expect(message, contains('selected CardDensity.compact'));
      expect(message, contains('the threshold is what puts it here'),
          reason: 'the family\'s own reason is carried as data so the shared '
              'check can print it — a generic message would send the reader back '
              'to the debugger');
      expect(family.hookRan, isFalse,
          reason: 'the premise is about the tree the runner pumped, so it is '
              'checked before a hook can pump another one over it');
    });

    testWidgets('the same cell passes on the form it declared', (tester) async {
      final family = _PremiseProbeFamily();
      await pumpForm(tester, CardDensity.normal);

      await family.onCellSettled(
          tester,
          premiseCell(
            expected: CardDensity.normal,
          ));

      expect(family.hookRan, isTrue,
          reason: 'the check is a precondition on the hook, not a replacement');
    });

    testWidgets('a tree with no scope at all fails rather than reading normal',
        (tester) async {
      // The vacuous pass this fix could have shipped with. `selectedCardDensity`
      // answers `normal` when nothing published a scope, and `normal` is the one
      // value this band declares — so a card that lost its `CardDensityHost` would
      // satisfy the premise having read nothing, which is #1364's own subject one
      // level down. `publishedCardDensity` returns null instead, and null is not a
      // form.
      final family = _PremiseProbeFamily();
      await tester.pumpWidget(const SizedBox());

      final message = await failureOf(
        () => family.onCellSettled(
            tester,
            premiseCell(
              expected: CardDensity.normal,
            )),
      );

      expect(message, contains('published no CardDensityScope at all'));
      expect(message, contains('CardDensityHost'),
          reason:
              'a missing scope is a missing host, not a moved threshold, and '
              'the two have different first things to look at');
      expect(family.hookRan, isFalse);
    });

    testWidgets('a cell that declares nothing is not asked at all',
        (tester) async {
      // The half that makes an empty hook a legible answer rather than a
      // suspicious one: three card families have no form to assert, and a cell
      // declaring no premise is how they say so. If this ever failed, those three
      // would have to invent a premise to stay green.
      final family = _PremiseProbeFamily();
      await pumpForm(tester, CardDensity.popup);

      await family.onCellSettled(tester, premiseCell());

      expect(family.hookRan, isTrue);
    });

    test('every normal-band cell declares normal, and says why', () {
      // The pin that catches the other mutation: deleting `expectedDensity:` from
      // `CardNormalBandFamily.enumerate()`. Written as a set rather than a count so
      // one cell losing the declaration is the failure — the count is already
      // pinned by the sweep, and a `null` slipping into 234 identical values is
      // exactly what a count cannot see.
      final cells = CardNormalBandFamily(CardSweepGate())
          .enumerateCells()
          .cast<CardSweepCell>()
          .toList();

      expect(cells, isNotEmpty);
      expect(
        {for (final cell in cells) cell.expectedDensity},
        {CardDensity.normal},
        reason:
            'this sweep exists to measure the normal band, and the cells are '
            'the only place that claim is now written down',
      );
      expect(
        cells.where((cell) => cell.expectedDensityReason == null),
        isEmpty,
        reason: 'the reason names the card\'s own normalAbove, which is what '
            'makes the failure actionable',
      );
      expect(cells.first.expectedDensityReason, contains('normalAbove'));
    });

    test('the other two card families declare none, deliberately', () {
      // Not symmetry for its own sake. `card.width` pumps whatever form the grid's
      // narrowest realization selects — the four cards that pass at 191px while
      // rendering unreadably are #1240 AC1's, not a premise this sweep can state —
      // and `card.profile` varies the data, not the form. Pinning the absence is
      // what stops someone "completing" the pattern by declaring a form these
      // sweeps do not have.
      for (final family in [
        CardWidthFamily(CardSweepGate()),
        CardProfileFamily(CardSweepGate()),
      ]) {
        final declared = family
            .enumerateCells()
            .cast<CardSweepCell>()
            .map((cell) => cell.expectedDensity)
            .toSet();
        expect(declared, {null}, reason: '${family.name} declares no form');
      }
    });
  });

  group('the declared structural premise', () {
    // #1366. The other three families' hooks held a `find.byType` `expect` that
    // nothing required them to keep, and the measurement said so: emptying
    // `ForcedCompactFloorFamily`'s two left the forced-form suite 38 of 38 green and
    // the whole `layout-gate` tag 1,368 of 1,368 green. These cases are the two
    // halves that make the move enforceable — the check, and the declaration it
    // reads.
    CardSweepCell premiseCell(List<CardWidgetPremise> premises) =>
        CardSweepCell(
          axes: {
            'card': spec.id,
            'width': widthCase.label,
            'px': widthCase.widthKey,
            'tab': 0,
          },
          locale: const Locale('de'),
          cardId: spec.id,
          widthCase: widthCase,
          rows: spec.getConstraints(DisplayMode.normal).minHeightRows,
          widgetPremises: premises,
        );

    /// The message [body] failed with, or a failure of our own if it passed.
    Future<String> failureOf(Future<void> Function() body) async {
      try {
        await body();
      } on TestFailure catch (failure) {
        return failure.message ?? '';
      }
      fail(
          'the declared premise was not checked: this cell named a widget that '
          'had to be in the tree, or had to be absent from it, and '
          'onCellSettled returned normally');
    }

    testWidgets('a required widget missing fails, naming it and the reason',
        (tester) async {
      final family = _PremiseProbeFamily();
      await tester.pumpWidget(const SizedBox());

      final message = await failureOf(
        () => family.onCellSettled(
          tester,
          premiseCell(const [
            CardWidgetPremise.present(Placeholder,
                reason: 'the pick is what produces it'),
          ]),
        ),
      );

      expect(message, contains('"device_info" @min 191px tab0'));
      expect(message, contains('Placeholder must be in the tree it pumped'));
      expect(message, contains('and 0 were'));
      expect(message, contains('the pick is what produces it'),
          reason: 'the family\'s own reason is carried as data for the same '
              'reason the form premise carries one');
      expect(family.hookRan, isFalse,
          reason: 'the premise is about the tree the runner pumped, so it is '
              'checked before anything can pump another one over it');
    });

    testWidgets(
        'a forbidden widget present fails, and says the smaller form fits',
        (tester) async {
      // The half with teeth. A card that fell through to a *smaller* form passes
      // every overflow assertion in the sweep by fitting the box, so the failure
      // has to say that out loud — a reader who only sees "premise not met" will
      // look for a layout bug that is not there.
      final family = _PremiseProbeFamily();
      await tester.pumpWidget(const Placeholder());

      final message = await failureOf(
        () => family.onCellSettled(
          tester,
          premiseCell(const [
            CardWidgetPremise.absent(Placeholder,
                reason: 'compact is the middle band'),
          ]),
        ),
      );

      expect(
          message, contains('Placeholder must not be in the tree it pumped'));
      expect(message, contains('and 1 were'));
      expect(
          message, contains('the form that fits is not the form under test'));
      expect(family.hookRan, isFalse);
    });

    testWidgets('both directions pass together, and the hook still runs',
        (tester) async {
      final family = _PremiseProbeFamily();
      await tester.pumpWidget(const Placeholder());

      await family.onCellSettled(
        tester,
        premiseCell(const [
          CardWidgetPremise.present(Placeholder,
              reason: 'it is what we pumped'),
          CardWidgetPremise.absent(SizedBox, reason: 'and this is not'),
        ]),
      );

      expect(family.hookRan, isTrue,
          reason: 'the check is a precondition on the hook, not a replacement');
    });

    testWidgets('a cell that declares none is not asked at all',
        (tester) async {
      final family = _PremiseProbeFamily();
      await tester.pumpWidget(const SizedBox());

      await family.onCellSettled(tester, premiseCell(const []));

      expect(family.hookRan, isTrue);
    });

    test('the three premise families declare their structure, and say why', () {
      // The pin that catches the other mutation: deleting `widgetPremises:` from an
      // enumeration. A set per family rather than a count, for the reason the form
      // premise's pin gives — a `const []` slipping into one card's cells is what a
      // count cannot see.
      final expected = <String, List<CardWidgetPremise>>{
        'forced_form.popup_tile': kPopupTilePremise,
        'forced_form.compact_floor': kCompactFloorPremises,
        'popup.form': kPopupFormPremise,
      };

      for (final family in [
        const ForcedPopupTileFamily(),
        const ForcedCompactFloorFamily(),
        const PopupFormFamily(),
      ]) {
        final cells = family.enumerateCells().cast<CardSweepCell>().toList();
        expect(cells, isNotEmpty);
        expect(
          cells.map((cell) => cell.widgetPremises).toSet(),
          {same(expected[family.name])},
          reason:
              '${family.name} measures a form it cannot find by type, so the '
              'structural claim is the only thing standing between a clean '
              'verdict and a verdict about another tree',
        );
      }

      expect(
        expected.values.expand((list) => list).where((p) => p.reason.isEmpty),
        isEmpty,
        reason:
            'a structural claim with no stated reason is one a reader cannot '
            'act on',
      );
    });

    test('the other six card families declare none, deliberately', () {
      // Pinning the absence, for the reason the form premise's twin case gives.
      // `forced_form.skeleton` is the interesting one: the widget under test *is*
      // the override, so it is in the tree by construction and a premise here would
      // assert the harness rather than the card.
      for (final family in [
        CardWidthFamily(CardSweepGate()),
        CardNormalBandFamily(CardSweepGate()),
        CardProfileFamily(CardSweepGate()),
        const ForcedFormSkeletonFamily(),
        const PopupDialogFamily(),
        const PickedPopupDialogFamily(),
      ]) {
        final declared = family
            .enumerateCells()
            .cast<CardSweepCell>()
            .map((cell) => cell.widgetPremises)
            .toSet();
        expect(declared, {isEmpty},
            reason: '${family.name} declares no structural premise');
      }
    });
  });

  group('the declared surface opener', () {
    // #1366's sharper half. The two dialog families' hook did not merely assert a
    // premise, it *produced the surface being measured* — so emptying it left the
    // popup suite 80 of 80 green **and** `overflow_baseline.sh check popup`
    // reporting 347 cells identical, while 78 cells quietly measured the 122px tile
    // instead of the presentation. The baseline is the tool built for exactly that
    // question and it cannot see this, because the cell id and the verdict are both
    // unchanged. Which leaves these cases as the only detector.
    CardSweepCell openerCell({
      CardSurfaceOpener? openWith,
      List<CardWidgetPremise> premises = const [],
    }) =>
        CardSweepCell(
          axes: {
            'card': spec.id,
            'width': widthCase.label,
            'px': widthCase.widthKey,
            'tab': 0,
          },
          locale: const Locale('de'),
          cardId: spec.id,
          widthCase: widthCase,
          rows: spec.getConstraints(DisplayMode.normal).minHeightRows,
          widgetPremises: premises,
          openWith: openWith,
        );

    testWidgets('the declared opener runs, and runs before the hook',
        (tester) async {
      // The order is the whole point: a hook that ran first would be asserting
      // against the tile, which is the confusion the ticket was filed for.
      final order = <String>[];
      final family = _PremiseProbeFamily(onHook: () => order.add('hook'));
      await tester.pumpWidget(const SizedBox());

      await family.onCellSettled(
        tester,
        openerCell(
          openWith: CardSurfaceOpener(
            name: 'probe',
            open: (_, __) async => order.add('open'),
          ),
        ),
      );

      expect(order, ['open', 'hook']);
    });

    testWidgets('a failing premise stops the opener', (tester) async {
      // Ordering in the other direction, and it matters for triage: opening a
      // surface on top of a tree that already failed its premise buries the first
      // failure under whatever the tap does next.
      var opened = false;
      final family = _PremiseProbeFamily();
      await tester.pumpWidget(const SizedBox());

      try {
        await family.onCellSettled(
          tester,
          openerCell(
            premises: const [
              CardWidgetPremise.present(Placeholder, reason: 'never here'),
            ],
            openWith: CardSurfaceOpener(
              name: 'probe',
              open: (_, __) async => opened = true,
            ),
          ),
        );
        fail('the premise was not checked before the surface was opened');
      } on TestFailure catch (_) {
        expect(opened, isFalse);
      }
    });

    testWidgets('a cell that declares none opens nothing', (tester) async {
      final family = _PremiseProbeFamily();
      await tester.pumpWidget(const SizedBox());

      await family.onCellSettled(tester, openerCell());

      expect(family.hookRan, isTrue);
    });

    test('the two dialog families declare the presentation opener', () {
      // The pin that catches deleting `openWith:` from either enumeration — the
      // mutation that was killed by nothing, baseline included.
      for (final family in [
        const PopupDialogFamily(),
        const PickedPopupDialogFamily(),
      ]) {
        final cells = family.enumerateCells().cast<CardSweepCell>().toList();
        expect(cells, isNotEmpty);
        expect(
          cells.map((cell) => cell.openWith?.name).toSet(),
          {kPresentationOpener.name},
          reason: '${family.name} is named after the presentation, and tapping '
              'the tile open is the only thing that puts one in the tree',
        );
      }
    });

    test('and no other card family declares one', () {
      // Symmetry with the form premise's absence pin, and the same reason: a family
      // that declared an opener it does not need would tap a tile that is not there.
      for (final family in [
        CardWidthFamily(CardSweepGate()),
        CardNormalBandFamily(CardSweepGate()),
        CardProfileFamily(CardSweepGate()),
        const ForcedPopupTileFamily(),
        const ForcedFormSkeletonFamily(),
        const ForcedCompactFloorFamily(),
        const PopupFormFamily(),
      ]) {
        final declared = family
            .enumerateCells()
            .cast<CardSweepCell>()
            .map((cell) => cell.openWith)
            .toSet();
        expect(declared, {null},
            reason: '${family.name} measures the tree the runner pumped');
      }
    });
  });

  group('the closing direction', () {
    testWidgets('a complete run reports the entry nothing needed',
        (tester) async {
      // The ratchet's second question, and the reason `judge` counts clean cells:
      // an exemption that no cell overflowed against is debt that was paid and
      // never written off, and the next real overflow at that line would be
      // waved through as this ticket's known debt.
      final gate = CardSweepGate()
        ..ratchet = leasedRatchet()
        ..declare('card.width', 1);
      await gate.judge(
        tester,
        cellFor('de'),
        verdictWith(const []),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'unreachable',
      );

      expect(gate.coverageGaps(), isEmpty, reason: '1 declared, 1 measured');
      final dead = await gate.close();
      expect(dead, isNotNull);
      expect(dead, contains('lib/x.dart:9'));
      expect(dead, contains('no gated cell overflowed there in this run'));
    });

    testWidgets(
        'a narrowed run takes no verdict, and says which one it skipped',
        (tester) async {
      // The guard that matters more than the check: the same measurements as
      // above, one declared cell short of complete. A partial run cannot tell "the
      // defect is fixed" from "that cell was never pumped", and calling a live
      // entry dead would send someone to delete a real exemption.
      final gate = CardSweepGate()
        ..ratchet = leasedRatchet()
        ..declare('card.width', 2);
      await gate.judge(
        tester,
        cellFor('de'),
        verdictWith(const []),
        subject: 'device_info @min 191px tab0',
        failure: (d) => 'unreachable',
      );

      final printed = <String>[];
      final dead = await runZoned(
        gate.close,
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => printed.add(line),
        ),
      );

      expect(dead, isNull);
      expect(printed, hasLength(1),
          reason: 'a skipped check is announced exactly once, at the end');
      expect(printed.single, contains('1 of 2 declared cells were measured'));
    });
  });
}

/// A card family that enumerates nothing and records whether its hook ran.
///
/// So that the premise cases exercise [CardOverflowFamily.onCellSettled] and
/// nothing else: the nine real families each carry an enumeration and a verdict, and
/// any of those failing would look like the check failing. `hookRan` is what pins the
/// *order*, which is the part a reader cannot see from the call — and [onHook], for
/// the one case where the order is three-way rather than two (#1366).
class _PremiseProbeFamily extends CardOverflowFamily {
  _PremiseProbeFamily({this.onHook});

  final void Function()? onHook;

  bool hookRan = false;

  @override
  String get name => 'card.premise_probe';

  @override
  List<String> get axisNames => const ['card'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() => const [];

  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {
    hookRan = true;
    onHook?.call();
  }
}
