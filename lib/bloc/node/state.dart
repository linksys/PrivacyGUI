import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/router/device.dart';

enum NodeSignalLevel {
  wired(displayTitle: 'Wired'),
  none(displayTitle: 'No signal'),
  weak(displayTitle: 'Weak'),
  good(displayTitle: 'Good'),
  fair(displayTitle: 'Fair'),
  excellent(displayTitle: 'Excellent');

  const NodeSignalLevel({required this.displayTitle});

  final String displayTitle;
}

class NodeState extends Equatable {
  final String deviceID;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final List<RouterDevice> connectedDevices;
  final String upstreamNode;
  final int signalStrength;
  final bool isWiredConnection;
  final bool isLightTurnedOn;
  final String serialNumber;
  final String modelNumber;
  final String firmwareVersion;
  final bool isLatestFw;
  final String lanIpAddress;
  final String wanIpAddress;
  final bool isSystemRestarting;
  NodeSignalLevel get signalLevel {
    if (isWiredConnection) {  //TODO: Make it better
      return NodeSignalLevel.wired;
    } else if (signalStrength <= -70) {
      return NodeSignalLevel.weak;
    } else if (signalStrength > -70 && signalStrength <= -60) {
      return NodeSignalLevel.fair;
    } else if (signalStrength > -60 && signalStrength <= -50) {
      return NodeSignalLevel.good;
    } else if (signalStrength > -50 && signalStrength <= 0) {
      return NodeSignalLevel.excellent;
    } else {
      return NodeSignalLevel.none;
    }
  }

  const NodeState({
    this.deviceID = '',
    this.location = '',
    this.isMaster = false,
    this.isOnline = false,
    this.connectedDevices = const [],
    this.upstreamNode = '',
    this.signalStrength = 0,
    this.isWiredConnection = false,
    this.isLightTurnedOn = true,
    this.serialNumber = '',
    this.modelNumber = '',
    this.firmwareVersion = '',
    this.isLatestFw = false,
    this.lanIpAddress = '',
    this.wanIpAddress = '',
    this.isSystemRestarting = false,
  });

  NodeState copyWith({
    String? deviceID,
    String? location,
    bool? isMaster,
    bool? isOnline,
    List<RouterDevice>? connectedDevices,
    String? upstreamNode,
    int? signalStrength,
    bool? isWiredConnection,
    bool? isLightTurnedOn,
    String? serialNumber,
    String? modelNumber,
    String? firmwareVersion,
    bool? isLatestFw,
    String? lanIpAddress,
    String? wanIpAddress,
    bool? isSystemRestarting,
  }) {
    return NodeState(
      deviceID: deviceID ?? this.deviceID,
      location: location ?? this.location,
      isMaster: isMaster ?? this.isMaster,
      isOnline: isOnline ?? this.isOnline,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      upstreamNode: upstreamNode ?? this.upstreamNode,
      signalStrength: signalStrength ?? this.signalStrength,
      isWiredConnection: isWiredConnection ?? this.isWiredConnection,
      isLightTurnedOn: isLightTurnedOn ?? this.isLightTurnedOn,
      serialNumber: serialNumber ?? this.serialNumber,
      modelNumber: modelNumber ?? this.modelNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      isLatestFw: isLatestFw ?? this.isLatestFw,
      lanIpAddress: lanIpAddress ?? this.lanIpAddress,
      wanIpAddress: wanIpAddress ?? this.wanIpAddress,
      isSystemRestarting: isSystemRestarting ?? this.isSystemRestarting,
    );
  }

  @override
  List<Object?> get props => [
    deviceID,
    location,
    isMaster,
    isOnline,
    connectedDevices,
    upstreamNode,
    signalStrength,
    isWiredConnection,
    isLightTurnedOn,
    serialNumber,
    modelNumber,
    firmwareVersion,
    isLatestFw,
    lanIpAddress,
    wanIpAddress,
    isSystemRestarting,
  ];
}