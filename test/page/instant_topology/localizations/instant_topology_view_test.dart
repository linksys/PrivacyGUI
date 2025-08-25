import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/topology_data.dart';
import '../../../mocks/instant_topology_notifier_mocks.dart';

void main() async {
  late InstantTopologyNotifier mockTopologyNotifier;
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockTopologyNotifier = MockInstantTopologyNotifier();
    initBetterActions();
    when(mockServiceHelper.isSupportAutoOnboarding()).thenReturn(true);
    when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
    when(mockServiceHelper.isSupportChildFactoryReset()).thenReturn(true);
    when(mockServiceHelper.isSupportChildReboot()).thenReturn(true);
  });

  group('Instant-Topology view', () {
    testLocalizations('Instant-Topology view - default',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant-Topology view - signal good',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopologyGoodSlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );

      await tester.pumpWidget(widget);
      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - signal fair',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopologyFairSlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );

      await tester.pumpWidget(widget);
      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - signal poor',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopologyPoorSlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );

      await tester.pumpWidget(widget);
      final treeNodeItemFinder = find.byType(TopologyNodeItem);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
    });

    testLocalizations('Instant-Topology view - instant-action popup',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
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
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
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
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopologyLegacySlavesDaisyState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
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
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
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
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
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
      await tester.tap(popupMenuItemFinder.at(1));
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Instant-Topology view - factory reset parent alert ',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
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
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
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
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1280)).toList()
    ]);

    testLocalizations('Instant-Topology view - firmware update available',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(
          TopologyTestData().testTopology2SlavesDaisyAndFwUpdateState);
      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      final treeNodeItemFinder =
          find.byType(TopologyNodeItem, skipOffstage: false);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
    });
    testLocalizations('Instant-Topology view - offline node',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1OfflineState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      final treeNodeItemFinder =
          find.byType(TopologyNodeItem, skipOffstage: false);
      await tester.scrollUntilVisible(treeNodeItemFinder.last, 10,
          scrollable: find.byType(Scrollable).last);
    });

    // testLocalizations('Instant topology view - 3 online nodes stars',
    //     (tester, locale) async {
    //   when(mockTopologyNotifier.build())
    //       .thenReturn(TopologyTestData().testTopology2SlavesStarState);

    //   final widget = testableSingleRoute(
    //     overrides: [
    //       instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
    //     ],
    //     child: const InstantTopologyView(),
    //     locale: locale,
    //   );
    //   await tester.pumpWidget(widget);
    // });

    // testLocalizations('Instant topology view - 3 online nodes daisy',
    //     (tester, locale) async {
    //   when(mockTopologyNotifier.build())
    //       .thenReturn(TopologyTestData().testTopology2SlavesDaisyState);

    //   final widget = testableSingleRoute(
    //     overrides: [
    //       instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
    //     ],
    //     child: const InstantTopologyView(),
    //     locale: locale,
    //   );
    //   await tester.pumpWidget(widget);
    // });

    // testLocalizations('Instant topology view - 6 online nodes stars',
    //     (tester, locale) async {
    //   when(mockTopologyNotifier.build())
    //       .thenReturn(TopologyTestData().testTopology5SlavesStarState);

    //   final widget = testableSingleRoute(
    //     overrides: [
    //       instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
    //     ],
    //     child: const InstantTopologyView(),
    //     locale: locale,
    //   );
    //   await tester.pumpWidget(widget);
    // });

    // testLocalizations('Instant topology view - 6 online nodes daisy',
    //     (tester, locale) async {
    //   when(mockTopologyNotifier.build())
    //       .thenReturn(TopologyTestData().testTopology5SlavesDaisyState);

    //   final widget = testableSingleRoute(
    //     overrides: [
    //       instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
    //     ],
    //     child: const InstantTopologyView(),
    //     locale: locale,
    //   );
    //   await tester.pumpWidget(widget);
    // });

    // testLocalizations('Instant topology view - 6 online nodes hybrid',
    //     (tester, locale) async {
    //   when(mockTopologyNotifier.build())
    //       .thenReturn(TopologyTestData().testTopology5SlavesMixedState);

    //   final widget = testableSingleRoute(
    //     overrides: [
    //       instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
    //     ],
    //     child: const InstantTopologyView(),
    //     locale: locale,
    //   );
    //   await tester.pumpWidget(widget);
    // });
  });

  // group('Instant topology view test - has offline nodes', () {
  //   testLocalizations('Instant topology view - 1 offline node',
  //       (tester, locale) async {
  //     when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology1OfflineState);
  //     // when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);
  //     final widget = testableSingleRoute(
  //       themeMode: ThemeMode.dark,
  //       overrides: [
  //         instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
  //       ],
  //       child: const InstantTopologyView(),
  //       locale: locale,
  //     );
  //     await tester.pumpWidget(widget);
  //   });

  //   testLocalizations('Instant topology view - 2 offline nodes',
  //       (tester, locale) async {
  //     when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology2OfflineState);
  //     // when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);

  //     final widget = testableSingleRoute(
  //       overrides: [
  //         instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
  //       ],
  //       child: const InstantTopologyView(),
  //       locale: locale,
  //     );
  //     await tester.pumpWidget(widget);
  //   });

  //   testLocalizations('Instant topology view - 3 offline nodes',
  //       (tester, locale) async {
  //     when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology3OfflineState);
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
  //       ],
  //       child: const InstantTopologyView(),
  //       locale: locale,
  //     );
  //     await tester.pumpWidget(widget);
  //   });

  //   testLocalizations('Instant topology view - 4 offline nodes',
  //       (tester, locale) async {
  //     when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology4OfflineState);
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
  //       ],
  //       child: const InstantTopologyView(),
  //       locale: locale,
  //     );
  //     await tester.pumpWidget(widget);
  //   });

  //   testLocalizations('Instant topology view - 5 offline nodes',
  //       (tester, locale) async {
  //     when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology5OfflineState);
  //     final widget = testableSingleRoute(
  //       overrides: [
  //         instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
  //       ],
  //       child: const InstantTopologyView(),
  //       locale: locale,
  //     );
  //     await tester.pumpWidget(widget);
  //   });
  // });
}
