import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/card_popup_form.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';

import '../../../util/dashboard/dashboard_card_probe.dart';
// The collector, `setLayoutSurface` and `settleIgnoringAnimations`, all through
// the one library that re-exports them.
import '../../../util/overflow_probe.dart';

/// The E2E hook on the Dashboard's entry into every detail page (#1450, unblocks
/// PrivacyGUI-USP-E2E#115).
///
/// ## What is being pinned, and why a source scan cannot do it
///
/// `pushNamed` on a card's detail link is the whole of the #1420 / #1421 / #1029 /
/// #1435 bug family: `goNamed` replaces the location, the Dashboard leaves the back
/// stack, and the detail page's back arrow falls through to a `backFallback` that
/// for every one of these targets is *not* the Dashboard. #1437 already guards the
/// verb by scanning `lib/` as source, which is the right check for a call site —
/// but only a real user pressing a real button can show that back lands on the
/// Dashboard, and E2E cannot press this button without a lint-legal handle. The
/// only handle it had was a localized label shared by 13 buttons.
///
/// So the assertion here is not "the string is spelled this way" but "each card's
/// entry is addressable **on its own**": the identifiers are derived from the
/// widget registry's card ids, which are unique by construction, and this file
/// pumps every registered card through the production factory to check that the
/// id each one publishes is its own and that no card publishes two.
///
/// ## Why the expectation is a literal table
///
/// Deriving the expected id here from the same expression the widget uses would
/// assert nothing — the test would agree with any renaming, including one that
/// collapsed two cards onto one id. The table is the contract the E2E specs are
/// written against, so a change to it has to be a deliberate edit here, and
/// `kCardsWithoutDetailEntry` keeps it honest from the other side: a card that
/// gains a detail entry cannot be silently left out of the table, because the
/// meta-test below requires the two sets to partition the registry.
///
/// Deliberately NOT tagged `layout-gate` or `ui`: the unit job
/// (`--exclude-tags="golden||loc||ui||layout-gate"`) is the one that blocks a PR,
/// and a cross-repo hook is worth blocking a PR on. It borrows the gate's pump
/// harness only for its geometry and its kitchen-sink fixture.

/// Card id → the identifier its detail-entry button must publish.
///
/// Thirteen buttons over eleven distinct route targets: `wifi_status` and
/// `wifi_networks` both enter `uspWifiSettings`, and `system_status` and
/// `traffic_analysis` both enter `uspStatistics`. That is why the id is the card's
/// and not the route's — a route-derived id would leave four of the thirteen
/// buttons sharing a handle with another card.
///
/// One caveat for the specs written against this table: `device_info`'s footer is
/// **data-gated**. It renders only once `devicesDataProvider` has produced a master
/// node with a non-empty `deviceId`, because the route it enters needs that id as a
/// query parameter — so on a real router the hook appears when the node list
/// arrives, not when the card does. Every case here supplies one (the fixture is
/// `kitchenSinkOverrides`), so this file measures the hook and not the gate; a spec
/// that clicks it straight after load has to wait for the button rather than assume
/// it. The other twelve are unconditional.
const Map<String, String> kCardDetailIdentifiers = {
  'device_info': 'card-detail-device-info',
  'network_status': 'card-detail-network-status',
  'topology': 'card-detail-topology',
  'lan_info': 'card-detail-lan-info',
  'system_status': 'card-detail-system-status',
  'connected_devices': 'card-detail-connected-devices',
  'wifi_status': 'card-detail-wifi-status',
  'wifi_networks': 'card-detail-wifi-networks',
  'time_settings': 'card-detail-time-settings',
  'dhcp_reservations': 'card-detail-dhcp-reservations',
  'port_forwarding': 'card-detail-port-forwarding',
  'firewall_overview': 'card-detail-firewall-overview',
  'traffic_analysis': 'card-detail-traffic-analysis',
};

/// The registered cards that enter no detail page, so publish no hook.
///
/// Listed rather than inferred, so that a card which *gains* an entry fails the
/// meta-test instead of quietly rendering an unasserted button.
const Set<String> kCardsWithoutDetailEntry = {
  'stats_panel',
  'ethernet_ports',
  'device_analytics',
  'network_health',
  'wifi_performance',
};

