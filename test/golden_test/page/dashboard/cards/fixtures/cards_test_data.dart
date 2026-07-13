import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/device_analytics_state.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

// ---------------------------------------------------------------------------
// System Info
// ---------------------------------------------------------------------------

const testSystemInfo = SystemInfoUIModel(
  manufacturer: 'Linksys',
  modelName: 'MR7500',
  serialNumber: 'ABC123456789',
  hardwareVersion: '1.0',
  softwareVersion: '1.0.16.215370',
  uptime: 300000,
  totalMemory: 524288,
  freeMemory: 204800,
  cpuUsage: 23,
);

final testSystemInfoData = SystemInfoData(model: testSystemInfo);

// ---------------------------------------------------------------------------
// Time Settings
// ---------------------------------------------------------------------------

const testTimeModel = TimeSettingsUIModel(
  enable: true,
  status: 'Synchronized',
  currentLocalTime: '2024-06-15T14:30:45-07:00',
  localTimeZone: 'America/Los_Angeles',
  ntpServer1: 'pool.ntp.org',
  ntpServer2: '',
);

final testTimeData = TimeData(model: testTimeModel);

const testTimeUnsyncModel = TimeSettingsUIModel(
  enable: true,
  status: 'Error',
  currentLocalTime: '2024-06-15T14:30:45-07:00',
  localTimeZone: 'America/Los_Angeles',
  ntpServer1: 'pool.ntp.org',
  ntpServer2: '',
);

final testTimeUnsyncData = TimeData(model: testTimeUnsyncModel);

// ---------------------------------------------------------------------------
// WAN Status
// ---------------------------------------------------------------------------

const testWanOnline = WanStatusUIModel(
  isUp: true,
  ipAddress: '203.0.113.42',
  subnetMask: '255.255.255.0',
  addressingType: 'DHCP',
  mtu: 1500,
  gateway: '203.0.113.1',
  ipv6Enabled: true,
  ipv6Addresses: ['2001:db8::1'],
);

const testWanOffline = WanStatusUIModel(
  isUp: false,
  ipAddress: '0.0.0.0',
  subnetMask: '0.0.0.0',
  addressingType: 'DHCP',
  mtu: 1500,
);

final testWanOnlineData = WanData(model: testWanOnline);
final testWanOfflineData = WanData(model: testWanOffline);

// ---------------------------------------------------------------------------
// LAN Info
// ---------------------------------------------------------------------------

const testLanDhcpEnabled = LanInfoUIModel(
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.200',
  leaseTimeMinutes: 1440,
  dnsServers: '8.8.8.8, 8.8.4.4',
  ipv6Enabled: true,
  ipv6Addresses: ['fd00::1'],
);

final testLanData = LanData(model: testLanDhcpEnabled);

const testLanDhcpDisabled = LanInfoUIModel(
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: false,
  minAddress: '',
  maxAddress: '',
  leaseTimeMinutes: 0,
  dnsServers: '',
  ipv6Enabled: false,
  ipv6Addresses: [],
);

final testLanDisabledData = LanData(model: testLanDhcpDisabled);

// ---------------------------------------------------------------------------
// Ethernet Ports
// ---------------------------------------------------------------------------

