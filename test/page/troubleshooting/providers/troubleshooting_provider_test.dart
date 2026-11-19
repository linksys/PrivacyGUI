import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/troubleshooting/models/device_status.dart';
import 'package:privacy_gui/page/troubleshooting/models/dhcp_client.dart';
import 'package:privacy_gui/page/troubleshooting/providers/troubleshooting_provider.dart';
import 'package:privacy_gui/page/troubleshooting/providers/troubleshooting_state.dart';

import '../../../common/router_boundary.dart';

/// One device of `GetDevices` output.
Map<String, dynamic> _device(
  String id, {
  required String mac,
  String? nodeType,
  bool isAuthority = false,
  String? ip,
  String? ipv6,
  String? name,
  String interfaceType = 'Wired',
  bool online = true,
}) =>
    {
      'connections': [
        if (online) {'macAddress': mac, 'ipAddress': ip, 'ipv6Address': ipv6},
      ],
      'properties': [
        if (name != null) {'name': 'userDeviceName', 'value': name},
      ],
      'unit': <String, dynamic>{},
      'deviceID': id,
      'maxAllowedProperties': 16,
      'model': {'deviceType': nodeType == null ? 'Computer' : 'Infrastructure'},
      'isAuthority': isAuthority,
      'lastChangeRevision': 1,
      'knownInterfaces': [
        {'macAddress': mac, 'interfaceType': interfaceType},
      ],
      if (nodeType != null) 'nodeType': nodeType,
    };

const _laptopMac = 'AA:BB:CC:00:00:01';
const _phoneMac = 'AA:BB:CC:00:00:02';

final _devices = {
  'devices': [
    _device('master',
        mac: '80:69:1A:00:00:01',
        nodeType: 'Master',
        isAuthority: true,
        ip: '192.168.1.1',
        name: 'Router'),
    _device('office',
        mac: '80:69:1A:00:00:02',
        nodeType: 'Slave',
        ip: '192.168.1.2',
        name: 'Office'),
    _device('laptop',
        mac: _laptopMac,
        ip: '192.168.1.50',
        ipv6: 'fe80::50',
        name: 'Laptop',
        interfaceType: 'Wireless'),
    _device('phone', mac: _phoneMac, name: 'Phone', online: false),
  ],
};

Map<String, dynamic> _lease(String mac, String ip,
        {String? hostName, String expiration = '2026-11-18T13:00:00Z'}) =>
    {
      'macAddress': mac,
      'ipAddress': ip,
      'expiration': expiration,
      if (hostName != null) 'hostName': hostName,
      'clientID': mac,
    };

