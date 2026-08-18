@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/card_form_choice.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_envelope.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/card_forms_provider.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

/// #1299 — what a picked form does on screen: the handles it removes, and the
/// content it selects.
///
/// The persistence half of this ticket is covered by
/// `test/page/dashboard/providers/usp_card_form_persistence_test.dart`, which
/// asserts the *flags* — `isResizable: false`, a raised `minW`. Flags are not the
/// acceptance criterion. AC 6 asks for the effect: **no resize handle is built**.
/// That is a widget-tree fact, and only a pumped grid can state it, because the
/// step from `LayoutItem.isResizable` to a handle belongs to the package
/// (`DashboardItemWrapper`, which gates on
/// `isEditing && (isResizable ?? true) && !isStatic`) rather than to us. A package
/// bump that stopped honouring the flag would leave every persistence test green
/// and every popup card resizable; this file is what fails instead.
///
/// The second half is the render side. A pick has to reach the *content*, not just
/// the box: [CardDensityHost] resolves three sources in order — the #1183 gate's
/// override, then the user's pick, then the measured width — and the pick has to
/// win over a width that would have chosen something else. Otherwise a card can be
/// picked into popup and still render its full form inside a 2x1 tile, which is
/// the overflow the parent epic exists to prevent.
///
/// ## Mutation table
///
/// Each row is one edit to the named source file, applied to the real file and run
/// against this file. Counts are what the run reported.
///
/// | # | mutated | mutation | killed by |
/// |---|---|---|---|
/// | 1 | `card_density_scope` | `CardDensityHost` ignores the pick entirely | 3 — every "a pick beats the width" test |
/// | 2 | `card_density_scope` | the pick is resolved *after* the no-threshold short-circuit | a card with no threshold still honours a pick |
/// | 3 | `card_density_scope` | drop `picked != CardDensity.normal`, so normal pins | an explicit normal pick does not pin |
/// | 4 | `card_density_scope` | read the pick at a hardcoded 12 instead of `currentMaxColumns` | 2 — the two phone-grid tests |
/// | 5 | `usp_widget_specs` | popup arm drops `isResizable: false` | the popup card has none, and its neighbour still has all eight |
/// | 6 | `usp_widget_specs` | compact arm writes `isResizable: false` instead of `true` | compact keeps its handles — its floor is a limit, not a lock |
///
/// Row 4 **survived** the first run: with every test pumped at a 1440px desktop,
/// "the current breakpoint" and "12" are the same number, so a hardcoded key was
/// indistinguishable — including in the test whose name is about breakpoints, since
/// it stores a *phone* pick and reads at desktop. The two phone-grid tests were
/// added for it, and they are also the case the ticket exists for. §2.6h item 4's
/// lesson, in a second shape: **a test can be about the right thing and still be
/// unable to fail.**
void main() {
  // ---------------------------------------------------------------------------
  // AC 6 — popup takes the resize handles away
  // ---------------------------------------------------------------------------

  /// A two-card layout run through the production normalisation, so the geometry
  /// under test is derived the same way the controller derives it.
  ///
  /// `device_info` is the card that gets picked; `lan_info` is the control. Both
  /// declare `normalAbove`, so both are eligible for every form — the difference
  /// between them in each test is the pick, and nothing else.
  List<dynamic> pickedLayout(Map<String, CardFormChoice> choices) =>
      UspWidgetSpecs.applyCardForms(
        [
          {
            'id': 'device_info',
            'x': 0,
            'y': 0,
            'w': 6,
            'h': 3,
            'minW': 3,
            'maxW': 8.0,
            'minH': 2,
            'maxH': 6.0,
          },
          {
            'id': 'lan_info',
            'x': 6,
            'y': 0,
            'w': 6,
            'h': 3,
            'minW': 3,
            'maxW': 8.0,
            'minH': 2,
            'maxH': 6.0,
          },
        ],
        UspLayoutEnvelope.desktopSlotCount,
        choices,
      );

  /// Pumps [layout] on a 12-column grid in edit mode.
  ///
  /// `DashboardOverlay` is included because production has it and it owns the
  /// pointer handling the handles are hit-tested through; leaving it out would
  /// pump a tree that is not the one shipping. Each item renders its own id, which
  /// is how a handle is later attributed to a card.
  Future<void> pumpGrid(WidgetTester tester, List<dynamic> layout) async {
    final controller = DashboardController(initialSlotCount: 12);
    controller.importLayout(layout);
    controller.setEditMode(true);
    addTearDown(controller.dispose);

    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    Widget itemBuilder(BuildContext context, LayoutItem item) =>
        Container(color: Colors.blue.shade100, child: Text(item.id));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardOverlay(
          controller: controller,
          scrollController: scrollController,
          itemBuilder: itemBuilder,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverDashboard(itemBuilder: itemBuilder, breakpoints: {0: 12}),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// How many resize handles the card showing [id] has.
  ///
  /// Per card rather than in total: a total tells you handles went missing, not
  /// which card lost them, and "the popup card has none" and "the grid has none"
  /// are different claims — the second would also be true if edit mode had simply
  /// failed to switch on.
  int handlesOn(WidgetTester tester, String id) => tester
      .widgetList(find.descendant(
        of: find.ancestor(
          of: find.text(id),
          matching: find.byType(DashboardItemWrapper),
        ),
        matching: find.byType(ResizeHandleWidget),
      ))
      .length;

  group('popup builds no resize handle', () {
    testWidgets(
        'a card with no pick has its handles, so the count is not zero '
        'by accident', (tester) async {
      await pumpGrid(tester, pickedLayout(const {}));

      expect(handlesOn(tester, 'device_info'), 8,
          reason: 'The premise of every assertion below. Four corners and four '
              'edges is what DashboardItemWrapper builds in edit mode; if this '
              'number changes the package changed, and the popup assertions need '
              're-reading rather than re-baselining.');
      expect(handlesOn(tester, 'lan_info'), 8);
    });

    testWidgets(
        'the popup card has none, and its neighbour still has all eight',
        (tester) async {
      await pumpGrid(
          tester,
          pickedLayout(const {
            'device_info': CardFormChoice(density: CardDensity.popup),
          }));

      expect(handlesOn(tester, 'device_info'), 0,
          reason: 'AC 6, stated as the ticket states it: not "isResizable is '
              'false" but "no resize handle is built". An icon and one value has '
              'no use for a larger box, and a locked-but-huge popup would be '
              'unrecoverable — so the box is pinned and the handles go with it.');
      expect(handlesOn(tester, 'lan_info'), 8,
          reason: "A pick is per card. Removing one card's handles must not "
              'disarm the grid.');
    });

    testWidgets('compact keeps its handles — its floor is a limit, not a lock',
        (tester) async {
      await pumpGrid(
          tester,
          pickedLayout(const {
            'device_info': CardFormChoice(density: CardDensity.compact),
          }));

      expect(handlesOn(tester, 'device_info'), 8,
          reason: 'The asymmetry the ticket asks for: compact can be enlarged '
              'and only refuses to shrink, and the refusal is minW/minH doing '
              'its job. Taking the handles away here would also forbid the '
              'enlargement.');
    });

    testWidgets('returning to normal gives the handles back', (tester) async {
      // The recovery path, on the tree rather than on the flags: a user who tries
      // popup and changes their mind must get a resizable card back, and the flag
      // that was written false has to be written true again for that to happen.
      await pumpGrid(
          tester,
          pickedLayout(const {
            'device_info': CardFormChoice(density: CardDensity.normal),
          }));

      expect(handlesOn(tester, 'device_info'), 8);
    });
  });

  // ---------------------------------------------------------------------------
  // The render side — a pick wins over the width
  // ---------------------------------------------------------------------------

  /// Reads the density in effect below a [CardDensityHost] pumped at [width].
  ///
  /// [width] is the width the *card* is given, not the screen's: that is the
  /// separation `CardDensityHost` exists to make. `MediaQuery` sets the screen so
  /// `currentMaxColumns` resolves to a real breakpoint — the number a pick is
  /// keyed by — and the `SizedBox` sets the card's own width independently.
  Future<CardDensity> densityUnderHost(
    WidgetTester tester, {
    required double width,
    required double screenWidth,
    required CardForms forms,
    double? normalAbove = 300,
  }) async {
    late CardDensity observed;
    await tester.pumpWidget(ProviderScope(
      overrides: [cardFormsProvider.overrideWith((ref) => forms)],
      child: MediaQuery(
        data: MediaQueryData(size: Size(screenWidth, 900)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 200,
              child: CardDensityHost(
                cardId: 'device_info',
                normalAbove: normalAbove,
                child: Builder(builder: (context) {
                  observed = CardDensityScope.of(context);
                  return const SizedBox.shrink();
                }),
              ),
            ),
          ),
        ),
      ),
    ));
    return observed;
  }

  group('a pick decides the form, not the width', () {
    /// 1440px of screen is the 12-column grid, and 600px of card is a width at
    /// which `densityForWidth` would answer normal for every threshold any card
    /// declares. So every pick below is contradicting the measurement, which is
    /// the only interesting case: agreeing with it proves nothing.
    const desktop = 1440.0;
    const wideEnoughForNormal = 600.0;

    /// `kMinSupportedScreenWidth` (§2.3), where the grid is 4 columns wide and a
    /// card is 288px — the only geometry a phone user ever gets, since the layout
    /// pins `x: 0, w: cols` there and #1293 forbids horizontal resize.
    const phone = 320.0;
    const phoneCardWidth = 288.0;

    testWidgets('the width alone selects normal at 600px', (tester) async {
      expect(
        await densityUnderHost(
          tester,
          width: wideEnoughForNormal,
          screenWidth: desktop,
          forms: CardForms.empty,
        ),
        CardDensity.normal,
        reason: 'The control. Without it the next two tests could be passing '
            'because the host always answers what it was asked for.',
      );
    });

    testWidgets('a popup pick beats a width that says normal', (tester) async {
      expect(
        await densityUnderHost(
          tester,
          width: wideEnoughForNormal,
          screenWidth: desktop,
          forms: CardForms.empty.withChoice(
            UspLayoutEnvelope.desktopSlotCount,
            'device_info',
            const CardFormChoice(density: CardDensity.popup),
          ),
        ),
        CardDensity.popup,
        reason: 'The inversion. The pick has already constrained which widths '
            'the card can be, so the width has nothing left to decide — and the '
            'card is 2x1 for exactly that reason, whatever this harness sizes it '
            'to.',
      );
    });

    testWidgets('a compact pick beats a width that says normal',
        (tester) async {
      expect(
        await densityUnderHost(
          tester,
          width: wideEnoughForNormal,
          screenWidth: desktop,
          forms: CardForms.empty.withChoice(
            UspLayoutEnvelope.desktopSlotCount,
            'device_info',
            const CardFormChoice(density: CardDensity.compact),
          ),
        ),
        CardDensity.compact,
        reason: 'Decision 3 on the issue: widening past normalAbove does not '
            're-promote a card the user set to compact. A chosen density is what '
            'renders, or the choice does not stick.',
      );
    });

    testWidgets(
        'an explicit normal pick does not pin — the width decides again',
        (tester) async {
      // The fifth decision, and the one the ticket did not make. If normal were a
      // pin, a user could park a compact-capable card at 191px in its full form —
      // precisely the overflow #1183 exists to prevent. So normal is the *removal*
      // of a pick, and the width rule takes over.
      expect(
        await densityUnderHost(
          tester,
          width: 250,
          screenWidth: desktop,
          forms: CardForms.empty.withChoice(
            UspLayoutEnvelope.desktopSlotCount,
            'device_info',
            const CardFormChoice(density: CardDensity.normal),
          ),
        ),
        CardDensity.compact,
        reason:
            '250px is below the declared 300px threshold and above the 200px '
            'popup floor, so #1232 answers compact. A pinning normal would '
            'answer normal here and overflow.',
      );
    });

    testWidgets('a pick made on another grid does not apply to this one',
        (tester) async {
      // AC 5's no-contamination clause, on the render side: the persistence tests
      // assert the *storage* is per breakpoint, and this asserts the reader keys
      // off the breakpoint too rather than off the first pick it finds.
      expect(
        await densityUnderHost(
          tester,
          width: wideEnoughForNormal,
          screenWidth: desktop,
          forms: CardForms.empty.withChoice(
            UspLayoutEnvelope.mobileSlotCount,
            'device_info',
            const CardFormChoice(density: CardDensity.popup),
          ),
        ),
        CardDensity.normal,
      );
    });

    testWidgets('the phone grid reads the pick made on the phone grid',
        (tester) async {
      // The other half of AC 5's no-contamination clause, and the half a suite
      // pumped only at desktop cannot state: with every screen 12 columns wide,
      // reading the pick under a hardcoded 12 and reading it under the current
      // breakpoint are indistinguishable — a mutation to that effect survived
      // until this test existed. The phone is also the form factor the ticket is
      // for, so "a pick applies where it was made" needs stating there and not
      // only at the width where the measurement could have covered for it.
      expect(
        await densityUnderHost(
          tester,
          width: phoneCardWidth,
          screenWidth: phone,
          forms: CardForms.empty.withChoice(
            UspLayoutEnvelope.mobileSlotCount,
            'device_info',
            const CardFormChoice(density: CardDensity.popup),
          ),
        ),
        CardDensity.popup,
      );
    });

    testWidgets('and not the pick made on the desktop grid', (tester) async {
      expect(
        await densityUnderHost(
          tester,
          width: phoneCardWidth,
          screenWidth: phone,
          forms: CardForms.empty.withChoice(
            UspLayoutEnvelope.desktopSlotCount,
            'device_info',
            const CardFormChoice(density: CardDensity.popup),
          ),
        ),
        CardDensity.compact,
        reason: '288px is below the declared 300px threshold and above the '
            '200px popup floor, so with no pick for this grid #1232 answers '
            'compact. popup here would mean a desktop pick had leaked onto the '
            'phone.',
      );
    });

    testWidgets('a card with no threshold still honours a pick',
        (tester) async {
      // `normalAbove: null` short-circuits the measurement — the LayoutBuilder is
      // deliberately not inserted for the 12 cards that declare no threshold
      // (#1240 AC 1/2). The pick is resolved before that short-circuit, which is
      // what makes popup available to all 17 template-built cards while compact
      // stays with the 6 that built one.
      expect(
        await densityUnderHost(
          tester,
          width: wideEnoughForNormal,
          screenWidth: desktop,
          normalAbove: null,
          forms: CardForms.empty.withChoice(
            UspLayoutEnvelope.desktopSlotCount,
            'device_info',
            const CardFormChoice(density: CardDensity.popup),
          ),
        ),
        CardDensity.popup,
      );
    });
  });
}