const testEthernetPorts = [
  EthernetPortUIModel(
    name: 'eth0',
    label: 'WAN',
    isWan: true,
    isUp: true,
    instancePath: 'Device.Ethernet.Interface.1.',
    currentBitRate: 1000,
    connectedDevices: [],
  ),
  EthernetPortUIModel(
    name: 'eth1',
    label: 'LAN 1',
    isWan: false,
    isUp: true,
    instancePath: 'Device.Ethernet.Interface.2.',
    currentBitRate: 1000,
    connectedDevices: [
      WiredDeviceInfo(
        hostName: 'Desktop-PC',
        macAddress: 'AA:BB:CC:DD:EE:01',
        ipAddress: '192.168.1.101',
      ),
    ],
  ),
  EthernetPortUIModel(
    name: 'eth2',
    label: 'LAN 2',
    isWan: false,
    isUp: true,
    instancePath: 'Device.Ethernet.Interface.3.',
    currentBitRate: 100,
    connectedDevices: [
      WiredDeviceInfo(
        hostName: 'NAS-Storage',
        macAddress: 'AA:BB:CC:DD:EE:02',
        ipAddress: '192.168.1.102',
      ),
      WiredDeviceInfo(
        hostName: 'Smart-TV',
        macAddress: 'AA:BB:CC:DD:EE:03',
        ipAddress: '192.168.1.103',
      ),
    ],
  ),
  EthernetPortUIModel(
    name: 'eth3',
    label: 'LAN 3',
    isWan: false,
    isUp: false,
    instancePath: 'Device.Ethernet.Interface.4.',
    currentBitRate: 0,
  ),
  EthernetPortUIModel(
    name: 'eth4',
    label: 'LAN 4',
    isWan: false,
    isUp: false,
    instancePath: 'Device.Ethernet.Interface.5.',
    currentBitRate: 0,
  ),
];

final testEthernetData = EthernetData(ethernetPortModels: testEthernetPorts);

// ---------------------------------------------------------------------------
// Connected Devices
// ---------------------------------------------------------------------------

final testDevices = [
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.101',
    hostName: 'Desktop-PC',
    isActive: true,
    connectionType: ConnectionType.wired,
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.102',
    hostName: 'iPhone-15',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(
      signalStrength: -45,
      band: '5GHz',
      ssidName: 'HomeNetwork',
    ),
    parentNodeName: 'MR7500',
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.103',
    hostName: 'MacBook-Air',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(
      signalStrength: -55,
      band: '5GHz',
      ssidName: 'HomeNetwork',
    ),
    parentNodeName: 'MR7500',
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:04',
    ip: '192.168.1.104',
    hostName: 'Smart-Speaker',
    isActive: true,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(
      signalStrength: -65,
      band: '2.4GHz',
      ssidName: 'HomeNetwork',
    ),
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:05',
    ip: '192.168.1.105',
    hostName: 'Gaming-Console',
    isActive: true,
    connectionType: ConnectionType.wired,
  ),
  ClientDevice(
    mac: 'AA:BB:CC:DD:EE:06',
    ip: '192.168.1.106',
    hostName: 'Old-Tablet',
    isActive: false,
    connectionType: ConnectionType.wifi,
    wifi: WifiConnectionInfo(
      signalStrength: -80,
      band: '2.4GHz',
    ),
  ),
];

final testMeshNetwork = MeshNetwork(
  master: MasterNode(
    deviceId: 'GATEWAY',
    model: 'MR7500',
    manufacturer: 'Linksys',
    serialNumber: 'ABC123456789',
    softwareVersion: '1.0.16',
    connectedClients: testDevices,
  ),
);

final testDevicesData = DevicesData(meshNetwork: testMeshNetwork);

final testDevicesEmptyData = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(
      deviceId: 'GATEWAY',
      model: 'MR7500',
      manufacturer: 'Linksys',
      serialNumber: 'ABC123456789',
      softwareVersion: '1.0.16',
      connectedClients: [],
    ),
  ),
);

// ---------------------------------------------------------------------------
// DHCP Reservations & Clients
// ---------------------------------------------------------------------------

final testDhcpReservations = [
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
    mac: 'AA:BB:CC:DD:EE:01',
    ip: '192.168.1.101',
    enable: true,
  ),
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.2.',
    mac: 'AA:BB:CC:DD:EE:05',
    ip: '192.168.1.105',
    enable: true,
  ),
  DhcpReservationUIModel(
    instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.3.',
    mac: 'AA:BB:CC:DD:EE:06',
    ip: '192.168.1.150',
    enable: false,
  ),
];

