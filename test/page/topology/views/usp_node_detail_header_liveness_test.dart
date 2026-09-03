import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../../util/settle.dart';

/// The node-detail header shows **two** independent facts — role and liveness
/// (#1465).
///
/// ## The bug this file closes
///
/// `_buildNodeInfoCard` built one `DetailStatusBadge` with `isActive: true`
/// hardcoded and the role passed as its *active* label, so the badge was a role
/// chip wearing a liveness widget's clothes. Two consequences, and the second is
/// why the fix is not a one-liner:
///
/// - `node.isOnline` — the value #1430 made meaningful — appeared nowhere on the
///   page. A node the topology paints as offline opened a detail page with a green
///   dot.
/// - `isActive: node.isOnline` alone would have replaced the role label with the
///   literal "Offline" (`inactiveLabel` is unset), trading one missing fact for
///   the other.
///
/// So the role moved to a ui_kit `AppTag` and the badge went back to meaning
/// liveness, which is what it already means on the device-detail page
/// (`usp_device_detail_view.dart:170`).
///
/// ## Why three states and not one
///
/// The AC only asks that an offline node not present as online, and one offline
/// slave would satisfy it — while leaving `isMaster ? online : offline` green.
/// That is the shape the old hardcoded badge invited, and it is wrong for exactly
/// one node: the slave that *is* online. [slaveNodeOnlineWithDevices] is
/// [slaveNodeWithDevices] with only its DataElements match added, so the pair
/// varies liveness with the role held fixed and the mutation dies.
///
/// ## Mutation
///
/// Measured, not assumed — and measured per assertion, because a widget test
/// halts at its first failure and a ledger that names later assertions is
/// claiming something the run never showed.
///
/// Reverting the header to `isActive: true` with the role as its label fails all
/// three tests. Each stops on its own first assertion: the offline slave on the
/// dot (`isActive` is `true`), the other two on `Online` not being inside the
/// badge (its label is the role). The role assertions never even run, and would
/// fail too — there is no `AppTag` left to read.
///
/// The dot is doing the work. `Offline` absent fails alongside it, and `Online`
/// absent — the third assertion in the offline test — *passes* under this revert,
/// because the reverted badge's label is `Slave`. It is not redundant, but it is
/// vacuous against this particular defect: what it rejects is a second liveness
/// surface elsewhere on the page contradicting the badge, and a badge hardcoded
/// `isActive: true` with no `activeLabel`.
///
/// Keeping the split but writing `isActive: node.isMaster` fails only
/// `an online slave`, which is the test that exists for it.
///
/// Not tagged: this asserts *which facts render*, not widths, so it runs in
/// `run_tests.sh`'s unit job (`--exclude-tags="golden||loc||ui||layout-gate"`).
void main() {
  /// Pumps the real node-detail page at a desktop surface.
  ///
  /// [pageSurfaceHost] rather than a local tree, for the reason
  /// `usp_node_detail_backhaul_state_test.dart` gives next door: it is the repo's
  /// one answer to "how do I pump a real view", and a copy here would be drift.
  Future<void> pumpNodeDetail(
      WidgetTester tester, UspNodeDetailState state) async {
    await setLayoutSurface(tester, const Size(1280, 1800));
    await tester.pumpWidget(pageSurfaceHost(
      view: UspNodeDetailView(deviceId: state.node!.deviceId),
      locale: const Locale('en'),
      overrides: nodeDetailOverrides(state),
    ));
    // The node card renders an `AppImage.provider` whose stream never completes
    // under the test binding, so `pumpAndSettle` would time out on it.
    await settleIgnoringAnimations(tester);
  }

  /// The liveness badge. Scoped by type because the page builds exactly one, and
  /// the connected-device rows below carry their own [UspStatusDot]s.
  Finder livenessBadge() => find.byType(DetailStatusBadge);

  bool livenessDotIsActive(WidgetTester tester) => tester
      .widget<UspStatusDot>(find.descendant(
        of: livenessBadge(),
        matching: find.byType(UspStatusDot),
      ))
      .isActive;

  String roleChipLabel(WidgetTester tester) =>
      tester.widget<AppTag>(find.byType(AppTag)).label;

  test('premise: the fixtures are the role × liveness pairs the tests need',
      () {
    // Asserted rather than assumed. Every test below reads a verdict out of a
    // fixture, and a fixture that drifts to the other liveness value would pass
    // the wrong assertion with no other signal — `slaveNodeWithDevices` is
    // offline only because it carries no DataElements match, which is one field
    // away from silently flipping.
    expect(slaveNodeWithDevices.node!.isMaster, isFalse);
    expect(slaveNodeWithDevices.node!.isOnline, isFalse,
        reason: 'the offline case: a slave with no DataElements match (#1430)');

    expect(slaveNodeOnlineWithDevices.node!.isMaster, isFalse);
    expect(slaveNodeOnlineWithDevices.node!.isOnline, isTrue,
        reason: 'the same slave, matched — liveness must not follow the role');

    expect(masterNodeWithDevices.node!.isMaster, isTrue);
    expect(masterNodeWithDevices.node!.isOnline, isTrue);
  });

  testWidgets('an offline slave presents as offline, and keeps its role',
      (tester) async {
    await pumpNodeDetail(tester, slaveNodeWithDevices);

    // Liveness — the AC's "does not present as online", stated three ways
    // because the badge can lie in three places: the dot's colour, the label it
    // chose, and the label it did not.
    expect(livenessDotIsActive(tester), isFalse,
        reason: 'the dot must not be the active colour for an offline node');
    expect(
      find.descendant(of: livenessBadge(), matching: find.text('Offline')),
      findsOneWidget,
    );
    expect(find.text('Online'), findsNothing,
        reason: 'nothing else on this page renders either word, so a page-wide '
            'finder is the strongest form of the assertion');

    // Role — still legible, which is the half a one-line `isActive:
    // node.isOnline` would have destroyed.
    expect(find.byType(AppTag), findsOneWidget);
    expect(roleChipLabel(tester), 'Slave');
  });

  testWidgets('an online slave presents as online — liveness is not the role',
      (tester) async {
    await pumpNodeDetail(tester, slaveNodeOnlineWithDevices);

    expect(livenessDotIsActive(tester), isTrue);
    expect(
      find.descendant(of: livenessBadge(), matching: find.text('Online')),
      findsOneWidget,
    );
    expect(find.text('Offline'), findsNothing);

    expect(roleChipLabel(tester), 'Slave',
        reason:
            'the role is unchanged by liveness — this and the offline slave '
            'differ in exactly one field, and it is not this one');
  });

  testWidgets('the master presents as online, and keeps its role',
      (tester) async {
    await pumpNodeDetail(tester, masterNodeWithDevices);

    // `MasterNode.isOnline` is `true` by construction — the master is the data
    // source itself (#1430, AC1) — so this is not a second copy of the online
    // slave: it is the only state that proves the role chip reads the role rather
    // than being hardcoded to one of its two values.
    expect(livenessDotIsActive(tester), isTrue);
    expect(
      find.descendant(of: livenessBadge(), matching: find.text('Online')),
      findsOneWidget,
    );
    expect(roleChipLabel(tester), 'Master');
  });
}
