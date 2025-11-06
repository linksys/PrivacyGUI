import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/topology_data.dart';

final _instantTopologyScreens = [
  ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
  ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
];

void main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    initBetterActions();
    when(testHelper.mockServiceHelper.isSupportAutoOnboarding()).thenReturn(true);
    when(testHelper.mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
    when(testHelper.mockServiceHelper.isSupportChildFactoryReset()).thenReturn(true);
    when(testHelper.mockServiceHelper.isSupportChildReboot()).thenReturn(true);
  });

  group('Instant-Topology view', () {
    testLocalizations('Instant-Topology view - default',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
    });

    testLocalizations('Instant-Topology view - signal good',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopologyGoodSlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );

      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - signal fair',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopologyFairSlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );

      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - signal poor',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopologyPoorSlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );

      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - instant-action popup',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpAndSettle();
      final treeNodeItemFinder =
          find.byType(TopologyNodeItem, skipOffstage: false);
      final instantActionFinder = find.descendant(
        of: treeNodeItemFinder.first,
        matching: find.byType(PopupMenuButton<NodeInstantActions>),
        skipOffstage: false,
      );
      await tester.tap(instantActionFinder);
      await tester.pumpAndSettle();
    });
    testLocalizations(
        'Instant-Topology view - instant-action popup - child node',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpAndSettle();
      final treeNodeItemFinder =
          find.byType(TopologyNodeItem, skipOffstage: false);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      final instantActionFinder = find.descendant(
        of: treeNodeItemFinder.last,
        matching: find.byType(PopupMenuButton<NodeInstantActions>),
        skipOffstage: false,
      );
      await tester.tap(instantActionFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'Instant-Topology view - instant-action popup - legacy child node',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopologyLegacySlavesDaisyState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(InstantTopologyView));
        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx5300, context);
        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await precacheImage(
            CustomTheme.of(context).images.devices_xl.routerLn12, context);
        await tester.pumpAndSettle();
      });
      await tester.pumpAndSettle();
      final treeNodeItemFinder =
          find.byType(TopologyNodeItem, skipOffstage: false);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - reboot parent alert ',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpAndSettle();
      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      final instantActionFinder = find.descendant(
        of: treeNodeItemFinder.first,
        matching: find.byType(PopupMenuButton<NodeInstantActions>),
        skipOffstage: true,
      );
      await tester.tap(instantActionFinder);
      await tester.pumpAndSettle();

      final popupMenuItemFinder =
          find.byType(PopupMenuItem<NodeInstantActions>);
      await tester.tap(popupMenuItemFinder.at(1));
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - reboot child alert ',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpAndSettle();
      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      final instantActionFinder = find.descendant(
        of: treeNodeItemFinder.last,
        matching: find.byType(PopupMenuButton<NodeInstantActions>),
        skipOffstage: true,
      );
      await tester.tap(instantActionFinder);
      await tester.pumpAndSettle();

      final popupMenuItemFinder =
          find.byType(PopupMenuItem<NodeInstantActions>);
    }, screens: _instantTopologyScreens);

    testLocalizations('Instant-Topology view - factory reset parent alert ',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpAndSettle();
      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      final instantActionFinder = find.descendant(
        of: treeNodeItemFinder.first,
        matching: find.byType(PopupMenuButton<NodeInstantActions>),
        skipOffstage: true,
      );
      await tester.tap(instantActionFinder);
      await tester.pumpAndSettle();

      final popupMenuItemFinder =
          find.byType(PopupMenuItem<NodeInstantActions>);
      await tester.tap(popupMenuItemFinder.at(3));
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - factory reset child alert ',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpAndSettle();
      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      final instantActionFinder = find.descendant(
        of: treeNodeItemFinder.last,
        matching: find.byType(PopupMenuButton<NodeInstantActions>),
        skipOffstage: true,
      );
      await tester.tap(instantActionFinder);
      await tester.pumpAndSettle();

      final popupMenuItemFinder =
          find.byType(PopupMenuItem<NodeInstantActions>);
      await tester.tap(popupMenuItemFinder.at(2));
      await tester.pumpAndSettle();
    }, screens: _instantTopologyScreens);

    testLocalizations('Instant-Topology view - firmware update available',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build()).thenReturn(
          TopologyTestData().testTopology2SlavesDaisyAndFwUpdateState);
      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpAndSettle();
      final treeNodeItemFinder =
          find.byType(TopologyNodeItem, skipOffstage: false);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
    });
    testLocalizations('Instant-Topology view - offline node',
        (tester, locale) async {
      when(testHelper.mockInstantTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1OfflineState);

      await testHelper.pumpView(
        tester,
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpAndSettle();
      final treeNodeItemFinder =
          find.byType(TopologyNodeItem, skipOffstage: false);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
    });
  });
}