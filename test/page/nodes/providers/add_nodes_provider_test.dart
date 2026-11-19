import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_exception.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';

/// One node of `GetDevices` output.
Map<String, dynamic> _node(String id,
        {required String mac, String nodeType = 'Slave', bool online = true}) =>
    {
      'connections': [
        if (online) {'macAddress': mac, 'ipAddress': '192.168.1.${id.length}'},
      ],
      'properties': [
        {'name': 'userDeviceLocation', 'value': id},
      ],
      'unit': <String, dynamic>{},
      'deviceID': id,
      'maxAllowedProperties': 16,
      'model': {'deviceType': 'Infrastructure', 'modelNumber': 'MX6200'},
      'isAuthority': nodeType == 'Master',
      'lastChangeRevision': 1,
      'knownInterfaces': [
        {'macAddress': mac, 'interfaceType': 'Wireless'},
      ],
      'nodeType': nodeType,
    };

/// The Bluetooth MAC the new node answered with while it was onboarded.
const _newNodeMac = 'BT:00:00:00:00:01';

/// The network once the new node, named "den", has joined the master and
/// the node already there, "hall". The router lists the master last.
final _withDen = {
  'devices': [
    _node('hall', mac: 'AA:00:00:00:00:02'),
    _node('den', mac: _newNodeMac),
    _node('master', mac: 'AA:00:00:00:00:01', nodeType: 'Master'),
  ],
};

/// One entry of `GetBackhaulInfo` output, for a node on 5 GHz.
Map<String, dynamic> _backhaulOf(String id) => {
      'deviceUUID': id,
      'ipAddress': '192.168.1.${id.length}',
      'parentIPAddress': '192.168.1.1',
      'connectionType': 'Wireless',
      'wirelessConnectionInfo': {'radioID': '5GH', 'channel': 149},
      'speedMbps': '866',
      'timestamp': '2026-11-18T12:00:00Z',
    };

/// The backhaul once every node, the new one included, reports one.
final _everyBackhaul = {
  'backhaulDevices': [_backhaulOf('hall'), _backhaulOf('den')],
};

Map<String, dynamic> _onboardingStatus(String status,
        {List<Map<String, dynamic>> devices = const []}) =>
    {'autoOnboardingStatus': status, 'deviceOnboardingStatus': devices};

const _denOnboarded = [
  {'btMACAddress': _newNodeMac, 'onboardingStatus': 'Onboarded'},
];

