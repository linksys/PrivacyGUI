import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/node_detail_state.dart';

final nodeDetailProvider =
    NotifierProvider<NodeDetailNotifier, NodeDetailState>(
  () => NodeDetailNotifier(),
);

class NodeDetailNotifier extends Notifier<NodeDetailState> {
  @override
  NodeDetailState build() {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    final targetId = ref.watch(deviceDetailIdProvider);
    return createState(deviceManagerState, targetId);
  }

  NodeDetailState createState(
    DeviceManagerState deviceManagerState,
    String targetId,
  ) {
    var newState = const NodeDetailState();
    // The target Id should never be empty
    if (targetId.isEmpty) {
      return newState;
    }
    // Details of the specific device
    var location = '';
    var isMaster = false;
    var isOnline = false;
    final connectedDevices = <RouterDevice>[];
    var upstreamDevice = '';
    var isWired = false;
    var signalStrength = 0;
    var serialNumber = '';
    var modelNumber = '';
    var firmwareVersion = '';
    var lanIpAddress = '';
    var wanIpAddress = '';

    var masterId = '';
    final alldevices = deviceManagerState.deviceList;
    for (final device in alldevices) {
      // Collect connected devices for the target device
      if (device.isAuthority || device.nodeType == 'Master') {
        masterId = device.deviceID;
      } else if (device.nodeType == null) {
        // Make sure the external device is online
        if (device.connections.isNotEmpty) {
          // There usually be only one item
          final parentDeviceId = device.connections.firstOrNull?.parentDeviceID;
          // Count it if this item's parentId is the target device,
          // or if its parentId is null and the target device is master
          if ((parentDeviceId == targetId) ||
              (parentDeviceId == null && targetId == masterId)) {
            connectedDevices.add(device);
          }
        }
      }
      // Fill the details of the target device
      if (device.deviceID == targetId) {
        final locationMap = deviceManagerState.locationMap;
        location = locationMap[targetId] ?? '';
        isMaster = (targetId == masterId);
        isOnline = device.connections.isNotEmpty;
        upstreamDevice = isMaster ? 'INTERNET' : _getUpstream(device, masterId);
        isWired = ref
            .read(deviceManagerProvider.notifier)
            .checkWiredConnection(device);
        signalStrength = isWired
            ? 0
            : ref
                .read(deviceManagerProvider.notifier)
                .getWirelessSignal(device);
        serialNumber = device.unit.serialNumber ?? '';
        modelNumber = device.model.modelNumber ?? '';
        firmwareVersion = device.unit.firmwareVersion ?? '';
        lanIpAddress = device.connections.firstOrNull?.ipAddress ?? '';
        final wanStatusModel = deviceManagerState.wanStatus;
        wanIpAddress = wanStatusModel?.wanConnection?.ipAddress ?? '';
      }
    }

    return newState.copyWith(
      deviceId: targetId,
      location: location,
      isMaster: isMaster,
      isOnline: isOnline,
      connectedDevices: connectedDevices,
      upstreamDevice: upstreamDevice,
      isWiredConnection: isWired,
      signalStrength: signalStrength,
      serialNumber: serialNumber,
      modelNumber: modelNumber,
      firmwareVersion: firmwareVersion,
      lanIpAddress: lanIpAddress,
      wanIpAddress: wanIpAddress,
    );
  }

  String _getUpstream(RouterDevice device, String masterId) {
    final locationMap = ref.read(deviceManagerProvider).locationMap;
    final parentId = device.connections.firstOrNull?.parentDeviceID;
    final upstreamLocation = locationMap[parentId];
    final masterLocation = locationMap[masterId];
    return upstreamLocation ?? (masterLocation ?? '');
  }

  Future<void> toggleNodeLight(bool isOn) async {
    //TODO: Implement real commands for switching the light
    state = state.copyWith(
      isLightTurnedOn: isOn,
    );
  }
}
