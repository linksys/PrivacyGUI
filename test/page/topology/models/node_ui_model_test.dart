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
        backhaulMediaType: 'Ethernet',
        backhaulPhyRate: 1000,
      );

      expect(node.props, hasLength(11));
      expect(node.props, contains('AA:BB:CC:DD:EE:01'));
      expect(node.props, contains('Router'));
      expect(node.props, contains('linksys'));
      expect(node.props, contains('MR7500'));
      expect(node.props, contains('Linksys'));
      expect(node.props, contains('SN123'));
      expect(node.props, contains('2.0.0'));
      expect(node.props, contains(true));
      expect(node.props, contains(5));
      expect(node.props, contains('Ethernet'));
      expect(node.props, contains(1000));
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
    });
  });
}
