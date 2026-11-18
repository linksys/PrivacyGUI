import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/page/instant_topology/views/model/tree_view_node.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/router_boundary.dart';

LinksysDevice _device(
  String id, {
  String? nodeType,
  bool isAuthority = false,
  LinksysDevice? upstream,
  bool online = true,
  String interfaceType = 'Wired',
}) =>
    LinksysDevice(
      connections: [
        if (online)
          RawDeviceConnection(
              macAddress: 'mac-$id', ipAddress: '192.168.1.${id.length}'),
      ],
      properties: [RawDeviceProperty(name: 'userDeviceLocation', value: id)],
      unit: RawDeviceUnit(serialNumber: 'SN-$id', firmwareVersion: '1.0.$id'),
      deviceID: id,
      maxAllowedProperties: 16,
      model: RawDeviceModel(
        deviceType: nodeType == null ? 'Computer' : 'Infrastructure',
        modelNumber: nodeType == null ? null : 'MX6200',
      ),
      isAuthority: isAuthority,
      lastChangeRevision: 1,
      nodeType: nodeType,
      upstream: upstream,
      knownInterfaces: [
        RawDeviceKnownInterface(
            macAddress: 'mac-$id', interfaceType: interfaceType),
      ],
    );

// A mesh: the master, a node under it, a node under that one, an offline
// node, and a laptop on the first node.
final _master = _device('master', nodeType: 'Master', isAuthority: true);
final _hall = _device('hall', nodeType: 'Slave', upstream: _master);
final _attic = _device('attic', nodeType: 'Slave', upstream: _hall);
final _garage = _device('garage', nodeType: 'Slave', online: false);
final _laptop = _device('laptop', upstream: _hall, interfaceType: 'Wireless');
final _mesh = [_master, _hall, _attic, _garage, _laptop];

class _DeviceManagerStub extends DeviceManagerNotifier {
  _DeviceManagerStub(this.devices);

  final List<LinksysDevice> devices;

  @override
  DeviceManagerState build() => DeviceManagerState(deviceList: devices);
}

class _FirmwareUpdateStub extends FirmwareUpdateNotifier {
  _FirmwareUpdateStub(this.statuses);

  final List<FirmwareUpdateStatus> statuses;

  @override
  FirmwareUpdateState build() =>
      FirmwareUpdateState.empty().copyWith(nodesStatus: statuses);
}

/// One line per node, indented by depth, offline nodes marked.
List<String> _outline(AppTreeNode<TopologyModel> node, [int depth = 0]) => [
      '${'  ' * depth}${node.data.location}${node.tag == 'offline' ? ' (offline)' : ''}',
      for (final child in node.children) ..._outline(child, depth + 1),
    ];

/// `GetDevices` output with [online] among the nodes still connected.
Map<String, dynamic> _devicesOnline(List<String> online) => {
      'devices': [
        for (final id in ['master', 'hall', 'attic'])
          _device(id,
                  nodeType: id == 'master' ? 'Master' : 'Slave',
                  online: online.contains(id))
              .toMap(),
      ],
    };

