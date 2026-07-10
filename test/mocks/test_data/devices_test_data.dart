import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

/// Test data builder for device/mesh network tests.
///
/// Provides factory methods to create test instances with sensible defaults.
/// Centralizes test data creation to avoid inline construction duplication.
class DevicesTestData {
  // ===========================================================================
  // Constants
  // ===========================================================================

  static const masterMac = 'AA:BB:CC:DD:EE:00';
  static const slaveMac1 = 'AA:BB:CC:DD:EE:01';
  static const slaveMac2 = 'AA:BB:CC:DD:EE:02';

  static const clientMac1 = '11:22:33:44:55:01';
  static const clientMac2 = '11:22:33:44:55:02';
  static const clientMac3 = '11:22:33:44:55:03';
  static const clientMac4 = '11:22:33:44:55:04';
  static const clientMac5 = '11:22:33:44:55:05';

  static const masterIp = '192.168.1.1';
  static const clientIp1 = '192.168.1.101';
  static const clientIp2 = '192.168.1.102';
  static const clientIp3 = '192.168.1.103';

  static const defaultModel = 'MR7500';
  static const defaultManufacturer = 'Linksys';
  static const defaultSerialNumber = 'SN123456789';
  static const defaultSoftwareVersion = '1.0.16.26013014';

  // ===========================================================================
  // WifiConnectionInfo Factories
  // ===========================================================================

  static WifiConnectionInfo createWifiInfo({
    int? signalStrength = -50,
    String? band = '5GHz',
    String? ssidName = 'HomeNetwork',
    int? downlinkRate = 866000,
    int? uplinkRate = 433000,
  }) =>
      WifiConnectionInfo(
        signalStrength: signalStrength,
        band: band,
        ssidName: ssidName,
        downlinkRate: downlinkRate,
        uplinkRate: uplinkRate,
      );

  static WifiConnectionInfo createExcellentSignal() => createWifiInfo(
        signalStrength: -45,
        band: '5GHz',
      );

  static WifiConnectionInfo createGoodSignal() => createWifiInfo(
        signalStrength: -68,
        band: '5GHz',
      );

  static WifiConnectionInfo createFairSignal() => createWifiInfo(
        signalStrength: -75,
        band: '2.4GHz',
      );

  static WifiConnectionInfo createPoorSignal() => createWifiInfo(
        signalStrength: -85,
        band: '2.4GHz',
      );

  // ===========================================================================
  // BackhaulInfo Factories
  // ===========================================================================

  static BackhaulInfo createWifiBackhaul({
    int signalStrength = -55,
    String parentNodeId = masterMac,
  }) =>
      BackhaulInfo(
        mediaType: 'IEEE 802.11ax',
        linkType: 'Wi-Fi',
        phyRate: 2402,
        signalStrength: signalStrength,
        uplinkRate: 500000,
        downlinkRate: 1000000,
        parentNodeId: parentNodeId,
      );

  static BackhaulInfo createEthernetBackhaul({
    String parentNodeId = masterMac,
  }) =>
      BackhaulInfo(
        mediaType: 'Ethernet',
        linkType: 'Ethernet',
        phyRate: 1000,
        parentNodeId: parentNodeId,
      );

  static const emptyBackhaul = BackhaulInfo(mediaType: '');

  // ===========================================================================
  // ClientInterfaceInfo Factories
  // ===========================================================================

  static ClientInterfaceInfo createWifiInterface({
    String mac = '11:22:33:44:55:FF',
    String ip = '192.168.1.150',
    bool isActive = true,
    WifiConnectionInfo? wifi,
  }) =>
      ClientInterfaceInfo(
        mac: mac,
        ip: ip,
        connectionType: ConnectionType.wifi,
        isActive: isActive,
        wifi: wifi ?? createWifiInfo(),
      );

  static ClientInterfaceInfo createWiredInterface({
    String mac = '11:22:33:44:55:FE',
    String ip = '192.168.1.151',
    bool isActive = true,
  }) =>
      ClientInterfaceInfo(
        mac: mac,
        ip: ip,
        connectionType: ConnectionType.wired,
        isActive: isActive,
      );

  // ===========================================================================
  // ClientDevice Factories
  // ===========================================================================

  /// Creates an online WiFi client device.
  static ClientDevice createWifiClient({
    String mac = clientMac1,
    String ip = clientIp1,
    String hostName = 'MacBook-Pro',
    String? friendlyName,
    bool isActive = true,
    WifiConnectionInfo? wifi,
    String? parentNodeId,
    String? parentNodeName,
    List<ClientInterfaceInfo> additionalInterfaces = const [],
  }) =>
      ClientDevice(
        mac: mac,
        ip: ip,
        hostName: hostName,
        friendlyName: friendlyName,
        isActive: isActive,
        connectionType: ConnectionType.wifi,
        wifi: wifi ?? createWifiInfo(),
        parentNodeId: parentNodeId,
        parentNodeName: parentNodeName,
        additionalInterfaces: additionalInterfaces,
      );

