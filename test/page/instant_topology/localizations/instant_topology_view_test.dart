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
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../test_data/topology_data.dart';
import '../../../mocks/instant_topology_notifier_mocks.dart';

void main() async {
  late InstantTopologyNotifier mockTopologyNotifier;
  ServiceHelper mockServiceHelper = MockServiceHelper();
  getIt.registerSingleton<ServiceHelper>(mockServiceHelper);

  setUp(() {
    mockTopologyNotifier = MockInstantTopologyNotifier();
    initBetterActions();
    when(mockServiceHelper.isSupportAutoOnboarding()).thenReturn(true);
    when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
  });

  group('Instant topology view test - online nodes', () {
    testLocalizations('Instant topology view - 2 online nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology1SlaveState);

      final widget = testableSingleRoute(
        themeMode: ThemeMode.dark,
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        locale: locale,
        child: const InstantTopologyView(),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 3 online nodes stars',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology2SlavesStarState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 3 online nodes daisy',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology2SlavesDaisyState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 6 online nodes stars',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology5SlavesStarState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 6 online nodes daisy',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology5SlavesDaisyState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 6 online nodes hybrid',
        (tester, locale) async {
      when(mockTopologyNotifier.build())
          .thenReturn(TopologyTestData().testTopology5SlavesMixedState);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });
  });

  group('Instant topology view test - has offline nodes', () {
    testLocalizations('Instant topology view - 1 offline node',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology1OfflineState);
      // when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);
      final widget = testableSingleRoute(
        themeMode: ThemeMode.dark,
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 2 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology2OfflineState);
      // when(mockTopologyNotifier.isSupportAutoOnboarding()).thenReturn(true);

      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 3 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology3OfflineState);
      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 4 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology4OfflineState);
      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('Instant topology view - 5 offline nodes',
        (tester, locale) async {
      when(mockTopologyNotifier.build()).thenReturn(TopologyTestData().testTopology5OfflineState);
      final widget = testableSingleRoute(
        overrides: [
          instantTopologyProvider.overrideWith(() => mockTopologyNotifier),
        ],
        child: const InstantTopologyView(),
        locale: locale,
      );
      await tester.pumpWidget(widget);
    });
  });
}
