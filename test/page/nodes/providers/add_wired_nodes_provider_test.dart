import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';
import 'package:privacy_gui/providers/idle_checker_pause_provider.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';

/// One entry of `GetBackhaulInfo` output. The times are months in the past
/// in every time zone.
Map<String, dynamic> _backhaul(String id, {required String at}) => {
      'deviceUUID': id,
      'ipAddress': '192.168.1.${id.length}',
      'parentIPAddress': '192.168.1.1',
      'connectionType': 'Wired',
      'wirelessConnectionInfo': null,
      'speedMbps': '1000',
      'timestamp': at,
    };

/// The node already in the mesh when the run starts, as the app last saw it.
final _hallBefore = _backhaul('hall', at: '2026-01-05T09:00:00Z');

/// The same node once the router has refreshed its backhaul data.
final _hallRefreshed = _backhaul('hall', at: '2026-01-05T09:10:00Z');

/// One device of `GetDevices` output.
Map<String, dynamic> _device(String id, {String? nodeType}) => {
      'connections': [
        {'macAddress': 'mac-$id', 'ipAddress': '192.168.1.${id.length}'},
      ],
      'properties': <Object>[],
      'unit': <String, dynamic>{},
      'deviceID': id,
      'maxAllowedProperties': 16,
      'model': {
        'deviceType': nodeType == null ? 'Computer' : 'Infrastructure',
      },
      'isAuthority': nodeType == 'Master',
      'lastChangeRevision': 1,
      'knownInterfaces': [
        {'macAddress': 'mac-$id', 'interfaceType': 'Wired'},
      ],
      if (nodeType != null) 'nodeType': nodeType,
    };

class _DeviceManagerStub extends DeviceManagerNotifier {
  _DeviceManagerStub(this.backhaul);

  final List<BackHaulInfoData> backhaul;

  @override
  DeviceManagerState build() => DeviceManagerState(backhaulInfoData: backhaul);
}

void main() {
  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;
  late BuildContext context;
  late List<bool> idleCheckerPaused;

  AddWiredNodesNotifier notifier() =>
      container.read(addWiredNodesProvider.notifier);
  AddWiredNodesState page() => container.read(addWiredNodesProvider);

  /// Builds an English app for `loc(context)` to read its strings from.
  Future<void> openApp(WidgetTester tester) => tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (built) {
          context = built;
          return const SizedBox();
        }),
      ));

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getBackhaulInfo, {
        'backhaulDevices': [_hallRefreshed],
      })
      ..holds(JNAPAction.getDevices, {
        'devices': [
          _device('master', nodeType: 'Master'),
          _device('hall', nodeType: 'Slave'),
          _device('laptop'),
        ],
      });
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
      deviceManagerProvider.overrideWith(() => _DeviceManagerStub([
            BackHaulInfoData.fromMap(_hallBefore),
          ])),
    ]);
    // The provider disposes itself once nothing listens, as the pairing
    // dialog's watch does.
    container.listen(addWiredNodesProvider, (_, __) {});
    idleCheckerPaused = [];
    container.listen<bool>(
        idleCheckerPauseProvider, (_, paused) => idleCheckerPaused.add(paused));
  });

  tearDown(() => container.dispose());

  group('the wired onboarding settings', () {
    test('turns wired auto-onboarding on and off', () async {
      await notifier().setAutoOnboardingSettings(true);
      await notifier().setAutoOnboardingSettings(false);

      expect(router.payloadsOf(JNAPAction.setWiredAutoOnboardingSettings), [
        {'isAutoOnboardingEnabled': true},
        {'isAutoOnboardingEnabled': false},
      ]);
    });

    test('reports a setting the router refuses', () async {
      router.refuses(JNAPAction.setWiredAutoOnboardingSettings);

      await expectLater(notifier().setAutoOnboardingSettings(true),
          throwsA(isA<JNAPError>()));
    });
  });

  group('startAutoOnboarding', () {
    testWidgets('turns wired onboarding on for the run and off at the end',
        (tester) async {
      await openApp(tester);

      await notifier().startAutoOnboarding(context);

      expect(router.payloadsOf(JNAPAction.setWiredAutoOnboardingSettings), [
        {'isAutoOnboardingEnabled': true},
        {'isAutoOnboardingEnabled': false},
      ]);
      // Sixty backhaul reads, ten seconds apart, unless the user stops it.
      expect(router.payloadsOf(JNAPAction.getBackhaulInfo), hasLength(60));
      expect(page().onboardingProceed, isTrue);
      expect(page().isLoading, isFalse);
    });

    testWidgets('pauses the idle checker for the run', (tester) async {
      await openApp(tester);

      await notifier().startAutoOnboarding(context);

      expect(idleCheckerPaused, [true, false]);
    });

    testWidgets('counts the nodes that come online on the backhaul',
        (tester) async {
      await openApp(tester);
      router.holds(JNAPAction.getBackhaulInfo, {
        'backhaulDevices': [
          _hallRefreshed,
          _backhaul('den', at: '2026-01-05T09:10:00Z'),
          _backhaul('attic', at: '2026-01-05T09:10:00Z'),
        ],
      });

      await notifier().startAutoOnboarding(context);

      expect(page().anyOnboarded, isTrue);
      expect(page().loadingMessage, '2 child nodes have just come online.');
    });

    testWidgets(
        'does not count a wired node already there whose backhaul was '
        'refreshed', (tester) async {
      await openApp(tester);

      await notifier().startAutoOnboarding(context);

      expect(page().anyOnboarded, isNull);
      expect(page().loadingMessage, 'Searching for nodes...');
    });

    testWidgets('lists the nodes once onboarding ends, and polls at once',
        (tester) async {
      await openApp(tester);

      await notifier().startAutoOnboarding(context);

      expect(page().nodes?.map((node) => node.deviceID), ['master', 'hall']);
      expect(polling.forced, 1);
    });

    testWidgets('ends without the nodes when the router cannot list them',
        (tester) async {
      await openApp(tester);
      router.refuses(JNAPAction.getDevices);

      await notifier().startAutoOnboarding(context);

      expect(page().nodes, isEmpty);
      expect(polling.forced, 1);
      expect(idleCheckerPaused.last, isFalse);
    });
  });

  group('forceStopAutoOnboarding', () {
    testWidgets('ends the backhaul watch at its next read', (tester) async {
      await openApp(tester);
      router.honorsPollDelays = true;

      final run = notifier().startAutoOnboarding(context);
      // The first read comes a second in, the next ten seconds after it.
      await tester.pump(const Duration(seconds: 1));
      await notifier().forceStopAutoOnboarding();
      expect(page().forceStop, isTrue);
      await tester.pump(const Duration(seconds: 10));
      await run;

      expect(router.payloadsOf(JNAPAction.getBackhaulInfo), hasLength(2));
      expect(router.payloadsOf(JNAPAction.setWiredAutoOnboardingSettings).last,
          {'isAutoOnboardingEnabled': false});
      expect(page().isLoading, isFalse);
      expect(page().forceStop, isFalse);
    });

    test('does nothing when no onboarding runs', () async {
      await notifier().forceStopAutoOnboarding();

      expect(page().forceStop, isFalse);
    });
  });
}