final testDhcpClients = [
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    ip: '192.168.1.102',
    leaseActive: true,
    isOnline: true,
    hostName: 'iPhone-15',
    leaseExpiry: DateTime(2024, 6, 16, 14, 30),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    ip: '192.168.1.103',
    leaseActive: true,
    isOnline: true,
    hostName: 'MacBook-Air',
    leaseExpiry: DateTime(2024, 6, 16, 10, 00),
  ),
  DhcpClientUIModel(
    mac: 'AA:BB:CC:DD:EE:04',
    ip: '192.168.1.104',
    leaseActive: true,
    isOnline: true,
    hostName: 'Smart-Speaker',
    leaseExpiry: DateTime(2024, 6, 16, 8, 00),
  ),
];

final testDhcpData = DhcpData(
  reservationModels: testDhcpReservations,
  clientModels: testDhcpClients,
);

final testDhcpEmptyData = DhcpData(
  reservationModels: const [],
  clientModels: const [],
);

// ---------------------------------------------------------------------------
// WiFi Data
// ---------------------------------------------------------------------------

const testRadios = [
  WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.1.',
    band: '2.4GHz',
    enable: true,
    transmitPower: -1,
    maxBitRate: 574,
    channel: 6,
    autoChannelEnable: false,
    channelBandwidth: '40MHz',
    supportedStandards: '802.11b/g/n/ax',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA2-Personal',
        encryptionMode: 'AES',
      ),
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork-Guest',
        securityMode: 'WPA2-Personal',
        encryptionMode: 'AES',
        isGuest: true,
      ),
    ],
  ),
  WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.2.',
    band: '5GHz',
    enable: true,
    transmitPower: -1,
    maxBitRate: 4804,
    channel: 36,
    autoChannelEnable: true,
    channelBandwidth: '160MHz',
    supportedStandards: '802.11a/n/ac/ax',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA3-Personal',
        encryptionMode: 'AES',
      ),
      WifiAccessPointUIModel(
        enable: false,
        ssidName: 'HomeNetwork-Guest',
        securityMode: 'WPA2-Personal',
        encryptionMode: 'AES',
        isGuest: true,
      ),
    ],
  ),
];

const testWifiClients = {
  'AA:BB:CC:DD:EE:02': WifiClientUIModel(
    macAddress: 'AA:BB:CC:DD:EE:02',
    signalStrength: -45,
    noise: -95,
    lastDataDownlinkRate: 866000,
    lastDataUplinkRate: 573000,
    active: true,
  ),
  'AA:BB:CC:DD:EE:03': WifiClientUIModel(
    macAddress: 'AA:BB:CC:DD:EE:03',
    signalStrength: -55,
    noise: -95,
    lastDataDownlinkRate: 720000,
    lastDataUplinkRate: 450000,
    active: true,
  ),
  'AA:BB:CC:DD:EE:04': WifiClientUIModel(
    macAddress: 'AA:BB:CC:DD:EE:04',
    signalStrength: -65,
    noise: -95,
    lastDataDownlinkRate: 144000,
    lastDataUplinkRate: 72000,
    active: true,
  ),
};

const testConnectionDetails = {
  'AA:BB:CC:DD:EE:02': ClientConnectionDetail(
    band: '5GHz',
    ssidName: 'HomeNetwork',
  ),
  'AA:BB:CC:DD:EE:03': ClientConnectionDetail(
    band: '5GHz',
    ssidName: 'HomeNetwork',
  ),
  'AA:BB:CC:DD:EE:04': ClientConnectionDetail(
    band: '2.4GHz',
    ssidName: 'HomeNetwork',
  ),
};

final testWifiData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: testRadios,
  wifiClientMap: testWifiClients,
  connectionDetailMap: testConnectionDetails,
);

final testWifiEmptyData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: const [],
  wifiClientMap: const {},
  connectionDetailMap: const {},
);

