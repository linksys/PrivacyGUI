import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../../util/settle.dart';

/// Node Detail for an offline extender (#1443, REQ-6a).
///
/// What the page must say about a node that left the mesh:
/// - how long it has been offline, counted from its `Hosts` row's
///   `ActiveLastChange`, or "unknown" when the row has no usable stamp —
///   never zero;
/// - that where it was attached is unknown, rather than naming the gateway the
///   topology draws it under;
/// - that it has no address, instead of leaving the Network card a bare title.
///
/// [slaveNodeOfflineFromHosts] is the shape `MeshNetworkBuilder` builds on
/// FL-WRT 2.0. The clock is fixed with `withClock`, which is what the page
/// reads, so the expected text does not depend on the day the suite runs.
///
/// Not tagged: this asserts which facts render, not widths.
void main() {
  Future<void> pumpNodeDetail(
      WidgetTester tester, UspNodeDetailState state) async {
    await setLayoutSurface(tester, const Size(1280, 1800));
    await tester.pumpWidget(pageSurfaceHost(
      view: UspNodeDetailView(deviceId: state.node!.deviceId),
      locale: const Locale('en'),
      overrides: nodeDetailOverrides(state),
    ));
    // The node card's `AppImage.provider` never settles under the test binding.
    await settleIgnoringAnimations(tester);
  }

  Finder byIdentifier(String id) => find.bySemanticsIdentifier(id);

  test('premise: the scenes are the states these tests need', () {
    final offline = slaveNodeOfflineFromHosts.node!;
    expect(offline.isOnline, isFalse);
    expect(offline.dataElementsId, isNull);
    expect(slaveNodeOfflineNoStamp.node!.isOnline, isFalse);
    expect(slaveNodeOnlineWithDevices.node!.isOnline, isTrue);
    expect(offlineExtenderNow.difference(offlineExtenderSince),
        const Duration(hours: 3, minutes: 7));
  });

  testWidgets('shows how long an offline extender has been offline',
      (tester) async {
    final handle = tester.ensureSemantics();
    await withClock(Clock.fixed(offlineExtenderNow), () async {
      await pumpNodeDetail(tester, slaveNodeOfflineFromHosts);
    });

    expect(find.text('Offline for 3 hrs'), findsOneWidget,
        reason: '3 h 7 min reads at hour granularity (AC4)');
    expect(byIdentifier('node-detail-offline-duration'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a row with no usable stamp reads unknown, never zero',
      (tester) async {
    await withClock(Clock.fixed(offlineExtenderNow), () async {
      await pumpNodeDetail(tester, slaveNodeOfflineNoStamp);
    });

    expect(find.text('Offline duration unknown'), findsOneWidget);
    expect(find.textContaining('Offline for'), findsNothing);
  });

  testWidgets('an online slave and the master show no duration (AC5)',
      (tester) async {
    final handle = tester.ensureSemantics();
    for (final state in [slaveNodeOnlineWithDevices, masterNodeWithDevices]) {
      await withClock(Clock.fixed(offlineExtenderNow), () async {
        await pumpNodeDetail(tester, state);
      });

      expect(byIdentifier('node-detail-offline-duration'), findsNothing,
          reason: '${state.node!.diagnosticName} is online');
      expect(find.textContaining('Offline for'), findsNothing);
      expect(find.text('Offline duration unknown'), findsNothing);
    }
    handle.dispose();
  });

  testWidgets('says the upstream node is unknown, not the gateway',
      (tester) async {
    final handle = tester.ensureSemantics();
    await withClock(Clock.fixed(offlineExtenderNow), () async {
      await pumpNodeDetail(tester, slaveNodeOfflineFromHosts);
    });

    expect(byIdentifier('node-detail-parent-unknown'), findsOneWidget);
    expect(byIdentifier('node-detail-parent'), findsNothing,
        reason: 'there is no parent node to open');
    expect(
      find.descendant(
        of: byIdentifier('node-detail-parent-unknown'),
        matching: find.text('Unknown'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('offers no rename for an offline extender', (tester) async {
    // A rename writes to the Hosts row index read before the dialog opened,
    // and rows renumber while a node rejoins (#1840), so the builder gives an
    // offline extender no row to write to and the page draws no pen. The
    // router's page, which always has one, is the control that the hook is
    // what this finder looks for.
    final handle = tester.ensureSemantics();
    await withClock(Clock.fixed(offlineExtenderNow), () async {
      await pumpNodeDetail(tester, masterNodeWithDevices);
    });
    expect(byIdentifier('node-detail-edit-name'), findsOneWidget);

    await withClock(Clock.fixed(offlineExtenderNow), () async {
      await pumpNodeDetail(tester, slaveNodeOfflineFromHosts);
    });
    expect(byIdentifier('node-detail-edit-name'), findsNothing);
    handle.dispose();
  });

  testWidgets('reads the no-address placeholder instead of an empty card',
      (tester) async {
    await withClock(Clock.fixed(offlineExtenderNow), () async {
      await pumpNodeDetail(tester, slaveNodeOfflineFromHosts);
    });

    expect(find.text('LAN IP'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('an online slave without an address keeps the row hidden',
      (tester) async {
    // The placeholder is the offline extender's alone: an online node with no
    // address keeps the existing behaviour (#1838 left hidden rows hidden).
    await withClock(Clock.fixed(offlineExtenderNow), () async {
      await pumpNodeDetail(tester, slaveNodeOnlineWithDevices);
    });

    expect(find.text('-'), findsNothing);
  });
}
