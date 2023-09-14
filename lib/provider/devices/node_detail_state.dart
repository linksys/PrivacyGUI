import 'package:flutter/foundation.dart';
import 'package:linksys_app/core/jnap/models/device.dart';

enum BlinkingStatus {
  blinkNode('Blink Node'),
  blinking('Blinking'),
  stopBlinking('Stop Blink');

  final String value;
  const BlinkingStatus(this.value);
}

@immutable
class NodeDetailState {
  final String deviceId;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final List<RawDevice> connectedDevices;
  final String upstreamDevice;
  final bool isWiredConnection;
  final int signalStrength;
  final String serialNumber;
  final String modelNumber;
  final String firmwareVersion;
  final String lanIpAddress;
  final String wanIpAddress;
  final bool isLightTurnedOn;
  final BlinkingStatus blinkingStatus;

  const NodeDetailState(
      {this.deviceId = '',
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
      this.lanIpAddress = '',
      this.wanIpAddress = '',
      this.isLightTurnedOn = true,
      this.blinkingStatus = BlinkingStatus.blinkNode});

  NodeDetailState copyWith({
    String? deviceId,
    String? location,
    bool? isMaster,
    bool? isOnline,
    List<RawDevice>? connectedDevices,
    String? upstreamDevice,
    bool? isWiredConnection,
    int? signalStrength,
    String? serialNumber,
    String? modelNumber,
    String? firmwareVersion,
    String? lanIpAddress,
    String? wanIpAddress,
    bool? isLightTurnedOn,
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
      lanIpAddress: lanIpAddress ?? this.lanIpAddress,
      wanIpAddress: wanIpAddress ?? this.wanIpAddress,
      isLightTurnedOn: isLightTurnedOn ?? this.isLightTurnedOn,
      blinkingStatus: blinkingStatus ?? this.blinkingStatus,
    );
  }
}
