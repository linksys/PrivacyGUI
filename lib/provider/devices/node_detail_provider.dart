import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/devices.dart';
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
    var connectedDevices = <RouterDevice>[];
    var upstreamDevice = '';
    var isWired = false;
    var signalStrength = 0;
    var serialNumber = '';
    var modelNumber = '';
    var firmwareVersion = '';
    var lanIpAddress = '';
    var wanIpAddress = '';

    RouterDevice? master = deviceManagerState.deviceList
        .firstWhereOrNull((element) => element.isAuthority);
    final alldevices = deviceManagerState.deviceList;
    for (final device in alldevices) {
      // Fill the details of the target device
      if (device.deviceID == targetId) {
        location = device.getDeviceLocation();
        isMaster = (targetId == master?.deviceID);
        isOnline = device.connections.isNotEmpty;
        upstreamDevice = isMaster
            ? 'INTERNET'
            : (_getUpstream(device) ?? master?.getDeviceLocation() ?? '');
        isWired = ref
            .read(deviceManagerProvider.notifier)
            .checkIsWiredConnection(device);
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
        connectedDevices = device.connectedDevices;
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

  String? _getUpstream(RouterDevice device) {
    final parent =
        ref.read(deviceManagerProvider.notifier).findParent(device.deviceID);
    final upstreamLocation = parent?.getDeviceLocation();
    return upstreamLocation;
  }

  Future<void> toggleNodeLight(bool isOn) async {
    //TODO: Implement real commands for switching the light
    state = state.copyWith(
      isLightTurnedOn: isOn,
    );
  }
}
