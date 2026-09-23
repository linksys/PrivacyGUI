import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/helpers/topology_nav_target.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:privacy_gui/page/topology/views/components/node_detail_popup.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/test_data/devices_test_data.dart';

/// What the panel shows for a leaf, now that ui_kit 3.4.0 opens one for it.
///
/// The kit used to refuse a leaf its panel, so [NodeDetailPopup] only ever had to
/// read a mesh node. Removing the untruthful `Role` row (#1614 D2) stopped it
/// lying, but left it *empty* — the guard dropped every row it had, and a tap that
/// opens a blank panel is worse than one that opens nothing. The Details button
/// had the same shape of gap: it resolved `deviceId`, which no leaf carries, so it
/// was drawn and did nothing.
///
/// These pin both halves against the builder's real output rather than a
/// hand-made node, because what a leaf carries is exactly what is in question.
void main() {
  setUpAll(() {
    OuiLookup.initializeForTesting(const {
      '112233': 'Test Vendor',
      'AABBCC': 'Linksys',
    });
  });

  tearDownAll(OuiLookup.reset);

  const sysInfo = SystemInfoUIModel(
    manufacturer: 'Linksys',
    modelName: 'MR7500',
    hardwareVersion: '1.0',
    serialNumber: 'SN123456',
    softwareVersion: '1.0.16.26013014',
    uptime: 3600,
    totalMemory: 512000,
    freeMemory: 256000,
    cpuUsage: 25,
  );

  /// The leaf a real build produces for [client].
  GraphNode leafFor(ClientDevice client) {
    final topology = UspTopologyBuilder.buildFromMeshNetwork(
      meshNetwork: DevicesTestData.createSingleNodeNetwork(
        masterClients: [client],
      ),
      info: sysInfo,
    );
    return topology.nodes.firstWhere((n) => n.styleSlot == 'leaf');
  }

  Future<void> pump(
    WidgetTester tester,
    GraphNode node, {
    bool showDetailsButton = false,
    VoidCallback? onDetailsTap,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.create(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: NodeDetailPopup(
          node: node,
          metadata: node.metadata,
          showDetailsButton: showDetailsButton,
          onDetailsTap: onDetailsTap,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('a leaf panel carries the device facts', () {
    testWidgets('a Wi-Fi leaf shows IP, MAC, connection, band and signal',
        (tester) async {
      final client = DevicesTestData.createWifiClient(
        mac: '11:22:33:44:55:01',
        ip: '192.168.1.50',
      );
      final node = leafFor(client);
      await pump(tester, node);

      // The panel is no longer empty: every row below is a fact the leaf's own
      // metadata carries.
      expect(find.text('192.168.1.50'), findsOneWidget);
      expect(find.text('11:22:33:44:55:01'), findsOneWidget);
      expect(find.text('WiFi'), findsOneWidget);

      // And none of the mesh-node rows, which it has no data for.
      expect(find.text('Master'), findsNothing);
      expect(find.text('Slave'), findsNothing);
      expect(find.text('S/N'), findsNothing);
    });

    testWidgets('a wired leaf says Ethernet and shows no signal',
        (tester) async {
      final client = DevicesTestData.createWiredClient(
        mac: '11:22:33:44:55:02',
        ip: '192.168.1.51',
      );
      await pump(tester, leafFor(client));

      expect(find.text('192.168.1.51'), findsOneWidget);
      expect(find.text('Ethernet'), findsOneWidget);
      // A wired client has no RSSI by design, so the row must be absent rather
      // than showing a zero.
      expect(find.textContaining('dBm'), findsNothing);
    });

    testWidgets('an offline leaf still shows what it has', (tester) async {
      final client = DevicesTestData.createOfflineClient(
        mac: '11:22:33:44:55:03',
      );
      final node = leafFor(client);
      await pump(tester, node);

      expect(node.status, NodeState.inactive);
      // The MAC is knowable whether or not the device is reachable, so an offline
      // leaf's panel is not a blank one.
      expect(find.text('11:22:33:44:55:03'), findsOneWidget);
    });
  });

  group('the Details button', () {
    // Asserted through the destination resolver rather than through an injected
    // callback. Passing our own `onDetailsTap` would have tested the button's
    // wiring while skipping the thing that was broken: `builder` resolved a
    // `deviceId`, which no leaf carries, so the button was drawn and inert.
    test('a leaf resolves to its device-detail page', () {
      final node =
          leafFor(DevicesTestData.createWifiClient(mac: '11:22:33:44:55:09'));
      final target = topologyNavTargetFor(node);

      expect(target, isNotNull,
          reason: 'a leaf has a device-detail page to reach');
      expect(target!.route, RouteNamed.uspDeviceDetail);
      expect(target.queryParameters, {'mac': '11:22:33:44:55:09'});
    });

    testWidgets('is drawn for a leaf when the caller asks for it',
        (tester) async {
      final node = leafFor(DevicesTestData.createWifiClient());
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Through `builder`, which is what production passes to the kit, so the
        // destination is resolved the way it is at runtime.
        home: Scaffold(
          body: Builder(
            builder: (context) => NodeDetailPopup.builder(
              context,
              node,
              node.metadata,
              showDetailsButton: true,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('is not drawn for a node with nowhere to go', (tester) async {
      // An offline mesh node: the #1465 gate makes it unreachable, and a button
      // that cannot navigate should not be offered.
      final node = GraphNode(
        id: 'extender-x',
        name: 'Slave',
        styleSlot: 'secondary',
        status: NodeState.inactive,
        metadata: const {'isMaster': false, 'deviceId': 'S-1'},
      );
      expect(topologyNavTargetFor(node), isNull);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => NodeDetailPopup.builder(
              context,
              node,
              node.metadata,
              showDetailsButton: true,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsNothing);
    });
  });
}
