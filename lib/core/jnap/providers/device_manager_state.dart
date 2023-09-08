import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:linksys_app/core/jnap/models/back_haul_info.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';

class LinksysDevice extends RawDevice {
  final List<LinksysDevice> connectedDevices;
  const LinksysDevice({
    required super.connections,
    required super.properties,
    required super.unit,
    required super.deviceID,
    required super.maxAllowedProperties,
    required super.model,
    required super.isAuthority,
    required super.lastChangeRevision,
    super.friendlyName,
    super.knownInterfaces,
    super.knownMACAddresses,
    super.nodeType,
    this.connectedDevices = const [],
  });

  @override
  LinksysDevice copyWith({
    List<RawDeviceConnection>? connections,
    List<RawDeviceProperty>? properties,
    RawDeviceUnit? unit,
    String? deviceID,
    int? maxAllowedProperties,
    RawDeviceModel? model,
    bool? isAuthority,
    int? lastChangeRevision,
    String? friendlyName,
    List<RawDeviceKnownInterface>? knownInterfaces,
    List<String>? knownMACAddresses,
    String? nodeType,
    List<LinksysDevice>? connectedDevices,
  }) {
    return LinksysDevice(
      connections: connections ?? this.connections,
      properties: properties ?? this.properties,
      unit: unit ?? this.unit,
      deviceID: deviceID ?? this.deviceID,
      maxAllowedProperties: maxAllowedProperties ?? this.maxAllowedProperties,
      model: model ?? this.model,
      isAuthority: isAuthority ?? this.isAuthority,
      lastChangeRevision: lastChangeRevision ?? this.lastChangeRevision,
      friendlyName: friendlyName ?? this.friendlyName,
      knownInterfaces: knownInterfaces ?? this.knownInterfaces,
      knownMACAddresses: knownMACAddresses ?? this.knownMACAddresses,
      nodeType: nodeType ?? this.nodeType,
      connectedDevices: connectedDevices ?? this.connectedDevices,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      ...super.toMap(),
      'connectedDevices': connectedDevices.map((e) => e.toMap()).toList(),
    }..removeWhere((key, value) => value == null);
  }

  factory LinksysDevice.fromMap(Map<String, dynamic> map) {
    return LinksysDevice(
      connections: List<RawDeviceConnection>.from(
        map['connections'].map<RawDeviceConnection>(
          (x) => RawDeviceConnection.fromMap(x as Map<String, dynamic>),
        ),
      ),
      properties: List<RawDeviceProperty>.from(
        map['properties'].map<RawDeviceProperty>(
          (x) => RawDeviceProperty.fromMap(x as Map<String, dynamic>),
        ),
      ),
      unit: RawDeviceUnit.fromMap(map['unit'] as Map<String, dynamic>),
      deviceID: map['deviceID'] as String,
      maxAllowedProperties: map['maxAllowedProperties'] as int,
      model: RawDeviceModel.fromMap(map['model'] as Map<String, dynamic>),
      isAuthority: map['isAuthority'] as bool,
      lastChangeRevision: map['lastChangeRevision'] as int,
      friendlyName:
          map['friendlyName'] != null ? map['friendlyName'] as String : null,
      knownInterfaces: map['knownInterfaces'] != null
          ? List<RawDeviceKnownInterface>.from(
              map['knownInterfaces'].map<RawDeviceKnownInterface?>(
                (x) => RawDeviceKnownInterface.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      knownMACAddresses: map['knownMACAddresses'] != null
          ? List<String>.from((map['knownMACAddresses'] as List<String>))
          : null,
      nodeType: map['nodeType'] != null ? map['nodeType'] as String : null,
      connectedDevices: map['connectedDevices'] != null
          ? List.from(map['connectedDevices'])
              .map((e) => LinksysDevice.fromMap(e))
              .toList()
          : [],
    );
  }

  @override
  String toJson() => json.encode(toMap());

  factory LinksysDevice.fromJson(String source) =>
      LinksysDevice.fromMap(json.decode(source) as Map<String, dynamic>);
}

@immutable
class DeviceManagerState {
  // Collected data for a specific network with its own devices shared to overall screens
  final List<LinksysDevice> deviceList;
  final Map<String, Map<String, dynamic>> wirelessConnections;
  final RouterWANStatus? wanStatus;
  final List<BackHaulInfoData> backhaulInfoData;
  final bool isFirmwareUpToDate;
  final int lastUpdateTime;

  const DeviceManagerState({
    this.deviceList = const [],
    this.wirelessConnections = const {},
    this.wanStatus,
    this.backhaulInfoData = const [],
    this.isFirmwareUpToDate = false,
    this.lastUpdateTime = 0,
  });

  DeviceManagerState copyWith({
    List<LinksysDevice>? deviceList,
    Map<String, String>? locationMap,
    Map<String, Map<String, dynamic>>? wirelessConnections,
    RouterWANStatus? wanStatus,
    List<BackHaulInfoData>? backhaulInfoData,
    bool? isFirmwareUpToDate,
    int? lastUpdateTime,
  }) {
    return DeviceManagerState(
      deviceList: deviceList ?? this.deviceList,
      wirelessConnections: wirelessConnections ?? this.wirelessConnections,
      wanStatus: wanStatus ?? this.wanStatus,
      backhaulInfoData: backhaulInfoData ?? this.backhaulInfoData,
      isFirmwareUpToDate: isFirmwareUpToDate ?? this.isFirmwareUpToDate,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }
}

enum NodeSignalLevel {
  wired(displayTitle: 'Wired'),
  none(displayTitle: 'No signal'),
  weak(displayTitle: 'Weak'),
  good(displayTitle: 'Good'),
  fair(displayTitle: 'Fair'),
  excellent(displayTitle: 'Excellent');

  const NodeSignalLevel({
    required this.displayTitle,
  });

  final String displayTitle;
}
