import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
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

    // Details of the specific device
    var location = '';
    var isMaster = false;
    var isOnline = false;
    var connectedDevices = <DeviceListItem>[];
    var upstreamDevice = '';
    var isWired = false;
    var signalStrength = 0;
    var serialNumber = '';
    var modelNumber = '';
    var firmwareVersion = '';
    var lanIpAddress = '';
    var wanIpAddress = '';
    var hardwareVersion = '';
    var isMLO = false;

    RawDevice? master = deviceManagerState.deviceList
        .firstWhereOrNull((element) => element.isAuthority);
    final alldevices = deviceManagerState.deviceList;
    for (final device in alldevices) {
      // Fill the details of the target device
      if (device.deviceID == targetId) {
        location = device.getDeviceLocation();
        isMaster = (targetId == master?.deviceID);
        isOnline = device.isOnline();
        upstreamDevice = isMaster
            ? 'INTERNET'
            : (device.upstream?.getDeviceLocation() ??
                master?.getDeviceLocation() ??
                '');
        isWired = device.getConnectionType() == DeviceConnectionType.wired;
        signalStrength = device.signalDecibels ?? 0;
        serialNumber = device.unit.serialNumber ?? '';
        modelNumber = device.model.modelNumber ?? '';
        firmwareVersion = device.unit.firmwareVersion ?? '';
        hardwareVersion = device.model.hardwareVersion ?? '';
        lanIpAddress = device.connections.firstOrNull?.ipAddress ?? '';
        final wanStatusModel = deviceManagerState.wanStatus;
        wanIpAddress = wanStatusModel?.wanConnection?.ipAddress ?? '';
        connectedDevices = device.connectedDevices
            .map((e) => ref.read(deviceListProvider.notifier).createItem(e))
            .toList();
        isMLO = device.wirelessConnectionInfo?.isMultiLinkOperation ?? false;
      }
    }

    final state = newState.copyWith(
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
      isMLO: isMLO,
    );
    logger.d('[State]:[NodeDetailsState]: ${state.toJson()}');
    return state;
  }

  Future startBlinkNodeLED(String deviceId) async {
    final repository = ref.read(routerRepositoryProvider);
    return repository.send(
      JNAPAction.startBlinkNodeLed,
      data: {'deviceID': deviceId},
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      auth: true,
    );
  }

  Future stopBlinkNodeLED() async {
    final repository = ref.read(routerRepositoryProvider);
    return repository.send(
      JNAPAction.stopBlinkNodeLed,
      auth: true,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );
  }

  Future<void> toggleBlinkNode([bool stopOnly = false]) async {
    final prefs = await SharedPreferences.getInstance();
    final blinkDevice = prefs.get(blinkingDeviceId);
    final deviceId = ref.read(nodeDetailIdProvider);
    if (!stopOnly && blinkDevice == null) {
      state = state.copyWith(blinkingStatus: BlinkingStatus.blinking);
      startBlinkNodeLED(deviceId).then((response) {
        prefs.setString(blinkingDeviceId, deviceId);
        state = state.copyWith(blinkingStatus: BlinkingStatus.stopBlinking);
        _blinkTimer?.cancel();
        _blinkTimer = Timer(const Duration(seconds: 24), () {
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
        _blinkTimer?.cancel();
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
