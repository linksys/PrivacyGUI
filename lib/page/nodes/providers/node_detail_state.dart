import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/node_light_settings.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/localization/localization_hook.dart';

enum BlinkingStatus {
  blinkNode('Blink Node'),
  blinking('Blinking'),
  stopBlinking('Stop Blink');

  final String value;
  const BlinkingStatus(this.value);
}

enum NodeLightStatus {
  on,
  off,
  night;

  static NodeLightStatus getStatus(NodeLightSettings? settings) {
    if (settings == null) {
      return NodeLightStatus.off;
    }
    if ((settings.allDayOff ?? false) ||
        (settings.startHour == 0 && settings.endHour == 24)) {
      return NodeLightStatus.off;
    } else if (!settings.isNightModeEnable) {
      return NodeLightStatus.on;
    } else {
      return NodeLightStatus.night;
    }
  }

  String resolveString(BuildContext context) {
    if (this == NodeLightStatus.on) {
      return getAppLocalizations(context).on;
    } else if (this == NodeLightStatus.off) {
      return getAppLocalizations(context).off;
    } else {
      return 'Night';
    }
  }
}

@immutable
class NodeDetailState {
  final String deviceId;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final List<LinksysDevice> connectedDevices;
  final String upstreamDevice;
  final bool isWiredConnection;
  final int signalStrength;
  final String serialNumber;
  final String modelNumber;
  final String firmwareVersion;
  final String hardwareVersion;
  final String lanIpAddress;
  final String wanIpAddress;
  final NodeLightSettings? nodeLightSettings;
  final BlinkingStatus blinkingStatus;

  const NodeDetailState({
    this.deviceId = '',
    this.location = '',
    this.isMaster = false,
    this.isOnline = false,
    this.connectedDevices = const [],
    this.upstreamDevice = '',
    this.isWiredConnection = false,
    this.signalStrength = 0,
    this.serialNumber = '',
    this.modelNumber = '',
    this.firmwareVersion = '',
    this.hardwareVersion = '',
    this.lanIpAddress = '',
    this.wanIpAddress = '',
    this.nodeLightSettings,
    this.blinkingStatus = BlinkingStatus.blinkNode,
  });

  NodeDetailState copyWith({
    String? deviceId,
    String? location,
    bool? isMaster,
    bool? isOnline,
    List<LinksysDevice>? connectedDevices,
    String? upstreamDevice,
    bool? isWiredConnection,
    int? signalStrength,
    String? serialNumber,
    String? modelNumber,
    String? firmwareVersion,
    String? hardwareVersion,
    String? lanIpAddress,
    String? wanIpAddress,
    NodeLightSettings? nodeLightSettings,
    BlinkingStatus? blinkingStatus,
  }) {
    return NodeDetailState(
      deviceId: deviceId ?? this.deviceId,
      location: location ?? this.location,
      isMaster: isMaster ?? this.isMaster,
      isOnline: isOnline ?? this.isOnline,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      upstreamDevice: upstreamDevice ?? this.upstreamDevice,
      isWiredConnection: isWiredConnection ?? this.isWiredConnection,
      signalStrength: signalStrength ?? this.signalStrength,
      serialNumber: serialNumber ?? this.serialNumber,
      modelNumber: modelNumber ?? this.modelNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      lanIpAddress: lanIpAddress ?? this.lanIpAddress,
      wanIpAddress: wanIpAddress ?? this.wanIpAddress,
      nodeLightSettings: nodeLightSettings ?? this.nodeLightSettings,
      blinkingStatus: blinkingStatus ?? this.blinkingStatus,
    );
  }
}
