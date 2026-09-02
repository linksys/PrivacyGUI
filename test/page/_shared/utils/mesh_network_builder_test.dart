import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_network_builder.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test Data Builders
  // ---------------------------------------------------------------------------

  ConnectedDevice buildConnectedDevice({
    required String macAddress,
    String deviceRole = 'client',
    String hostName = '',
    String? friendlyName,
    String ipAddress = '',
    String interface_ = '',
    String? interfaceType,
    bool isActive = true,
    int? signalStrength,
    int? lastDataDownlinkRate,
    int? lastDataUplinkRate,
    String? deviceId,
  }) {
    return ConnectedDevice(
      instancePath: 'Device.Hosts.Host.1.',
      macAddress: macAddress,
      deviceRole: deviceRole,
      hostName: hostName,
      friendlyName: friendlyName,
      ipAddress: ipAddress,
      interface_: interface_,
      interfaceType: interfaceType,
      isActive: isActive,
      signalStrength: signalStrength,
      lastDataDownlinkRate: lastDataDownlinkRate,
      lastDataUplinkRate: lastDataUplinkRate,
      deviceId: deviceId,
      ipv4Addresses: const [],
      ipv6Addresses: const [],
      manufacturer: '',
      modelName: '',
      operatingSystem: '',
    );
  }

  MasterNode buildMasterNode({
    required String deviceId,
    String model = 'TestRouter',
  }) {
    return MasterNode(
      deviceId: deviceId,
      model: model,
      manufacturer: 'Test',
      serialNumber: 'SN123',
      softwareVersion: '1.0.0',
    );
  }

  SlaveNode buildSlaveNode({
    required String deviceId,
    String model = 'TestExtender',
    BackhaulInfo? backhaul,
  }) {
    return SlaveNode(
      deviceId: deviceId,
      model: model,
      manufacturer: 'Test',
      serialNumber: 'SN456',
      softwareVersion: '1.0.0',
      backhaul: backhaul ?? const BackhaulInfo(mediaType: 'Wi-Fi'),
    );
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('MeshNetworkBuilder.build', () {
    test('separates master and slave nodes from clients', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
          hostName: 'Router',
        ),
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:02',
          deviceRole: 'slave',
          hostName: 'Extender',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'Phone',
          interface_: 'Device.WiFi.Radio.1',
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      expect(result.master.deviceId, 'AA:BB:CC:DD:EE:01');
      expect(result.slaves.length, 1);
      expect(result.slaves.first.deviceId, 'AA:BB:CC:DD:EE:02');
      expect(result.allClients.length, 1);
      expect(result.allClients.first.mac, '11:22:33:44:55:01');
    });

    test('assigns clients to master when no mesh topology', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
          hostName: 'Router',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'Phone',
          interface_: 'Device.WiFi.Radio.1',
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      expect(result.master.connectedClients.length, 1);
      expect(result.master.connectedClients.first.mac, '11:22:33:44:55:01');
    });

    test('assigns clients to correct node via clientToNodeMap', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
          hostName: 'Router',
        ),
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:02',
          deviceRole: 'slave',
          hostName: 'Extender',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'MasterClient',
          interface_: 'Device.WiFi.Radio.1',
          isActive: true,
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:02',
          deviceRole: 'client',
          hostName: 'SlaveClient',
          interface_: 'Device.WiFi.Radio.1',
          isActive: true,
        ),
      ]);

      final meshTopology = MeshTopologyInfo(
        nodes: [
          buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
          buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
        ],
        clientToNodeMap: {
          '11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01', // on master
          '11:22:33:44:55:02': 'AA:BB:CC:DD:EE:02', // on slave
        },
      );

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: meshTopology,
        gatewayName: 'Router',
      );

      expect(result.master.connectedClients.length, 1);
      expect(result.master.connectedClients.first.hostName, 'MasterClient');
      expect(result.slaves.first.connectedClients.length, 1);
      expect(
          result.slaves.first.connectedClients.first.hostName, 'SlaveClient');
    });

    test('uses clientSignalMap as signal fallback for slave clients', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:02',
          deviceRole: 'slave',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'SlaveClient',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
          signalStrength: null, // No signal from Hosts
        ),
      ]);

      final meshTopology = MeshTopologyInfo(
        nodes: [
          buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
          buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
        ],
        clientToNodeMap: {
          '11:22:33:44:55:01': 'AA:BB:CC:DD:EE:02',
        },
        clientSignalMap: {
          '11:22:33:44:55:01': -45, // Signal from DataElements
        },
      );

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: meshTopology,
        gatewayName: 'Router',
      );

      final client = result.slaves.first.connectedClients.first;
      expect(client.signalStrength, -45);
    });

    test('uses clientBandSsidMap as band/SSID fallback for slave clients', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:02',
          deviceRole: 'slave',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'SlaveClient',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
        ),
      ]);

      final meshTopology = MeshTopologyInfo(
        nodes: [
          buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
          buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
        ],
        clientToNodeMap: {
          '11:22:33:44:55:01': 'AA:BB:CC:DD:EE:02',
        },
        clientBandSsidMap: {
          '11:22:33:44:55:01': (band: '5GHz', ssid: 'HomeNetwork'),
        },
      );

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {}, // No connectionDetailMap for slave client
        meshTopology: meshTopology,
        gatewayName: 'Router',
      );

      final client = result.slaves.first.connectedClients.first;
      expect(client.band, '5GHz');
      expect(client.wifi?.ssidName, 'HomeNetwork');
    });

    test('connectionDetailMap takes precedence over clientBandSsidMap', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'MasterClient',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
        ),
      ]);

      final meshTopology = MeshTopologyInfo(
        nodes: [buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01')],
        clientToNodeMap: {
          '11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01',
        },
        clientBandSsidMap: {
          '11:22:33:44:55:01': (band: '2.4GHz', ssid: 'OldSSID'),
        },
      );

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {
          '11:22:33:44:55:01':
              ClientConnectionDetail(band: '5GHz', ssidName: 'NewSSID'),
        },
        meshTopology: meshTopology,
        gatewayName: 'Router',
      );

      final client = result.master.connectedClients.first;
      expect(client.band, '5GHz'); // From connectionDetailMap
      expect(client.wifi?.ssidName, 'NewSSID'); // From connectionDetailMap
    });

    test(
        'empty-string band/SSID in connectionDetailMap falls back to '
        'clientBandSsidMap', () {
      // Regression: ClientConnectionDetail.band is a non-nullable String that
      // is '' when AP→SSID→radio resolution fails. An empty string must be
      // treated as absent so the DataElements value is used instead.
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'MasterClient',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
        ),
      ]);

      final meshTopology = MeshTopologyInfo(
        nodes: [buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01')],
        clientToNodeMap: {
          '11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01',
        },
        clientBandSsidMap: {
          '11:22:33:44:55:01': (band: '5GHz', ssid: 'ResolvedSSID'),
        },
      );

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {
          // Present but unresolved → empty strings.
          '11:22:33:44:55:01': ClientConnectionDetail(band: '', ssidName: ''),
        },
        meshTopology: meshTopology,
        gatewayName: 'Router',
      );

      final client = result.master.connectedClients.first;
      expect(client.band, '5GHz'); // Fell back to clientBandSsidMap
      expect(client.wifi?.ssidName, 'ResolvedSSID'); // Fell back
    });

    test('merges multi-interface devices by hostname', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'Laptop',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:02',
          deviceRole: 'client',
          hostName: 'Laptop', // Same hostname
          interface_: 'Device.Ethernet.Interface.1',
          interfaceType: 'Ethernet',
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      // Should merge into 1 client with additional interfaces
      expect(result.allClients.length, 1);
      expect(result.allClients.first.hostName, 'Laptop');
      expect(result.allClients.first.hasMultipleInterfaces, isTrue);
      expect(result.allClients.first.additionalInterfaces.length, 1);
    });

    test('patches parentNodeName on clients', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
          friendlyName: 'Living Room Router',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'Phone',
          interface_: 'Device.WiFi.Radio.1',
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      expect(
        result.master.connectedClients.first.parentNodeName,
        'Living Room Router',
      );
    });

    test('uses wifiClientMap for signal enrichment on master clients', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'Phone',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
          signalStrength: null, // No signal from Hosts
        ),
      ]);

      final wifiClientMap = {
        '11:22:33:44:55:01': WifiClientUIModel(
          macAddress: '11:22:33:44:55:01',
          signalStrength: -50,
          noise: -90,
          lastDataDownlinkRate: 100000,
          lastDataUplinkRate: 50000,
          active: true,
        ),
      };

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: wifiClientMap,
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      final client = result.master.connectedClients.first;
      expect(client.signalStrength, -50);
      expect(client.downlinkRate, 100000);
      expect(client.uplinkRate, 50000);
    });

    test('detects WiFi client via interfaceType containing wi-fi', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'Phone',
          interface_: '', // Empty interface
          interfaceType: 'Wi-Fi', // But interfaceType indicates WiFi
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      expect(result.master.connectedClients.first.isWifi, isTrue);
    });

    test('detects wired client correctly', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          deviceRole: 'client',
          hostName: 'Desktop',
          interface_: 'Device.Ethernet.Interface.1',
          interfaceType: 'Ethernet',
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      expect(result.master.connectedClients.first.isWifi, isFalse);
      expect(
        result.master.connectedClients.first.connectionType,
        ConnectionType.wired,
      );
    });

    test('handles empty connectedDevices gracefully', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: []),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      expect(result.master.deviceId, 'GATEWAY');
      expect(result.slaves, isEmpty);
      expect(result.allClients, isEmpty);
    });

    test('uses gatewayName as fallback when no master device found', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: []),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'MyRouter',
      );

      expect(result.master.hostName, 'MyRouter');
    });

    test('normalizes MAC addresses to uppercase', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'aa:bb:cc:dd:ee:01', // lowercase
          deviceRole: 'master',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01', // lowercase
          deviceRole: 'client',
          hostName: 'Phone',
          interface_: 'Device.WiFi.Radio.1',
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      expect(result.master.deviceId, 'AA:BB:CC:DD:EE:01');
      expect(result.allClients.first.mac, '11:22:33:44:55:01');
    });

    // Issue #1439: a device whose parent node cannot be resolved must not be
    // attributed to the master. Both orphan shapes — a null parentNodeId (in a
    // mesh network) and a non-null parentNodeId matching no known node — land
    // in the unassigned bucket, flagged isUnattributed.
    group('unattributed (orphan) clients — issue #1439', () {
      ConnectedDevices meshWithOrphans() => ConnectedDevices(items: [
            buildConnectedDevice(
              macAddress: 'AA:BB:CC:DD:EE:01',
              deviceRole: 'master',
              hostName: 'Router',
            ),
            buildConnectedDevice(
              macAddress: 'AA:BB:CC:DD:EE:02',
              deviceRole: 'slave',
              hostName: 'Extender',
            ),
            buildConnectedDevice(
              macAddress: '11:22:33:44:55:01',
              deviceRole: 'client',
              hostName: 'AttributedPhone',
              interface_: 'Device.WiFi.Radio.1',
              isActive: true,
            ),
            buildConnectedDevice(
              macAddress: '11:22:33:44:55:02',
              deviceRole: 'client',
              hostName: 'NullParentPhone',
              interface_: 'Device.WiFi.Radio.1',
              isActive: true,
            ),
            buildConnectedDevice(
              macAddress: '11:22:33:44:55:03',
              deviceRole: 'client',
              hostName: 'UnknownParentPhone',
              interface_: 'Device.WiFi.Radio.1',
              isActive: true,
            ),
          ]);

      MeshTopologyInfo meshTopologyWithOrphans() => MeshTopologyInfo(
            nodes: [
              buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
              buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
            ],
            clientToNodeMap: {
              // Attributed to the master (known node).
              '11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01',
              // 55:02 is absent from the map → null parentNodeId (orphan shape A).
              // 55:03 points at a node that is not in `nodes` (orphan shape B).
              '11:22:33:44:55:03': 'GHOST-NODE-ID',
            },
          );

      test(
          'both orphan shapes land in unassignedClients, flagged, and are '
          'NOT on the master', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: meshWithOrphans(),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: meshTopologyWithOrphans(),
          gatewayName: 'Router',
        );

        // The attributed device is on the master; neither orphan is.
        final masterMacs = result.master.connectedClients.map((c) => c.mac);
        expect(masterMacs, contains('11:22:33:44:55:01'));
        expect(masterMacs, isNot(contains('11:22:33:44:55:02')));
        expect(masterMacs, isNot(contains('11:22:33:44:55:03')));

        // Both orphan shapes are in the unassigned bucket and flagged.
        final unassignedMacs =
            result.unassignedClients.map((c) => c.mac).toSet();
        expect(unassignedMacs,
            containsAll(['11:22:33:44:55:02', '11:22:33:44:55:03']));
        expect(
          result.unassignedClients.every((c) => c.isUnattributed),
          isTrue,
        );

        // The attributed device is not flagged.
        final attributed =
            result.allClients.firstWhere((c) => c.mac == '11:22:33:44:55:01');
        expect(attributed.isUnattributed, isFalse);
      });

      test('non-mesh null-parent clients stay on the master (not orphans)', () {
        final connectedDevices = ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: 'AA:BB:CC:DD:EE:01',
            deviceRole: 'master',
            hostName: 'Router',
          ),
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            deviceRole: 'client',
            hostName: 'Phone',
            interface_: 'Device.WiFi.Radio.1',
            isActive: true,
          ),
        ]);

        final result = MeshNetworkBuilder.build(
          connectedDevices: connectedDevices,
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: MeshTopologyInfo.empty, // non-mesh
          gatewayName: 'Router',
        );

        expect(result.unassignedClients, isEmpty);
        expect(result.master.connectedClients.map((c) => c.mac),
            contains('11:22:33:44:55:01'));
        expect(
          result.master.connectedClients.every((c) => !c.isUnattributed),
          isTrue,
        );
      });
    });
  });
}
