import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_network_builder.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Test Data Builders
  // ---------------------------------------------------------------------------

  ConnectedDevice buildConnectedDevice({
    required String macAddress,
    String instancePath = 'Device.Hosts.Host.1.',
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
    String manufacturer = '',
    String modelName = '',
    String operatingSystem = '',
    String? linksysManufacturer,
    String? linksysModelName,
    String? linksysOperatingSystem,
    String? linksysDeviceType,
    String? linksysFriendlyName,
    String? linksysUserDeviceType,
    String? linksysUserDeviceLocation,
  }) {
    return ConnectedDevice(
      instancePath: instancePath,
      macAddress: macAddress,
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
      manufacturer: manufacturer,
      modelName: modelName,
      operatingSystem: operatingSystem,
      linksysManufacturer: linksysManufacturer,
      linksysModelName: linksysModelName,
      linksysOperatingSystem: linksysOperatingSystem,
      linksysDeviceType: linksysDeviceType,
      linksysFriendlyName: linksysFriendlyName,
      linksysUserDeviceType: linksysUserDeviceType,
      linksysUserDeviceLocation: linksysUserDeviceLocation,
    );
  }

  MasterNode buildMasterNode({
    required String deviceId,
    String model = 'TestRouter',
    String manufacturer = 'Test',
    String serialNumber = 'SN123',
    String softwareVersion = '1.0.0',
  }) {
    return MasterNode(
      deviceId: deviceId,
      model: model,
      manufacturer: manufacturer,
      serialNumber: serialNumber,
      softwareVersion: softwareVersion,
    );
  }

  SystemInfoUIModel buildSystemInfo({
    String modelName = 'MR7500',
    String manufacturer = 'Linksys',
    String serialNumber = 'SN-REAL-12345',
    String softwareVersion = '2.0.1.216125',
    String? userDeviceLocation,
    String? friendlyName,
  }) {
    return SystemInfoUIModel(
      manufacturer: manufacturer,
      modelName: modelName,
      serialNumber: serialNumber,
      hardwareVersion: '1.0',
      softwareVersion: softwareVersion,
      uptime: 0,
      totalMemory: 0,
      freeMemory: 0,
      cpuUsage: 0,
      userDeviceLocation: userDeviceLocation,
      friendlyName: friendlyName,
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
      backhaul: backhaul ?? const BackhaulInfo(linkType: 'Wi-Fi'),
    );
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('MeshNetworkBuilder.build', () {
    // #1688 item 1. FL-WRT 2.0 has no `DeviceRole` on Hosts, so the nodes come
    // from DataElements and a Hosts row is a node's when its PhysAddress is the
    // node's `Device.{i}.ID` (linksys/FWDEV#208). The shape is the one measured
    // on 2.0.3.26101482: the controller has no Hosts row of its own, and an
    // agent's row carries nothing that marks it as a node.
    test(
        'builds nodes from DataElements and keeps their Hosts rows out of '
        'the clients (#1688)', () {
      final connectedDevices = ConnectedDevices(items: [
        // The agent's own row: no role leaf, only a MAC equal to its ID.
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:02',
          hostName: 'Extender',
          ipAddress: '192.168.1.120',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          hostName: 'Phone',
          interface_: 'Device.WiFi.Radio.1',
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
          clientToNodeMap: const {},
        ),
        gatewayName: 'Router',
      );

      // The controller, with no Hosts row, is still the master.
      expect(result.master.deviceId, 'AA:BB:CC:DD:EE:01');
      expect(result.slaves, hasLength(1));
      final slave = result.slaves.single;
      expect(slave.deviceId, 'AA:BB:CC:DD:EE:02');
      // The agent's Hosts row supplies what DataElements does not carry.
      expect(slave.hostName, 'Extender');
      expect(slave.ipAddress, '192.168.1.120');
      // ...and is not also listed as a client.
      expect(result.allClients.map((c) => c.mac), ['11:22:33:44:55:01']);
    });

    // The controller has no Hosts row on 2.0.3.26101482, but a build that
    // gives it one must still treat that row as the controller's: its IP and
    // host name, and not a client. The row's MAC case differs from the node
    // ID's on purpose — Hosts and DataElements are separate producers.
    test(
        'a controller with its own Hosts row takes its IP from it and does '
        'not list it as a client (#1688)', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: 'aa:bb:cc:dd:ee:01',
            hostName: 'Router',
            ipAddress: '192.168.1.1',
          ),
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            hostName: 'Phone',
            interface_: 'Device.WiFi.Radio.1',
          ),
        ]),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo(
          nodes: [buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01')],
          clientToNodeMap: const {},
        ),
        gatewayName: 'Router',
      );

      expect(result.master.ipAddress, '192.168.1.1');
      expect(result.master.hostName, 'Router');
      expect(result.allClients.map((c) => c.mac), ['11:22:33:44:55:01']);
    });

    // The FWDEV#208 rule matches on the MAC, and Hosts and DataElements are
    // separate producers. A spelling difference between the two must not turn
    // the agent back into a client.
    test('matches a node to its Hosts row regardless of MAC spelling (#1688)',
        () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: 'aa:bb:cc:dd:ee:02',
            hostName: 'Extender',
          ),
        ]),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo(
          nodes: [
            buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
            buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
          ],
          clientToNodeMap: const {},
        ),
        gatewayName: 'Router',
      );

      expect(result.slaves.single.hostName, 'Extender');
      expect(result.allClients, isEmpty);
    });

    // FWDEV#208 measured every agent with a matching Hosts row, but our own
    // bench has not confirmed it. An agent with no row must still be built.
    test(
        'builds an agent that has no Hosts row, with no IP or host name '
        '(#1688)', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: const ConnectedDevices(items: []),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo(
          nodes: [
            buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
            buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02', model: 'MX5300'),
          ],
          clientToNodeMap: const {},
        ),
        gatewayName: 'Router',
      );

      final slave = result.slaves.single;
      expect(slave.deviceId, 'AA:BB:CC:DD:EE:02');
      expect(slave.dataElementsId, 'AA:BB:CC:DD:EE:02');
      expect(slave.model, 'MX5300');
      expect(slave.ipAddress, isNull);
      expect(slave.hostName, isNull);
      expect(slave.isOnline, isTrue);
    });

    // The Hosts names on a node row are the 2.0 `X_LINKSYS_` leaves, as for
    // clients (#1693). The unprefixed 1.0 FriendlyName is absent on 2.0 and
    // must not be what names an agent.
    test('names an agent from its X_LINKSYS_FriendlyName (#1688)', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: 'AA:BB:CC:DD:EE:02',
            hostName: 'mx5300-host',
            friendlyName: 'stale 1.0 leaf',
            linksysFriendlyName: 'Upstairs',
          ),
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            hostName: 'Phone',
            interface_: 'Device.WiFi.Radio.1',
          ),
        ]),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo(
          nodes: [
            buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
            buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
          ],
          clientToNodeMap: const {'11:22:33:44:55:01': 'AA:BB:CC:DD:EE:02'},
        ),
        gatewayName: 'Router',
      );

      final slave = result.slaves.single;
      expect(slave.friendlyName, 'Upstairs');
      expect(slave.displayName, 'Upstairs');
      // A client on that agent is labelled with the same name.
      expect(slave.connectedClients.single.parentNodeName, 'Upstairs');
    });

    // #1688 item 4. A rename writes the agent's own Hosts row, so the slave
    // has to carry that row's path and the name already on it.
    test(
        'carries the agent Hosts row path and the user name onto the slave '
        '(#1688 item 4)', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: 'AA:BB:CC:DD:EE:02',
            instancePath: 'Device.Hosts.Host.3.',
            hostName: 'mx5300-host',
            linksysUserDeviceLocation: 'Upstairs',
          ),
        ]),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo(
          nodes: [
            buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
            buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
          ],
          clientToNodeMap: const {},
        ),
        gatewayName: 'Router',
      );

      final slave = result.slaves.single;
      expect(slave.hostInstancePath, 'Device.Hosts.Host.3.');
      expect(slave.userDeviceName, 'Upstairs');
    });

    test('an agent with no Hosts row has no rename path (#1688 item 4)', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: const ConnectedDevices(items: []),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo(
          nodes: [
            buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
            buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
          ],
          clientToNodeMap: const {},
        ),
        gatewayName: 'Router',
      );

      expect(result.slaves.single.hostInstancePath, isNull);
      expect(result.slaves.single.userDeviceName, isNull);
    });

    test('nothing is a node when DataElements reported no node', () {
      // On 2.0 an empty topology carries no node information at all, and no
      // Hosts row can say otherwise: every row is a client.
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: 'AA:BB:CC:DD:EE:02',
            hostName: 'Extender',
          ),
        ]),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      expect(result.slaves, isEmpty);
      expect(result.master.deviceId, 'GATEWAY');
      expect(result.allClients.map((c) => c.mac), ['AA:BB:CC:DD:EE:02']);
    });

    test('assigns clients to master when no mesh topology', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
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
          hostName: 'Router',
        ),
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:02',
          hostName: 'Extender',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          hostName: 'MasterClient',
          interface_: 'Device.WiFi.Radio.1',
          isActive: true,
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:02',
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
        ),
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:02',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
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
        ),
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:02',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
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
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
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

    // #1686 item 1. A client on an agent has no Hosts rate on FL-WRT 2.0 and
    // no AssociatedDevice row on the controller, so only DataElements BSS.STA
    // gives it a rate.
    group('client rates (#1686)', () {
      const clientMac = '11:22:33:44:55:01';
      MeshNetwork buildWith({
        int? hostsDownlink,
        Map<String, WifiClientUIModel> wifiClientMap = const {},
        ({int? downlink, int? uplink})? dataElements,
      }) =>
          MeshNetworkBuilder.build(
            connectedDevices: ConnectedDevices(items: [
              buildConnectedDevice(macAddress: 'AA:BB:CC:DD:EE:01'),
              buildConnectedDevice(macAddress: 'AA:BB:CC:DD:EE:02'),
              buildConnectedDevice(
                macAddress: clientMac,
                hostName: 'AgentClient',
                interface_: 'Device.WiFi.Radio.1',
                interfaceType: 'Wi-Fi',
                isActive: true,
                lastDataDownlinkRate: hostsDownlink,
              ),
            ]),
            wifiClientMap: wifiClientMap,
            connectionDetailMap: const {},
            meshTopology: MeshTopologyInfo(
              nodes: [
                buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
                buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
              ],
              clientToNodeMap: const {clientMac: 'AA:BB:CC:DD:EE:02'},
              clientRateMap: {
                if (dataElements != null) clientMac: dataElements
              },
            ),
            gatewayName: 'Router',
          );

      test('an agent client takes its rates from DataElements', () {
        final client = buildWith(dataElements: (downlink: 6000, uplink: 24000))
            .slaves
            .first
            .connectedClients
            .first;

        expect(client.downlinkRate, 6000);
        expect(client.uplinkRate, 24000);
      });

      test('the controller AssociatedDevice rate still wins', () {
        final client = buildWith(
          wifiClientMap: {
            clientMac: WifiClientUIModel(
              macAddress: clientMac,
              signalStrength: -50,
              noise: -90,
              lastDataDownlinkRate: 100000,
              lastDataUplinkRate: 50000,
              active: true,
            ),
          },
          dataElements: (downlink: 6000, uplink: 24000),
        ).slaves.first.connectedClients.first;

        expect(client.downlinkRate, 100000);
        expect(client.uplinkRate, 50000);
      });

      test('a Hosts rate still wins', () {
        final client = buildWith(
                hostsDownlink: 300000,
                dataElements: (downlink: 6000, uplink: 24000))
            .slaves
            .first
            .connectedClients
            .first;

        expect(client.downlinkRate, 300000);
        expect(client.uplinkRate, 24000);
      });
    });

    // An unknown band is null, not ''. `''` used to come through from
    // clientBandSsidMap (an SSID known, its band not) and became a nameless
    // bucket in the band filter.
    test('a client whose band is unknown has a null band, not empty', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: [
          buildConnectedDevice(macAddress: 'AA:BB:CC:DD:EE:01'),
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: true,
          ),
        ]),
        wifiClientMap: const {},
        connectionDetailMap: const {},
        meshTopology: MeshTopologyInfo(
          nodes: [buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01')],
          clientToNodeMap: const {'11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01'},
          clientBandSsidMap: const {
            '11:22:33:44:55:01': (band: '', ssid: 'HomeNetwork'),
          },
        ),
        gatewayName: 'Router',
      );

      final client = result.master.connectedClients.first;
      expect(client.band, isNull);
      expect(client.wifi?.ssidName, 'HomeNetwork');
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
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
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

    test('a padded SSID keeps its spaces and does not fall back (#1555)', () {
      // Why this one chain keeps a non-trimming guard while the four identity
      // chains moved to the shared, trimming `nonEmpty`. An SSID may legitimately
      // begin or end with a space — trimming would both change what is displayed
      // and let a real single-space SSID lose the `??` to another source.
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          hostName: 'MasterClient',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {
          '11:22:33:44:55:01':
              ClientConnectionDetail(band: '5GHz', ssidName: ' Home Wi-Fi '),
        },
        meshTopology: MeshTopologyInfo(
          nodes: [buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01')],
          clientToNodeMap: {'11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01'},
          clientBandSsidMap: {
            '11:22:33:44:55:01': (band: '2.4GHz', ssid: 'OtherSSID'),
          },
        ),
        gatewayName: 'Router',
      );

      final client = result.master.connectedClients.first;
      expect(client.wifi?.ssidName, ' Home Wi-Fi ',
          reason: 'the spaces are part of the SSID, not padding to strip');
    });

    test('an all-whitespace SSID is a value, not absence (#1555)', () {
      // The single-space SSID the chain must not trim away. A trimming guard
      // would read it as absent and substitute the DataElements value, showing
      // the client on an SSID it is not associated with.
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'AA:BB:CC:DD:EE:01',
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          hostName: 'MasterClient',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
        ),
      ]);

      final result = MeshNetworkBuilder.build(
        connectedDevices: connectedDevices,
        wifiClientMap: {},
        connectionDetailMap: {
          '11:22:33:44:55:01':
              ClientConnectionDetail(band: '5GHz', ssidName: ' '),
        },
        meshTopology: MeshTopologyInfo(
          nodes: [buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01')],
          clientToNodeMap: {'11:22:33:44:55:01': 'AA:BB:CC:DD:EE:01'},
          clientBandSsidMap: {
            '11:22:33:44:55:01': (band: '2.4GHz', ssid: 'OtherSSID'),
          },
        ),
        gatewayName: 'Router',
      );

      expect(result.master.connectedClients.first.wifi?.ssidName, ' ');
    });

    test('merges multi-interface devices by hostname', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          hostName: 'Laptop',
          interface_: 'Device.WiFi.Radio.1',
          interfaceType: 'Wi-Fi',
          isActive: true,
        ),
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:02',
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

    // A laptop with Wi-Fi and a cable is two Hosts rows merged into one device.
    // The primary is the active Wi-Fi row, but the user may have named it while
    // it was on the cable. The merged device shows the name and icon the user
    // set on whichever row has them, and an edit writes back to that row, so a
    // name does not vanish when the primary interface changes (#1691).
    test('a merged device keeps the user name and icon from any of its rows',
        () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            instancePath: 'Device.Hosts.Host.5.',
            hostName: 'Laptop',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            linksysFriendlyName: 'Laptop',
          ),
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:02',
            instancePath: 'Device.Hosts.Host.6.',
            hostName: 'Laptop',
            interface_: 'Device.Ethernet.Interface.1',
            interfaceType: 'Ethernet',
            linksysFriendlyName: 'Work laptop',
            linksysUserDeviceLocation: 'Work laptop',
            linksysUserDeviceType: '3',
          ),
        ]),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      final laptop = result.allClients.single;
      expect(laptop.mac, '11:22:33:44:55:01', reason: 'Wi-Fi stays primary');
      expect(laptop.userDeviceName, 'Work laptop');
      expect(laptop.userDeviceType, '3');
      expect(laptop.friendlyName, 'Work laptop');
      expect(laptop.hostInstancePath, 'Device.Hosts.Host.6.',
          reason: 'an edit goes to the row that holds the user values');
    });

    test('a merged device with no user values keeps the primary row', () {
      final result = MeshNetworkBuilder.build(
        connectedDevices: ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            instancePath: 'Device.Hosts.Host.5.',
            hostName: 'Laptop',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
          ),
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:02',
            instancePath: 'Device.Hosts.Host.6.',
            hostName: 'Laptop',
            interface_: 'Device.Ethernet.Interface.1',
            interfaceType: 'Ethernet',
          ),
        ]),
        wifiClientMap: {},
        connectionDetailMap: {},
        meshTopology: MeshTopologyInfo.empty,
        gatewayName: 'Router',
      );

      final laptop = result.allClients.single;
      expect(laptop.userDeviceName, isNull);
      expect(laptop.hostInstancePath, 'Device.Hosts.Host.5.');
    });

    // A client is labelled with the name of the node it is on. On 2.0 the
    // router has no Hosts row and names itself on DeviceInfo (#1691), so that
    // is where the name comes from here.
    test('patches parentNodeName on clients', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
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
        systemInfo: buildSystemInfo(userDeviceLocation: 'Living Room Router'),
      );

      expect(
        result.master.connectedClients.first.parentNodeName,
        'Living Room Router',
      );
    });

    test('uses wifiClientMap for signal enrichment on master clients', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
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
          macAddress: '11:22:33:44:55:01',
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
          macAddress: '11:22:33:44:55:01',
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
          macAddress: '11:22:33:44:55:01',
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
          macAddress: '11:22:33:44:55:01',
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

    // Node IDs are normalized by MeshTopologyBuilder and matched by
    // `matches a node to its Hosts row regardless of MAC spelling` above.
    test('normalizes client MAC addresses to uppercase', () {
      final connectedDevices = ConnectedDevices(items: [
        buildConnectedDevice(
          macAddress: 'dc:52:85:5d:d0:7c', // lowercase, as Hosts writes it
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

      expect(result.allClients.single.mac, 'DC:52:85:5D:D0:7C');
    });

    // Issue #1439: a device whose parent node cannot be resolved must not be
    // attributed to the master. Both orphan shapes — a null parentNodeId (in a
    // mesh network) and a non-null parentNodeId matching no known node — land
    // in the unassigned bucket, flagged isUnattributed.
    group('unattributed (orphan) clients — issue #1439', () {
      ConnectedDevices meshWithOrphans() => ConnectedDevices(items: [
            buildConnectedDevice(
              macAddress: 'AA:BB:CC:DD:EE:01',
              hostName: 'Router',
            ),
            buildConnectedDevice(
              macAddress: 'AA:BB:CC:DD:EE:02',
              hostName: 'Extender',
            ),
            buildConnectedDevice(
              macAddress: '11:22:33:44:55:01',
              hostName: 'AttributedPhone',
              interface_: 'Device.WiFi.Radio.1',
              isActive: true,
            ),
            buildConnectedDevice(
              macAddress: '11:22:33:44:55:02',
              hostName: 'NullParentPhone',
              interface_: 'Device.WiFi.Radio.1',
              isActive: true,
            ),
            buildConnectedDevice(
              macAddress: '11:22:33:44:55:03',
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
            hostName: 'Router',
          ),
          buildConnectedDevice(
            macAddress: 'AA:BB:CC:DD:EE:02',
            hostName: 'Extender',
          ),
          // Wi-Fi client with a station row → resolves to the master.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            hostName: 'WifiPhone',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: true,
          ),
          // Wired desktop on the master: never a Wi-Fi station key.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:02',
            hostName: 'DesktopPC',
            interface_: 'Device.Ethernet.Interface.1',
            interfaceType: 'Ethernet',
            isActive: true,
          ),
          // Offline tablet: never a Wi-Fi station key.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:03',
            hostName: 'OldTablet',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: false,
          ),
          // Online Wi-Fi client absent from the station map → the real orphan.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:04',
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
            macAddress: '11:22:33:44:55:01',
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
            hostName: 'Router',
          ),
          // Wi-Fi client with an STA row → resolves to the master.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:01',
            hostName: 'WifiPhone',
            interface_: 'Device.WiFi.Radio.1',
            interfaceType: 'Wi-Fi',
            isActive: true,
          ),
          // Wired desktop: never a Wi-Fi STA key → null parentNodeId.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:02',
            hostName: 'DesktopPC',
            interface_: 'Device.Ethernet.Interface.1',
            interfaceType: 'Ethernet',
            isActive: true,
          ),
          // Offline tablet: never a Wi-Fi STA key → null parentNodeId.
          buildConnectedDevice(
            macAddress: '11:22:33:44:55:03',
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

    // #1688 item 2 — a wired client goes under the node whose neighbor table
    // lists it. The three cases, and what changed for each:
    //
    //   listed by exactly one node   → under that node (was: on the master)
    //   listed by two or more nodes  → unattributed   (was: on the master)
    //   listed by no node            → on the master  (unchanged)
    //
    // MeshTopologyBuilder.wiredClientAttribution decides which case a MAC is;
    // these tests pin what the builder does with each.
    group('wired clients under their node (#1688 item 2)', () {
      MeshTopologyInfo topology({
        Map<String, String> wired = const {},
        Set<String> ambiguous = const {},
        Map<String, String> wifi = const {},
      }) =>
          MeshTopologyInfo(
            nodes: [
              buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
              buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
            ],
            clientToNodeMap: wifi,
            wiredClientToNodeMap: wired,
            ambiguousWiredClients: ambiguous,
          );

      ConnectedDevice desktop({bool isActive = true}) => buildConnectedDevice(
            macAddress: '00:E0:4C:68:08:2D',
            hostName: 'Desktop',
            interface_: 'Device.Ethernet.Interface.1',
            interfaceType: 'Ethernet',
            isActive: isActive,
          );

      MeshNetwork buildWith(MeshTopologyInfo meshTopology, ConnectedDevice d) =>
          MeshNetworkBuilder.build(
            connectedDevices: ConnectedDevices(items: [d]),
            wifiClientMap: {},
            connectionDetailMap: {},
            meshTopology: meshTopology,
            gatewayName: 'Router',
          );

      test('a wired client one node lists is under that node', () {
        final result = buildWith(
          topology(wired: {'00:E0:4C:68:08:2D': 'AA:BB:CC:DD:EE:02'}),
          desktop(),
        );

        final slaveClients = result.slaves.single.connectedClients;
        expect(slaveClients.map((c) => c.mac), ['00:E0:4C:68:08:2D']);
        expect(slaveClients.single.isUnattributed, isFalse);
        expect(result.master.connectedClients, isEmpty);
      });

      test('a wired client two nodes list is unattributed', () {
        final result = buildWith(
          topology(ambiguous: {'00:E0:4C:68:08:2D'}),
          desktop(),
        );

        expect(
            result.unassignedClients.map((c) => c.mac), ['00:E0:4C:68:08:2D']);
        expect(result.unassignedClients.single.isUnattributed, isTrue);
        expect(result.master.connectedClients, isEmpty);
      });

      // The forwarding table keeps an unplugged client ~300 s, so the listing
      // is not liveness. An offline client two nodes still list is not
      // claimed to be anywhere.
      test('an offline wired client two nodes list stays on the master', () {
        final result = buildWith(
          topology(ambiguous: {'00:E0:4C:68:08:2D'}),
          desktop(isActive: false),
        );

        expect(result.unassignedClients, isEmpty);
        expect(result.master.connectedClients.map((c) => c.mac),
            ['00:E0:4C:68:08:2D']);
      });

      test('a wired client no node lists stays on the master', () {
        final result = buildWith(topology(), desktop());

        expect(result.master.connectedClients.map((c) => c.mac),
            ['00:E0:4C:68:08:2D']);
        expect(result.unassignedClients, isEmpty);
      });

      test('a Wi-Fi station entry wins over a wired listing', () {
        final result = buildWith(
          topology(
            wifi: {'00:E0:4C:68:08:2D': 'AA:BB:CC:DD:EE:01'},
            wired: {'00:E0:4C:68:08:2D': 'AA:BB:CC:DD:EE:02'},
          ),
          desktop(),
        );

        expect(result.master.connectedClients.map((c) => c.mac),
            ['00:E0:4C:68:08:2D']);
        expect(result.slaves.single.connectedClients, isEmpty);
      });
    });

    // #1430 — node liveness, under #1688's rule that the nodes come from
    // DataElements.
    //
    // Before #1688 the slaves were the Hosts rows tagged `DeviceRole=slave`, so
    // a powered-off extender was an *offline* node: its Hosts row lingered
    // while it had already left `DataElements.Network.Device.`, and an
    // unmatched row was the offline shape. FL-WRT 2.0 has no `DeviceRole`, so
    // that lingering row is indistinguishable from a client and the offline
    // shape cannot be built from this input. The decision recorded on #1688 is
    // to build every node from DataElements now and add offline recovery (the
    // app remembering which MACs were nodes) once a multi-node bench has
    // measured how long an agent's row lingers on 2.0. These tests pin what
    // holds today; the offline case is the next one to add, not a regression.
    group('node liveness (#1430, under #1688)', () {
      test('every agent DataElements reports is built online', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: ConnectedDevices(items: [
            buildConnectedDevice(
              macAddress: 'AA:BB:CC:DD:EE:02',
              hostName: 'Extender',
            ),
          ]),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: MeshTopologyInfo(
            nodes: [
              buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
              buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
            ],
            clientToNodeMap: const {},
          ),
          gatewayName: 'Router',
        );

        final slave = result.slaves.single;
        expect(slave.livenessKnown, isTrue);
        expect(slave.dataElementsId, 'AA:BB:CC:DD:EE:02');
        expect(slave.isOnline, isTrue);
        expect(result.master.isOnline, isTrue);
      });

      // AC5b, still true: liveness is DataElements membership, never the Hosts
      // row's `Active`. A node row reads `Active=0` whether the node is up or
      // not (#1430's bench measurement), so isActive:false is the point here.
      test('a node whose Hosts row reads Active=0 is still online (AC5b)', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: ConnectedDevices(items: [
            buildConnectedDevice(
              macAddress: 'AA:BB:CC:DD:EE:02',
              hostName: 'Extender',
              isActive: false,
            ),
          ]),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: MeshTopologyInfo(
            nodes: [
              buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
              buildSlaveNode(deviceId: 'AA:BB:CC:DD:EE:02'),
            ],
            clientToNodeMap: const {},
          ),
          gatewayName: 'Router',
        );

        expect(result.slaves.single.isOnline, isTrue);
        // An Active=0 node row is still the node's, not a client.
        expect(result.allClients, isEmpty);
      });

      // The single-extender house with its extender powered off: DataElements
      // lists only the controller, and the extender's lingering Hosts row has
      // nothing to mark it as a node. Today it is not built as a node at all —
      // the gap the class doc of MeshNetworkBuilder names. The assertion is on
      // the slaves only: the lingering row is not active, so it is not listed
      // as a client either.
      test(
          'an agent DataElements no longer reports is not built (offline '
          'recovery deferred, #1688)', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: ConnectedDevices(items: [
            buildConnectedDevice(
              macAddress: 'AA:BB:CC:DD:EE:02',
              hostName: 'Extender',
              isActive: false,
            ),
          ]),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: MeshTopologyInfo(
            nodes: [buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01')],
            clientToNodeMap: const {},
          ),
          gatewayName: 'Router',
        );

        expect(result.slaves, isEmpty);
      });
    });

    // #1555 AC4 — the controller row's identity fields describe prplMesh, not
    // the product.
    //
    // Measured on the bench, `Device.WiFi.DataElements.Network.Device.1.` (the
    // controller's own row) reports the four strings asserted below. They are
    // not wrong data to be fixed upstream; they are prplMesh answering
    // truthfully about itself. `system_info` is the router describing the
    // *product* over the same session, so it wins for the master — and only for
    // the master, since a remote agent has no `system_info` to check against
    // (`_buildSlaveNode` deliberately keeps DataElements first).
    //
    // This was latent before #1555: `DataElementsNetwork.fetch()` threw on this
    // firmware, so `masterMeshInfo` was always null and nobody ever saw the
    // placeholders. Regenerating the definition is what makes the ordering
    // load-bearing, which is why it is pinned in the same change.
    group('master identity fields prefer system_info (#1555 AC4)', () {
      // Verbatim from the bench. `SoftwareVersion` is the prplMesh release
      // (2026.6.4), not the firmware build — the most misleading of the four,
      // since it looks like a plausible version number in the UI.
      const prplManufacturer = 'qcom';
      const prplModel = 'Qualcomm Technologies, Inc. IP';
      const prplSerial = 'prplmesh12345';
      const prplSoftware = '2026.6.4';

      ConnectedDevices masterOnly() => ConnectedDevices(items: [
            buildConnectedDevice(
              macAddress: 'AA:BB:CC:DD:EE:01',
              hostName: 'Router',
            ),
          ]);

      MeshTopologyInfo topologyWithPlaceholders() => MeshTopologyInfo(
            nodes: [
              buildMasterNode(
                deviceId: 'AA:BB:CC:DD:EE:01',
                model: prplModel,
                manufacturer: prplManufacturer,
                serialNumber: prplSerial,
                softwareVersion: prplSoftware,
              ),
            ],
            clientToNodeMap: const {},
          );

      test('system_info wins over the DataElements placeholders', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: masterOnly(),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: topologyWithPlaceholders(),
          gatewayName: 'Router',
          systemInfo: buildSystemInfo(),
        );

        expect(result.master.model, 'MR7500');
        expect(result.master.manufacturer, 'Linksys');
        expect(result.master.serialNumber, 'SN-REAL-12345');
        expect(result.master.softwareVersion, '2.0.1.216125');
      });

      test('none of the four placeholders reaches the master', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: masterOnly(),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: topologyWithPlaceholders(),
          gatewayName: 'Router',
          systemInfo: buildSystemInfo(),
        );

        // Asserted as a set rather than field-by-field so that adding a fifth
        // identity field without ordering it correctly reds this test too.
        final shown = {
          result.master.model,
          result.master.manufacturer,
          result.master.serialNumber,
          result.master.softwareVersion,
        };
        for (final placeholder in [
          prplManufacturer,
          prplModel,
          prplSerial,
          prplSoftware,
        ]) {
          expect(shown, isNot(contains(placeholder)),
              reason: '"$placeholder" is prplMesh describing itself and must '
                  'never reach node detail');
        }
      });

      // The reason the chain is `nonEmpty(...) ?? nonEmpty(...)` and not a bare
      // `??`. `system_info` fields are non-nullable Strings that are '' on a
      // router that did not answer them, and '' is a perfectly good value to
      // `??`, so a bare chain would show an empty model instead of falling
      // through — and an empty string is indistinguishable from "no data" on
      // screen, which is how this would ship unnoticed.
      test('an empty system_info field falls through to DataElements', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: masterOnly(),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: topologyWithPlaceholders(),
          gatewayName: 'Router',
          systemInfo: buildSystemInfo(
            modelName: '',
            manufacturer: '',
            serialNumber: '',
            softwareVersion: '',
          ),
        );

        // Placeholders are the wrong answer, but they are the only answer left;
        // the point here is that the `??` hole is closed, not that the values
        // are good.
        expect(result.master.model, prplModel);
        expect(result.master.manufacturer, prplManufacturer);
        expect(result.master.serialNumber, prplSerial);
        expect(result.master.softwareVersion, prplSoftware);
      });

      // And the reason the shared `nonEmpty` trims. A whitespace-only value is
      // non-empty, so it *wins* the `??` and lands a blank-looking model on the
      // master while the real value from DataElements is never consulted — the
      // same silent failure as the row above, one space further along. The
      // builder's own non-trimming copy of this guard let it through until #1555
      // replaced it with the shared one.
      test('a whitespace-only system_info field falls through too', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: masterOnly(),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: topologyWithPlaceholders(),
          gatewayName: 'Router',
          systemInfo: buildSystemInfo(
            modelName: ' ',
            manufacturer: '\t',
            serialNumber: '   ',
            softwareVersion: '\n',
          ),
        );

        expect(result.master.model, prplModel);
        expect(result.master.manufacturer, prplManufacturer);
        expect(result.master.serialNumber, prplSerial);
        expect(result.master.softwareVersion, prplSoftware);
      });

      // A real value keeps winning, padding and all — trimming is what the chain
      // decides on, not what it stores.
      test('a padded system_info field still wins, trimmed', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: masterOnly(),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: topologyWithPlaceholders(),
          gatewayName: 'Router',
          systemInfo: buildSystemInfo(modelName: '  MR7500 '),
        );

        expect(result.master.model, 'MR7500');
      });

      test('with neither source the fields are empty, never null', () {
        final result = MeshNetworkBuilder.build(
          connectedDevices: masterOnly(),
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: MeshTopologyInfo.empty,
          gatewayName: 'Router',
        );

        expect(result.master.model, isEmpty);
        expect(result.master.manufacturer, isEmpty);
        expect(result.master.serialNumber, isEmpty);
        expect(result.master.softwareVersion, isEmpty);
      });

      // The mirror image, and the reason the two builders differ. A slave has
      // no `system_info` of its own, so DataElements is the only source it has
      // — swapping `_buildSlaveNode`'s order to match the master's would leave
      // every extender's model blank.
      test('a slave still takes its model from DataElements', () {
        final connectedDevices = ConnectedDevices(items: [
          buildConnectedDevice(
            macAddress: 'AA:BB:CC:DD:EE:01',
            hostName: 'Router',
          ),
          buildConnectedDevice(
            macAddress: 'AA:BB:CC:DD:EE:02',
            hostName: 'Extender',
          ),
        ]);

        final result = MeshNetworkBuilder.build(
          connectedDevices: connectedDevices,
          wifiClientMap: {},
          connectionDetailMap: {},
          meshTopology: MeshTopologyInfo(
            nodes: [
              buildMasterNode(deviceId: 'AA:BB:CC:DD:EE:01'),
              buildSlaveNode(
                deviceId: 'AA:BB:CC:DD:EE:02',
                model: 'MX5500',
              ),
            ],
            clientToNodeMap: const {},
          ),
          gatewayName: 'Router',
          // Present, and describing the *router* — it must not leak onto the
          // extender.
          systemInfo: buildSystemInfo(),
        );

        expect(result.slaves.single.model, 'MX5500');
        expect(result.master.model, 'MR7500');
      });
    });

    // FL-WRT 2.0 serves a client's identity from devidentd under the
    // X_LINKSYS_ prefix (FWDEV#207). A leaf it has not identified reads "",
    // never absent, so "" is what has to fall back.
    group('client identity from X_LINKSYS_ leaves (#1693)', () {
      ClientDevice buildOne(ConnectedDevice host) => MeshNetworkBuilder.build(
            connectedDevices: ConnectedDevices(items: [host]),
            wifiClientMap: {},
            connectionDetailMap: {},
            meshTopology: MeshTopologyInfo.empty,
            gatewayName: 'Router',
          ).allClients.single;

      test('carries the firmware values onto the client', () {
        final client = buildOne(buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          hostName: 'iPhone',
          interface_: 'Device.WiFi.Radio.1',
          linksysManufacturer: 'Apple',
          linksysModelName: 'iPhone',
          linksysOperatingSystem: 'iOS',
          linksysDeviceType: 'Phone',
          linksysFriendlyName: "Austin's iPhone",
          linksysUserDeviceType: 'Tablet',
        ));

        expect(client.manufacturer, 'Apple');
        expect(client.modelName, 'iPhone');
        expect(client.operatingSystem, 'iOS');
        expect(client.deviceType, 'Phone');
        expect(client.userDeviceType, 'Tablet');
        expect(client.friendlyName, "Austin's iPhone");
        expect(client.displayName, "Austin's iPhone");
      });

      test('a leaf reading "" leaves the field null, so the name is HostName',
          () {
        final client = buildOne(buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          hostName: 'android-1a2b3c',
          interface_: 'Device.WiFi.Radio.1',
          linksysManufacturer: '',
          linksysModelName: '',
          linksysOperatingSystem: '',
          linksysDeviceType: '',
          linksysFriendlyName: '',
          linksysUserDeviceType: '',
        ));

        expect(client.manufacturer, isNull);
        expect(client.modelName, isNull);
        expect(client.operatingSystem, isNull);
        expect(client.deviceType, isNull);
        expect(client.userDeviceType, isNull);
        expect(client.friendlyName, isNull);
        expect(client.displayName, 'android-1a2b3c');
      });

      test('a host the firmware has not identified classifies as today', () {
        OuiLookup.initializeForTesting(const {'001422': 'Dell Inc.'});
        addTearDown(OuiLookup.reset);

        final client = buildOne(buildConnectedDevice(
          macAddress: '00:14:22:12:34:56',
          hostName: 'PlayStation5',
          interface_: 'Device.WiFi.Radio.1',
          linksysManufacturer: '',
          linksysDeviceType: '',
          linksysFriendlyName: '',
          linksysUserDeviceType: '',
        ));

        expect(DeviceClassifier.classifyClient(client),
            DeviceCategory.gameConsole);
        expect(DeviceClassifier.manufacturerOf(client), 'Dell Inc.');
      });

      // The detail page edits the name the user gave (#1691), which is not
      // FriendlyName: that is the firmware's pick of several names.
      test('carries the name the user gave, apart from FriendlyName', () {
        final client = buildOne(buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          interface_: 'Device.WiFi.Radio.1',
          linksysFriendlyName: 'Living room TV',
          linksysUserDeviceLocation: 'Living room TV',
        ));
        expect(client.userDeviceName, 'Living room TV');

        final unnamed = buildOne(buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          interface_: 'Device.WiFi.Radio.1',
          linksysFriendlyName: 'android-1a2b',
          linksysUserDeviceLocation: '',
        ));
        expect(unnamed.userDeviceName, isNull);
      });

      test('the unprefixed 1.0 leaves are not read', () {
        final client = buildOne(buildConnectedDevice(
          macAddress: '11:22:33:44:55:01',
          hostName: 'host',
          interface_: 'Device.WiFi.Radio.1',
          friendlyName: 'Old Name',
          manufacturer: 'Old Maker',
          modelName: 'Old Model',
          operatingSystem: 'Old OS',
        ));

        expect(client.friendlyName, isNull);
        expect(client.manufacturer, isNull);
        expect(client.modelName, isNull);
        expect(client.operatingSystem, isNull);
        expect(client.displayName, 'host');
      });
    });

    // The router's own name (#1691). The controller has no Hosts row, so its
    // name is on DeviceInfo, and only X_LINKSYS_UserDeviceLocation is written.
    // Measured on 2.0.3.26101472: writing the location leaves FriendlyName
    // "", so the app, not the firmware, puts the location first.
    group('master name from DeviceInfo (#1691)', () {
      MasterNode buildMaster(SystemInfoUIModel systemInfo) =>
          MeshNetworkBuilder.build(
            connectedDevices: const ConnectedDevices(items: []),
            wifiClientMap: {},
            connectionDetailMap: {},
            meshTopology: MeshTopologyInfo.empty,
            gatewayName: 'M60',
            systemInfo: systemInfo,
          ).master;

      test('the location the user gave is the name', () {
        final master = buildMaster(buildSystemInfo(
          userDeviceLocation: 'Office',
          friendlyName: 'Main router',
        ));
        expect(master.userDeviceLocation, 'Office');
        expect(master.displayName, 'Office');
      });

      test('with no location, DeviceInfo.FriendlyName is the name', () {
        final master =
            buildMaster(buildSystemInfo(friendlyName: 'Main router'));
        expect(master.userDeviceLocation, isNull);
        expect(master.displayName, 'Main router');
      });

      test('with neither, the name is what it is today', () {
        final master = buildMaster(buildSystemInfo(modelName: 'M60'));
        expect(master.displayName, 'M60');
      });
    });
  });
}