const testRadiosOneDisabled = [
  WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.1.',
    band: '2.4GHz',
    enable: true,
    transmitPower: -1,
    maxBitRate: 574,
    channel: 6,
    autoChannelEnable: false,
    channelBandwidth: '40MHz',
    supportedStandards: '802.11b/g/n/ax',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: true,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA2-Personal',
        encryptionMode: 'AES',
      ),
    ],
  ),
  WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.2.',
    band: '5GHz',
    enable: false,
    transmitPower: -1,
    maxBitRate: 4804,
    channel: 36,
    autoChannelEnable: true,
    channelBandwidth: '160MHz',
    supportedStandards: '802.11a/n/ac/ax',
    accessPoints: [
      WifiAccessPointUIModel(
        enable: false,
        ssidName: 'HomeNetwork',
        securityMode: 'WPA3-Personal',
        encryptionMode: 'AES',
      ),
    ],
  ),
];

final testWifiOneDisabledData = WifiData(
  codegenContext: WifiCodegenContext.empty,
  radioModels: testRadiosOneDisabled,
  wifiClientMap: testWifiClients,
  connectionDetailMap: testConnectionDetails,
);

// ---------------------------------------------------------------------------
// Port Forwarding & Triggering
// ---------------------------------------------------------------------------

const testPortForwardingRules = [
  PortForwardingRuleUIModel(
    instancePath: 'Device.NAT.PortMapping.1.',
    description: 'Web Server',
    externalPort: 8080,
    internalPort: 80,
    internalClient: '192.168.1.101',
    protocol: 'TCP',
    enabled: true,
  ),
  PortForwardingRuleUIModel(
    instancePath: 'Device.NAT.PortMapping.2.',
    description: 'Game Server',
    externalPort: 27015,
    internalPort: 27015,
    internalClient: '192.168.1.105',
    protocol: 'Both',
    enabled: true,
  ),
  PortForwardingRuleUIModel(
    instancePath: 'Device.NAT.PortMapping.3.',
    description: 'SSH Access',
    externalPort: 2222,
    internalPort: 22,
    internalClient: '192.168.1.101',
    protocol: 'TCP',
    enabled: false,
  ),
];

const testPortTriggeringRules = [
  PortTriggeringRuleUIModel(
    instancePath: 'Device.NAT.PortTrigger.1.',
    enabled: true,
    description: 'FTP Trigger',
    triggerPort: 21,
    triggerProtocol: 'TCP',
  ),
];

final testPortForwardingData =
    PortForwardingData(ruleModels: testPortForwardingRules);
final testPortTriggeringData =
    PortTriggeringData(ruleModels: testPortTriggeringRules);
final testPortForwardingEmptyData = PortForwardingData(ruleModels: const []);
final testPortTriggeringEmptyData = PortTriggeringData(ruleModels: const []);

// ---------------------------------------------------------------------------
// Firewall Data
// ---------------------------------------------------------------------------

final testFirewallData = FirewallData(
  firewallModel: const FirewallUIModel(
    isIPv4FirewallEnabled: true,
    isIPv6FirewallEnabled: true,
    blockIPSec: false,
    blockPPTP: false,
    blockL2TP: false,
    blockAnonymousRequests: true,
    blockMulticast: true,
    blockIDENT: false,
  ),
  ruleContext: FirewallRuleContext.empty,
  ruleSummaries: const [
    FirewallRuleSummary(target: 'DROP', enabled: true),
    FirewallRuleSummary(target: 'DROP', enabled: true),
    FirewallRuleSummary(target: 'ACCEPT', enabled: true),
    FirewallRuleSummary(target: 'DROP', enabled: false),
    FirewallRuleSummary(target: 'REJECT', enabled: true),
  ],
  dmzModel: const DmzUIModel.disabled(),
  dmzSummaries: const [
    DmzEntrySummary(enable: true, destIp: '192.168.1.200'),
  ],
);

final testFirewallEmptyData = FirewallData(
  firewallModel: const FirewallUIModel(
    isIPv4FirewallEnabled: false,
    isIPv6FirewallEnabled: false,
    blockIPSec: false,
    blockPPTP: false,
    blockL2TP: false,
    blockAnonymousRequests: false,
    blockMulticast: false,
    blockIDENT: false,
  ),
  ruleContext: FirewallRuleContext.empty,
  ruleSummaries: const [],
  dmzModel: const DmzUIModel.disabled(),
  dmzSummaries: const [],
);

