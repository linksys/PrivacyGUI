import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_state.dart';

const csDiagnosticLoadedState = CsDiagnosticState(
  loadState: DiagnosticLoadState.loaded,
  clients: [
    DiagnosticClient(
      macAddress: '00:11:22:33:44:55',
      hostname: 'iPhone',
      ipAddress: '192.168.1.100',
      band: '5GHz',
      signalDecibels: -45,
      txRateMbps: 200,
      rxRateMbps: 150,
      isWireless: true,
    ),
    DiagnosticClient(
      macAddress: '00:11:22:33:44:56',
      hostname: 'MacBook Pro',
      ipAddress: '192.168.1.101',
      band: '5GHz',
      signalDecibels: -38,
      txRateMbps: 300,
      rxRateMbps: 250,
      isWireless: true,
    ),
    DiagnosticClient(
      macAddress: '00:11:22:33:44:57',
      hostname: 'Desktop PC',
      ipAddress: '192.168.1.102',
      band: 'Wired',
      signalDecibels: null,
      txRateMbps: null,
      rxRateMbps: null,
      isWireless: false,
    ),
  ],
  wanStatus: {
    'wanStatus': 'Connected',
    'wanConnection': {
      'ipAddress': '203.178.141.194',
      'connectionType': 'DHCP',
    },
  },
  routerHealth: {
    'uptimeInSeconds': 86400,
    'cpuLoad': 15,
    'memoryLoad': 45,
  },
  deviceInfo: {
    'modelNumber': 'MR9600',
    'firmwareVersion': '1.2.9.208',
    'serialNumber': 'ABC123456',
  },
  dhcpLeasesCount: 8,
  dhcpPoolLimit: 150,
  radioInfo: {
    'isBandSteeringSupported': true,
    'radios': [
      {
        'band': '2.4GHz',
        'channel': 6,
        'channelWidth': '40MHz',
        'mode': '802.11n',
      },
      {
        'band': '5GHz',
        'channel': 149,
        'channelWidth': '80MHz',
        'mode': '802.11ac',
      },
    ],
  },
  guestNetwork: {
    'isGuestNetworkEnabled': false,
  },
  firmwareUpdate: {
    'firmwareUpdateStatus': 'NoUpdateAvailable',
  },
);

const csDiagnosticDegradedState = CsDiagnosticState(
  loadState: DiagnosticLoadState.loaded,
  clients: [
    DiagnosticClient(
      macAddress: '00:11:22:33:44:55',
      hostname: 'iPhone',
      ipAddress: '192.168.1.100',
      band: '2.4GHz',
      signalDecibels: -75, // Poor signal
      txRateMbps: 24,
      rxRateMbps: 18,
      isWireless: true,
    ),
    DiagnosticClient(
      macAddress: '00:11:22:33:44:56',
      hostname: 'Android Phone',
      ipAddress: '192.168.1.101',
      band: '2.4GHz',
      signalDecibels: -80, // Very poor signal
      txRateMbps: 11,
      rxRateMbps: 6,
      isWireless: true,
    ),
    DiagnosticClient(
      macAddress: '00:11:22:33:44:57',
      hostname: 'Laptop',
      ipAddress: '192.168.1.102',
      band: '5GHz',
      signalDecibels: -72, // Marginal signal
      txRateMbps: 65,
      rxRateMbps: 48,
      isWireless: true,
    ),
  ],
  wanStatus: {
    'wanStatus': 'Connected',
    'wanConnection': {
      'ipAddress': '203.178.141.194',
      'connectionType': 'DHCP',
    },
  },
  routerHealth: {
    'uptimeInSeconds': 3600, // Recently rebooted
    'cpuLoad': 85, // High CPU
    'memoryLoad': 78, // High memory
  },
  deviceInfo: {
    'modelNumber': 'MR9600',
    'firmwareVersion': '1.2.8.205', // Old firmware
    'serialNumber': 'ABC123456',
  },
  dhcpLeasesCount: 135, // Near capacity
  dhcpPoolLimit: 150,
  radioInfo: {
    'isBandSteeringSupported': true,
    'radios': [
      {
        'band': '2.4GHz',
        'channel': 1, // Congested channel
        'channelWidth': '20MHz',
        'mode': '802.11n',
      },
      {
        'band': '5GHz',
        'channel': 36, // Lower 5GHz channel
        'channelWidth': '40MHz',
        'mode': '802.11ac',
      },
    ],
  },
  guestNetwork: {
    'isGuestNetworkEnabled': true,
  },
  firmwareUpdate: {
    'firmwareUpdateStatus': 'UpdateAvailable',
    'availableUpdate': {
      'firmwareVersion': '1.2.9.208',
    },
  },
  backhaulInfo: {
    'backhaulDevices': [
      {
        'deviceID': 'Node-123456',
        'connectionType': 'Wireless',
        'speedMbps': 150,
      },
    ],
  },
);