import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/_topology.dart';
import 'package:mockito/mockito.dart';

import '../../../common/mock_firebase_messaging.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/topology_data.dart';
import '../topology_view_test_mocks.dart';

void main() async {
  late TopologyNotifier mockTopologyNotifier;

  setupFirebaseMessagingMocks();
  // FirebaseMessaging? messaging;
  await Firebase.initializeApp();
  // FirebaseMessagingPlatform.instance = kMockMessagingPlatform;
  // messaging = FirebaseMessaging.instance;
  setUp(() {
    mockTopologyNotifier = MockTopologyNotifier();
    when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);
  });
  group('Topology view test - online nodes', () {
    testLocalizations('topology view - 2 online nodes', (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyState1);

      final widget = testableSingleRoute(
        themeMode: ThemeMode.dark,
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const TopologyView(),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 3 online nodes stars',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyState2);

      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 3 online nodes daisy',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyState3);

      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 6 online nodes stars',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyState4);

      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 6 online nodes daisy',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyState5);

      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 6 online nodes hybrid',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyState5);

      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });
  });

  group('Topology view test - has offline nodes', () {
    testLocalizations('topology view - 1 offline node', (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline1);
      when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);
      final widget = testableSingleRoute(
        themeMode: ThemeMode.dark,
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 2 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline2);
      when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);

      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 3 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline3);
      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 4 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline4);
      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 5 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline5);
      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const TopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });
  });
}
