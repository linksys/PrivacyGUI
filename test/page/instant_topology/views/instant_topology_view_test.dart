import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:mockito/mockito.dart';

import '../../../common/_index.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../test_data/topology_data.dart';
import '../../../mocks/instant_topology_notifier_mocks.dart';

void main() {
  late InstantTopologyNotifier mockTopologyNotifier;
  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    mockTopologyNotifier = MockInstantTopologyNotifier();
    initBetterActions();
    when(mockServiceHelper.isSupportAutoOnboarding()).thenReturn(true);
    when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
  });
  group('Topology view test - online nodes', () {
    testResponsiveWidgets('topology view - 2 online nodes', (tester) async {
      when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
          themeMode: ThemeMode.dark,
          overrides: [
            instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
          ],
          child: const InstantTopologyView());
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();
      // Find Build Context
      final BuildContext context =
          tester.element(find.byType(InstantTopologyView));

      // Find by text
      final internetItem = find.text('Internet');
      // Find by icon
      final internetItemIcon = find.byIcon(LinksysIcons.language);
      // internet node check
      expect(internetItem, findsOneWidget);
      expect(internetItemIcon, findsOneWidget);

      // TopologyNodeItem widget
      final node1Finder = find.widgetWithText(TopologyNodeItem, 'Living room');
      final node1 = tester.firstWidget(node1Finder) as TopologyNodeItem;
      final node1ImageFinder =
          find.descendant(of: node1Finder, matching: find.byType(Image));
      final node1Image = tester.firstWidget(node1ImageFinder) as Image;
      expect(node1Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node1.node.data.location, 'Living room');

      final node2Finder = find.widgetWithText(TopologyNodeItem, 'Kitchen');
      final node2 = tester.firstWidget(node2Finder) as TopologyNodeItem;
      final node2ImageFinder =
          find.descendant(of: node1Finder, matching: find.byType(Image));
      final node2Image = tester.firstWidget(node2ImageFinder) as Image;
      expect(node2Image.image,
          CustomTheme.of(context).images.devices.routerLn12);

      expect(node2.node.data.location, 'Kitchen');
    }, variants: ValueVariant({device480w}));

    testResponsiveWidgets('topology view - 3 online nodes stars',
        (tester) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology2SlavesStarState);

      final widget = testableSingleRoute(overrides: [
        instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
      ], child: const InstantTopologyView());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Find Build Context
      final BuildContext context =
          tester.element(find.byType(InstantTopologyView));

      // Find by text
      final internetItem = find.text('Internet');
      // Find by icon
      final internetItemIcon = find.byIcon(LinksysIcons.language);
      // internet node check
      expect(internetItem, findsOneWidget);
      expect(internetItemIcon, findsOneWidget);

      // TopologyNodeItem widget
      final node1Finder =
          find.widgetWithText(TopologyNodeItem, 'Living room', skipOffstage: false);
      final node1 = tester.firstWidget(node1Finder) as TopologyNodeItem;
      final node1ImageFinder =
          find.descendant(of: node1Finder, matching: find.byType(Image));
      final node1Image = tester.firstWidget(node1ImageFinder) as Image;
      expect(node1Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node1.node.data.location, 'Living room');

      // TopologyNodeItem widget
      final node2Finder =
          find.widgetWithText(TopologyNodeItem, 'Kitchen', skipOffstage: false);

      // Scroll until node 2 visible
      await tester.scrollUntilVisible(node2Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node2 = tester.firstWidget(node2Finder) as TopologyNodeItem;
      final node2ImageFinder =
          find.descendant(of: node2Finder, matching: find.byType(Image));
      final node2Image = tester.firstWidget(node2ImageFinder) as Image;
      expect(node2Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node2.node.data.location, 'Kitchen');

      // TopologyNodeItem widget
      final node3Finder =
          find.widgetWithText(TopologyNodeItem, 'Basement', skipOffstage: false);

      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node3Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node3 = tester.firstWidget(node3Finder) as TopologyNodeItem;
      final node3ImageFinder = find.descendant(
          of: node3Finder, matching: find.byType(Image), skipOffstage: false);
      final node3Image = tester.firstWidget(node3ImageFinder) as Image;
      expect(node3Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node3.node.data.location, 'Basement');
    });

    testResponsiveWidgets('topology view - 3 online nodes daisy',
        (tester) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology2SlavesDaisyState);

      final widget = testableSingleRoute(overrides: [
        instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
      ], child: const InstantTopologyView());
      await tester.pumpWidget(widget);

      // Find Build Context
      final BuildContext context =
          tester.element(find.byType(InstantTopologyView));

      // Find by text
      final internetItem = find.text('Internet');
      // Find by icon
      final internetItemIcon = find.byIcon(LinksysIcons.language);
      // internet node check
      expect(internetItem, findsOneWidget);
      expect(internetItemIcon, findsOneWidget);

      // TopologyNodeItem widget
      final node1Finder = find.widgetWithText(TopologyNodeItem, 'Living room');
      final node1 = tester.firstWidget(node1Finder) as TopologyNodeItem;
      final node1ImageFinder =
          find.descendant(of: node1Finder, matching: find.byType(Image));
      final node1Image = tester.firstWidget(node1ImageFinder) as Image;
      expect(node1Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node1.node.data.location, 'Living room');

      // TopologyNodeItem widget
      final node2Finder = find.widgetWithText(TopologyNodeItem, 'Kitchen');

      // Scroll until node 2 visible
      await tester.scrollUntilVisible(node2Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node2 = tester.firstWidget(node2Finder) as TopologyNodeItem;
      final node2ImageFinder =
          find.descendant(of: node2Finder, matching: find.byType(Image));
      final node2Image = tester.firstWidget(node2ImageFinder) as Image;
      expect(node2Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node2.node.data.location, 'Kitchen');

      // TopologyNodeItem widget
      final node3Finder = find.widgetWithText(TopologyNodeItem, 'Basement');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node3Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node3 = tester.firstWidget(node3Finder) as TopologyNodeItem;
      final node3ImageFinder =
          find.descendant(of: node3Finder, matching: find.byType(Image));
      final node3Image = tester.firstWidget(node3ImageFinder) as Image;
      expect(node3Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node3.node.data.location, 'Basement');
    });

    testResponsiveWidgets('topology view - 6 online nodes stars',
        (tester) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology5SlavesStarState);

      final widget = testableSingleRoute(overrides: [
        instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
      ], child: const InstantTopologyView());
      await tester.pumpWidget(widget);

      // Find Build Context
      final BuildContext context =
          tester.element(find.byType(InstantTopologyView));

      // Find by text
      final internetItem = find.text('Internet');
      // Find by icon
      final internetItemIcon = find.byIcon(LinksysIcons.language);
      // internet node check
      expect(internetItem, findsOneWidget);
      expect(internetItemIcon, findsOneWidget);

      // TopologyNodeItem widget
      final node1Finder = find.widgetWithText(TopologyNodeItem, 'Living room');
      final node1 = tester.firstWidget(node1Finder) as TopologyNodeItem;
      final node1ImageFinder =
          find.descendant(of: node1Finder, matching: find.byType(Image));
      final node1Image = tester.firstWidget(node1ImageFinder) as Image;
      expect(node1Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node1.node.data.location, 'Living room');

      // TopologyNodeItem widget
      final node2Finder = find.widgetWithText(TopologyNodeItem, 'Kitchen');
      // Scroll until node 2 visible
      await tester.scrollUntilVisible(node2Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node2 = tester.firstWidget(node2Finder) as TopologyNodeItem;
      final node2ImageFinder =
          find.descendant(of: node2Finder, matching: find.byType(Image));
      final node2Image = tester.firstWidget(node2ImageFinder) as Image;
      expect(node2Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node2.node.data.location, 'Kitchen');

      // TopologyNodeItem widget
      final node3Finder = find.widgetWithText(TopologyNodeItem, 'Basement');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node3Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node3 = tester.firstWidget(node3Finder) as TopologyNodeItem;
      final node3ImageFinder =
          find.descendant(of: node3Finder, matching: find.byType(Image));
      final node3Image = tester.firstWidget(node3ImageFinder) as Image;
      expect(node3Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node3.node.data.location, 'Basement');

      // TopologyNodeItem widget
      final node4Finder = find.widgetWithText(TopologyNodeItem, 'Bed room 1');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node4Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node4 = tester.firstWidget(node4Finder) as TopologyNodeItem;
      final node4ImageFinder =
          find.descendant(of: node4Finder, matching: find.byType(Image));
      final node4Image = tester.firstWidget(node4ImageFinder) as Image;
      expect(node4Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node4.node.data.location, 'Bed room 1');

      // TopologyNodeItem widget
      final node5Finder = find.widgetWithText(TopologyNodeItem, 'Bed room 2');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node5Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node5 = tester.firstWidget(node5Finder) as TopologyNodeItem;
      final node5ImageFinder =
          find.descendant(of: node5Finder, matching: find.byType(Image));
      final node5Image = tester.firstWidget(node5ImageFinder) as Image;
      expect(node5Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node5.node.data.location, 'Bed room 2');

      // TopologyNodeItem widget
      final node6Finder = find.widgetWithText(
          TopologyNodeItem, 'A super long long long long long long cool name');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node5Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node6 = tester.firstWidget(node6Finder) as TopologyNodeItem;
      final node6ImageFinder =
          find.descendant(of: node6Finder, matching: find.byType(Image));
      final node6Image = tester.firstWidget(node6ImageFinder) as Image;
      expect(node6Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node6.node.data.location,
          'A super long long long long long long cool name');
    });

    testResponsiveWidgets('topology view - 6 online nodes daisy',
        (tester) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology5SlavesDaisyState);

      final widget = testableSingleRoute(overrides: [
        instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
      ], child: const InstantTopologyView());
      await tester.pumpWidget(widget);

      // Find Build Context
      final BuildContext context =
          tester.element(find.byType(InstantTopologyView));

      // Find by text
      final internetItem = find.text('Internet');
      // Find by icon
      final internetItemIcon = find.byIcon(LinksysIcons.language);
      // internet node check
      expect(internetItem, findsOneWidget);
      expect(internetItemIcon, findsOneWidget);

      // TopologyNodeItem widget
      final node1Finder = find.widgetWithText(TopologyNodeItem, 'Living room');
      final node1 = tester.firstWidget(node1Finder) as TopologyNodeItem;
      final node1ImageFinder =
          find.descendant(of: node1Finder, matching: find.byType(Image));
      final node1Image = tester.firstWidget(node1ImageFinder) as Image;
      expect(node1Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node1.node.data.location, 'Living room');

      // TopologyNodeItem widget
      final node2Finder = find.widgetWithText(TopologyNodeItem, 'Kitchen');
      // Scroll until node 2 visible
      await tester.scrollUntilVisible(node2Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node2 = tester.firstWidget(node2Finder) as TopologyNodeItem;
      final node2ImageFinder =
          find.descendant(of: node2Finder, matching: find.byType(Image));
      final node2Image = tester.firstWidget(node2ImageFinder) as Image;
      expect(node2Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node2.node.data.location, 'Kitchen');

      // TopologyNodeItem widget
      final node3Finder = find.widgetWithText(TopologyNodeItem, 'Basement');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node3Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node3 = tester.firstWidget(node3Finder) as TopologyNodeItem;
      final node3ImageFinder =
          find.descendant(of: node3Finder, matching: find.byType(Image));
      final node3Image = tester.firstWidget(node3ImageFinder) as Image;
      expect(node3Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node3.node.data.location, 'Basement');

      // TopologyNodeItem widget
      final node4Finder = find.widgetWithText(TopologyNodeItem, 'Bed room 1');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node4Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node4 = tester.firstWidget(node4Finder) as TopologyNodeItem;
      final node4ImageFinder =
          find.descendant(of: node4Finder, matching: find.byType(Image));
      final node4Image = tester.firstWidget(node4ImageFinder) as Image;
      expect(node4Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node4.node.data.location, 'Bed room 1');

      // TopologyNodeItem widget
      final node5Finder = find.widgetWithText(TopologyNodeItem, 'Bed room 2');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node5Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node5 = tester.firstWidget(node5Finder) as TopologyNodeItem;
      final node5ImageFinder =
          find.descendant(of: node5Finder, matching: find.byType(Image));
      final node5Image = tester.firstWidget(node5ImageFinder) as Image;
      expect(node5Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node5.node.data.location, 'Bed room 2');

      // TopologyNodeItem widget
      final node6Finder = find.widgetWithText(
          TopologyNodeItem, 'A super long long long long long long cool name');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node5Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node6 = tester.firstWidget(node6Finder) as TopologyNodeItem;
      final node6ImageFinder =
          find.descendant(of: node6Finder, matching: find.byType(Image));
      final node6Image = tester.firstWidget(node6ImageFinder) as Image;
      expect(node6Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node6.node.data.location,
          'A super long long long long long long cool name');
    });

    testResponsiveWidgets('topology view - 6 online nodes hybrid',
        (tester) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology5SlavesDaisyState);

      final widget = testableSingleRoute(overrides: [
        instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
      ], child: const InstantTopologyView());
      await tester.pumpWidget(widget);

      // Find Build Context
      final BuildContext context =
          tester.element(find.byType(InstantTopologyView));

      // Find by text
      final internetItem = find.text('Internet');
      // Find by icon
      final internetItemIcon = find.byIcon(LinksysIcons.language);
      // internet node check
      expect(internetItem, findsOneWidget);
      expect(internetItemIcon, findsOneWidget);

      // TopologyNodeItem widget
      final node1Finder = find.widgetWithText(TopologyNodeItem, 'Living room');
      final node1 = tester.firstWidget(node1Finder) as TopologyNodeItem;
      final node1ImageFinder =
          find.descendant(of: node1Finder, matching: find.byType(Image));
      final node1Image = tester.firstWidget(node1ImageFinder) as Image;
      expect(node1Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node1.node.data.location, 'Living room');

      // TopologyNodeItem widget
      final node2Finder = find.widgetWithText(TopologyNodeItem, 'Kitchen');
      // Scroll until node 2 visible
      await tester.scrollUntilVisible(node2Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node2 = tester.firstWidget(node2Finder) as TopologyNodeItem;
      final node2ImageFinder =
          find.descendant(of: node2Finder, matching: find.byType(Image));
      final node2Image = tester.firstWidget(node2ImageFinder) as Image;
      expect(node2Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node2.node.data.location, 'Kitchen');

      // TopologyNodeItem widget
      final node3Finder = find.widgetWithText(TopologyNodeItem, 'Basement');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node3Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node3 = tester.firstWidget(node3Finder) as TopologyNodeItem;
      final node3ImageFinder =
          find.descendant(of: node3Finder, matching: find.byType(Image));
      final node3Image = tester.firstWidget(node3ImageFinder) as Image;
      expect(node3Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node3.node.data.location, 'Basement');

      // TopologyNodeItem widget
      final node4Finder = find.widgetWithText(TopologyNodeItem, 'Bed room 1');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node4Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node4 = tester.firstWidget(node4Finder) as TopologyNodeItem;
      final node4ImageFinder =
          find.descendant(of: node4Finder, matching: find.byType(Image));
      final node4Image = tester.firstWidget(node4ImageFinder) as Image;
      expect(node4Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node4.node.data.location, 'Bed room 1');

      // TopologyNodeItem widget
      final node5Finder = find.widgetWithText(TopologyNodeItem, 'Bed room 2');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node5Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node5 = tester.firstWidget(node5Finder) as TopologyNodeItem;
      final node5ImageFinder =
          find.descendant(of: node5Finder, matching: find.byType(Image));
      final node5Image = tester.firstWidget(node5ImageFinder) as Image;
      expect(node5Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node5.node.data.location, 'Bed room 2');

      // TopologyNodeItem widget
      final node6Finder = find.widgetWithText(
          TopologyNodeItem, 'A super long long long long long long cool name');
      // Scroll until node 3 visible
      await tester.scrollUntilVisible(node5Finder.first, 100,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();

      final node6 = tester.firstWidget(node6Finder) as TopologyNodeItem;
      final node6ImageFinder =
          find.descendant(of: node6Finder, matching: find.byType(Image));
      final node6Image = tester.firstWidget(node6ImageFinder) as Image;
      expect(node6Image.image,
          CustomTheme.of(context).images.devices.routerLn12);
      expect(node6.node.data.location,
          'A super long long long long long long cool name');
    });
  });

  // group('Topology view test - has offline nodes', () {
  //   testResponsiveWidgets('topology view - 1 offline node', (tester) async {
  //     when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline1);
  //     // when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);
  //     final widget = testableSingleRoute(
  //         themeMode: ThemeMode.dark,
  //         overrides: [
  //           topologyProvider.overrideWith(() => mockTopologyNotifier),
  //         ],
  //         child: const TopologyDetailedView());
  //     await tester.pumpWidget(widget);

  //     // Find Build Context
  //     final BuildContext context =
  //         tester.element(find.byType(TopologyDetailedView));

  //     // Find by text
  //     final internetItem = find.text('Internet');
  //     // Find by icon
  //     final internetItemIcon = find.byIcon(LinksysIcons.language);
  //     // internet node check
  //     expect(internetItem, findsOneWidget);
  //     expect(internetItemIcon, findsOneWidget);

  //     // Find offline text
  //     final offlineItem = find.text('Offline');

  //     // check
  //     expect(offlineItem, findsNWidgets(1));

  //     // Find by type
  //     final treeNodeItems = find.byType(TopologyNodeItem);
  //     final treeNodeLargeItems = find.byType(TopologyNodeItem);

  //     // nodes check
  //     expect(treeNodeItems, findsNWidgets(1));
  //     expect(treeNodeLargeItems, findsNWidgets(1));

  //     // TopologyNodeItem widget
  //     final node1Finder = find.widgetWithText(TopologyNodeItem, 'Living room');
  //     final node1 = tester.firstWidget(node1Finder) as TopologyNodeItem;

  //     expect(node1.name, 'Living room');
  //     expect(node1.image, CustomTheme.of(context).images.devices.routerLn12);

  //     final node2Finder = find.widgetWithText(TopologyNodeItem, 'Kitchen');
  //     final node2 = tester.firstWidget(node2Finder) as TopologyNodeItem;
  //     expect(node2.name, 'Kitchen');
  //     expect(node2.image, CustomTheme.of(context).images.devices.routerLn12);
  //     expect(node2.status, 'Offline');
  //   });

  //   testResponsiveWidgets('topology view - 2 offline nodes', (tester) async {
  //     when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline2);
  //     // when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);

  //     final widget = testableSingleRoute(overrides: [
  //       topologyProvider.overrideWith(() => mockTopologyNotifier),
  //     ], child: const TopologyDetailedView());
  //     await tester.pumpWidget(widget);

  //     // Find Build Context
  //     final BuildContext context =
  //         tester.element(find.byType(TopologyDetailedView));

  //     // Find by text
  //     final internetItem = find.text('Internet');
  //     // Find by icon
  //     final internetItemIcon = find.byIcon(LinksysIcons.language);
  //     // internet node check
  //     expect(internetItem, findsOneWidget);
  //     expect(internetItemIcon, findsOneWidget);

  //     // Find offline text
  //     final offlineItem = find.text('Offline');

  //     // check
  //     expect(offlineItem, findsNWidgets(2));

  //     // Find by type
  //     final treeNodeItems = find.byType(TopologyNodeItem);
  //     final treeNodeLargeItems = find.byType(TopologyNodeItem);

  //     // nodes check
  //     expect(treeNodeItems, findsNWidgets(2));
  //     expect(treeNodeLargeItems, findsNWidgets(1));

  //     // TopologyNodeItem widget
  //     final node1Finder = find.widgetWithText(TopologyNodeItem, 'Living room');
  //     final node1 = tester.firstWidget(node1Finder) as TopologyNodeItem;

  //     expect(node1.name, 'Living room');
  //     expect(node1.image, CustomTheme.of(context).images.devices.routerLn12);

  //     final node2Finder = find.widgetWithText(TopologyNodeItem, 'Kitchen');
  //     final node2 = tester.firstWidget(node2Finder) as TopologyNodeItem;
  //     expect(node2.name, 'Kitchen');
  //     expect(node2.status, 'Offline');
  //     expect(node2.image, CustomTheme.of(context).images.devices.routerLn12);

  //     final node3Finder = find.widgetWithText(TopologyNodeItem, 'Basement');
  //     final node3 = tester.firstWidget(node3Finder) as TopologyNodeItem;
  //     expect(node3.name, 'Basement');
  //     expect(node3.status, 'Offline');
  //     expect(node3.image, CustomTheme.of(context).images.devices.routerLn12);
  //   });
  // });
}
