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
    required this.expectedDensity,
    required this.expectedDensityReason,
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
    CardDensity? expectedDensity,
    String? expectedDensityReason,
    Widget? cardOverride,
    int? screenHeightRows,
    GlobalKey? repaintKey,
    List<Override> Function()? overrides,
  }) {
    assert(
      expectedDensityReason == null || expectedDensity != null,
      'a reason with no declared density asserts nothing: it would be quoted by '
      'a failure that can never happen',
    );
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
      expectedDensity: expectedDensity,
      expectedDensityReason: expectedDensityReason,
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

  /// The form this cell's tree must have selected for its measurement to be about
  /// the coordinate it is named after — or null for "this cell asserts nothing
  /// about the form it measured, and is saying so" (#1364).
  ///
  /// ## Not the same field as `density`
  ///
  /// The factory's `density` is what a cell *pins into* the tree, through
  /// `cardDensityOverrideProvider`; this is what the tree is *required to have
  /// come out as*. They coincide for a forced cell and are unrelated for a swept
  /// one: [CardNormalBandFamily] pins nothing and picks a width at which
  /// production's own rule selects normal, which is exactly the premise that can
  /// stop being true without anyone editing the sweep.
  ///
  /// ## Why it is a declared value and not an `expect` in a hook
  ///
  /// #1364. `onCardSettled` is abstract, so a family cannot *omit* it — but an
  /// emptied body is a legal family that measures overflow and asserts nothing
  /// about the tree it measured it in, and nothing in the gate noticed. Measured:
  /// emptying [CardNormalBandFamily]'s hook left the card suite 102 of 102 green,
  /// and paired with a loosened `normalBandCaseFor` it took that mutation from 10
  /// killers to 1 while 234 cells carried on measuring the wrong band.
  ///
  /// As data it is enforced by [CardOverflowFamily.onCellSettled], which no family
  /// overrides, and pinned by `dashboard_card_gate_test.dart` — the same move
  /// `expectedCellCount` already made for coverage. It also separates the two empty
  /// hooks by construction: a family that declares no premise is answering the
  /// question, where a family with an emptied body is not.
  ///
  /// ## Which families declare one
  ///
  /// The one whose premise *is* a form: [CardNormalBandFamily]. The forced-form and
  /// popup families pin their density and then assert something strictly stronger in
  /// their hooks — that the form's own widget is in the tree — so their premise is
  /// structural and stays there. [CardWidthFamily] and [CardProfileFamily] declare
  /// none, and their hooks say why.
  final CardDensity? expectedDensity;

  /// Why this coordinate must select [expectedDensity], and what to look at when it
  /// did not — quoted verbatim by [cardDensityPremiseFailure].
  ///
  /// The family's own prose, carried as data so the shared check can print it: the
  /// reason a width is the normal band's is `normalAbove`, which the framework has
  /// no business knowing. Null is allowed and asserted against a null
  /// [expectedDensity] in the factory, since a reason for a premise that does not
  /// exist would be quoted by a failure that cannot happen.
  final String? expectedDensityReason;

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

/// What a broken form premise reads as: the coordinate, both forms, and the
/// family's own reason.
///
/// A pure function rather than a `reason:` built inline, so the wording is
/// assertable from `dashboard_card_gate_test.dart` without pumping a card that is
/// genuinely in the wrong form — and because this is the message that has to carry
/// triage on its own: [CardNormalBandFamily] collects no report row, so there is no
/// HTML page to open behind it.
String cardDensityPremiseFailure(CardSweepCell card, CardDensity? selected) {
  final declared =
      '"${card.cardId}" ${card.widthLabel} declares expectedDensity '
      'CardDensity.${card.expectedDensity!.name}, and the tree it pumped ';
  return [
    if (selected == null)
      '$declared'
          'published no CardDensityScope at all. Nothing in it selected a form, '
          'so there is no host that applied the threshold — and this cell is not '
          'measuring the band it is named after, whatever it is measuring. Read '
          'as a pass it would be the emptiest premise there is: '
          '`selectedCardDensity` answers `normal` when the scope is missing, '
          'which is exactly the value declared here.'
    else
      '$declared'
          'selected CardDensity.${selected.name}. This cell measured a form its '
          'own coordinate does not name, so every overflow verdict it reported is '
          'about the wrong layout.',
    if (card.expectedDensityReason != null) card.expectedDensityReason!,
    if (selected == null)
      'Look first at whether the host is still there: `buildDashboardCardApp` '
          'wraps the card in a `CardDensityHost`, and every path through that '
          'widget publishes a scope, so no scope means the wrapping went away '
          'rather than the threshold moving.'
    else
      'If this coordinate is genuinely meant to measure another form now, move '
          'the declaration and say why — deleting it leaves the cells measuring '
          'whatever they happen to select.',
    'The premise is declared on the cell and checked for every card family '
        '(#1364), so it is not something a hook body can be emptied out of.',
  ].join('\n');
}

/// Checks the form premise [card] declared against the tree that was just pumped.
///
/// Nothing at all for a cell that declared none, which is the deliberately-empty
/// case made legible: three families have no form to assert and say so in their
/// hooks, and this is what tells them apart from a family whose assertion was
/// deleted (#1364).
///
/// [publishedCardDensity] is read only when there is a premise to check — it walks
/// the element tree for a `CardDensityScope`, and every card cell in the gate
/// except the normal band's 234 declares nothing.
///
/// [publishedCardDensity] and not [selectedCardDensity], because the latter answers
/// `normal` for a tree that published no scope at all — the same value this band
/// declares, so a card that lost its `CardDensityHost` would pass a premise that had
/// read nothing. A vacuous pass is the thing #1364 is about, and it would be
/// embarrassing to leave one inside its own fix.
void checkCardDensityPremise(WidgetTester tester, CardSweepCell card) {
  final expected = card.expectedDensity;
  if (expected == null) return;
  final selected = publishedCardDensity(tester);
  if (selected == expected) return;
  fail(cardDensityPremiseFailure(card, selected));
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
///
/// Being asked, though, is not the same as answering, which is #1364: the abstract
/// member forces a *declaration* and nothing forced the body to assert anything.
/// [onCellSettled] is therefore no longer a bare delegation — it checks the form
/// premise the cell declared first, and that half is framework code sitting under
/// every card family at once.
abstract class CardOverflowFamily extends OverflowSurfaceFamily {
  const CardOverflowFamily();

  @override
  Future<void> onCellSettled(
      WidgetTester tester, OverflowSweepCell cell) async {
    final card = cell as CardSweepCell;
    // Before the family's hook, not after. The premise is about the tree the
    // runner pumped, and two hooks pump another one over it: the dialog
    // `_openPresentation` opens publishes a density scope of its own, so a check
    // that ran afterwards would be reading the presentation's form.
    checkCardDensityPremise(tester, card);
    await onCardSettled(tester, card);
  }

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
