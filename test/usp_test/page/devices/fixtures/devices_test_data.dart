import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';

const wifiDevice1 = DeviceUIModel(
  mac: 'AA:BB:CC:DD:EE:01',
  ip: '192.168.1.100',
  hostName: 'iPhone-15-Pro',
  isActive: true,
  isWifi: true,
  signalStrength: -42,
  downlinkRate: 866000000,
  uplinkRate: 433000000,
  band: '5GHz',
  ssidName: 'MyNetwork',
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

const wifiDeviceGood = DeviceUIModel(
  mac: 'AA:BB:CC:DD:EE:02',
  ip: '192.168.1.101',
  hostName: 'MacBook-Air',
  isActive: true,
  isWifi: true,
  signalStrength: -68,
  downlinkRate: 400000000,
  uplinkRate: 200000000,
  band: '5GHz',
  ssidName: 'MyNetwork',
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

const wiredDevice1 = DeviceUIModel(
  mac: 'AA:BB:CC:DD:EE:03',
  ip: '192.168.1.102',
  hostName: 'PlayStation-5',
  isActive: true,
  isWifi: false,
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

const offlineDevice = DeviceUIModel(
  mac: 'AA:BB:CC:DD:EE:04',
  ip: '192.168.1.103',
  hostName: 'iPad-Mini',
  isActive: false,
  isWifi: true,
);

const wifiDeviceFair = DeviceUIModel(
  mac: 'AA:BB:CC:DD:EE:05',
  ip: '192.168.1.104',
  hostName: 'Samsung-TV',
  isActive: true,
  isWifi: true,
  signalStrength: -75,
  downlinkRate: 72000000,
  uplinkRate: 36000000,
  band: '2.4GHz',
  ssidName: 'MyNetwork',
  parentNodeId: 'node-2',
  parentNodeName: 'Bedroom',
);

const wifiDevicePoor = DeviceUIModel(
  mac: 'AA:BB:CC:DD:EE:06',
  ip: '192.168.1.105',
  hostName: 'Nest-Cam-Outdoor',
  isActive: true,
  isWifi: true,
  signalStrength: -82,
  downlinkRate: 24000000,
  uplinkRate: 12000000,
  band: '2.4GHz',
  ssidName: 'MyNetwork',
  parentNodeId: 'node-2',
  parentNodeName: 'Bedroom',
);

const testReservation = DhcpReservationUIModel(
  instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
  mac: 'AA:BB:CC:DD:EE:01',
  ip: '192.168.1.100',
  enable: true,
);

List<DeviceUIModel> get allDevices => [
      wifiDevice1,
      wifiDeviceGood,
      wiredDevice1,
      offlineDevice,
      wifiDeviceFair,
      wifiDevicePoor,
    ];

DeviceDetailState get wifiDetailWithReservation => DeviceDetailState(
      device: wifiDevice1,
      reservation: testReservation,
    );

DeviceDetailState get wifiDetailNoReservation => DeviceDetailState(
      device: wifiDeviceGood,
    );

DeviceDetailState get wiredDetail => DeviceDetailState(
      device: wiredDevice1,
    );

DeviceDetailState get offlineDetail => DeviceDetailState(
      device: offlineDevice,
    );

DeviceDetailState get deviceNotFound => DeviceDetailState.empty();