void main() {
  late RouterBoundary router;
  late ProviderContainer container;

  TroubleshootingNotifier notifier() =>
      container.read(troubleshootingProvider.notifier);
  TroubleshootingState page() => container.read(troubleshootingProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getDevices, _devices)
      ..holds(JNAPAction.getDHCPClientLeases, {
        'leases': [
          _lease(_laptopMac, '192.168.1.50'),
          _lease(_phoneMac, '192.168.1.60', hostName: 'phone-host'),
          // Nothing the router knows of holds this one.
          _lease('AA:BB:CC:00:00:99', '192.168.1.99'),
        ],
      })
      ..holds(JNAPAction.getBackhaulInfo, {'backhaulDevices': <Object>[]})
      ..holds(JNAPAction.getNodesWirelessNetworkConnections,
          {'nodeWirelessConnections': <Object>[]})
      ..holds(
          JNAPAction.getTimeSettings, {'currentTime': '2026-11-18T12:00:00Z'})
      ..holds(JNAPAction.sendSysinfoEmail, const {});
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('reads the router in one transaction', () async {
      await notifier().fetch(force: true);

      expect(router.transactions.single.map((command) => command.key), [
        JNAPAction.getDevices,
        JNAPAction.getDHCPClientLeases,
        JNAPAction.getBackhaulInfo,
        JNAPAction.getNodesWirelessNetworkConnections,
        JNAPAction.getTimeSettings,
      ]);
    });

    test('lists each online node and client by every address it has', () async {
      await notifier().fetch();

      expect(page().deviceStatusList, const [
        DeviceStatusModel(
          name: 'Office',
          mac: '80:69:1A:00:00:02',
          ipAddress: '192.168.1.2',
          connection: 'LAN',
          type: DeviceStatusType.ipv4,
        ),
        DeviceStatusModel(
          name: 'Laptop',
          mac: _laptopMac,
          ipAddress: '192.168.1.50',
          connection: 'Wireless',
          type: DeviceStatusType.ipv4,
        ),
        DeviceStatusModel(
          name: 'Laptop',
          mac: _laptopMac,
          ipAddress: 'fe80::50',
          connection: 'Wireless',
          type: DeviceStatusType.ipv6,
        ),
      ]);
    });

    test('lists the DHCP clients the router knows, sorted by interface',
        () async {
      await notifier().fetch();

      expect(page().dhcpClientList, const [
        DhcpClientModel(
          name: 'phone-host',
          mac: _phoneMac,
          interface: 'Offline',
          ipAddress: '192.168.1.60',
          expires: '01:00:00',
        ),
        DhcpClientModel(
          name: 'Laptop',
          mac: _laptopMac,
          interface: 'Wireless',
          ipAddress: '192.168.1.50',
          expires: '01:00:00',
        ),
      ]);
    });

    test('reports a read the router refuses', () async {
      router.failsTransactions(const JNAPError(result: 'ErrorUnknown'));

      await expectLater(notifier().fetch(), throwsA(isA<JNAPError>()));
      expect(page().deviceStatusList, isEmpty);
    });
  });

  group('sendRouterInfo', () {
    test('sends the router report to support and to every address given',
        () async {
      await notifier().sendRouterInfo(userEmailList: 'a@x.com, b@x.com');

      // A debug build, as tests run in, reports to the internal address.
      expect(router.payloadsOf(JNAPAction.sendSysinfoEmail).single, {
        'addressList': [
          'routerinfo-internal@integrationtests.linksys.com',
          'a@x.com',
          'b@x.com',
        ],
      });
    });

    test('sends it to support alone when no address is given', () async {
      await notifier().sendRouterInfo(userEmailList: '');

      expect(
          router.payloadsOf(JNAPAction.sendSysinfoEmail).single['addressList'],
          ['routerinfo-internal@integrationtests.linksys.com']);
    });

    test('sends it to a single address given', () async {
      await notifier().sendRouterInfo(userEmailList: ' a@x.com ');

      expect(
          router.payloadsOf(JNAPAction.sendSysinfoEmail).single['addressList'],
          ['routerinfo-internal@integrationtests.linksys.com', 'a@x.com']);
    });

    test('reports a report the router refuses', () async {
      router.refuses(JNAPAction.sendSysinfoEmail);

      await expectLater(notifier().sendRouterInfo(userEmailList: ''),
          throwsA(isA<JNAPError>()));
    });
  });

  group('ping', () {
    test('starts a ping of the host with 32-byte packets', () async {
      router.holds(JNAPAction.startPing, const {});

      await notifier().ping(host: 'linksys.com', pingCount: 4);

      expect(router.payloadsOf(JNAPAction.startPing).single,
          {'host': 'linksys.com', 'packetSizeBytes': 32, 'pingCount': 4});
    });

    test('leaves the count to the router when none is given', () async {
      router.holds(JNAPAction.startPing, const {});

      await notifier().ping(host: 'linksys.com', pingCount: null);

      expect(router.payloadsOf(JNAPAction.startPing).single,
          {'host': 'linksys.com', 'packetSizeBytes': 32});
    });

    test('reports a ping the router refuses', () async {
      router.refuses(JNAPAction.startPing);

      await expectLater(
          notifier().ping(host: 'x', pingCount: 1), throwsA(isA<JNAPError>()));
    });

    test('follows the ping until it stops running', () async {
      router.holdsInTurn(JNAPAction.getPingStatus, [
        {'isRunning': true, 'pingLog': 'PING linksys.com'},
        {'isRunning': true, 'pingLog': 'PING linksys.com\n64 bytes'},
        {'isRunning': false, 'pingLog': 'PING linksys.com\n64 bytes\ndone'},
      ]);

      final statuses = await notifier().getPingStatus().toList();

      expect(statuses.map((status) => status.isRunning), [true, true, false]);
      expect(statuses.last.pingLog, endsWith('done'));
    });

    test('passes on a status it cannot read, and keeps following', () async {
      router.holdsInTurn(JNAPAction.getPingStatus, [
        {'isRunning': true, 'pingLog': ''},
        const JNAPError(result: 'ErrorUnknown'),
        {'isRunning': false, 'pingLog': 'done'},
      ]);

      await expectLater(
        notifier().getPingStatus(),
        emitsInOrder([
          isA<PingStatus>(),
          emitsError(isA<JNAPError>()),
          predicate<PingStatus>((status) => !status.isRunning),
          emitsDone,
        ]),
      );
    });
  });

  group('factoryReset', () {
    test('asks the router to reset itself', () async {
      router.holds(JNAPAction.factoryReset, const {});

      await notifier().factoryReset();

      expect(router.actions, [JNAPAction.factoryReset]);
    });

    test('reports a reset the router refuses', () async {
      router.refuses(JNAPAction.factoryReset);

      await expectLater(notifier().factoryReset(), throwsA(isA<JNAPError>()));
    });
  });
}