// ---------------------------------------------------------------------------
// System Monitor
// ---------------------------------------------------------------------------

final _baseTime = DateTime(2024, 6, 15, 14, 0, 0);

final testSystemMonitorWithHistory = SystemMonitorState(
  history: List.generate(
    10,
    (i) => SystemSnapshot(
      timestamp: _baseTime.add(Duration(seconds: i * 10)),
      cpuPercent: 20 + (i * 3) % 40,
      memoryPercent: 55 + (i * 2) % 20,
      totalMemoryKb: 524288,
      freeMemoryKb: 234288 - i * 5000,
      uptimeSeconds: 86400 + i * 10,
    ),
  ),
  refreshInterval: Duration(seconds: 10),
);

const testSystemMonitorEmpty = SystemMonitorState();

// ---------------------------------------------------------------------------
// Traffic Analysis
// ---------------------------------------------------------------------------

final testTrafficWithHistory = TrafficAnalysisState(
  history: List.generate(
    10,
    (i) => MultiInterfaceSnapshot(
      timestamp: _baseTime.add(Duration(seconds: i * 5)),
      interfaces: {
        TrafficInterface.wan: InterfaceTrafficSnapshot(
          uploadBytesPerSec: 50000.0 + i * 10000,
          downloadBytesPerSec: 200000.0 + i * 30000,
          totalBytesSent: 5000000 + i * 50000,
          totalBytesReceived: 20000000 + i * 200000,
          totalPacketsSent: 5000 + i * 50,
          totalPacketsReceived: 20000 + i * 200,
          uploadPacketsPerSec: 50.0 + i * 5,
          downloadPacketsPerSec: 200.0 + i * 20,
          errorsSentPerSec: i * 0.05,
          errorsReceivedPerSec: i * 0.05,
        ),
        TrafficInterface.lan: InterfaceTrafficSnapshot(
          uploadBytesPerSec: 100000.0 + i * 20000,
          downloadBytesPerSec: 150000.0 + i * 15000,
          totalBytesSent: 10000000 + i * 100000,
          totalBytesReceived: 15000000 + i * 150000,
          totalPacketsSent: 10000 + i * 100,
          totalPacketsReceived: 15000 + i * 150,
          uploadPacketsPerSec: 100.0 + i * 10,
          downloadPacketsPerSec: 150.0 + i * 15,
        ),
      },
    ),
  ),
  refreshInterval: Duration(seconds: 5),
);

const testTrafficEmpty = TrafficAnalysisState();

// ---------------------------------------------------------------------------
// Device Analytics
// ---------------------------------------------------------------------------

final testDeviceAnalyticsWithData = DeviceAnalyticsState(
  current: DeviceDistribution(
    onlineCount: 5,
    offlineCount: 1,
    wifiCount: 3,
    wiredCount: 2,
    bandDistribution: const {'2.4GHz': 1, '5GHz': 2},
    bandSignalQuality: const {'2.4GHz': 0.6, '5GHz': 0.85, '6GHz': 0.0},
    signalLevelDistribution: const {3: 1, 2: 1, 1: 1},
  ),
  hourlyHistory: List.generate(
    12,
    (i) => HourlyAggregate(
      hour: _baseTime.subtract(Duration(hours: 11 - i)),
      wifiCount: 2 + (i % 3),
      wiredCount: 2,
      activeMacs: {'AA:BB:CC:DD:EE:02', 'AA:BB:CC:DD:EE:03'},
    ),
  ),
  allKnownMacs: const {'AA:BB:CC:DD:EE:02', 'AA:BB:CC:DD:EE:03'},
  macDisplayNames: const {
    'AA:BB:CC:DD:EE:02': 'iPhone-15',
    'AA:BB:CC:DD:EE:03': 'MacBook-Air',
  },
);

const testDeviceAnalyticsEmpty = DeviceAnalyticsState();
