import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/device_list_provider.dart';
import 'package:linksys_app/provider/devices/device_list_state.dart';
import 'package:linksys_app/provider/devices/external_device_detail_state.dart';

final externalDeviceDetailProvider =
    NotifierProvider<ExternalDeviceDetailNotifier, ExternalDeviceDetailState>(
  () => ExternalDeviceDetailNotifier(),
);

class ExternalDeviceDetailNotifier extends Notifier<ExternalDeviceDetailState> {
  @override
  ExternalDeviceDetailState build() {
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    print(
        "XXXXXX ExternalDeviceDetailNotifier Build: filteredDeviceList: devicesNum=${filteredDeviceList.length}");
    return createState();
  }

  ExternalDeviceDetailState createState() {
    var newState = const ExternalDeviceDetailState(item: DeviceListItem());
    // Get the current target device Id
    final targetId = ref.read(deviceDetailIdProvider);
    // The target Id should never be empty
    if (targetId.isEmpty) {
      return newState;
    }
    final filteredDeviceList = ref.read(filteredDeviceListProvider);
    final targetItem =
        filteredDeviceList.firstWhere((item) => item.deviceId == targetId);
    return newState.copyWith(
      item: targetItem,
    );
    // Details of the specific external device
    // var name = '';
    // var icon = '';
    // var upstreamDevice = '';
    // var upstreamIcon = '';
    // var ipv4Address = '';
    // var ipv6Address = '';
    // var macAddress = '';
    // var manufacturer = '';
    // var model = '';
    // var operatingSystem = '';
    // var signalStrength = 0;
    // var isOnline = false;

    // final deviceList = ref.read(deviceManagerProvider).deviceList;
    // final targetDevice =
    //     deviceList.firstWhere((device) => device.deviceID == targetId);
    // final locationMap = ref.read(deviceManagerProvider).locationMap;

    // name = locationMap[targetId] ?? '';
    // icon = iconTest(targetDevice.toJson());
    // upstreamDevice =
    //     locationMap[_getUpstreamDevice(targetDevice).deviceID] ?? '';
    // upstreamIcon = iconTest(_getUpstreamDevice(targetDevice).toJson());
    // isOnline = targetDevice.connections.isNotEmpty;
    // ipv4Address =
    //     isOnline ? (targetDevice.connections.first.ipAddress ?? '') : '';
    // ipv6Address =
    //     isOnline ? (targetDevice.connections.first.ipv6Address ?? '') : '';
    // macAddress = isOnline ? (targetDevice.connections.first.macAddress) : '';
    // manufacturer = targetDevice.model.manufacturer ?? '';
    // model = targetDevice.model.modelNumber ?? '';
    // operatingSystem = targetDevice.unit.operatingSystem ?? '';
    // signalStrength = ref
    //     .read(deviceManagerProvider.notifier)
    //     .getWirelessSignal(targetDevice);

    // return newState.copyWith(
    //   deviceId: targetId,
    //   name: name,
    //   icon: icon,
    //   upstreamDevice: upstreamDevice,
    //   upstreamIcon: upstreamIcon,
    //   ipv4Address: ipv4Address,
    //   ipv6Address: ipv6Address,
    //   macAddress: macAddress,
    //   manufacturer: manufacturer,
    //   model: model,
    //   operatingSystem: operatingSystem,
    //   signalStrength: signalStrength,
    //   isOnline: isOnline,
    // );
  }

  // RouterDevice _getUpstreamDevice(RouterDevice device) {
  //   final deviceList = ref.read(deviceManagerProvider).deviceList;
  //   final parentId = device.connections.firstOrNull?.parentDeviceID;
  //   if (parentId != null) {
  //     return deviceList.first;//deviceList.firstWhere((device) => device.deviceID == parentId);
  //   } else {
  //     // No specified parent, use the master instead
  //     // Master node is always at the first
  //     return deviceList.first;
  //   }
  // }
}
