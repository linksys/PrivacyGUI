import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/nodes/services/node_detail_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String blinkingDeviceId = 'blinkDeviceId';
final nodeDetailProvider =
    NotifierProvider<NodeDetailNotifier, NodeDetailState>(
  () => NodeDetailNotifier(),
);

class NodeDetailNotifier extends Notifier<NodeDetailState> {
  Timer? _blinkTimer;

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

    // Find the target device and master device
    final device = deviceManagerState.deviceList
        .firstWhereOrNull((element) => element.deviceID == targetId);
    final master = deviceManagerState.deviceList
        .firstWhereOrNull((element) => element.isAuthority);

    if (device == null) {
      return newState;
    }

    // Use Service for transformation
    final service = ref.read(nodeDetailServiceProvider);
    final values = service.transformDeviceToUIValues(
      device: device,
      masterDevice: master,
      wanStatus: deviceManagerState.wanStatus,
    );

    final connectedDevices = service.transformConnectedDevices(
      devices: device.connectedDevices,
      deviceListNotifier: ref.read(deviceListProvider.notifier),
    );

    final state = newState.copyWith(
      deviceId: targetId,
      location: values['location'] as String,
      isMaster: values['isMaster'] as bool,
      isOnline: values['isOnline'] as bool,
      connectedDevices: connectedDevices,
      upstreamDevice: values['upstreamDevice'] as String,
      isWiredConnection: values['isWiredConnection'] as bool,
      signalStrength: values['signalStrength'] as int,
      serialNumber: values['serialNumber'] as String,
      modelNumber: values['modelNumber'] as String,
      firmwareVersion: values['firmwareVersion'] as String,
      hardwareVersion: values['hardwareVersion'] as String,
      lanIpAddress: values['lanIpAddress'] as String,
      wanIpAddress: values['wanIpAddress'] as String,
      isMLO: values['isMLO'] as bool,
      macAddress: values['macAddress'] as String,
    );
    logger.d('[State]:[NodeDetailsState]: ${state.toJson()}');
    return state;
  }

  Future<void> _startBlinkNodeLED(String deviceId) async {
    final service = ref.read(nodeDetailServiceProvider);
    await service.startBlinkNodeLED(deviceId);
  }

  Future<void> _stopBlinkNodeLED() async {
    final service = ref.read(nodeDetailServiceProvider);
    await service.stopBlinkNodeLED();
  }

  Future<void> toggleBlinkNode([bool stopOnly = false]) async {
    final prefs = await SharedPreferences.getInstance();
    final blinkDevice = prefs.get(blinkingDeviceId);
    final deviceId = ref.read(nodeDetailIdProvider);
    if (!stopOnly && blinkDevice == null) {
      state = state.copyWith(blinkingStatus: BlinkingStatus.blinking);
      _startBlinkNodeLED(deviceId).then((_) {
        prefs.setString(blinkingDeviceId, deviceId);
        state = state.copyWith(blinkingStatus: BlinkingStatus.stopBlinking);
        _blinkTimer?.cancel();
        _blinkTimer = Timer(const Duration(seconds: 24), () {
          _stopBlinkNodeLED().then((_) {
            state = state.copyWith(blinkingStatus: BlinkingStatus.blinkNode);
          });
        });
      }).onError((error, stackTrace) {
        state = state.copyWith(blinkingStatus: BlinkingStatus.blinkNode);
        if (error is ServiceError) {
          logger.e('ServiceError: $error');
        } else {
          logger.e(error.toString());
        }
      });
    } else {
      _stopBlinkNodeLED().then((_) {
        _blinkTimer?.cancel();
        prefs.remove(blinkingDeviceId);
        state = state.copyWith(blinkingStatus: BlinkingStatus.blinkNode);
      }).onError((error, stackTrace) {
        state = state.copyWith(blinkingStatus: BlinkingStatus.stopBlinking);
        if (error is ServiceError) {
          logger.e('ServiceError: $error');
        } else {
          logger.e(error.toString());
        }
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