void main() {
  late RouterBoundary router;
  late ProviderContainer container;

  ProviderContainer start({
    List<LinksysDevice>? devices,
    List<FirmwareUpdateStatus> firmware = const [],
  }) {
    router = RouterBoundary();
    for (final action in [
      JNAPAction.reboot,
      JNAPAction.reboot2,
      JNAPAction.factoryReset,
      JNAPAction.factoryReset2,
      JNAPAction.startBlinkNodeLed,
      JNAPAction.stopBlinkNodeLed,
    ]) {
      router.holds(action, const {});
    }
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      deviceManagerProvider
          .overrideWith(() => _DeviceManagerStub(devices ?? _mesh)),
      firmwareUpdateProvider.overrideWith(() => _FirmwareUpdateStub(firmware)),
    ]);
    return container;
  }

  InstantTopologyNotifier notifier() =>
      container.read(instantTopologyProvider.notifier);
  AppTreeNode<TopologyModel> tree() =>
      container.read(instantTopologyProvider).root;
  TopologyModel nodeOf(String id) =>
      tree().toFlatList().firstWhere((node) => node.data.deviceId == id).data;

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => container.dispose());

  group('the topology', () {
    test('hangs each node under its upstream, offline nodes under the master',
        () {
      start();

      expect(_outline(tree()), [
        'Internet',
        '  master',
        '    hall',
        '      attic',
        '    garage (offline)',
      ]);
    });

    test('shows a client only while it is the one selected', () {
      start();
      container.read(topologySelectedIdProvider.notifier).state = 'laptop';

      expect(_outline(tree()), [
        'Internet',
        '  master',
        '    hall',
        '      attic',
        '      laptop',
        '    garage (offline)',
      ]);
      final laptop = nodeOf('laptop');
      expect(laptop.isRouter, isFalse);
      expect(laptop.isWiredConnection, isFalse);
    });

    test('puts a node whose upstream is unknown under the master', () {
      final stray = _device('stray',
          nodeType: 'Slave', upstream: _device('gone', nodeType: 'Slave'));
      start(devices: [_master, stray]);

      expect(_outline(tree()), ['Internet', '  master', '    stray']);
    });

    test('is only the internet before any device is known', () {
      start(devices: const []);

      expect(_outline(tree()), ['Internet']);
    });

    test('describes each node from what the router reports of it', () {
      start();

      final hall = nodeOf('hall');
      expect(hall.isMaster, isFalse);
      expect(hall.isRouter, isTrue);
      expect(hall.isOnline, isTrue);
      expect(hall.serialNumber, 'SN-hall');
      expect(hall.fwVersion, '1.0.hall');
      expect(hall.model, 'MX6200');
      expect(hall.macAddress, 'mac-hall');
      expect(tree().children.single.data.isMaster, isTrue);
    });

    test('marks the nodes that have a firmware update waiting', () {
      NodesFirmwareUpdateStatus status(String id, {bool update = false}) =>
          NodesFirmwareUpdateStatus.fromMap({
            'deviceUUID': id,
            'lastSuccessfulCheckTime': '2026-11-18T00:00:00Z',
            if (update)
              'availableUpdate': {
                'firmwareVersion': '1.3.2',
                'firmwareDate': '2026-11-01T00:00:00Z',
              },
          });
      start(firmware: [
        status('master'),
        status('hall', update: true),
        status('attic'),
      ]);

      final upToDate = {
        for (final node in tree().toFlatList().skip(1))
          node.data.deviceId: node.data.fwUpToDate,
      };
      expect(upToDate['master'], isTrue);
      expect(upToDate['hall'], isFalse);
      expect(upToDate['attic'], isTrue);
    });
  });

  group('reboot', () {
    setUp(() => start());

    test('reboots the master alone with one command', () async {
      await notifier().reboot();

      expect(router.actions, [JNAPAction.reboot]);
    });

    test('reboots nodes from the bottom up, then waits for them to go',
        () async {
      router.holdsInTurn(JNAPAction.getDevices, [
        _devicesOnline(['master', 'hall']),
        _devicesOnline(['master']),
      ]);

      await notifier().reboot(['hall', 'attic']);

      expect(
          router.transactions.single
              .map((command) => [command.key, command.value]),
          [
            [
              JNAPAction.reboot2,
              {'deviceUUID': 'attic'}
            ],
            [
              JNAPAction.reboot2,
              {'deviceUUID': 'hall'}
            ],
          ]);
      expect(router.payloadsOf(JNAPAction.getDevices), hasLength(2));
    });

    test('stops waiting after twenty checks', () async {
      router.holds(JNAPAction.getDevices, _devicesOnline(['master', 'hall']));

      await notifier().reboot(['hall']);

      expect(router.payloadsOf(JNAPAction.getDevices), hasLength(20));
    });

    test('reports a reboot the router refuses, and waits for nothing',
        () async {
      router.failsTransactions(const JNAPError(result: 'ErrorUnknown'));

      await expectLater(notifier().reboot(['hall']), throwsA(isA<JNAPError>()));
      expect(router.polls, isEmpty);
    });
  });

  group('factoryReset', () {
    setUp(() => start());

    test('resets the master alone with one command', () async {
      await notifier().factoryReset(const []);

      expect(router.actions, [JNAPAction.factoryReset]);
    });

    test('resets nodes from the bottom up, then waits for them to go',
        () async {
      router.holds(JNAPAction.getDevices, _devicesOnline(['master']));

      await notifier().factoryReset(['hall', 'attic']);

      expect(router.transactions.single.map((command) => command.value), [
        {'deviceUUID': 'attic'},
        {'deviceUUID': 'hall'},
      ]);
      expect(router.transactions.single.first.key, JNAPAction.factoryReset2);
      expect(router.polls, [JNAPAction.getDevices]);
    });

    test('reports a reset the router refuses', () async {
      router.refuses(JNAPAction.factoryReset);

      await expectLater(
          notifier().factoryReset(const []), throwsA(isA<JNAPError>()));
    });
  });

  group('blinking a node', () {
    setUp(() => start());

    test('starts and stops the light of a node', () async {
      await notifier().startBlinkNodeLED('hall');
      await notifier().stopBlinkNodeLED();

      expect(router.payloadsOf(JNAPAction.startBlinkNodeLed).single,
          {'deviceID': 'hall'});
      expect(router.actions.last, JNAPAction.stopBlinkNodeLed);
    });

    test('reports a light the router will not start or stop', () async {
      router
        ..refuses(JNAPAction.startBlinkNodeLed)
        ..refuses(JNAPAction.stopBlinkNodeLed);

      await expectLater(
          notifier().startBlinkNodeLED('hall'), throwsA(isA<JNAPError>()));
      await expectLater(
          notifier().stopBlinkNodeLED(), throwsA(isA<JNAPError>()));
    });

    test('toggling a node blinks it and remembers it', () async {
      await notifier().toggleBlinkNode('hall');
      await pumpEventQueue();

      expect(router.actions, [JNAPAction.startBlinkNodeLed]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pBlinkingNodeId), 'hall');
    });

    test('toggling another node stops the one blinking first', () async {
      SharedPreferences.setMockInitialValues({pBlinkingNodeId: 'hall'});

      await notifier().toggleBlinkNode('attic');
      await pumpEventQueue();

      expect(router.actions,
          [JNAPAction.stopBlinkNodeLed, JNAPAction.startBlinkNodeLed]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pBlinkingNodeId), 'attic');
    });

    test('toggling the node already blinking blinks it again', () async {
      SharedPreferences.setMockInitialValues({pBlinkingNodeId: 'hall'});

      await notifier().toggleBlinkNode('hall');
      await pumpEventQueue();

      expect(router.actions, [JNAPAction.startBlinkNodeLed]);
    });
  });
}
