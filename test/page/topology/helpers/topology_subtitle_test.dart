import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/topology/helpers/topology_subtitle.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/devices_test_data.dart';
import '../../../mocks/test_data/system_info_test_data.dart';

/// The one line under a node's name on a tree row.
///
/// The medium used to be written into `GraphNode.extra` by the builder, straight
/// from `MultiAPDevice.Backhaul.LinkType` — a firmware string — so a slave row read
/// `Ethernet` in all 26 locales. That is the same defect as the kit printing its
/// own enum names, which `TopologyTreeLabels` exists to close; this closes the
/// other half.
///
/// The builder stays a pure function with no `BuildContext`, so the word is chosen
/// here instead, from the boolean it recorded.
void main() {
  setUpAll(() {
    OuiLookup.initializeForTesting(const {
      '112233': 'Test Vendor',
      'AABBCC': 'Linksys',
    });
  });

  tearDownAll(OuiLookup.reset);

  final sysInfo = SystemInfoTestData.create();

  /// A context with the app's localisations resolved for [locale].
  Future<BuildContext> contextFor(WidgetTester tester, Locale locale) async {
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        captured = context;
        return const SizedBox.shrink();
      }),
    ));
    await tester.pumpAndSettle();
    return captured;
  }

  GraphNode nodeOf(GraphData topology, String slot) =>
      topology.nodes.firstWhere((n) => n.styleSlot == slot);

  GraphData buildWith() => UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(),
        info: sysInfo,
      );

  group('a slave row carries its model and its backhaul', () {
    testWidgets('the builder no longer words the medium at all',
        (tester) async {
      final slave = nodeOf(buildWith(), 'secondary');

      // `extra` is the model and nothing else now, which is what makes the locale
      // the only source of the word.
      expect(slave.extra, DevicesTestData.defaultModel);
      expect(slave.extra, isNot(contains('Wi-Fi')));
      // The fields the word is derived from moved to metadata, where they were
      // already being recorded for the detail panel.
      expect(slave.metadata!['backhaulLinkType'], isNotNull);
    });

    testWidgets('the medium is translated, not echoed', (tester) async {
      // Asserted on a **wired** backhaul. `wifi` is the literal string `WiFi` in
      // both `app_en.arb` and `app_zh.arb`, so a Wi-Fi slave reads identically in
      // the two locales whether the word came from the ARB or from firmware —
      // measured, and the reason this case is Ethernet: `乙太網路` can only have
      // come from the ARB.
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(
          slave: DevicesTestData.createEthernetSlave(),
        ),
        info: sysInfo,
      );
      final slave = nodeOf(topology, 'secondary');

      final english = await contextFor(tester, const Locale('en'));
      final inEnglish = TopologySubtitle.build(english, slave);

      final chinese = await contextFor(
          tester, const Locale.fromSubtags(languageCode: 'zh'));
      final inChinese = TopologySubtitle.build(chinese, slave);

      // The model is the same in both; the medium is not. Asserted as a
      // difference rather than against a literal translation, because the ARB owns
      // the wording and pinning it here would red this test for a copy change.
      expect(inEnglish, contains(DevicesTestData.defaultModel));
      expect(inChinese, contains(DevicesTestData.defaultModel));
      expect(inEnglish, contains('Ethernet'));
      expect(inChinese, isNot(inEnglish),
          reason: 'the medium must be translated, not echoed');
      expect(inChinese, isNot(contains('Ethernet')),
          reason: 'the firmware spelling must not survive into a zh row');
    });

    testWidgets('a Wi-Fi backhaul shows the signal', (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      final slave = nodeOf(buildWith(), 'secondary');
      final subtitle = TopologySubtitle.build(context, slave);

      expect(subtitle, contains('dBm'));
    });

    testWidgets('an Ethernet backhaul names the medium and shows no signal',
        (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(
          slave: DevicesTestData.createEthernetSlave(),
        ),
        info: sysInfo,
      );
      final subtitle =
          TopologySubtitle.build(context, nodeOf(topology, 'secondary'));

      expect(subtitle, contains('Ethernet'));
      // A wired backhaul has no RSSI by design, not by absence.
      expect(subtitle, isNot(contains('dBm')));
    });

    testWidgets('a medium spelled unexpectedly still reads as Ethernet',
        (tester) async {
      // Classified through `isMeshBackhaulEthernet`, which case-folds and trims,
      // so a build spelling the value differently gets the right word — and, more
      // importantly, does not acquire a signal row it has no business showing.
      final context = await contextFor(tester, const Locale('en'));
      const node = GraphNode(
        id: 'extender-x',
        name: 'Study',
        styleSlot: 'secondary',
        extra: 'MX2000',
        metadata: {
          'backhaulLinkType': '  ETHERNET  ',
          'backhaulSignalStrength': -55,
        },
      );

      final subtitle = TopologySubtitle.build(context, node);
      expect(subtitle, contains('Ethernet'));
      expect(subtitle, isNot(contains('dBm')));
    });
  });

  group('what the line withholds', () {
    testWidgets('a backhaul firmware did not name shows the model alone',
        (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(
          slave: DevicesTestData.createWifiSlave(backhaul: BackhaulInfo.none),
        ),
        info: sysInfo,
      );
      final subtitle =
          TopologySubtitle.build(context, nodeOf(topology, 'secondary'));

      // `LinkType = None` is the ordinary state on FL-WRT 2.0, not an error, and
      // claiming Wi-Fi for it is the defect #1464 closed.
      expect(subtitle, contains(DevicesTestData.defaultModel));
      expect(subtitle, isNot(contains('Wi-Fi')));
      expect(subtitle, isNot(contains('Ethernet')));
    });

    testWidgets("firmware's literal 'None' shows no medium either",
        (tester) async {
      // Two different absences, and only one of them was covered. `BackhaulInfo
      // .none` leaves `linkType` null, so the case above exercises the `isEmpty`
      // arm; prplMesh reports the string `None` on the controller row, which is a
      // *positive* statement of "no backhaul" and reaches the second arm. Found by
      // mutating that arm away and watching every test stay green.
      final context = await contextFor(tester, const Locale('en'));
      const node = GraphNode(
        id: 'gateway',
        name: 'Router',
        styleSlot: 'primary',
        extra: 'MR7500',
        metadata: {'backhaulLinkType': 'None'},
      );

      expect(TopologySubtitle.build(context, node), 'MR7500');
    });

    testWidgets("'None' is recognised whatever its casing", (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      const node = GraphNode(
        id: 'gateway',
        name: 'Router',
        styleSlot: 'primary',
        extra: 'MR7500',
        metadata: {'backhaulLinkType': '  NONE  '},
      );

      expect(TopologySubtitle.build(context, node), 'MR7500');
    });

    testWidgets('a node with no metadata at all is its extra, not a crash',
        (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      const node = GraphNode(
        id: 'client-1',
        name: 'Thermostat',
        styleSlot: 'leaf',
        extra: '192.168.1.50',
      );

      expect(TopologySubtitle.build(context, node), '192.168.1.50');
    });

    testWidgets('a node with nothing at all is empty, not a separator',
        (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      const node = GraphNode(id: 'x', name: 'x');

      // `subtitleBuilder` is non-nullable `String`, and the tree draws no row for
      // an empty one. A naive join would return ' · ' here.
      expect(TopologySubtitle.build(context, node), '');
    });

    testWidgets('a node with only a medium does not lead with a separator',
        (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      const node = GraphNode(
        id: 'extender-x',
        name: 'Study',
        styleSlot: 'secondary',
        metadata: {'backhaulLinkType': 'Wi-Fi'},
      );

      final subtitle = TopologySubtitle.build(context, node);
      expect(subtitle, isNotEmpty);
      expect(subtitle, isNot(startsWith('·')));
      expect(subtitle, isNot(startsWith(' ')));
    });
  });

  group('a leaf and the master are unaffected', () {
    testWidgets('a leaf keeps its IP first', (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createSingleNodeNetwork(
          masterClients: [
            DevicesTestData.createWifiClient(ip: '192.168.1.77'),
          ],
        ),
        info: sysInfo,
      );

      // An IP and a band read the same in every locale, so they stay in `extra`
      // and this only passes them through.
      expect(TopologySubtitle.build(context, nodeOf(topology, 'leaf')),
          startsWith('192.168.1.77'));
    });

    testWidgets('the master shows its model', (tester) async {
      final context = await contextFor(tester, const Locale('en'));
      final topology = buildWith();

      expect(TopologySubtitle.build(context, nodeOf(topology, 'primary')),
          contains(DevicesTestData.defaultModel));
    });
  });
}
