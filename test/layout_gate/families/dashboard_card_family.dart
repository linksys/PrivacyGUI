/// The dashboard card families: which card coordinates the gate measures (#1343).
///
/// The port of the gate's largest surface — 1,898 of its 3,587 committed baseline
/// cells — onto [runOverflowSweep]. What each of the three sweeps *is* remains
/// documented where it is declared (`dashboard_card_overflow_test.dart`); this file
/// is the enumeration and the verdict, and nothing else.
///
/// ## Three families, one gate
///
/// The dataset already records three groups — `card.width`, `card.normal_band`,
/// `card.profile` — and [OverflowSurfaceFamily.name] *is* that group name, so one
/// class could not have kept the 1,898 cell ids byte-identical. They also differ in
/// the two ways §2 calls essential: `card.profile` carries a `profile` axis the
/// others do not, and `card.normal_band` asserts something about the tree it pumps
/// (that production still selects the normal form there) which is meaningless for
/// the other two.
///
/// What they share — the allowlist, the report, the locale set, the coverage
/// counters — is one [CardSweepGate] passed to all three. See its header for why
/// that state cannot be per-family. The shape they share is `_CardFamily`, which
/// holds the gate, the cached enumeration and the coverage delegate, and narrows
/// both runner hooks to [CardSweepCell] so the cast is paid once.
///
/// ## Why the host is a plain `buildDashboardCardApp` call
///
/// [probeCardOverflow] is the pre-#1343 equivalent of the whole runner: it installs
/// the collector, sets the surface, pumps and settles. Under the runner those are
/// the runner's job (invariants 1–3), so a family that called it would nest one
/// collector inside another and key nothing. What survives from it is the two lines
/// that are actually about a card — the surface is the card's own box, and the host
/// is [buildDashboardCardApp] — reproduced here exactly, which is what keeps the
/// measurement identical. The satellite suites still call `probeCardOverflow`, so it
/// stays.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';

import '../../util/dashboard/card_data_profiles.dart';
import '../../util/dashboard/dashboard_card_probe.dart';
import '../locale_tag.dart';
import '../sweep.dart';
import 'dashboard_card_gate.dart';

/// One card coordinate, plus what the gate needs to judge it.
///
/// A subclass rather than a `Map` of extras on [OverflowSweepCell.axes]: the axes
/// are the cell's *identity* and every entry in them lands in the dataset id, so
/// putting `tabCount` or a `GlobalKey` there would rename 1,898 cells. Everything
/// here is derivable from the axes plus the registry, and is carried rather than
/// re-derived because the verdict is 26 locales deep in a loop.
class CardSweepCell extends OverflowSweepCell {
  CardSweepCell._({
    required super.axes,
    required super.locale,
    required super.surfaceSize,
    required super.build,
    required this.cardId,
    required this.widthCase,
    required this.rows,
    required this.tab,
    required this.tabCount,
    required this.repaintKey,
  });

  /// Builds the cell and the host it pumps in one place, so the surface and the
  /// card geometry cannot be given two different heights.
  ///
  /// [overrides] is called inside [build] rather than here: `profile.overrides()`
  /// constructs Riverpod overrides, and the pre-#1343 sweep built them per pump.
  /// Building them once at enumeration would make 52 cells share one list, which
  /// is a change to what the sweep pumps rather than to how it is declared.
  factory CardSweepCell({
    required Map<String, Object?> axes,
    required Locale locale,
    required String cardId,
    required CardWidthCase widthCase,
    required int rows,
    required int tab,
    required int tabCount,
    List<Override> Function()? overrides,
  }) {
    // Allocated per cell, and only when a dump run will read it: a `GlobalKey`
    // must be unique in the tree, and one cell's host is the only tree mounted
    // while it is measured.
    final repaintKey = shouldDumpCardPng ? GlobalKey() : null;
    final cardHeight = dashboardCardHeight(rows);
    return CardSweepCell._(
      axes: axes,
      locale: locale,
      // The viewport is the card's own box, which is what keeps every sweep
      // measuring exactly the space the grid gives the card
      // (`probeCardOverflow` says the same, and why).
      surfaceSize: Size(widthCase.screenWidth, cardHeight),
      build: () => buildDashboardCardApp(
        cardId: cardId,
        locale: locale,
        screenWidth: widthCase.screenWidth,
        cardWidth: widthCase.cardWidth,
        cardHeight: cardHeight,
        tabIndex: tab,
        repaintKey: repaintKey,
        extraOverrides: overrides?.call() ?? const [],
      ),
      cardId: cardId,
      widthCase: widthCase,
      rows: rows,
      tab: tab,
      tabCount: tabCount,
      repaintKey: repaintKey,
    );
  }