/// Every `card-detail-*` identifier declared anywhere in the pumped tree.
///
/// Read off the [Semantics] *widgets* rather than through
/// `find.bySemanticsIdentifier`, which needs the id it is looking for: the
/// question here is what the card publishes, including an id nobody expected.
Set<String> _publishedDetailIdentifiers(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((s) => s.properties.identifier)
    .whereType<String>()
    .where((id) => id.startsWith('card-detail-'))
    .toSet();

/// Rows of viewport the popup group's screen gets — six, or 800px, a laptop.
///
/// Only has to be taller than the tallest card's declared height, so that the
/// presentation the tap opens is not itself the constraint. The same figure the
/// gate's popup sweep uses (`kPopupSweepScreenRows`), restated rather than
/// imported: it is a floor on the screen and not a measurement, and reading it
/// would mean this file importing a gate *family* to learn that 800 > 528.
const int _kPresentationScreenRows = 6;

/// Pumps one card into a box of [cardWidth] × [cardHeight] and runs [body] on it,
/// with the gate's RenderFlex collector installed for the whole thing.
///
/// Overflow is not this file's subject, and swallowing it here is not a blind eye:
/// a card that overflows at one of these geometries is the #1183 gate's business
/// and is baselined there, whereas an uncollected RenderFlex error fails *this*
/// test for something it never asserted. `dhcp_reservations` does exactly that in
/// its presentation (+70px, and only under the placeholder test font — this file
/// asserts nothing about text metrics, so it does not pay for real fonts).
///
/// [body] runs inside the collection because the taps it makes are themselves
/// layout events: the presentation lays out after the tap, so an overflow raised
/// there would arrive with no handler installed.
///
/// No [OverflowCell]: this is not a sweep coordinate and must stay out of the
/// baseline dataset.
Future<void> _withPumpedCard(
  WidgetTester tester, {
  required String cardId,
  required double screenWidth,
  required double cardWidth,
  required double cardHeight,
  required double surfaceHeight,
  CardDensity? density,
  required Future<void> Function() body,
}) =>
    runWithOverflowCollection((_) async {
      await setLayoutSurface(tester, Size(screenWidth, surfaceHeight));
      await tester.pumpWidget(
        buildDashboardCardApp(
          cardId: cardId,
          locale: const Locale('en'),
          screenWidth: screenWidth,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
          density: density,
        ),
      );
      await settleIgnoringAnimations(tester);
      await body();
    });

void main() {
  test('the expectation partitions the widget registry', () {
    final registry = UspWidgetSpecs.all.map((s) => s.id).toSet();
    expect(
      {...kCardDetailIdentifiers.keys, ...kCardsWithoutDetailEntry},
      registry,
      reason: 'every registered card must be either expected to publish a '
          'detail hook or listed as having no detail entry — a card in neither '
          'set is one whose Dashboard entry nothing here measures',
    );
    expect(
      kCardDetailIdentifiers.values.toSet(),
      hasLength(kCardDetailIdentifiers.length),
      reason: 'two cards sharing an identifier is the defect #1450 exists to '
          'remove: E2E could not tell which card it entered from',
    );
  });

  for (final spec in UspWidgetSpecs.all) {
    final expected = kCardDetailIdentifiers[spec.id];
    final what = expected == null
        ? 'publishes no detail hook'
        : 'publishes "$expected" on its detail button';

    testWidgets('${spec.id} $what', (tester) async {
      // Disposed in a `finally` rather than an `addTearDown`, because the
      // framework's own "was every handle disposed" check runs *before*
      // teardowns — a registered dispose leaves every test in this file
      // reporting a handle leak on top of whatever it actually asserted.
      final handle = tester.ensureSemantics();

      // A card's preferred span on a desktop screen: the detail footer only
      // exists in the normal form, and every narrower band would first have to
      // be shown not to be popup — which is a different test's subject (#1239).
      final widthCase = desktopCaseFor(spec);
      final rows =
          spec.getConstraints(DisplayMode.normal).getPreferredHeightCells();
      final cardHeight = dashboardCardHeight(rows);

      try {
        await _withPumpedCard(
          tester,
          cardId: spec.id,
          screenWidth: widthCase.screenWidth,
          cardWidth: widthCase.cardWidth,
          cardHeight: cardHeight,
          surfaceHeight: cardHeight + 64,
          body: () async {
            expect(
              _publishedDetailIdentifiers(tester),
              expected == null ? isEmpty : {expected},
              reason: 'the card must publish exactly the hook the E2E contract '
                  'names, and no second one',
            );
            if (expected == null) return;

            final hook = find.bySemanticsIdentifier(expected);
            expect(hook, findsOneWidget,
                reason:
                    'the identifier must reach the semantics tree, not just '
                    'the widget — release web builds keep that tree alive and it '
                    'is what E2E clicks through');

            final node = tester.getSemantics(hook);
            expect(
                node,
                isSemantics(
                    identifier: expected, isButton: true, hasTapAction: true),
                reason: 'the hook must land on the node that carries the tap, '
                    'not on an ancestor that merely contains it');
            expect(node.label, isNotEmpty,
                reason: 'the localized label is what a screen reader announces '
                    'and the identifier must not have displaced it');

            // #1301: the grid item wrapping a card is a semantics boundary, so a
            // hook placed above the link's own `Semantics(container: true)` gets
            // absorbed into a node whose rect is the whole card — and a click
            // there navigates from anywhere on the card.
            //
            // Pinned against the link's own box rather than against the card's,
            // because this harness pumps the card into a plain sized box with no
            // grid item above it: the absorbing ancestor is absent from the tree
            // under test, so "narrower than the card" would pass for any
            // end-aligned row and would still pass with the hook moved up onto
            // the card. Equality with the `InkWell` is the assertion that only
            // holds where the hook actually is.
            expect(
              tester.getRect(hook),
              tester.getRect(
                  find.descendant(of: hook, matching: find.byType(InkWell))),
              reason: 'the hook must be exactly the tappable link (#1301) — a '
                  'larger rect means it sits on an ancestor',
            );
          },
        );
      } finally {
        handle.dispose();
      }
    });
  }

  /// A card degraded to popup keeps its hook — in the presentation.
  ///
  /// This is the one place the hook could have been correct in the grid and
  /// missing where it matters most. A popup tile is one grid row showing a value
  /// over the card's name and no footer at all, so the presentation the tap opens
  /// holds the *only* copy of that card's detail button: without the id travelling
  /// into the presented scope, such a card would be unenterable by E2E, or worse
  /// would answer to a different handle than the same card does in the grid.
  ///
  /// Both halves are asserted, because the first is what makes the second
  /// necessary: the tile publishes nothing, then the presentation publishes
  /// exactly the card's own handle.
  ///
  /// What the hook being *present* here does not mean: **#1453**. This button
  /// pushes the detail route without closing the presentation it sits in, so the
  /// page it opens is mounted under a modal barrier and its own controls —
  /// including its back arrow — are not hit-testable until one tap has been spent
  /// dismissing the presentation. Measured with a real router on both branches
  /// (dialog and phone sheet). That is a defect of the navigation and not of the
  /// identifier: the handle is what lets an E2E spec reach the button at all, and
  /// a spec that clicks it will hit #1453 immediately after.
  ///
  /// ## Which of the three density paths this drives
  ///
  /// `density:` pins [cardDensityOverrideProvider], the first of the three sources
  /// [CardDensityHost] consults — not [cardFormsProvider], which is the user's
  /// *pick* (#1299), nor the width (#1232). It covers all three anyway, and for a
  /// reason the host states as its own invariant: every source funnels into the
  /// single `_scope(density)` construction, precisely so that a field travelling
  /// alongside the density cannot be supplied on one path and missed on another.
  /// The membership filter is `selectableForms`, so what these cases enumerate is
  /// the cards a user *can* pick into popup, entered through the override.
  ///
  /// Mutation run: dropping `cardId:` from either `showCardNormalForm`'s call or
  /// the scope it builds fails every case here and none above.
  group('a card degraded to popup', () {
    final pickable = UspWidgetSpecs.all.where((spec) =>
        kCardDetailIdentifiers.containsKey(spec.id) &&
        UspWidgetSpecs.selectableForms(spec.id).contains(CardDensity.popup));

    for (final spec in pickable) {
      final expected = kCardDetailIdentifiers[spec.id]!;

      testWidgets('${spec.id} publishes "$expected" in its presentation',
          (tester) async {
        final handle = tester.ensureSemantics();

        // The tile is one grid row on a screen tall enough that the dialog the
        // tap opens is not itself constrained — the same geometry
        // `dashboard_card_popup_overflow_test.dart` presents at.
        final widthCase = pickedTileCase();

        try {
          await _withPumpedCard(
            tester,
            cardId: spec.id,
            screenWidth: widthCase.screenWidth,
            cardWidth: widthCase.cardWidth,
            cardHeight: dashboardCardHeight(UspWidgetSpecs.popupHeightRows),
            surfaceHeight: dashboardCardHeight(_kPresentationScreenRows),
            density: CardDensity.popup,
            body: () async {
              expect(
                _publishedDetailIdentifiers(tester),
                isEmpty,
                reason:
                    'the degraded tile has no footer, so it has no hook — an '
                    'E2E spec has to open the presentation to enter this card',
              );

              await tester.tap(find.byType(CardPopupForm));
              await settleIgnoringAnimations(tester);

              expect(
                _publishedDetailIdentifiers(tester),
                {expected},
                reason: 'the presented card is the same card, so its detail '
                    'button must answer to the same handle it does in the grid',
              );
              expect(find.bySemanticsIdentifier(expected), findsOneWidget);
            },
          );
        } finally {
          handle.dispose();
        }
      });
    }
  });
}
