import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/provider/devices/device_list_state.dart';

final offlineDeviceListProvider = Provider((ref) {
  final deviceListState = ref.watch(_deviceListProvider);
  return deviceListState.devices.where((device) => !device.isOnline).toList();
});
final filteredDeviceListProvider = Provider((ref) {
  final filterType = ref.watch(deviceListTypeProvider);
  final deviceListState = ref.watch(_deviceListProvider);
  return deviceListState.devices
      .where(
        (device) => device.type == filterType,
      )
      .where((device) => device.isOnline)
      .toList();
});

final deviceListTypeProvider = StateProvider((ref) {
  // Main Wi-Fi devices are given by default
  return WifiConnectionType.main;
});

final _deviceListProvider =
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
    upstreamDevice = _getUpstreamDevice(device).getDeviceLocation();
    upstreamIcon = iconTest(_getUpstreamDevice(device).toMap());
    isOnline = device.connections.isNotEmpty;
    isWired =
        ref.read(deviceManagerProvider.notifier).checkIsWiredConnection(device);
    ipv4Address = isOnline ? (device.connections.first.ipAddress ?? '') : '';
    ipv6Address = isOnline ? (device.connections.first.ipv6Address ?? '') : '';
    macAddress =
        ref.read(deviceManagerProvider.notifier).getDeviceMacAddress(device);
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
    final deviceList = ref.read(deviceManagerProvider).deviceList;
    final parentId = device.connections.firstOrNull?.parentDeviceID;
    if (parentId != null) {
      return deviceList.firstWhere((device) => device.deviceID == parentId);
    } else {
      // No specified parent, use the master instead
      // Master node is always at the first
      return deviceList.first;
    }
  }
}
