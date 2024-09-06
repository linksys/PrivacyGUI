import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_topology/views/instant_topology_view.dart';

import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/jnap_service_helper_spec_mocks.dart';
import '../../../test_data/topology_data.dart';
import '../../../mocks/topology_notifier_mocks.dart';

void main() async {
  late TopologyNotifier mockTopologyNotifier;
  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    mockTopologyNotifier = MockTopologyNotifier();
    initBetterActions();
    when(mockServiceHelper.isSupportAutoOnboarding()).thenReturn(true);
    when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
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
        child: const InstantTopologyView(),
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
        child: const InstantTopologyView(),
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
        child: const InstantTopologyView(),
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
        child: const InstantTopologyView(),
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
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 6 online nodes hybrid',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyState6);

      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });
  });

  group('Topology view test - has offline nodes', () {
    testLocalizations('topology view - 1 offline node', (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline1);
      // when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);
      final widget = testableSingleRoute(
        themeMode: ThemeMode.dark,
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('topology view - 2 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(testTopologyStateOffline2);
      // when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);

      final widget = testableSingleRoute(
        overrides: [
          topologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
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
        child: const InstantTopologyView(),
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
        child: const InstantTopologyView(),
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
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });
  });
}
