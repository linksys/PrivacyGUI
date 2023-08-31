import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/device_detail_state.dart';

class DeviceDetailNotifier extends Notifier<DeviceDetailState> {
  @override
  DeviceDetailState build() {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    print(
        "XXXXXX DeviceDetailNotifier Build: DevMgr: devicesNum=${deviceManagerState.deviceList.length}");
    return createState();
  }

  DeviceDetailState createState() {
    var newState = const DeviceDetailState();
    // Get the current target device Id
    final targetId = ref.read(deviceDetailIdProvider);
    // The target Id should never be empty
    if (targetId.isEmpty) {
      return newState;
    }
    // Details of the specific device
    String location = '';
    bool isMaster = false;
    bool isOnline = false;
    List<RouterDevice> connectedDevices = [];
    String upstreamDevice = '';
    bool isWired = false;
    int signalStrength = 0;
    String serialNumber = '';
    String modelNumber = '';
    String firmwareVersion = '';
    String lanIpAddress = '';
    String wanIpAddress = '';

    String masterId = '';
    final alldevices = ref.read(deviceManagerProvider).deviceList;
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
        final locationMap = ref.read(deviceManagerProvider).locationMap;
        location = locationMap[targetId] ?? '';
        isMaster = (targetId == masterId);
        isOnline = device.connections.isNotEmpty;
        upstreamDevice =
            isMaster ? 'INTERNET' : _getSlaveUpstream(device, masterId);
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
        final wanStatusModel = ref.read(deviceManagerProvider).wanStatus;
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

  String _getSlaveUpstream(RouterDevice device, String masterId) {
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

//TODO: Implement reboot 
  // Future rebootMeshSystem() async {
    // emit(state.copyWith(
    //   isSystemRestarting: true,
    // ));
    // final results = await _repository.send(
    //   JNAPAction.reboot,
    //   auth: true,
    // );
    // if (results.result == 'OK') {
    //   Future.delayed(const Duration(seconds: 130), () {
    //     emit(state.copyWith(
    //       isSystemRestarting: false,
    //     ));
    //   });
    // } else {
    //   emit(state.copyWith(
    //     isSystemRestarting: false,
    //   ));
    // }
  // }
}

final deviceDetailProvider =
    NotifierProvider<DeviceDetailNotifier, DeviceDetailState>(
        () => DeviceDetailNotifier());