  final String cardId;
  final CardWidthCase widthCase;
  final int rows;
  final int tab;

  /// How many tabs the card has — not which one this cell pumps. It is in the PNG
  /// filename and the report row, both of which distinguish "tab 0 of 3" from a
  /// single-view card.
  final int tabCount;

  /// The `RepaintBoundary` key the before-screenshot is taken from, null outside a
  /// PNG dump run.
  final GlobalKey? repaintKey;

  String get tag => localeTag(locale);

  /// `@min 191px tab0` — the coordinate as the dump tooling and the tolerated-
  /// overflow line spell it.
  String get widthLabel => '@${widthCase.label} ${widthCase.widthKey}px '
      'tab$tab';
}

/// The registry entry for a card id.
///
/// Non-null by construction everywhere it is called: every id reaching it came
/// either from [UspWidgetSpecs.all] itself or from a list the suite pins against
/// it, so a missing id is a broken pin and belongs as a throw here.
WidgetSpec _specFor(String cardId) =>
    UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);

/// What the three card families share: the gate, the cached enumeration, the
/// coverage answer, and the cell type.
///
/// A base class rather than three copies, for a reason beyond the line count:
/// [enumerationGaps] has to delegate to the gate in *every* card family, because
/// the two defines it reports narrow all three enumerations at once. A fourth
/// family that forgot to override it would pin a subset of its cells as though it
/// were the whole sweep — green, while measuring less than it claims.
///
/// [onCardSettled] and [judgeCard] are the runner's two hooks with the cast paid
/// once. They stay **abstract**, which is the point: `onCellSettled` is abstract
/// in the runner deliberately (architecture doc §6), and an inherited empty body
/// is exactly how the next family would stop being asked whether it has a premise
/// to check.
abstract class _CardFamily extends OverflowSurfaceFamily {
  _CardFamily(this.gate);

  final CardSweepGate gate;

  @override
  Iterable<OverflowSweepCell> enumerateCells() => cells;

  /// Enumerated once, lazily, and cached: [runOverflowSweep] calls this once per
  /// declaration, and [CardSweepGate.declare] must be told a number that cannot
  /// then be counted twice.
  late final List<CardSweepCell> cells = enumerate();

  /// Every coordinate this family measures, ending in the [CardSweepGate.declare]
  /// the count test reads.
  List<CardSweepCell> enumerate();

  /// The cast each hook would otherwise repeat, paid once and explained once.
  ///
  /// Safe by construction, and unsound to express in the signature instead: the
  /// runner's hooks are typed on the base cell, and the only cells it hands back
  /// are the ones [enumerate] built.
  @override
  Future<void> onCellSettled(WidgetTester tester, OverflowSweepCell cell) =>
      onCardSettled(tester, cell as CardSweepCell);

  @override
  Future<String?> judgeCell(
    WidgetTester tester,
    OverflowSweepCell cell,
    OverflowCellVerdict verdict,
  ) =>
      judgeCard(tester, cell as CardSweepCell, verdict);

  Future<void> onCardSettled(WidgetTester tester, CardSweepCell cell);

  Future<String?> judgeCard(
    WidgetTester tester,
    CardSweepCell cell,
    OverflowCellVerdict verdict,
  );

  @override
  List<String> enumerationGaps() => gate.enumerationGaps();
}

/// The main sweep: every card, at the narrowest realization of each column span
/// its spec declares, on every tab, in every locale. 1,638 cells.
///
/// The only family that dumps PNGs and collects report rows, which is the whole
/// reason #1343 is the ticket the ratchet and report hooks were shaped by.
class CardWidthFamily extends _CardFamily {
  CardWidthFamily(super.gate);

  @override
  String get name => 'card.width';

