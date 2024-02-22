import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/page/devices/_devices.dart';

final offlineDeviceListProvider = Provider((ref) {
  final deviceListState = ref.watch(deviceListProvider);
  return deviceListState.devices.where((device) => !device.isOnline).toList();
});
final filteredDeviceListProvider = Provider((ref) {
  final ssidFilter = ref.watch(ssidFilterProvider);
  final deviceListState = ref.watch(deviceListProvider);
  final nodeId = ref.watch(nodeIdFilterProvider);
  final band = ref.watch(bandFilterProvider);
  final connection = ref.watch(connectionFilterProvider);

  var upstreamName = '';
  final isApplyFilter = ssidFilter == null &&
      nodeId.isEmpty &&
      band.isEmpty &&
      connection.isEmpty;

  return (
    isApplyFilter,
    deviceListState.devices
        .where((device) => device.isOnline)
        .where(
          (device) => ssidFilter == null ? true : device.type == ssidFilter,
        )
        .where((device) {
          if (nodeId.isEmpty) {
            return true;
          } else if (device.upstreamDeviceID == nodeId) {
            upstreamName = device.upstreamDevice;
            return true;
          } else {
            return false;
          }
        })
        .where((device) => band.isEmpty ? true : device.band == band)
        .where((device) => connection.isEmpty
            ? true
            : (device.isWired && connection == 'Wired') ||
                (!device.isWired && connection == 'WiFi'))
        .toList(),
    [ssidFilter?.value, upstreamName, band, connection]
      ..removeWhere((element) => element == null || element.isEmpty)
  );
});

final ssidFilterProvider = StateProvider<WifiConnectionType?>((ref) {
  return null;
});

final nodeIdFilterProvider = StateProvider((ref) {
  return '';
});

final bandFilterProvider = StateProvider((ref) => '');
final connectionFilterProvider = StateProvider((ref) => '');

final deviceListProvider =
    NotifierProvider<DeviceListNotifier, DeviceListState>(
  () => DeviceListNotifier(),
);

class DeviceListNotifier extends Notifier<DeviceListState> {
  @override
  DeviceListState build() {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    return createState(deviceManagerState);
  }

  DeviceListState createState(DeviceManagerState deviceManagerState) {
    const newState = DeviceListState();
    final list = deviceManagerState.externalDevices
        .map((device) => createItem(device))
        .toList();
    return newState.copyWith(
      devices: list,
    );
  }

  DeviceListItem createItem(LinksysDevice device) {
    const newState = DeviceListItem();
    // Details of the specific external device
    final targetId = device.deviceID;
    var name = '';
    var icon = '';
    var upstreamDevice = '';
    var upstreamDeviceID = '';
    var upstreamIcon = '';
    var ipv4Address = '';
    var ipv6Address = '';
    var macAddress = '';
    var manufacturer = '';
    var model = '';
    var operatingSystem = '';
    var band = '';
    var signalStrength = 0;
    var isOnline = false;
    var isWired = false;
    var type = WifiConnectionType.main;

    name = device.getDeviceLocation();
    icon = iconTest(device.toMap());
    final upstream = _getUpstreamDevice(device);

    upstreamDevice = upstream.getDeviceLocation();
    upstreamDeviceID = upstream.deviceID;
    upstreamIcon = iconTest(upstream.toMap());
    isOnline = device.connections.isNotEmpty;
    isWired = device.isWiredConnection();
    ipv4Address = isOnline ? (device.connections.first.ipAddress ?? '') : '';
    ipv6Address = isOnline ? (device.connections.first.ipv6Address ?? '') : '';
    macAddress = device.getMacAddress();
    manufacturer = device.manufacturer ?? '';
    model = device.modelNumber ?? '';
    operatingSystem = device.operatingSystem ?? '';
    band = ref.read(deviceManagerProvider.notifier).getWirelessBand(device);
    signalStrength =
        ref.read(deviceManagerProvider.notifier).getWirelessSignal(device);
    type = device.connectedWifiType;

    return newState.copyWith(
      deviceId: targetId,
      name: name,
      icon: icon,
      upstreamDevice: upstreamDevice,
      upstreamDeviceID: upstreamDeviceID,
      upstreamIcon: upstreamIcon,
      ipv4Address: ipv4Address,
      ipv6Address: ipv6Address,
      macAddress: macAddress,
      manufacturer: manufacturer,
      model: model,
      operatingSystem: operatingSystem,
      band: band,
      signalStrength: signalStrength,
      isOnline: isOnline,
      isWired: isWired,
      type: type,
    );
  }

  //TODO: Check if this logic is duplicate
  RawDevice _getUpstreamDevice(RawDevice device) {
    final parent =
        ref.read(deviceManagerProvider.notifier).findParent(device.deviceID);
    return parent ?? ref.read(deviceManagerProvider).deviceList.first;
    // final deviceList = ref.read(deviceManagerProvider).deviceList;
    // final parentId = device.connections.firstOrNull?.parentDeviceID;
    // if (parentId != null) {
    //   return deviceList.firstWhere((device) => device.deviceID == parentId);
    // } else {
    //   // No specified parent, use the master instead
    //   // Master node is always at the first
    //   return deviceList.first;
    // }
  }
}