  /// Creates an online wired client device.
  static ClientDevice createWiredClient({
    String mac = clientMac2,
    String ip = clientIp2,
    String hostName = 'Desktop-PC',
    String? friendlyName,
    bool isActive = true,
    String? parentNodeId,
    String? parentNodeName,
    List<ClientInterfaceInfo> additionalInterfaces = const [],
  }) =>
      ClientDevice(
        mac: mac,
        ip: ip,
        hostName: hostName,
        friendlyName: friendlyName,
        isActive: isActive,
        connectionType: ConnectionType.wired,
        parentNodeId: parentNodeId,
        parentNodeName: parentNodeName,
        additionalInterfaces: additionalInterfaces,
      );

  /// Creates an offline client device.
  static ClientDevice createOfflineClient({
    String mac = clientMac3,
    String ip = clientIp3,
    String hostName = 'Offline-Device',
    ConnectionType connectionType = ConnectionType.wifi,
  }) =>
      ClientDevice(
        mac: mac,
        ip: ip,
        hostName: hostName,
        isActive: false,
        connectionType: connectionType,
      );

  /// Creates a client with multiple network interfaces.
  static ClientDevice createMultiInterfaceClient({
    String mac = clientMac4,
    String ip = '192.168.1.104',
    String hostName = 'Multi-Interface-Device',
    bool isActive = true,
    List<ClientInterfaceInfo>? additionalInterfaces,
  }) =>
      ClientDevice(
        mac: mac,
        ip: ip,
        hostName: hostName,
        isActive: isActive,
        connectionType: ConnectionType.wifi,
        wifi: createWifiInfo(),
        additionalInterfaces: additionalInterfaces ??
            [
              createWiredInterface(
                mac: '${mac.substring(0, 14)}:FE',
                ip: '192.168.1.204',
              ),
            ],
      );

  /// Creates a client connected to a slave (extender) node.
  static ClientDevice createSlaveConnectedClient({
    String mac = clientMac5,
    String ip = '192.168.1.105',
    String hostName = 'Extender-Client',
    String parentNodeId = slaveMac1,
    String parentNodeName = 'Extender-1',
    bool isWifi = true,
    bool isActive = true,
  }) =>
      ClientDevice(
        mac: mac,
        ip: ip,
        hostName: hostName,
        isActive: isActive,
        connectionType: isWifi ? ConnectionType.wifi : ConnectionType.wired,
        wifi: isWifi ? createWifiInfo() : null,
        parentNodeId: parentNodeId,
        parentNodeName: parentNodeName,
      );

  // ===========================================================================
  // NodeEntity Factories
  // ===========================================================================

  /// Creates a master (gateway) node.
  static MasterNode createMaster({
    String deviceId = masterMac,
    String? dataElementsId,
    String? friendlyName,
    String? hostName = 'Linksys-Router',
    String model = defaultModel,
    String manufacturer = defaultManufacturer,
    String serialNumber = defaultSerialNumber,
    String softwareVersion = defaultSoftwareVersion,
    String? ipAddress = masterIp,
    List<ClientDevice> connectedClients = const [],
    String? wanIpAddress = '100.64.1.100',
    String? hostsDeviceId,
  }) =>
      MasterNode(
        deviceId: deviceId,
        dataElementsId: dataElementsId,
        friendlyName: friendlyName,
        hostName: hostName,
        model: model,
        manufacturer: manufacturer,
        serialNumber: serialNumber,
        softwareVersion: softwareVersion,
        ipAddress: ipAddress,
        connectedClients: connectedClients,
        wanIpAddress: wanIpAddress,
        hostsDeviceId: hostsDeviceId,
      );

  /// Creates a slave (extender) node with WiFi backhaul.
  static SlaveNode createWifiSlave({
    String deviceId = slaveMac1,
    String? dataElementsId,
    String? friendlyName,
    String? hostName = 'Extender-1',
    String model = defaultModel,
    String? ipAddress = '192.168.1.2',
    List<ClientDevice> connectedClients = const [],
    BackhaulInfo? backhaul,
  }) =>
      SlaveNode(
        deviceId: deviceId,
        dataElementsId: dataElementsId,
        friendlyName: friendlyName,
        hostName: hostName,
        model: model,
        manufacturer: defaultManufacturer,
        ipAddress: ipAddress,
        connectedClients: connectedClients,
        backhaul: backhaul ?? createWifiBackhaul(),
      );

  /// Creates a slave (extender) node with Ethernet backhaul.
  static SlaveNode createEthernetSlave({
    String deviceId = slaveMac2,
    String? dataElementsId,
    String? friendlyName,
    String? hostName = 'Extender-2',
    String model = defaultModel,
    String? ipAddress = '192.168.1.3',
    List<ClientDevice> connectedClients = const [],
  }) =>
      SlaveNode(
        deviceId: deviceId,
        dataElementsId: dataElementsId,
        friendlyName: friendlyName,
        hostName: hostName,
        model: model,
        manufacturer: defaultManufacturer,
        ipAddress: ipAddress,
        connectedClients: connectedClients,
        backhaul: createEthernetBackhaul(),
      );