  @override
  List<String> get axisNames => const ['card', 'width', 'px', 'tab'];

  @override
  List<CardSweepCell> enumerate() {
    final cells = <CardSweepCell>[];
    // Loop order is the pre-#1343 declaration order — card, width, tab, locale —
    // because it is the order the committed dataset was captured in and the order
    // the grouping preserves.
    for (final spec in UspWidgetSpecs.all) {
      final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
      final tabCount = tabCountFor(spec.id);
      for (final wc in widthCasesFor(spec)) {
        for (var tab = 0; tab < tabCount; tab++) {
          for (final locale in cardSweepLocales) {
            cells.add(CardSweepCell(
              axes: {
                'card': spec.id,
                'width': wc.label,
                'px': wc.widthKey,
                'tab': tab,
              },
              locale: locale,
              cardId: spec.id,
              widthCase: wc,
              rows: rows,
              tab: tab,
              tabCount: tabCount,
            ));
          }
        }
      }
    }
    gate.declare(name, cells.length);
    return cells;
  }

  /// Nothing yet, and named as a gap rather than left blank: four cards pass this
  /// sweep at 191px while rendering unreadably (`overflow_gate_architecture.md`
  /// §7), which is #1240 AC1's work and not something this port may quietly
  /// pretend it did.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell cell) async {}

  @override
  Future<String?> judgeCard(
    WidgetTester tester,
    CardSweepCell card,
    OverflowCellVerdict verdict,
  ) {
    return gate.judge(
      tester,
      card,
      verdict,
      subject: '${card.cardId} ${card.widthLabel}',
      withReport: true,
      failure: (detail) => 'Dashboard card "${card.cardId}" overflows at '
          '${card.widthCase.label} width (${card.widthCase.widthKey}px), tab '
          '${card.tab}, locale "${card.tag}": $detail.',
    );
  }
}

/// The normal band (#1318): the six cards that declare a `normalAbove`, each at the
/// narrowest width the grid produces at or above its own threshold. 208 cells.
///
/// For three of the six this is the only place the grid's own widths reach the
/// normal form at all — see the sweep's own header in the suite for the
/// measurement, and [normalBandCaseFor] for why one width per card is exhaustive
/// within a form.
class CardNormalBandFamily extends _CardFamily {
  CardNormalBandFamily(super.gate);

  @override
  String get name => 'card.normal_band';

  @override
  List<String> get axisNames => const ['card', 'width', 'px', 'tab'];

  @override
  List<CardSweepCell> enumerate() {
    final cells = <CardSweepCell>[];
    for (final spec in normalBandSpecs) {
      final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
      final wc = normalBandCaseFor(spec)!;
      final tabCount = tabCountFor(spec.id);
      for (var tab = 0; tab < tabCount; tab++) {
        for (final locale in cardSweepLocales) {
          cells.add(CardSweepCell(
            axes: {
              'card': spec.id,
              'width': wc.label,
              'px': wc.widthKey,
              'tab': tab,
            },
            locale: locale,
            cardId: spec.id,
            widthCase: wc,
            rows: rows,
            tab: tab,
            tabCount: tabCount,
          ));
        }
      }
    }
    gate.declare(name, cells.length);
    return cells;
  }

  /// The sweep's premise, checked on the tree it just pumped: no density is pinned
  /// here, so a threshold that moved out from under the coordinate would leave
  /// these cells measuring a degraded form and reporting green.
  ///
  /// In the settled-cell hook rather than after the measurement, which is what the
  /// hook is for. A failure here is invariant 3's case: it becomes this cell's
  /// failure and the other 25 locales are still measured — where the pre-#1343
  /// `expect` failed one whole `testWidgets`, which was one locale anyway.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell card) async {
    final spec = _specFor(card.cardId);
    expect(
      selectedCardDensity(tester),
      CardDensity.normal,
      reason:
          '"${card.cardId}" was pumped at ${card.widthCase.widthKey}px — the '
          'narrowest width at or above its declared normalAbove '
          '(${spec.normalAbove}) — but selected a degraded form, so this case is '
          'no longer measuring the normal band. normalBandCaseFor and '
          'densityForWidth have disagreed: check whether the threshold moved or '
          'the selection rule changed.',
    );
  }

  @override
  Future<String?> judgeCard(
    WidgetTester tester,
    CardSweepCell card,
    OverflowCellVerdict verdict,
  ) {
    final spec = _specFor(card.cardId);
    return gate.judge(
      tester,
      card,
      verdict,
      subject: '${card.cardId} ${card.widthLabel}',
      failure: (detail) =>
          'Dashboard card "${card.cardId}" overflows in its **normal** form at '
          '${card.widthCase.widthKey}px — the narrowest width its own '
          'normalAbove (${spec.normalAbove}) admits — tab ${card.tab}, locale '
          '"${card.tag}": $detail.\n'
          'This width is above the threshold, so no degradation applies here: the '
          'fix is to the normal form itself, or to the threshold if the form '
          'cannot read at this width (#1288 measured it).',
    );
  }
}

