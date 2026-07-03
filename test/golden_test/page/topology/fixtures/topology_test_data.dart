import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';

// ---------------------------------------------------------------------------
// System Info
// ---------------------------------------------------------------------------

const _testSystemInfo = SystemInfoUIModel(
  manufacturer: 'Linksys',
  modelName: 'MR7500',
  serialNumber: 'ABC123456',
  hardwareVersion: '1.0',
  softwareVersion: '1.0.16.215118',
  uptime: 86400,
  totalMemory: 524288,
  freeMemory: 262144,
  cpuUsage: 25,
);

final testSystemInfoData = SystemInfoData(model: _testSystemInfo);

// ---------------------------------------------------------------------------
// Devices
// ---------------------------------------------------------------------------

final _testClients = [
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -45, band: '5GHz'),
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'MacBook Pro',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -55, band: '5GHz'),
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    hostName: 'Desktop PC',
    isActive: true,
    connectionType: ConnectionType.wired,
  ),
];

final _meshMasterClients = [
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -45, band: '5GHz'),
    parentNodeId: '11:22:33:44:55:66',
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'MacBook Pro',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(signalStrength: -55, band: '5GHz'),
    parentNodeId: '11:22:33:44:55:66',
  ),
];

final _meshSlaveClients = [
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    hostName: 'Desktop PC',
    isActive: true,
    connectionType: ConnectionType.wired,
    parentNodeId: 'AA:BB:CC:DD:FF:01',
  ),
];

// ---------------------------------------------------------------------------
// Topology View States
// ---------------------------------------------------------------------------

final singleNodeDevicesData = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(
      deviceId: 'gateway',
      model: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'ABC123456',
      softwareVersion: '1.0.16.215118',
      connectedClients: _testClients,
    ),
  ),
);

final meshNetworkDevicesData = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(
      deviceId: '11:22:33:44:55:66',
      model: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'ABC123456',
      softwareVersion: '1.0.16.215118',
      connectedClients: _meshMasterClients,
    ),
    slaves: [
      SlaveNode(
        deviceId: 'AA:BB:CC:DD:FF:01',
        model: 'MX2000',
        manufacturer: 'Linksys',
        serialNumber: 'DEF789012',
        softwareVersion: '1.0.10.200000',
        connectedClients: _meshSlaveClients,
        backhaul: BackhaulInfo(mediaType: 'Wi-Fi', signalStrength: -50),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Node Detail States
// ---------------------------------------------------------------------------

final masterNodeWithDevices = UspNodeDetailState(
  node: MasterNode(
    deviceId: '11:22:33:44:55:66',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456',
    softwareVersion: '1.0.16.215118',
    connectedClients: _meshMasterClients,
  ),
  connectedClients: _meshMasterClients,
);

final slaveNodeWithDevices = UspNodeDetailState(
  node: SlaveNode(
    deviceId: 'AA:BB:CC:DD:FF:01',
    model: 'MX2000',
    manufacturer: 'Linksys',
    serialNumber: 'DEF789012',
    softwareVersion: '1.0.10.200000',
    connectedClients: _meshSlaveClients,
    backhaul: BackhaulInfo(mediaType: 'Wi-Fi', signalStrength: -50),
  ),
  connectedClients: _meshSlaveClients,
);

final masterNodeEmptyDevices = UspNodeDetailState(
  node: MasterNode(
    deviceId: '11:22:33:44:55:66',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456',
    softwareVersion: '1.0.16.215118',
    connectedClients: [],
  ),
  connectedClients: [],
);

const nodeNotFoundState = UspNodeDetailState();
