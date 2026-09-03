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

    // linksys/PrivacyGUI#1438 — a present-but-zero Hosts SignalStrength means
    // "no reading", not 0 dBm. It must be treated as absent so the `??` chain
    // can reach the WifiClient / DataElements sources.
    test('Hosts signalStrength 0 falls through to wifiClient value (#1438)',
        () {
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
          signalStrength: 0, // "no reading" from Hosts, not a real 0 dBm
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
      expect(client.signalStrength, -50,
          reason: 'Hosts 0 must not short-circuit the WifiClient reading');
    });

    // linksys/PrivacyGUI#1438 — a WiFi device with no signal from any source
    // (Hosts 0, no WifiClient, no DataElements) must render as unknown, not as
    // a bar level: signalStrength null → hasSignalDisplay false.
    test('Hosts signalStrength 0 with no other source yields unknown (#1438)',
        () {
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
          signalStrength: 0, // "no reading" and nothing anywhere else
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      final client = result.master.connectedClients.first;
      expect(client.signalStrength, isNull,
          reason: 'Hosts 0 with no fallback must normalize to null');
      expect(client.hasSignalDisplay, isFalse,
          reason: 'unknown signal must not render a bar level');
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

        // …and neither still names a parent. The ghost-parent shape is the one
        // that can: the resolver had already filled parentNodeName in from the
        // unmatched node's model, or from the gateway name when that model is
        // empty. A name surviving here is what makes the device card badge and
        // analytics grouping keep attributing the orphan to a node.
        expect(
          result.unassignedClients.map((c) => c.parentNodeName),
          everyElement(isNull),
          reason: 'an orphan must not name a parent on any surface',
        );

        // The attributed device is not flagged.
        final attributed =
            result.allClients.firstWhere((c) => c.mac == '11:22:33:44:55:01');
        expect(attributed.isUnattributed, isFalse);
      });

      // The orphan predicate must be no broader than the orphan population.
      // clientToNodeMap is written in exactly one place — the DataElements
      // Wi-Fi station loop — so a wired client and an offline client are absent
      // from it whatever node they are really on, and a null parentNodeId is no
      // evidence about them. Reading it as evidence relabels every wired device
      // in a mesh house as "Unattributed", drops it from the master's client
      // count, and makes it bypass the node filter entirely. Only an *online
      // Wi-Fi* client missing from the map is genuinely unplaceable.
      test(
          'mesh with an extender: wired and offline clients stay on the '
          'master; only the online Wi-Fi client with no station row is an '
          'orphan', () {
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
          // Wi-Fi client with a station row → resolves to the master.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            deviceRole: 'client',
            hostName: 'WifiPhone',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: true,
          ),
          // Wired desktop on the master: never a Wi-Fi station key.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:02',
            deviceRole: 'client',
            hostName: 'DesktopPC',
            interface_: 'Device.Ethernet.Interface.1',
            interfaceType: 'Ethernet',
            isActive: true,
          ),
          // Offline tablet: never a Wi-Fi station key.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:03',
            deviceRole: 'client',
            hostName: 'OldTablet',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: false,
          ),
          // Online Wi-Fi client absent from the station map → the real orphan.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:04',
            deviceRole: 'client',
            hostName: 'OrphanWifiPhone',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: true,
          ),
        ]);

        final result = MeshNetworkBuilder.build(
          connectedDevices: connectedDevices,
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: MeshTopologyInfo(
            nodes: [
              buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
              buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
            ],
            clientToNodeMap: const {
              '11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01',
            },
          ),
          gatewayName: 'Router',
        );

        // A real mesh — the standalone-router exemption does not apply here.
        expect(result.slaves, hasLength(1));

        final masterMacs = result.master.connectedClients.map((c) => c.mac);
        expect(
          masterMacs,
          containsAll([
            '11:22:33:44:55:01', // Wi-Fi, resolved
            '11:22:33:44:55:02', // wired
            '11:22:33:44:55:03', // offline
          ]),
          reason: 'wired and offline clients are not orphans in a mesh either',
        );
        expect(
          result.master.connectedClients.every((c) => !c.isUnattributed),
          isTrue,
        );

        // Exactly one orphan, and it is the online Wi-Fi client.
        expect(
            result.unassignedClients.map((c) => c.mac), ['11:22:33:44:55:04']);
        expect(result.unassignedClients.single.isUnattributed, isTrue);
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

      // A standalone router that supports DataElements reports a single
      // (master) node, so `meshTopology.nodes` is non-empty even though there
      // is no extender. Such a network is NOT a mesh (no slaves), so its
      // null-parent clients — every wired and every offline client, which are
      // never Wi-Fi STA keys in clientToNodeMap — must stay on the master, not
      // be swept into the unassigned bucket. Guards against classifying a
      // single-router-with-DataElements network as a mesh via nodes.isNotEmpty.
      test(
          'standalone DataElements router (no slaves): wired/offline '
          'null-parent clients stay on the master, not unattributed', () {
        final connectedDevices = ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: 'AA:BB:CC:DD:EE:01',
            deviceRole: 'master',
            hostName: 'Router',
          ),
          // Wi-Fi client with an STA row → resolves to the master.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            deviceRole: 'client',
            hostName: 'WifiPhone',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: true,
          ),
          // Wired desktop: never a Wi-Fi STA key → null parentNodeId.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:02',
            deviceRole: 'client',
            hostName: 'DesktopPC',
            interface_: 'Device.Ethernet.Interface.1',
            interfaceType: 'Ethernet',
            isActive: true,
          ),
          // Offline tablet: never a Wi-Fi STA key → null parentNodeId.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:03',
            deviceRole: 'client',
            hostName: 'OldTablet',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: false,
          ),
        ]);

        // DataElements present, but only the master node (no slaves).
        final meshTopology = MeshTopologyInfo(
          nodes: [buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01')],
          clientToNodeMap: {
            '11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01', // Wi-Fi STA on master
          },
        );

        final result = MeshNetworkBuilder.build(
          connectedDevices: connectedDevices,
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: meshTopology,
          gatewayName: 'Router',
        );

        // No slaves → not a mesh → nothing is unattributed.
        expect(result.slaves, isEmpty);
        expect(result.unassignedClients, isEmpty);

        // All three clients are on the master, none flagged.
        final masterMacs = result.master.connectedClients.map((c) => c.mac);
        expect(
          masterMacs,
          containsAll([
            '11:22:33:44:55:01',
            '11:22:33:44:55:02',
            '11:22:33:44:55:03',
          ]),
        );
        expect(
          result.master.connectedClients.every((c) => !c.isUnattributed),
          isTrue,
        );
      });
    });
  });
}
