import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/provider/devices/device_list_state.dart';

final filteredDeviceListProvider = Provider((ref) {
  final filterType = ref.watch(deviceListTypeProvider);
  final deviceListState = ref.watch(_deviceListProvider);
  return deviceListState.devices
      .where(
        (device) => device.type == filterType,
      )
      .toList()
    ..sort((dev1, dev2) {
      if (dev1.isOnline == dev2.isOnline) {
        return 0;
      } else if (dev1.isOnline) {
        return -1;
      } else {
        return 1;
      }
    });
});

final deviceListTypeProvider = StateProvider((ref) {
  return DeviceListItemType.main;
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
    final deviceList = deviceManagerState.deviceList;
    final externalDevices = deviceList.where(
      (device) => (device.nodeType == null),
    );
    final list = externalDevices
        .map(
          (device) => createItem(device),
        )
        .toList();
    return newState.copyWith(
      devices: list,
    );
  }

  DeviceListItem createItem(RouterDevice device) {
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
    var type = DeviceListItemType.main;

    final locationMap = ref.read(deviceManagerProvider).locationMap;
    name = locationMap[targetId] ?? '';
    icon = iconTest(device.toJson());
    upstreamDevice = locationMap[_getUpstreamDevice(device).deviceID] ?? '';
    upstreamIcon = iconTest(_getUpstreamDevice(device).toJson());
    isOnline = device.connections.isNotEmpty;
    ipv4Address = isOnline ? (device.connections.first.ipAddress ?? '') : '';
    ipv6Address = isOnline ? (device.connections.first.ipv6Address ?? '') : '';
    macAddress =
        ref.read(deviceManagerProvider.notifier).getDeviceMacAddress(device);
    manufacturer = device.model.manufacturer ?? '';
    model = device.model.modelNumber ?? '';
    operatingSystem = device.unit.operatingSystem ?? '';
    band = ref.read(deviceManagerProvider.notifier).getWirelessBand(device);
    signalStrength =
        ref.read(deviceManagerProvider.notifier).getWirelessSignal(device);
    type = ref.read(deviceManagerProvider.notifier).checkIsGuestNetwork(device)
        ? DeviceListItemType.guest
        : DeviceListItemType.main;

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
      type: type,
    );
  }

  RouterDevice _getUpstreamDevice(RouterDevice device) {
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