  // ===========================================================================
  // MeshNetwork Factories
  // ===========================================================================

  /// Creates a simple single-node (non-mesh) network.
  static MeshNetwork createSingleNodeNetwork({
    MasterNode? master,
    List<ClientDevice>? masterClients,
  }) {
    final clients = masterClients ??
        [
          createWifiClient(),
          createWiredClient(),
        ];
    return MeshNetwork(
      master: master?.copyWith(connectedClients: clients) ??
          createMaster(connectedClients: clients),
    );
  }

  /// Creates a mesh network with one master and one WiFi slave.
  static MeshNetwork createMeshNetwork({
    MasterNode? master,
    List<ClientDevice>? masterClients,
    SlaveNode? slave,
    List<ClientDevice>? slaveClients,
  }) {
    final mClients = masterClients ?? [createWifiClient()];
    final sClients = slaveClients ??
        [
          createSlaveConnectedClient(),
        ];

    return MeshNetwork(
      master: master?.copyWith(connectedClients: mClients) ??
          createMaster(connectedClients: mClients),
      slaves: [
        slave?.copyWith(connectedClients: sClients) ??
            createWifiSlave(connectedClients: sClients),
      ],
    );
  }

  /// Creates a multi-slave mesh network.
  static MeshNetwork createMultiSlaveMeshNetwork({
    List<ClientDevice>? masterClients,
    List<ClientDevice>? slave1Clients,
    List<ClientDevice>? slave2Clients,
  }) {
    return MeshNetwork(
      master: createMaster(
        connectedClients: masterClients ?? [createWifiClient()],
      ),
      slaves: [
        createWifiSlave(
          deviceId: slaveMac1,
          hostName: 'Extender-1',
          connectedClients: slave1Clients ??
              [
                createSlaveConnectedClient(
                  mac: clientMac3,
                  parentNodeId: slaveMac1,
                  parentNodeName: 'Extender-1',
                ),
              ],
        ),
        createEthernetSlave(
          deviceId: slaveMac2,
          hostName: 'Extender-2',
          connectedClients: slave2Clients ??
              [
                createSlaveConnectedClient(
                  mac: clientMac4,
                  parentNodeId: slaveMac2,
                  parentNodeName: 'Extender-2',
                ),
              ],
        ),
      ],
    );
  }

  /// Creates an empty network (master only, no clients).
  static MeshNetwork createEmptyNetwork() => MeshNetwork(
        master: createMaster(connectedClients: []),
      );

  /// Creates a network with unassigned clients.
  static MeshNetwork createNetworkWithUnassignedClients({
    List<ClientDevice>? unassignedClients,
  }) =>
      MeshNetwork(
        master: createMaster(connectedClients: []),
        unassignedClients: unassignedClients ??
            [
              createWifiClient(parentNodeId: null),
              createWiredClient(parentNodeId: null),
            ],
      );

  // ===========================================================================
  // DevicesData Factories
  // ===========================================================================

  /// Creates a complete DevicesData instance.
  static DevicesData createDevicesData({
    MeshNetwork? meshNetwork,
    MeshTopologyInfo meshTopology = MeshTopologyInfo.empty,
    Map<String, String>? hostNameByMac,
  }) =>
      DevicesData(
        codegenContext: DevicesCodegenContext.empty,
        meshTopology: meshTopology,
        hostNameByMac: hostNameByMac ?? {},
        meshNetwork: meshNetwork ?? createSingleNodeNetwork(),
      );

  /// Creates DevicesData with a simple single-node network.
  static DevicesData createSimpleDevicesData() => createDevicesData(
        meshNetwork: createSingleNodeNetwork(),
      );

  /// Creates DevicesData with a mesh network.
  static DevicesData createMeshDevicesData() => createDevicesData(
        meshNetwork: createMeshNetwork(),
      );

  // ===========================================================================
  // Client Device Lists (for filter/list tests)
  // ===========================================================================

  /// Creates a mixed list of online and offline devices.
  static List<ClientDevice> createMixedClientList() => [
        createWifiClient(mac: clientMac1, isActive: true),
        createWiredClient(mac: clientMac2, isActive: true),
        createOfflineClient(mac: clientMac3),
        createWifiClient(mac: clientMac4, isActive: false),
      ];

  /// Creates a list of devices with different signal strengths.
  static List<ClientDevice> createSignalVarietyList() => [
        createWifiClient(
          mac: '11:22:33:44:55:E1',
          wifi: createExcellentSignal(),
        ),
        createWifiClient(
          mac: '11:22:33:44:55:E2',
          wifi: createGoodSignal(),
        ),
        createWifiClient(
          mac: '11:22:33:44:55:E3',
          wifi: createFairSignal(),
        ),
        createWifiClient(
          mac: '11:22:33:44:55:E4',
          wifi: createPoorSignal(),
        ),
      ];
}
