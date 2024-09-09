import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/extensions/icon_device_category_ext.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

final offlineDeviceListProvider = Provider((ref) {
  final deviceListState = ref.watch(deviceListProvider);
  return deviceListState.devices.where((device) => !device.isOnline).toList();
});

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
    var newState = const DeviceListState();
    final list = deviceManagerState.externalDevices
        .map((device) => createItem(device))
        .toList();
    newState = newState.copyWith(
      devices: list,
    );
    return newState;
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
    int? signalStrength = 0;
    var isOnline = false;
    var isWired = false;
    var type = WifiConnectionType.main;

    name = device.getDeviceLocation();
    icon = _readIcon(device);
    final upstream = device.upstream;
    upstreamDevice = upstream?.getDeviceLocation() ?? '';
    upstreamDeviceID = upstream?.deviceID ?? '';
    upstreamIcon = routerIconTest(upstream?.toMap() ?? {});
    isOnline = device.isOnline();
    isWired = device.getConnectionType() == DeviceConnectionType.wired;
    ipv4Address = isOnline ? (device.connections.first.ipAddress ?? '') : '';
    ipv6Address = isOnline ? (device.connections.first.ipv6Address ?? '') : '';
    macAddress = device.getMacAddress();
    manufacturer = device.manufacturer ?? '';
    model = device.modelNumber ?? '';
    operatingSystem = device.operatingSystem ?? '';
    band = ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device);
    signalStrength = device.signalDecibels;
    type = device.connectedWifiType;
    final ssid =
        ref.read(deviceManagerProvider.notifier).getSsidConnectedBy(device);
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
      ssid: ssid,
    );
  }

  String _readIcon(LinksysDevice device) {
    final userDeviceType = (device.properties.firstWhereOrNull((element) {
      return element.name == 'userDeviceType';
    }))?.value;
    // device icon test will be the only way to resolve the device type
    // if userDeviceType is null
    if (userDeviceType == null) {
      return deviceIconTest(device.toMap());
    }
    final match = IconDeviceCategoryExt.resolveByName(userDeviceType);
    // The userDeviceType failed to be resolved may be because its value is not one of our custom values
    // but can be resolved correctly by device icon test (e.g., desktop-mac)
    if (match == LinksysIcons.genericDevice) {
      return deviceIconTest(device.toMap());
    }
    return userDeviceType;
  }
}
