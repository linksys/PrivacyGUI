/// What every dashboard-card sweep is made of: one card coordinate, and the
/// family shape that narrows the runner's hooks to it (#1344).
///
/// ## Why this is its own file
///
/// [CardSweepCell] arrived with #1343 inside `dashboard_card_family.dart`, whose
/// header says that file is "the enumeration and the verdict, and nothing else".
/// #1344 and #1345 put three more families each on the same cell, in two more
/// suites, so it is no longer a detail of the largest surface — it is the card
/// half of the framework, and six families now depend on it. Left where it was,
/// two suites would import a third suite's families to reach it, and the
/// `families/` directory would have one file that means both things.
///
/// Nothing here knows about [CardSweepGate]: the ratchet, the report and the PNG
/// dump belong to the three sweeps that have them, which is why [judgeCard] has a
/// working default and `dashboard_card_family.dart`'s own base re-abstracts it.
/// The two secondary suites use the geometry half alone.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';

import '../../util/dashboard/dashboard_card_probe.dart';
import '../locale_tag.dart';
import '../sweep.dart';

/// The three locales that bound the text of a card sweep that cannot afford 26.
///
/// English as the baseline, German for the longest Latin compounds, Traditional
/// Chinese for the widest glyphs. One list rather than the two identical consts
/// #1344 and #1345 found in their suites, each restating the same three reasons:
/// the sweeps that take it are the *second* pump of a coordinate the 26-locale
/// sweeps already cover, so what they add is a geometry or a card list, not a
/// string table. A locale added here is added to all of them, which is the point.
const List<Locale> kCardTextBoundingLocales = [
  Locale('en'),
  Locale('de'),
  Locale('zh', 'TW'),
];

/// One card coordinate, plus what a family needs to judge it.
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
  ///
  /// [tab] and [tabCount] default to a single-view card because five of the six
  /// families sweep a *degraded* form, and no degraded form has a tab bar — the
  /// popup form renders one value over the card's name, so a tab index there
  /// selects nothing.
  factory CardSweepCell({
    required Map<String, Object?> axes,
    required Locale locale,
    required String cardId,
    required CardWidthCase widthCase,
    required int rows,
    int tab = 0,
    int tabCount = 1,
    CardDensity? density,
    Widget? cardOverride,
    int? screenHeightRows,
    GlobalKey? repaintKey,
    List<Override> Function()? overrides,
  }) {
    final cardHeight = dashboardCardHeight(rows);
    return CardSweepCell._(
      axes: axes,
      locale: locale,
      // The viewport is the card's own box unless [screenHeightRows] says
      // otherwise, which is what keeps every sweep measuring exactly the space
      // the grid gives the card (`probeCardOverflow` says the same, and why —
      // including the one case where the two genuinely differ: a picked popup
      // tile is one row of a full-height screen, and sizing the viewport to that
      // row would leave the presentation it opens no room to be drawn at all).
      surfaceSize: Size(
        widthCase.screenWidth,
        dashboardCardHeight(screenHeightRows ?? rows),
      ),
      build: () => buildDashboardCardApp(
        cardId: cardId,
        locale: locale,
        screenWidth: widthCase.screenWidth,
        cardWidth: widthCase.cardWidth,
        cardHeight: cardHeight,
        tabIndex: tab,
        repaintKey: repaintKey,
        cardOverride: cardOverride,
        density: density,
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
  /// PNG dump run — and null for every family that does not dump, which is five
  /// of the six.
  final GlobalKey? repaintKey;

  String get tag => localeTag(locale);

  /// `@min 191px tab0` — the coordinate as the dump tooling and the tolerated-
  /// overflow line spell it.
  String get widthLabel => '@${widthCase.label} ${widthCase.widthKey}px '
      'tab$tab';
}

/// A family whose cells are all [CardSweepCell]s: the runner's two hooks with the
/// cast paid once.
///
/// Safe by construction, and unsound to express in the signature instead: the
/// runner's hooks are typed on the base cell, and the only cells it hands back are
/// the ones the family enumerated.
///
/// [onCardSettled] stays **abstract**, which is the point — `onCellSettled` is
/// abstract in the runner deliberately (`sweep.dart`'s header), and an inherited
/// empty body is exactly how the next family would stop being asked whether it has
/// a premise to check. [judgeCard] is not: its default *is* the runner's default
/// verdict, which is what five of the six card families want, and the one that
/// needs more re-abstracts it rather than making the other five say so.
abstract class CardOverflowFamily extends OverflowSurfaceFamily {
  const CardOverflowFamily();

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

  /// The runner's own zero-tolerance verdict, reached through the cast.
  Future<String?> judgeCard(
    WidgetTester tester,
    CardSweepCell cell,
    OverflowCellVerdict verdict,
  ) =>
      super.judgeCell(tester, cell, verdict);
}
