import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';

import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/add_wired_nodes_notifier_mocks.dart';
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

  group('Instant topology view - add wired node', () {
    Future operateForShowingAddWiredNode(WidgetTester tester) async {
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
      final popupMenuFinder = find.byKey(ValueKey('popup-menu-pair'));
      await tester.scrollUntilVisible(popupMenuFinder, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(popupMenuFinder);
      await tester.pumpAndSettle();
      final subPopupMenuFinder =
          find.byKey(ValueKey('popup-sub-menu-pairWired'));
      await tester.scrollUntilVisible(subPopupMenuFinder, 10,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(subPopupMenuFinder);
    }

    Widget createAddWiredNodeWidget(
        WidgetTester tester, Locale locale, AddWiredNodesNotifier notifier) {
      return testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
          addWiredNodesProvider.overrideWith(() => notifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
    }

    testLocalizations('Instant-Topology view - add wired node processing',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);
      final simple = SimpleAddWiredNodesNotifier();
      final widget = createAddWiredNodeWidget(tester, locale, simple);
      await tester.pumpWidget(widget);
      await operateForShowingAddWiredNode(tester);
      await tester.pumpFrames(widget, Duration(seconds: 2));
    });

    testLocalizations('Instant-Topology view - add wired node success',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);
      final simple = SimpleSuccessAddWiredNodesNotifier();
      final widget = createAddWiredNodeWidget(tester, locale, simple);
      await tester.pumpWidget(widget);
      await operateForShowingAddWiredNode(tester);
      await tester.pumpFrames(widget, Duration(seconds: 2));
      await tester.pumpFrames(widget, Duration(seconds: 5));
    });

    testLocalizations('Instant-Topology view - add wired node failed',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology1SlaveState);
      final simple = SimpleAddWiredNodesNotifier();
      final widget = createAddWiredNodeWidget(tester, locale, simple);
      await tester.pumpWidget(widget);
      await operateForShowingAddWiredNode(tester);
      await tester.pumpFrames(widget, Duration(seconds: 2));
      await tester.pumpFrames(widget, Duration(seconds: 5));
    });
  });
}

class SimpleAddWiredNodesNotifier extends AddWiredNodesNotifier with Mock {
  @override
  AddWiredNodesState get state => const AddWiredNodesState(isLoading: true);

  @override
  set state(AddWiredNodesState newState) {
    super.state = newState;
  }

  @override
  Future startAutoOnboarding(BuildContext context) async {
    state = state.copyWith(isLoading: true, loadingMessage: '');
    await Future.delayed(const Duration(seconds: 5));
    state = state.copyWith(
        isLoading: false, loadingMessage: '', onboardingProceed: true);
  }
}

class SimpleSuccessAddWiredNodesNotifier extends AddWiredNodesNotifier
    with Mock {
  @override
  AddWiredNodesState get state => const AddWiredNodesState(isLoading: true);

  @override
  set state(AddWiredNodesState newState) {
    super.state = newState;
  }

  @override
  Future startAutoOnboarding(BuildContext context) async {
    state = state.copyWith(isLoading: true, loadingMessage: '');
    await Future.delayed(const Duration(seconds: 5));
    state = state.copyWith(
        isLoading: false,
        loadingMessage: loc(context).foundNNodesOnline(1),
        onboardingProceed: true,
        anyOnboarded: true);
  }
}
