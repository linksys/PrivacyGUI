import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
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

const _testDevices = [
  DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    isWifi: true,
    signalStrength: -45,
    band: '5GHz',
    parentNodeId: null,
  ),
  DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'MacBook Pro',
    isActive: true,
    isWifi: true,
    signalStrength: -55,
    band: '5GHz',
    parentNodeId: null,
  ),
  DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    hostName: 'Desktop PC',
    isActive: true,
    isWifi: false,
    parentNodeId: null,
  ),
];

const _meshDevices = [
  DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.100',
    hostName: 'iPhone',
    isActive: true,
    isWifi: true,
    signalStrength: -45,
    band: '5GHz',
    parentNodeId: '11:22:33:44:55:66',
  ),
  DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.101',
    hostName: 'MacBook Pro',
    isActive: true,
    isWifi: true,
    signalStrength: -55,
    band: '5GHz',
    parentNodeId: '11:22:33:44:55:66',
  ),
  DeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.102',
    hostName: 'Desktop PC',
    isActive: true,
    isWifi: false,
    parentNodeId: 'AA:BB:CC:DD:FF:01',
  ),
];

// ---------------------------------------------------------------------------
// Topology View States
// ---------------------------------------------------------------------------

final singleNodeDevicesData = DevicesData(
  deviceModels: _testDevices,
  nodeModels: const [
    NodeUIModel(
      deviceId: 'gateway',
      model: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'ABC123456',
      softwareVersion: '1.0.16.215118',
      isMaster: true,
      connectedDeviceCount: 3,
    ),
  ],
  meshTopology: MeshTopologyInfo.empty,
);

final meshNetworkDevicesData = DevicesData(
  deviceModels: _meshDevices,
  nodeModels: const [
    NodeUIModel(
      deviceId: '11:22:33:44:55:66',
      model: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'ABC123456',
      softwareVersion: '1.0.16.215118',
      isMaster: true,
      connectedDeviceCount: 2,
    ),
    NodeUIModel(
      deviceId: 'AA:BB:CC:DD:FF:01',
      model: 'MX2000',
      manufacturer: 'Linksys',
      serialNumber: 'DEF789012',
      softwareVersion: '1.0.10.200000',
      isMaster: false,
      connectedDeviceCount: 1,
    ),
  ],
  meshTopology: const MeshTopologyInfo(
    nodes: [
      NodeUIModel(
        deviceId: '11:22:33:44:55:66',
        model: 'MR7500',
        manufacturer: 'Linksys',
        serialNumber: 'ABC123456',
        softwareVersion: '1.0.16.215118',
        isMaster: true,
        connectedDeviceCount: 2,
        instancePath: 'Device.DeviceInfo.1.',
      ),
      NodeUIModel(
        deviceId: 'AA:BB:CC:DD:FF:01',
        model: 'MX2000',
        manufacturer: 'Linksys',
        serialNumber: 'DEF789012',
        softwareVersion: '1.0.10.200000',
        isMaster: false,
        connectedDeviceCount: 1,
        instancePath: 'Device.DeviceInfo.2.',
      ),
    ],
    clientToNodeMap: {
      'AA:BB:CC:DD:EE:01': '11:22:33:44:55:66',
      'AA:BB:CC:DD:EE:02': '11:22:33:44:55:66',
      'AA:BB:CC:DD:EE:03': 'AA:BB:CC:DD:FF:01',
    },
  ),
);

// ---------------------------------------------------------------------------
// Node Detail States
// ---------------------------------------------------------------------------

const masterNodeWithDevices = UspNodeDetailState(
  node: NodeUIModel(
    deviceId: '11:22:33:44:55:66',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456',
    softwareVersion: '1.0.16.215118',
    isMaster: true,
    connectedDeviceCount: 2,
  ),
  connectedDevices: [
    DeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01',
      ip: '192.168.1.100',
      hostName: 'iPhone',
      isActive: true,
      isWifi: true,
      signalStrength: -45,
      band: '5GHz',
    ),
    DeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:02',
      ip: '192.168.1.101',
      hostName: 'MacBook Pro',
      isActive: true,
      isWifi: true,
      signalStrength: -55,
      band: '5GHz',
    ),
  ],
);

const slaveNodeWithDevices = UspNodeDetailState(
  node: NodeUIModel(
    deviceId: 'AA:BB:CC:DD:FF:01',
    model: 'MX2000',
    manufacturer: 'Linksys',
    serialNumber: 'DEF789012',
    softwareVersion: '1.0.10.200000',
    isMaster: false,
    connectedDeviceCount: 1,
  ),
  connectedDevices: [
    DeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:03',
      ip: '192.168.1.102',
      hostName: 'Desktop PC',
      isActive: true,
      isWifi: false,
    ),
  ],
);

const masterNodeEmptyDevices = UspNodeDetailState(
  node: NodeUIModel(
    deviceId: '11:22:33:44:55:66',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456',
    softwareVersion: '1.0.16.215118',
    isMaster: true,
    connectedDeviceCount: 0,
  ),
  connectedDevices: [],
);

const nodeNotFoundState = UspNodeDetailState(
  node: null,
  connectedDevices: [],
);
