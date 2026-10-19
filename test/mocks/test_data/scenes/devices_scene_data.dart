// Composed scenes, not builders — see `test/mocks/test_data/` one directory up.
//
// The two are different kinds of fixture and used to be different kinds of file
// with the same name: `wifi_settings_test_data.dart` existed here and there with
// different contents, and `devices_test_data.dart` did too. CLAUDE.md documents
// exactly one location for test data, so an author autocompleting the wrong import
// got a fixture that did not match the provider overrides it was paired with —
// which for a page- or card-family cell renders `AppLoader` instead of the page,
// the failure `PageSurfaceCase.requires` exists to catch and which reads as green
// in any suite that does not use it.
//
// The split, as the names now say it:
//
// * `test_data/<feature>_test_data.dart` — a class of static factory methods over
//   USP codegen models, parameterised with defaults (constitution Article I
//   §1.6.2). What a unit test calls to build the one object it is about.
// * `test_data/scenes/<feature>_scene_data.dart` — top-level finals holding whole
//   composed states, ready to hand to a provider override. What a golden, a
//   density test or a layout-gate cell pumps a real page with.

import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';
import 'package:privacy_gui/page/devices/providers/device_detail_provider.dart';

final wifiDevice1 = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:01',
  ip: '192.168.1.100',
  hostName: 'iPhone-15-Pro',
  isActive: true,
  hostInstancePath: 'Device.Hosts.Host.1.',
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
  hostInstancePath: 'Device.Hosts.Host.2.',
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
  hostInstancePath: 'Device.Hosts.Host.3.',
  connectionType: ConnectionType.wired,
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

final offlineDevice = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:04',
  ip: '192.168.1.103',
  hostName: 'iPad-Mini',
  isActive: false,
  hostInstancePath: 'Device.Hosts.Host.4.',
  connectionType: ConnectionType.wifi,
);

final wifiDeviceFair = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:05',
  ip: '192.168.1.104',
  hostName: 'Samsung-TV',
  isActive: true,
  hostInstancePath: 'Device.Hosts.Host.5.',
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
  hostInstancePath: 'Device.Hosts.Host.6.',
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

// Device with a global (routable) IPv6 address — shown without a scope badge.
final wifiDeviceGlobalIpv6 = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:06',
  ip: '192.168.1.106',
  hostName: 'Desktop-PC',
  isActive: true,
  hostInstancePath: 'Device.Hosts.Host.7.',
  connectionType: ConnectionType.wifi,
  wifi: WifiConnectionInfo(
    signalStrength: -42,
    downlinkRate: 866000,
    uplinkRate: 433000,
    band: '5GHz',
    ssidName: 'MyNetwork',
  ),
  ipv6Addresses: const ['2401:e180:8801:d79d::5'],
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

// Device whose only IPv6 address is link-local (fe80::/10) — shown with a
// scope badge in place of the leading icon.
final wifiDeviceLinkLocalIpv6 = ClientDevice(
  mac: 'AA:BB:CC:DD:EE:07',
  ip: '192.168.1.107',
  hostName: 'Laptop',
  isActive: true,
  hostInstancePath: 'Device.Hosts.Host.8.',
  connectionType: ConnectionType.wifi,
  wifi: WifiConnectionInfo(
    signalStrength: -42,
    downlinkRate: 866000,
    uplinkRate: 433000,
    band: '5GHz',
    ssidName: 'MyNetwork',
  ),
  ipv6Addresses: const ['fe80::cd3:70da:d0a0:49cf'],
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

// A client the firmware identified (FWDEV#207, #1693) and the user named and
// typed (#1691): the identity card shows the firmware's maker, model and OS,
// and the name the user gave. The MAC is randomised, so without the firmware
// the maker row would read "Private/Random".
final wifiDeviceIdentified = ClientDevice(
  mac: 'BA:16:44:9F:EB:8B',
  ip: '192.168.1.108',
  hostName: 'iPhone',
  friendlyName: "Austin's iPhone",
  userDeviceName: "Austin's iPhone",
  isActive: true,
  hostInstancePath: 'Device.Hosts.Host.9.',
  connectionType: ConnectionType.wifi,
  wifi: WifiConnectionInfo(
    signalStrength: -48,
    downlinkRate: 866000,
    uplinkRate: 433000,
    band: '5GHz',
    ssidName: 'MyNetwork',
  ),
  manufacturer: 'Apple Inc.',
  modelName: 'iPhone',
  operatingSystem: 'iOS',
  deviceType: 'Phone',
  userDeviceType: '2', // tablet: the user's choice wins over the firmware's
  parentNodeId: 'node-1',
  parentNodeName: 'Living Room',
);

DeviceDetailState get wifiDetailIdentified => DeviceDetailState(
      device: wifiDeviceIdentified,
    );

DeviceDetailState get deviceNotFound => DeviceDetailState.empty();

DeviceDetailState get wifiDetailGlobalIpv6 => DeviceDetailState(
      device: wifiDeviceGlobalIpv6,
    );

DeviceDetailState get wifiDetailLinkLocalIpv6 => DeviceDetailState(
      device: wifiDeviceLinkLocalIpv6,
    );
