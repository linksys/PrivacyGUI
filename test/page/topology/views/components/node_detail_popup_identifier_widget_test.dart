@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';
import 'package:privacy_gui/page/topology/views/components/node_detail_popup.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Verifies that the node-detail popup's `Details` button carries the stable
/// E2E identifier added in issue #1254 and that it is locatable via
/// [CommonFinders.bySemanticsIdentifier].
///
/// This is the fast local proxy for the E2E `byId()` contract (constitution
/// Article XVI): once the identifier reaches the Semantics tree, the CanvasKit
/// → `flt-semantics-identifier` DOM projection is a Flutter-runtime guarantee,
/// so no web round is needed here.
///
/// Unlike the node identifiers (`topology_node_identifier_widget_test.dart`),
/// this hook is a FIXED slug with no per-instance key. That is sound only
/// because the button renders inside the graph view's singleton detail panel —
/// `TopologyGraphView._selectedNodeId` is a single `String?`, so tapping
/// another node replaces the panel rather than adding one. The two render
/// gates that keep it singular are asserted below, so wiring this popup into
/// `TopologyTreeConfiguration.detailBuilder` (which renders per row) fails
/// here rather than as a Playwright strict-mode violation.
void main() {
  // Master / slave nodes reach the node-detail page through `deviceId`.
  const masterMetadata = <String, dynamic>{
    'deviceId': 'AA:BB:CC:DD:EE:00',
    'isMaster': true,
    'model': 'MR7500',
    'manufacturer': 'Linksys',
  };

  const slaveMetadata = <String, dynamic>{
    'deviceId': 'AA:BB:CC:DD:EE:01',
    'isMaster': false,
    'model': 'MX2000',
  };

  // Client nodes carry only `mac` — `UspTopologyBuilder` puts no `deviceId`
  // in their metadata (usp_topology_builder.dart:202-206).
  const clientMetadata = <String, dynamic>{
    'mac': '11:22:33:44:55:01',
    'hasMultipleInterfaces': false,
  };

  MeshNode node({
    required MeshNodeType type,
    MeshNodeStatus status = MeshNodeStatus.online,
  }) =>
      MeshNode(
        id: 'node-1',
        name: 'Test Node',
        type: type,
        status: status,
      );

  // Mirrors the production call in usp_topology_view.dart:123-125, which is
  // the only site that passes `showDetailsButton: true`.
  Widget wrap(
    MeshNode target,
    Map<String, dynamic> metadata, {
    required bool showDetailsButton,
  }) {
    return MaterialApp(
      theme: AppTheme.create(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: Builder(
            builder: (ctx) => NodeDetailPopup.builder(
              ctx,
              target,
              metadata,
              showDetailsButton: showDetailsButton,
            ),
          ),
        ),
      ),
    );
  }

  // Asserted against the literal, not the constant: this is the cross-repo
  // contract value the E2E selector map is generated from, so a rename must
  // fail here rather than silently follow the constant.
  const detailsIdentifier = 'topology-node-detail-button';

  group('Details button identifier', () {
    test('the contract value is unchanged', () {
      expect(kTopologyNodeDetailButtonIdentifier, detailsIdentifier);
    });

    testWidgets('master node with showDetailsButton carries the identifier',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(
        node(type: MeshNodeType.gateway),
        masterMetadata,
        showDetailsButton: true,
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(detailsIdentifier), findsOneWidget);

      handle.dispose();
    });

    testWidgets('slave node with showDetailsButton carries the identifier',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(
        node(type: MeshNodeType.extender),
        slaveMetadata,
        showDetailsButton: true,
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(detailsIdentifier), findsOneWidget);

      handle.dispose();
    });

    // Gate 1 of 2 (node_detail_popup.dart:98). The dashboard card
    // (usp_network_topology_card.dart:79-80) and the AI topology section both
    // rely on this default, so the hook must be absent there.
    testWidgets('absent when showDetailsButton is not set (the default)',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(
        node(type: MeshNodeType.extender),
        slaveMetadata,
        showDetailsButton: false,
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(detailsIdentifier), findsNothing);

      handle.dispose();
    });

    // Gate 2 of 2 (node_detail_popup.dart:98). E2E must therefore assert node
    // state before locating this hook — an offline node yields count 0.
    testWidgets('absent when the node is offline', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(
        node(type: MeshNodeType.extender, status: MeshNodeStatus.offline),
        slaveMetadata,
        showDetailsButton: true,
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(detailsIdentifier), findsNothing);

      handle.dispose();
    });

    // CHARACTERIZATION TEST — documents a latent coupling, NOT a live bug.
    //
    // A client node's metadata has no `deviceId` (only `mac`), so
    // `NodeDetailPopup.builder` (node_detail_popup.dart:36-46) builds a
    // non-null `onDetailsTap` whose body is a no-op: the `deviceId.isNotEmpty`
    // guard fails and no navigation happens. The button renders and carries
    // the identifier regardless.
    //
    // Unreachable in production today: `TopologyGraphView._handleNodeTap`
    // short-circuits client and internet nodes before the detail panel opens
    // (ui_kit v2.34.5 topology_graph_view.dart:352-355), and all three app
    // call sites use `NodeDetailTrigger.tap` with no hover path. So a client
    // node never renders this popup.
    //
    // Pinned here because that guard lives in ui_kit, not in this repo: if it
    // is relaxed, or if this popup is wired into
    // `TopologyTreeConfiguration.detailBuilder`, E2E gains a locatable button
    // that does nothing when tapped. Flip to `findsNothing` if the render gate
    // is ever extended with `deviceId.isNotEmpty`.
    testWidgets('client node renders the hook despite having no deviceId',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(wrap(
        node(type: MeshNodeType.client),
        clientMetadata,
        showDetailsButton: true,
      ));
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(detailsIdentifier), findsOneWidget);

      handle.dispose();
    });
  });
}
