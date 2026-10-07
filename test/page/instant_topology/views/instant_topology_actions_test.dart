// The Instant Topology node action menu.
//
// With full access: which actions each node gets, and that choosing one still
// reaches the provider after its confirmation. A read-only login keeps only
// Blink, a diagnostic; reboot, pair and reset all change the network (#1637).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';

import '../../../common/_index.dart';
import '../../../common/di.dart';
import '../../../mocks/instant_topology_notifier_mocks.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../test_data/topology_data.dart';

void main() {
  late MockInstantTopologyNotifier mockTopologyNotifier;
  late MockPollingNotifier mockPollingNotifier;
  mockDependencyRegister();
  final ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockTopologyNotifier = MockInstantTopologyNotifier();
    mockPollingNotifier = MockPollingNotifier();
    initBetterActions();
    when(mockTopologyNotifier.build())
        .thenReturn(TopologyTestData().testTopology1SlaveState);
    when(mockTopologyNotifier.reboot(any)).thenAnswer((_) async {});
    when(mockTopologyNotifier.factoryReset(any)).thenAnswer((_) async {});
    when(mockTopologyNotifier.toggleBlinkNode(any)).thenAnswer((_) async {});
    when(mockServiceHelper.isSupportAutoOnboarding()).thenReturn(true);
    when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
    when(mockServiceHelper.isSupportChildReboot()).thenReturn(true);
    when(mockServiceHelper.isSupportChildFactoryReset()).thenReturn(true);
  });

  tearDown(() => reset(mockServiceHelper));

  Future<void> pump(WidgetTester tester,
      {AccessPolicy policy = AccessPolicy.full}) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        pollingProvider.overrideWith(() => mockPollingNotifier),
        accessPolicyProvider.overrideWithValue(policy),
      ],
      child: const InstantTopologyView(),
    ));
    await tester.pumpAndSettle();
  }

  TopologyNodeItem node(WidgetTester tester, String location) =>
      tester.widget<TopologyNodeItem>(
          find.widgetWithText(TopologyNodeItem, location));

  group('actions offered to each node', () {
    testWidgets('the master gets blink, reboot, pair and reset',
        (tester) async {
      await pump(tester);
      expect(node(tester, 'Living room').actions, [
        NodeInstantActions.blink,
        NodeInstantActions.reboot,
        NodeInstantActions.pair,
        NodeInstantActions.reset,
      ]);
    });

    testWidgets('a child gets blink, reboot and reset', (tester) async {
      await pump(tester);
      expect(node(tester, 'Kitchen').actions, [
        NodeInstantActions.blink,
        NodeInstantActions.reboot,
        NodeInstantActions.reset,
      ]);
    });

    testWidgets('pair follows auto-onboarding support', (tester) async {
      when(mockServiceHelper.isSupportAutoOnboarding()).thenReturn(false);
      await pump(tester);
      expect(node(tester, 'Living room').actions,
          isNot(contains(NodeInstantActions.pair)));
    });
  });

  group('choosing an action', () {
    Future<void> choose(
        WidgetTester tester, String location, NodeInstantActions action) async {
      node(tester, location).onActionTap!(action);
      await tester.pumpAndSettle();
    }

    testWidgets('blink reaches the provider without confirmation',
        (tester) async {
      await pump(tester);
      await choose(tester, 'Living room', NodeInstantActions.blink);

      verify(mockTopologyNotifier.toggleBlinkNode(any)).called(1);
    });

    testWidgets('reboot asks first, then reaches the provider', (tester) async {
      await pump(tester);
      await choose(tester, 'Living room', NodeInstantActions.reboot);

      verifyNever(mockTopologyNotifier.reboot(any));
      await tester.tap(find.text('Yes, Reboot All'));
      await tester.pumpAndSettle();
      verify(mockTopologyNotifier.reboot(any)).called(1);
    });

    testWidgets('cancelling reboot sends nothing', (tester) async {
      await pump(tester);
      await choose(tester, 'Living room', NodeInstantActions.reboot);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(mockTopologyNotifier.reboot(any));
    });

    testWidgets('reset asks first, then reaches the provider', (tester) async {
      await pump(tester);
      await choose(tester, 'Living room', NodeInstantActions.reset);

      verifyNever(mockTopologyNotifier.factoryReset(any));
      await tester.tap(find.text('Yes, Factory Reset All'));
      await tester.pumpAndSettle();
      verify(mockTopologyNotifier.factoryReset(any)).called(1);
    });
  });

  group('a read-only login', () {
    const readOnly = AccessPolicy(canWrite: false);

    testWidgets('every node keeps only blink', (tester) async {
      await pump(tester, policy: readOnly);

      expect(node(tester, 'Living room').actions, [NodeInstantActions.blink]);
      expect(node(tester, 'Kitchen').actions, [NodeInstantActions.blink]);
    });

    testWidgets('blink still reaches the provider', (tester) async {
      await pump(tester, policy: readOnly);
      node(tester, 'Living room').onActionTap!(NodeInstantActions.blink);
      await tester.pumpAndSettle();

      verify(mockTopologyNotifier.toggleBlinkNode(any)).called(1);
    });
  });
}