/// The cards that declare a `normalAbove`, in registry order.
///
/// Shared with the suite, which pins the list and the thresholds: this sweep's size
/// is entirely a function of it, so a card that gains or loses a threshold has to
/// be a failure rather than a silent change in coverage.
final List<WidgetSpec> normalBandSpecs =
    UspWidgetSpecs.all.where((s) => s.normalAbove != null).toList();

/// The named data profiles (#1267): the same widths and locales as the main sweep,
/// on a second router shape. 52 cells.
///
/// `kCardDataProfileSweeps` decides which (card, tab) pairs are worth a second
/// profile — see `card_data_profiles.dart` for why the list is opt-in per card
/// rather than all 18, and what that deliberately does not claim.
class CardProfileFamily extends _CardFamily {
  CardProfileFamily(super.gate);

  @override
  String get name => 'card.profile';

  @override
  List<String> get axisNames => const ['card', 'profile', 'width', 'px', 'tab'];

  /// Kept beside the cells so [judgeCard] can name the profile without a second
  /// lookup: the axis carries its key, and the failure quotes its description.
  final Map<String, CardDataProfile> _profiles = {};

  @override
  List<CardSweepCell> enumerate() {
    final cells = <CardSweepCell>[];
    for (final sweep in kCardDataProfileSweeps) {
      final spec = _specFor(sweep.cardId);
      final rows = spec.getConstraints(DisplayMode.normal).minHeightRows;
      final widthCases = widthCasesFor(spec);
      final tabCount = tabCountFor(spec.id);
      final profile = sweep.profile;
      _profiles[profile.key] = profile;
      for (final tab in sweep.tabs) {
        for (final wc in widthCases) {
          for (final locale in cardSweepLocales) {
            cells.add(CardSweepCell(
              axes: {
                'card': sweep.cardId,
                'profile': profile.key,
                'width': wc.label,
                'px': wc.widthKey,
                'tab': tab,
              },
              locale: locale,
              cardId: sweep.cardId,
              widthCase: wc,
              rows: rows,
              tab: tab,
              tabCount: tabCount,
              overrides: profile.overrides,
            ));
          }
        }
      }
    }
    gate.declare(name, cells.length);
    return cells;
  }

  /// Nothing: whether the profile's data actually reached the tree is checked by
  /// the suite's own guard at one desktop coordinate, not 52 times here — see the
  /// sweep's header.
  @override
  Future<void> onCardSettled(WidgetTester tester, CardSweepCell cell) async {}

  @override
  Future<String?> judgeCard(
    WidgetTester tester,
    CardSweepCell card,
    OverflowCellVerdict verdict,
  ) {
    // Non-null by construction: the axis value was written from this map's key.
    final profile = _profiles[card.axes['profile']]!;
    return gate.judge(
      tester,
      card,
      verdict,
      subject: '${card.cardId} [${profile.key}] ${card.widthLabel}',
      failure: (detail) => 'Dashboard card "${card.cardId}" overflows on the '
          '"${profile.key}" data profile (${profile.description}) at '
          '${card.widthCase.label} width (${card.widthCase.widthKey}px), tab '
          '${card.tab}, locale "${card.tag}": $detail.\n'
          'This coordinate is clean on the default profile — the data, not the '
          'width, is what breaks it, so allowlisting it exempts the same source '
          'location on the default data too (see the note above this sweep).',
    );
  }
}
