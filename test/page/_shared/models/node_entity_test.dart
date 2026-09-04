import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';

import '../../../mocks/test_data/devices_test_data.dart';

void main() {
  // ===========================================================================
  // MasterNode
  // ===========================================================================

  group('MasterNode', () {
    group('isMaster', () {
      test('returns true', () {
        final master = DevicesTestData.createMaster();
        expect(master.isMaster, isTrue);
      });
    });

    group('roleLabel', () {
      test('returns Master', () {
        final master = DevicesTestData.createMaster();
        expect(master.roleLabel, 'Master');
      });
    });

    group('displayName', () {
      test('returns friendlyName when set', () {
        final node = DevicesTestData.createMaster(
          friendlyName: 'My Router',
          hostName: 'Linksys-Router',
          model: 'MR7500',
          deviceId: DevicesTestData.masterMac,
        );

        expect(node.displayName, 'My Router');
      });

      test('returns hostName when friendlyName is null', () {
        final node = DevicesTestData.createMaster(
          friendlyName: null,
          hostName: 'Linksys-Router',
          model: 'MR7500',
        );

        expect(node.displayName, 'Linksys-Router');
      });

      test('returns hostName when friendlyName is empty', () {
        final node = MasterNode(
          deviceId: DevicesTestData.masterMac,
          friendlyName: '',
          hostName: 'Linksys-Router',
          model: 'MR7500',
        );

        expect(node.displayName, 'Linksys-Router');
      });

      test('returns model when friendlyName and hostName are null/empty', () {
        final node = MasterNode(
          deviceId: DevicesTestData.masterMac,
          friendlyName: null,
          hostName: null,
          model: 'MR7500',
        );

        expect(node.displayName, 'MR7500');
      });

      test('returns deviceId when all others are null/empty', () {
        final node = MasterNode(
          deviceId: DevicesTestData.masterMac,
          friendlyName: null,
          hostName: null,
          model: '',
        );

        expect(node.displayName, DevicesTestData.masterMac);
      });
    });

    group('NetworkEntity implementation', () {
      test('id returns deviceId', () {
        final node = DevicesTestData.createMaster(
          deviceId: DevicesTestData.masterMac,
        );

        expect(node.id, DevicesTestData.masterMac);
      });

      test('isOnline is always true (master stays online unconditionally)', () {
        // The master is the data source itself; per #1430 AC1 its liveness is
        // not gated on a DataElements agent match.
        final node = DevicesTestData.createMaster(); // dataElementsId null
        expect(node.isOnline, isTrue);
      });
    });

    group('connectedDeviceCount', () {
      test('returns number of connected clients', () {
        final node = DevicesTestData.createMaster(
          connectedClients: [
            DevicesTestData.createWifiClient(),
            DevicesTestData.createWiredClient(),
          ],
        );

        expect(node.connectedDeviceCount, 2);
      });

      test('returns 0 when no clients', () {
        final node = DevicesTestData.createMaster(connectedClients: []);
        expect(node.connectedDeviceCount, 0);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final original = DevicesTestData.createMaster();
        final copied = original.copyWith();

        expect(copied.deviceId, original.deviceId);
        expect(copied.model, original.model);
        expect(copied.manufacturer, original.manufacturer);
      });

      test('updates specified fields', () {
        final original = DevicesTestData.createMaster();
        final copied = original.copyWith(
          friendlyName: 'New Name',
          model: 'MR8000',
        );

        expect(copied.friendlyName, 'New Name');
        expect(copied.model, 'MR8000');
        expect(copied.deviceId, original.deviceId);
      });

      test('carries hostsDeviceId (UUID) through construction and equality',
          () {
        final withUuid =
            DevicesTestData.createMaster(hostsDeviceId: 'uuid-1234');
        expect(withUuid.hostsDeviceId, 'uuid-1234');

        final sameUuid =
            DevicesTestData.createMaster(hostsDeviceId: 'uuid-1234');
        final otherUuid =
            DevicesTestData.createMaster(hostsDeviceId: 'uuid-9999');

        // hostsDeviceId participates in Equatable props.
        expect(withUuid, equals(sameUuid));
        expect(withUuid, isNot(equals(otherUuid)));
      });

      test('cannot clear a nullable field (merges with `?? this`)', () {
        // Pins the documented limitation: because every parameter is applied
        // as `param ?? this.param`, passing null keeps the old value, so
        // `copyWith(dataElementsId: null)` is indistinguishable from
        // `copyWith()`. To clear a field, construct a new node directly.
        final original =
            DevicesTestData.createMaster(dataElementsId: 'DE-master');

        expect(
            original.copyWith(dataElementsId: null).dataElementsId, 'DE-master',
            reason: 'passing null keeps the old value');
        expect(original.copyWith().dataElementsId, 'DE-master');
        // The only way to clear it is a fresh construction.
        expect(
          MasterNode(deviceId: original.deviceId, model: original.model)
              .dataElementsId,
          isNull,
        );
      });
    });
  });

  // ===========================================================================
  // SlaveNode
  // ===========================================================================

  group('SlaveNode', () {
    group('isMaster', () {
      test('returns false', () {
        final slave = DevicesTestData.createWifiSlave();
        expect(slave.isMaster, isFalse);
      });
    });

    group('roleLabel', () {
      test('returns Slave', () {
        final slave = DevicesTestData.createWifiSlave();
        expect(slave.roleLabel, 'Slave');
      });
    });

    group('displayName', () {
      test('follows same priority as MasterNode', () {
        final withFriendly = DevicesTestData.createWifiSlave(
          friendlyName: 'Living Room Extender',
          hostName: 'Extender-1',
        );
        final withHost = DevicesTestData.createWifiSlave(
          friendlyName: null,
          hostName: 'Extender-1',
        );

        expect(withFriendly.displayName, 'Living Room Extender');
        expect(withHost.displayName, 'Extender-1');
      });
    });

    group('backhaul properties', () {
      test('isEthernetBackhaul returns true for Ethernet backhaul', () {
        final ethernetSlave = DevicesTestData.createEthernetSlave();
        final wifiSlave = DevicesTestData.createWifiSlave();

        expect(ethernetSlave.isEthernetBackhaul, isTrue);
        expect(wifiSlave.isEthernetBackhaul, isFalse);
      });

      test('hasBackhaul returns true when backhaul has info', () {
        final withBackhaul = DevicesTestData.createWifiSlave();
        final noBackhaul = SlaveNode(
          deviceId: DevicesTestData.slaveMac1,
          model: 'MR7500',
          backhaul: DevicesTestData.emptyBackhaul,
        );

        expect(withBackhaul.hasBackhaul, isTrue);
        expect(noBackhaul.hasBackhaul, isFalse);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final original = DevicesTestData.createWifiSlave();
        final copied = original.copyWith();

        expect(copied.deviceId, original.deviceId);
        expect(copied.backhaul, original.backhaul);
      });

      test('updates backhaul', () {
        final original = DevicesTestData.createWifiSlave();
        final newBackhaul = DevicesTestData.createEthernetBackhaul();
        final copied = original.copyWith(backhaul: newBackhaul);

        expect(copied.isEthernetBackhaul, isTrue);
      });

      test('cannot clear a nullable field (merges with `?? this`)', () {
        // Pins the documented limitation, same as MasterNode: `param ?? this`
        // means passing null keeps the old value. To clear a field, construct
        // a new node directly.
        final original =
            DevicesTestData.createWifiSlave(dataElementsId: 'DE-slave');

        expect(
            original.copyWith(dataElementsId: null).dataElementsId, 'DE-slave',
            reason: 'passing null keeps the old value');
        expect(original.copyWith().dataElementsId, 'DE-slave');
        expect(
          SlaveNode(
            deviceId: original.deviceId,
            model: original.model,
            backhaul: original.backhaul,
          ).dataElementsId,
          isNull,
        );
      });
    });
  });

  // ===========================================================================
  // List<NodeEntity> Extensions
  // ===========================================================================

  group('List<NodeEntity> extensions', () {
    late List<NodeEntity> nodes;

    setUp(() {
      nodes = [
        DevicesTestData.createMaster(),
        DevicesTestData.createWifiSlave(deviceId: DevicesTestData.slaveMac1),
        DevicesTestData.createEthernetSlave(
            deviceId: DevicesTestData.slaveMac2),
      ];
    });

    test('master returns the MasterNode', () {
      final master = nodes.master;

      expect(master, isNotNull);
      expect(master, isA<MasterNode>());
    });

    test('master returns null when no MasterNode', () {
      final slavesOnly = <NodeEntity>[
        DevicesTestData.createWifiSlave(),
      ];

      expect(slavesOnly.master, isNull);
    });

    test('slaves returns only SlaveNodes', () {
      final slaves = nodes.slaves;

      expect(slaves, hasLength(2));
      expect(slaves.first.deviceId, DevicesTestData.slaveMac1);
      expect(slaves.last.deviceId, DevicesTestData.slaveMac2);
    });

    test('hasMesh returns true when slaves exist', () {
      expect(nodes.hasMesh, isTrue);
    });

    test('hasMesh returns false when no slaves', () {
      final masterOnly = <NodeEntity>[
        DevicesTestData.createMaster(),
      ];

      expect(masterOnly.hasMesh, isFalse);
    });
  });

  // ===========================================================================
  // BackhaulInfo
  // ===========================================================================

  group('BackhaulInfo', () {
    test('isEthernet returns true for Ethernet linkType', () {
      final ethernet = DevicesTestData.createEthernetBackhaul();
      final wifi = DevicesTestData.createWifiBackhaul();

      expect(ethernet.isEthernet, isTrue);
      expect(wifi.isEthernet, isFalse);
    });

    test('isWifi returns true for non-Ethernet linkType', () {
      final wifi = DevicesTestData.createWifiBackhaul();
      final ethernet = DevicesTestData.createEthernetBackhaul();

      expect(wifi.isWifi, isTrue);
      expect(ethernet.isWifi, isFalse);
    });

    test('hasInfo returns true when mediaType is not empty', () {
      final withInfo = DevicesTestData.createWifiBackhaul();
      const noInfo = BackhaulInfo(mediaType: '');

      expect(withInfo.hasInfo, isTrue);
      expect(noInfo.hasInfo, isFalse);
    });

    test('Equatable compares all fields', () {
      final backhaul1 = DevicesTestData.createWifiBackhaul(signalStrength: -55);
      final backhaul2 = DevicesTestData.createWifiBackhaul(signalStrength: -55);
      final backhaul3 = DevicesTestData.createWifiBackhaul(signalStrength: -70);

      expect(backhaul1, equals(backhaul2));
      expect(backhaul1, isNot(equals(backhaul3)));
    });
  });

  // ===========================================================================
  // Equatable
  // ===========================================================================

  group('NodeEntity Equatable', () {
    test('equal MasterNodes are equal', () {
      final node1 = DevicesTestData.createMaster(
        deviceId: DevicesTestData.masterMac,
        model: 'MR7500',
      );
      final node2 = DevicesTestData.createMaster(
        deviceId: DevicesTestData.masterMac,
        model: 'MR7500',
      );

      expect(node1, equals(node2));
    });

    test('different deviceId makes nodes not equal', () {
      final node1 = DevicesTestData.createMaster(deviceId: 'AA:AA:AA:AA:AA:01');
      final node2 = DevicesTestData.createMaster(deviceId: 'AA:AA:AA:AA:AA:02');

      expect(node1, isNot(equals(node2)));
    });

    test('equal SlaveNodes are equal', () {
      final node1 = DevicesTestData.createWifiSlave(
        deviceId: DevicesTestData.slaveMac1,
      );
      final node2 = DevicesTestData.createWifiSlave(
        deviceId: DevicesTestData.slaveMac1,
      );

      expect(node1, equals(node2));
    });

    test('different connectedClients makes nodes not equal', () {
      final node1 = DevicesTestData.createMaster(connectedClients: []);
      final node2 = DevicesTestData.createMaster(
        connectedClients: [DevicesTestData.createWifiClient()],
      );

      expect(node1, isNot(equals(node2)));
    });
  });
}