void main() {
  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;

  AddNodesNotifier notifier() => container.read(addNodesProvider.notifier);
  AddNodesState page() => container.read(addNodesProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.startBlueboothAutoOnboarding, const {})
      ..holds(JNAPAction.getBluetoothAutoOnboardingSettings,
          {'isAutoOnboardingEnabled': true})
      ..holdsInTurn(JNAPAction.getBluetoothAutoOnboardingStatus, [
        _onboardingStatus('Onboarding', devices: _denOnboarded),
        _onboardingStatus('Complete', devices: _denOnboarded),
      ])
      ..holds(JNAPAction.getDevices, _withDen)
      ..holds(JNAPAction.getBackhaulInfo, _everyBackhaul);
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
    // The provider disposes itself once nothing listens.
    container.listen(addNodesProvider, (_, __) {});
  });

  tearDown(() => container.dispose());

  test('reads whether auto-onboarding is on', () async {
    expect(await notifier().getAutoOnboardingSettings(), isTrue);

    router.holds(JNAPAction.getBluetoothAutoOnboardingSettings, const {});
    expect(await notifier().getAutoOnboardingSettings(), isFalse);
  });

  group('startAutoOnboarding', () {
    testWidgets('adds the node that onboarded, with its backhaul',
        (tester) async {
      await notifier().startAutoOnboarding();

      expect(page().onboardingProceed, isTrue);
      expect(page().anyOnboarded, isTrue);
      expect(page().onboardedMACList, [_newNodeMac]);
      expect(page().addedNodes?.map((node) => node.deviceID), ['den']);
      final children = page().childNodes!;
      expect(children.first.deviceID, 'master');
      expect(children.map((node) => node.deviceID).toSet(),
          {'master', 'hall', 'den'});
      final den = children.firstWhere((node) => node.deviceID == 'den');
      expect(den.connectionType, 'Wireless');
      expect(den.wirelessConnectionInfo?.channel, 149);
      // Every node reported its backhaul at the first read.
      expect(router.payloadsOf(JNAPAction.getBackhaulInfo), hasLength(1));
      expect(page().isLoading, isFalse);
    });

    testWidgets('reads the backhaul until every node reports one',
        (tester) async {
      router.holdsInTurn(JNAPAction.getBackhaulInfo, [
        {
          'backhaulDevices': [_backhaulOf('den')],
        },
        _everyBackhaul,
      ]);

      await notifier().startAutoOnboarding();

      expect(router.payloadsOf(JNAPAction.getBackhaulInfo), hasLength(2));
      expect(
          page()
              .childNodes
              ?.firstWhere((node) => node.deviceID == 'hall')
              .connectionType,
          'Wireless');
    });

    testWidgets('holds polling for the whole run and polls once at the end',
        (tester) async {
      await notifier().startAutoOnboarding();

      expect(polling.stopped, 1);
      expect(polling.forced, 1);
      expect(polling.started, 1);
      expect(router.polls, [
        JNAPAction.getBluetoothAutoOnboardingStatus,
        JNAPAction.getDevices,
        JNAPAction.getBackhaulInfo,
      ]);
    });

    testWidgets('adds nothing when no node was found', (tester) async {
      router.holdsInTurn(JNAPAction.getBluetoothAutoOnboardingStatus,
          [_onboardingStatus('Idle')]);

      await notifier().startAutoOnboarding();

      expect(page().onboardingProceed, isFalse);
      expect(page().anyOnboarded, isFalse);
      expect(page().addedNodes, isEmpty);
      expect(router.polls, [JNAPAction.getBluetoothAutoOnboardingStatus]);
      expect(polling.started, 1);
    });

    testWidgets('adds nothing when the node it found failed to onboard',
        (tester) async {
      router.holdsInTurn(JNAPAction.getBluetoothAutoOnboardingStatus, [
        _onboardingStatus('Onboarding', devices: [
          {'btMACAddress': _newNodeMac, 'onboardingStatus': 'Failed'},
        ]),
        _onboardingStatus('Complete', devices: [
          {'btMACAddress': _newNodeMac, 'onboardingStatus': 'Failed'},
        ]),
      ]);

      await notifier().startAutoOnboarding();

      expect(page().onboardingProceed, isTrue);
      expect(page().anyOnboarded, isFalse);
      expect(page().onboardedMACList, isEmpty);
      expect(router.polls, [JNAPAction.getBluetoothAutoOnboardingStatus]);
    });

    testWidgets('looks for the new node until it is online', (tester) async {
      router.holdsInTurn(JNAPAction.getDevices, [
        {
          'devices': [
            _node('master', mac: 'AA:00:00:00:00:01', nodeType: 'Master'),
            _node('hall', mac: 'AA:00:00:00:00:02'),
            _node('den', mac: _newNodeMac, online: false),
          ],
        },
        _withDen,
      ]);

      await notifier().startAutoOnboarding();

      expect(router.payloadsOf(JNAPAction.getDevices), hasLength(2));
      expect(page().addedNodes?.single.isOnline(), isTrue);
    });

    testWidgets('waits for the router to get SmartConnect ready',
        (tester) async {
      router.holdsInTurn(JNAPAction.startBlueboothAutoOnboarding, [
        const JNAPError(result: 'ErrorSmartConnectNotReady'),
        const <String, dynamic>{},
      ]);

      final run = notifier().startAutoOnboarding();
      await tester.pump(const Duration(seconds: 3));
      await run;

      expect(router.payloadsOf(JNAPAction.startBlueboothAutoOnboarding),
          hasLength(2));
      expect(page().anyOnboarded, isTrue);
    });

    testWidgets('gives up on SmartConnect after twenty tries', (tester) async {
      router.refuses(JNAPAction.startBlueboothAutoOnboarding,
          result: 'ErrorSmartConnectNotReady');

      Object? failure;
      final run = notifier()
          .startAutoOnboarding()
          .catchError((Object error) => failure = error);
      await tester.pump(const Duration(seconds: 60));
      await run;

      expect(failure, isA<ExceptionSmartConnectTimeout>());
      expect(router.payloadsOf(JNAPAction.startBlueboothAutoOnboarding),
          hasLength(20));
      expect(polling.started, 1);
      expect(page().isLoading, isFalse);
    });

    testWidgets('reports another refusal at once, and restarts polling',
        (tester) async {
      router.refuses(JNAPAction.startBlueboothAutoOnboarding);

      await expectLater(
          notifier().startAutoOnboarding(), throwsA(isA<JNAPError>()));

      expect(router.payloadsOf(JNAPAction.startBlueboothAutoOnboarding),
          hasLength(1));
      expect(polling.started, 1);
      expect(page().isLoading, isFalse);
    });
  });

  group('startRefresh', () {
    testWidgets('reads the nodes and their backhaul again', (tester) async {
      await notifier().startAutoOnboarding();
      router.holds(JNAPAction.getBackhaulInfo, {
        'backhaulDevices': [
          _backhaulOf('hall'),
          {
            ..._backhaulOf('den'),
            'connectionType': 'Wired',
            'wirelessConnectionInfo': null,
          },
        ],
      });

      await notifier().startRefresh();

      expect(page().childNodes?.first.deviceID, 'master');
      expect(
          page()
              .childNodes
              ?.firstWhere((node) => node.deviceID == 'den')
              .connectionType,
          'Wired');
      expect(page().isLoading, isFalse);
      expect(page().loadingMessage, '');
    });
  });
}
