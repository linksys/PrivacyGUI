import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // NodeUIModel — displayName priority
  // ---------------------------------------------------------------------------

  group('NodeUIModel — displayName', () {
    test('displayName prefers friendlyName when available', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: 'Living Room Router',
        hostName: 'linksys-router',
        model: 'MR7500',
        isMaster: true,
      );
      expect(node.displayName, 'Living Room Router');
    });

    test('displayName uses hostName when friendlyName is null', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: null,
        hostName: 'linksys-router',
        model: 'MR7500',
        isMaster: true,
      );
      expect(node.displayName, 'linksys-router');
    });

    test('displayName uses hostName when friendlyName is empty', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: '',
        hostName: 'linksys-router',
        model: 'MR7500',
        isMaster: true,
      );
      expect(node.displayName, 'linksys-router');
    });

    test('displayName uses model when friendlyName and hostName are empty', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: '',
        hostName: '',
        model: 'MR7500',
        isMaster: true,
      );
      expect(node.displayName, 'MR7500');
    });

    test('displayName uses model when friendlyName and hostName are null', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: null,
        hostName: null,
        model: 'MR7500',
        isMaster: true,
      );
      expect(node.displayName, 'MR7500');
    });

    test('displayName falls back to deviceId when all names are empty', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: '',
        hostName: '',
        model: '',
        isMaster: true,
      );
      expect(node.displayName, 'AA:BB:CC:DD:EE:01');
    });
  });

  // ---------------------------------------------------------------------------
  // NodeUIModel — roleLabel
  // ---------------------------------------------------------------------------

  group('NodeUIModel — roleLabel', () {
    test('roleLabel is Master for isMaster=true', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        model: 'MR7500',
        isMaster: true,
      );
      expect(node.roleLabel, 'Master');
    });

    test('roleLabel is Slave for isMaster=false', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
      );
      expect(node.roleLabel, 'Slave');
    });
  });

  // ---------------------------------------------------------------------------
  // NodeUIModel — hasBackhaul
  // ---------------------------------------------------------------------------

  group('NodeUIModel — hasBackhaul', () {
    test('hasBackhaul is true when backhaulMediaType is set', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02',
        model: 'MX5500',
        isMaster: false,
        backhaulMediaType: 'IEEE 802.11ax',
        backhaulPhyRate: 1200,
      );
      expect(node.hasBackhaul, isTrue);
    });

    test('hasBackhaul is false when backhaulMediaType is empty', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        model: 'MR7500',
        isMaster: true,
      );
      expect(node.hasBackhaul, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // NodeUIModel — Equatable
  // ---------------------------------------------------------------------------

  group('NodeUIModel — Equatable', () {
    test('equality based on all fields', () {
      const node1 = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: 'Router',
        hostName: 'linksys',
        model: 'MR7500',
        manufacturer: 'Linksys',
        serialNumber: 'SN123',
        softwareVersion: '2.0.0',
        isMaster: true,
        connectedDeviceCount: 5,
        backhaulMediaType: '',
        backhaulPhyRate: 0,
      );
      const node2 = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: 'Router',
        hostName: 'linksys',
        model: 'MR7500',
        manufacturer: 'Linksys',
        serialNumber: 'SN123',
        softwareVersion: '2.0.0',
        isMaster: true,
        connectedDeviceCount: 5,
        backhaulMediaType: '',
        backhaulPhyRate: 0,
      );
      const node3 = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:02', // Different deviceId
        friendlyName: 'Router',
        hostName: 'linksys',
        model: 'MR7500',
        manufacturer: 'Linksys',
        serialNumber: 'SN123',
        softwareVersion: '2.0.0',
        isMaster: true,
        connectedDeviceCount: 5,
      );

      expect(node1, equals(node2));
      expect(node1, isNot(equals(node3)));
    });

    test('props includes all fields', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        friendlyName: 'Router',
        hostName: 'linksys',
        model: 'MR7500',
        manufacturer: 'Linksys',
        serialNumber: 'SN123',
        softwareVersion: '2.0.0',
        isMaster: true,
        connectedDeviceCount: 5,
        ipAddress: '192.168.1.1',
        ipv6Addresses: ['fe80::1'],
        wanIpAddress: '203.0.113.1',
        backhaulMediaType: 'Ethernet',
        backhaulPhyRate: 1000,
        backhaulSignalStrength: -45,
        backhaulUplinkRate: 500000,
        backhaulLinkType: 'Wi-Fi',
        backhaulDownlinkRate: 600000,
      );

      // 25 props total: base fields + network addresses + DataElements enrichment
      expect(node.props, hasLength(25));
      expect(node.props, contains('AA:BB:CC:DD:EE:01'));
      expect(node.props, contains('Router'));
      expect(node.props, contains('linksys'));
      expect(node.props, contains('MR7500'));
      expect(node.props, contains('Linksys'));
      expect(node.props, contains('SN123'));
      expect(node.props, contains('2.0.0'));
      expect(node.props, contains(true));
      expect(node.props, contains(5));
      expect(node.props, contains('192.168.1.1'));
      // List uses reference equality, so check by finding the list element
      expect(node.props.any((p) => p is List && p.contains('fe80::1')), isTrue);
      expect(node.props, contains('203.0.113.1'));
      expect(node.props, contains('Ethernet'));
      expect(node.props, contains(1000));
      expect(node.props, contains(-45));
      expect(node.props, contains(500000));
      expect(node.props, contains('Wi-Fi'));
      expect(node.props, contains(600000));
      // Remaining DataElements enrichment fields default to null:
      // dataElementsId(1) + instancePath(1) + backhaulAlId(1) +
      // backhaulMacAddress(1) + backhaulParentDeviceId(1) + backhaulParentBssid(1) +
      // lastContactTime(1) = 7 nulls
      expect(node.props.where((p) => p == null).length, 7);
    });
  });

  // ---------------------------------------------------------------------------
  // NodeUIModel — default values
  // ---------------------------------------------------------------------------

  group('NodeUIModel — default values', () {
    test('default values are applied correctly', () {
      const node = NodeUIModel(
        deviceId: 'AA:BB:CC:DD:EE:01',
        model: 'MR7500',
      );

      expect(node.friendlyName, isNull);
      expect(node.hostName, isNull);
      expect(node.manufacturer, '');
      expect(node.serialNumber, '');
      expect(node.softwareVersion, '');
      expect(node.isMaster, isFalse);
      expect(node.connectedDeviceCount, 0);
      expect(node.backhaulMediaType, '');
      expect(node.backhaulPhyRate, 0);
      expect(node.backhaulSignalStrength, isNull);
      expect(node.backhaulUplinkRate, isNull);
      // DataElements enrichment fields default to null
      expect(node.instancePath, isNull);
      expect(node.backhaulAlId, isNull);
      expect(node.backhaulMacAddress, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // NodeUIModelListExt — extension methods
  // ---------------------------------------------------------------------------

  group('NodeUIModelListExt', () {
    const masterNode = NodeUIModel(
      deviceId: 'AA:BB:CC:DD:EE:01',
      model: 'MR7500',
      isMaster: true,
    );
    const slaveNode1 = NodeUIModel(
      deviceId: 'AA:BB:CC:DD:EE:02',
      model: 'MX5500',
      isMaster: false,
    );
    const slaveNode2 = NodeUIModel(
      deviceId: 'AA:BB:CC:DD:EE:03',
      model: 'MX5500',
      isMaster: false,
    );

    test('master returns the master node', () {
      final nodes = [masterNode, slaveNode1, slaveNode2];
      expect(nodes.master, equals(masterNode));
    });

    test('master returns null when no master exists', () {
      final nodes = [slaveNode1, slaveNode2];
      expect(nodes.master, isNull);
    });

    test('slaves returns all non-master nodes', () {
      final nodes = [masterNode, slaveNode1, slaveNode2];
      expect(nodes.slaves, equals([slaveNode1, slaveNode2]));
    });

    test('slaves returns empty list when all nodes are master', () {
      final nodes = [masterNode];
      expect(nodes.slaves, isEmpty);
    });

    test('hasMesh returns true when slaves exist', () {
      final nodes = [masterNode, slaveNode1];
      expect(nodes.hasMesh, isTrue);
    });

    test('hasMesh returns false when no slaves', () {
      final nodes = [masterNode];
      expect(nodes.hasMesh, isFalse);
    });

    test('hasMesh returns false for empty list', () {
      final List<NodeUIModel> nodes = [];
      expect(nodes.hasMesh, isFalse);
    });
  });
}
