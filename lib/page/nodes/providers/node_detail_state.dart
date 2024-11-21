// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';

enum BlinkingStatus {
  blinkNode('Blink Node'),
  blinking('Blinking'),
  stopBlinking('Stop Blink');

  final String value;
  const BlinkingStatus(this.value);

  static BlinkingStatus resolve(String value) => switch (value) {
        'Blink Node' => BlinkingStatus.blinkNode,
        'Blinking' => BlinkingStatus.blinking,
        _ => BlinkingStatus.stopBlinking,
      };
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

class NodeDetailState extends Equatable {
  final String deviceId;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final List<DeviceListItem> connectedDevices;
  final String upstreamDevice;
  final bool isWiredConnection;
  final int signalStrength;
  final String serialNumber;
  final String modelNumber;
  final String firmwareVersion;
  final String hardwareVersion;
  final String lanIpAddress;
  final String wanIpAddress;
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
    this.blinkingStatus = BlinkingStatus.blinkNode,
  });

  NodeDetailState copyWith({
    String? deviceId,
    String? location,
    bool? isMaster,
    bool? isOnline,
    List<DeviceListItem>? connectedDevices,
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
      blinkingStatus: blinkingStatus ?? this.blinkingStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'location': location,
      'isMaster': isMaster,
      'isOnline': isOnline,
      'connectedDevices': connectedDevices.map((x) => x.toMap()).toList(),
      'upstreamDevice': upstreamDevice,
      'isWiredConnection': isWiredConnection,
      'signalStrength': signalStrength,
      'serialNumber': serialNumber,
      'modelNumber': modelNumber,
      'firmwareVersion': firmwareVersion,
      'hardwareVersion': hardwareVersion,
      'lanIpAddress': lanIpAddress,
      'wanIpAddress': wanIpAddress,
      'blinkingStatus': blinkingStatus.value,
    };
  }

  factory NodeDetailState.fromMap(Map<String, dynamic> map) {
    return NodeDetailState(
      deviceId: map['deviceId'] as String,
      location: map['location'] as String,
      isMaster: map['isMaster'] as bool,
      isOnline: map['isOnline'] as bool,
      connectedDevices: List<DeviceListItem>.from(
        map['connectedDevices'].map<DeviceListItem>(
          (x) => DeviceListItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      upstreamDevice: map['upstreamDevice'] as String,
      isWiredConnection: map['isWiredConnection'] as bool,
      signalStrength: map['signalStrength'] as int,
      serialNumber: map['serialNumber'] as String,
      modelNumber: map['modelNumber'] as String,
      firmwareVersion: map['firmwareVersion'] as String,
      hardwareVersion: map['hardwareVersion'] as String,
      lanIpAddress: map['lanIpAddress'] as String,
      wanIpAddress: map['wanIpAddress'] as String,
      blinkingStatus: BlinkingStatus.resolve(map['blinkingStatus'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory NodeDetailState.fromJson(String source) =>
      NodeDetailState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      deviceId,
      location,
      isMaster,
      isOnline,
      connectedDevices,
      upstreamDevice,
      isWiredConnection,
      signalStrength,
      serialNumber,
      modelNumber,
      firmwareVersion,
      hardwareVersion,
      lanIpAddress,
      wanIpAddress,
      blinkingStatus,
    ];
  }
}
