import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';

final wifiDevice1 = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:01',
  ip: '192.168.1.100',
  hostName: 'iPhone-15-Pro',
  isActive: true,
  connectionType: ConnectionType.wifi,
  wifi: WifiConnectionInfo(
    signalStrength: -42,
    downlinkRate: 866000,
    uplinkRate: 433000,
    band: '5GHz',
    ssidName: 'MyNetwork',
  ),
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

final wifiDeviceGood = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:02',
  ip: '192.168.1.101',
  hostName: 'MacBook-Air',
  isActive: true,
  connectionType: ConnectionType.wifi,
  wifi: WifiConnectionInfo(
    signalStrength: -68,
    downlinkRate: 400000,
    uplinkRate: 200000,
    band: '5GHz',
    ssidName: 'MyNetwork',
  ),
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

final wiredDevice1 = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:03',
  ip: '192.168.1.102',
  hostName: 'PlayStation-5',
  isActive: true,
  connectionType: ConnectionType.wired,
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

final offlineDevice = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:04',
  ip: '192.168.1.103',
  hostName: 'iPad-Mini',
  isActive: false,
  connectionType: ConnectionType.wifi,
);

final wifiDeviceFair = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:05',
  ip: '192.168.1.104',
  hostName: 'Samsung-TV',
  isActive: true,
  connectionType: ConnectionType.wifi,
  wifi: WifiConnectionInfo(
    signalStrength: -75,
    downlinkRate: 72000,
    uplinkRate: 36000,
    band: '2.4GHz',
    ssidName: 'MyNetwork',
  ),
  parentNodeId: 'node-2',
  parentNodeName: 'Bedroom',
);

final wifiDevicePoor = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:06',
  ip: '192.168.1.105',
  hostName: 'Nest-Cam-Outdoor',
  isActive: true,
  connectionType: ConnectionType.wifi,
  wifi: WifiConnectionInfo(
    signalStrength: -82,
    downlinkRate: 24000,
    uplinkRate: 12000,
    band: '2.4GHz',
    ssidName: 'MyNetwork',
  ),
  parentNodeId: 'node-2',
  parentNodeName: 'Bedroom',
);

final testReservation = DhcpReservationUIModel(
  instancePath: 'Device.DHCPv4.Server.Pool.1.StaticAddress.1.',
  mac: 'AA:BB:CC:DD:EE:01',
  ip: '192.168.1.100',
  enable: true,
);

List<ClientDevice> get allDevices => [
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
