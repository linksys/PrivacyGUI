import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/node_light_settings.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/nodes/_nodes.dart';
import 'package:linksys_app/page/nodes/providers/node_detail_id_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String blinkingDeviceId = 'blinkDeviceId';
final nodeDetailProvider =
    NotifierProvider<NodeDetailNotifier, NodeDetailState>(
  () => NodeDetailNotifier(),
);

class NodeDetailNotifier extends Notifier<NodeDetailState> {
  @override
  NodeDetailState build() {
    final deviceManagerState = ref.watch(deviceManagerProvider);
    final targetId = ref.watch(nodeDetailIdProvider);
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
    var connectedDevices = <LinksysDevice>[];
    var upstreamDevice = '';
    var isWired = false;
    var signalStrength = 0;
    var serialNumber = '';
    var modelNumber = '';
    var firmwareVersion = '';
    var lanIpAddress = '';
    var wanIpAddress = '';
    var hardwareVersion = '';

    RawDevice? master = deviceManagerState.deviceList
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
            : (device.upstream?.getDeviceLocation() ??
                master?.getDeviceLocation() ??
                '');
        isWired = device.isWiredConnection();
        signalStrength = isWired
            ? 0
            : ref
                .read(deviceManagerProvider.notifier)
                .getWirelessSignalOf(device);
        serialNumber = device.unit.serialNumber ?? '';
        modelNumber = device.model.modelNumber ?? '';
        firmwareVersion = device.unit.firmwareVersion ?? '';
        hardwareVersion = device.model.hardwareVersion ?? '';
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
      hardwareVersion: hardwareVersion,
      lanIpAddress: lanIpAddress,
      wanIpAddress: wanIpAddress,
    );
  }

  Future<void> getLEDLight() async {
    return ref.read(deviceManagerProvider.notifier).getLEDLight().then((value) {
      state = state.copyWith(nodeLightSettings: value);
    });
  }

  Future<void> setLEDLight(NodeLightSettings settings) async {
    return ref
        .read(deviceManagerProvider.notifier)
        .setLEDLight(settings)
        .then((_) => ref.read(deviceManagerProvider.notifier).getLEDLight())
        .then((value) {
      state = state.copyWith(nodeLightSettings: settings);
    });
  }

  Future<JNAPResult> startBlinkNodeLED(String deviceId) async {
    final repository = ref.read(routerRepositoryProvider);
    return repository.send(JNAPAction.startBlinkNodeLed,
        data: {'deviceID': deviceId}, auth: true);
  }

  Future<JNAPResult> stopBlinkNodeLED() async {
    final repository = ref.read(routerRepositoryProvider);
    return repository.send(JNAPAction.stopBlinkNodeLed,
        auth: true, cacheLevel: CacheLevel.noCache);
  }

  Future<void> toggleBlinkNode() async {
    final prefs = await SharedPreferences.getInstance();
    final blinkDevice = prefs.get(blinkingDeviceId);
    final deviceId = ref.read(nodeDetailIdProvider);
    if (blinkDevice == null) {
      state = state.copyWith(blinkingStatus: BlinkingStatus.blinking);
      startBlinkNodeLED(deviceId).then((response) {
        prefs.setString(blinkingDeviceId, deviceId);
        state = state.copyWith(blinkingStatus: BlinkingStatus.stopBlinking);
        Timer(const Duration(seconds: 24), () {
          stopBlinkNodeLED().then((response) {
            state = state.copyWith(blinkingStatus: BlinkingStatus.blinkNode);
          });
        });
      }).onError((error, stackTrace) {
        state = state.copyWith(blinkingStatus: BlinkingStatus.blinkNode);
        logger.e(error.toString());
      });
    } else {
      stopBlinkNodeLED().then((response) {
        prefs.remove(blinkingDeviceId);
        state = state.copyWith(blinkingStatus: BlinkingStatus.blinkNode);
      }).onError((error, stackTrace) {
        state = state.copyWith(blinkingStatus: BlinkingStatus.stopBlinking);
        logger.e(error.toString());
      });
    }
  }

  Future<void> updateDeviceName(String newName) {
    return ref.read(deviceManagerProvider.notifier).updateDeviceNameAndIcon(
          targetId: state.deviceId,
          newName: newName,
          isLocation: true,
        );
  }
}
