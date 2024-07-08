// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/models/wirless_connection.dart';

class LinksysDevice extends RawDevice {
  final List<LinksysDevice> connectedDevices;
  final WifiConnectionType connectedWifiType;
  final int? signalDecibels;
  final LinksysDevice? upstream;
  final String connectionType;
  final WirelessConnectionInfo? wirelessConnectionInfo;
  final String speedMbps;

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
    this.connectedWifiType = WifiConnectionType.main,
    this.signalDecibels,
    this.upstream,
    this.connectionType = 'wireless',
    this.wirelessConnectionInfo,
    this.speedMbps = '--',
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
    WifiConnectionType? connectedWifiType,
    int? signalDecibels,
    LinksysDevice? upstream,
    String? connectionType,
    WirelessConnectionInfo? wirelessConnectionInfo,
    String? speedMbps,
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
      connectedWifiType: connectedWifiType ?? this.connectedWifiType,
      signalDecibels: signalDecibels ?? this.signalDecibels,
      upstream: upstream ?? this.upstream,
      connectionType: connectionType ?? this.connectionType,
      wirelessConnectionInfo:
          wirelessConnectionInfo ?? this.wirelessConnectionInfo,
      speedMbps: speedMbps ?? this.speedMbps,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      ...super.toMap(),
      'connectedDevices': connectedDevices.map((e) => e.toMap()).toList(),
      'connectedWifiType': connectedWifiType.value,
      'signalDecibels': signalDecibels,
      'upstream': upstream?.toMap(),
      'connectionType': connectionType,
      'wirelessConnectionInfo': wirelessConnectionInfo?.toMap(),
      'speedMbps': speedMbps,
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
                (x) =>
                    RawDeviceKnownInterface.fromMap(x as Map<String, dynamic>),
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
      connectedWifiType: map['connectedWifiType'] != null
          ? WifiConnectionType.values.firstWhereOrNull(
                  (element) => element.value == map['connectedWifiType']) ??
              WifiConnectionType.main
          : WifiConnectionType.main,
      signalDecibels: map['signalDecibels'],
      upstream: map['upstream'] != null
          ? LinksysDevice.fromMap(map['upstream'])
          : null,
      connectionType: map['connectionType'] ?? 'wireless',
      wirelessConnectionInfo: map['wirelessConnectionInfo'] != null
          ? WirelessConnectionInfo.fromMap(map['wirelessConnectionInfo'])
          : null,
      speedMbps: map['speedMbps'] ?? '--',
    );
  }

  @override
  String toJson() => json.encode(toMap());

  factory LinksysDevice.fromJson(String source) =>
      LinksysDevice.fromMap(json.decode(source) as Map<String, dynamic>);
}

class DeviceManagerState extends Equatable {
  // Collected data for a specific network with its own devices shared to overall screens
  final Map<String, WirelessConnection> wirelessConnections;
  final Map<String, RouterRadio> radioInfos;
  final List<LinksysDevice> deviceList;
  final RouterWANStatus? wanStatus;
  final List<BackHaulInfoData> backhaulInfoData;
  final int lastUpdateTime;

  // Calculated properties
  List<LinksysDevice> get nodeDevices {
    return deviceList.where((device) => device.nodeType != null).toList();
  }

  List<LinksysDevice> get externalDevices {
    return deviceList.where((device) => device.nodeType == null).toList();
  }

  List<LinksysDevice> get mainWifiDevices {
    return deviceList
        .where((device) => device.connectedWifiType == WifiConnectionType.main)
        .toList();
  }

  List<LinksysDevice> get guestWifiDevices {
    return deviceList
        .where((device) => device.connectedWifiType == WifiConnectionType.guest)
        .toList();
  }

  LinksysDevice get masterDevice {
    return nodeDevices.firstWhere((device) => device.isAuthority == true);
  }

  List<LinksysDevice> get slaveDevices {
    return nodeDevices.where((device) => device.isAuthority == false).toList();
  }

  const DeviceManagerState({
    this.wirelessConnections = const {},
    this.radioInfos = const {},
    this.deviceList = const [],
    this.wanStatus,
    this.backhaulInfoData = const [],
    this.lastUpdateTime = 0,
  });

  DeviceManagerState copyWith({
    Map<String, WirelessConnection>? wirelessConnections,
    Map<String, RouterRadio>? radioInfos,
    List<LinksysDevice>? deviceList,
    RouterWANStatus? wanStatus,
    List<BackHaulInfoData>? backhaulInfoData,
    int? lastUpdateTime,
  }) {
    return DeviceManagerState(
      wirelessConnections: wirelessConnections ?? this.wirelessConnections,
      radioInfos: radioInfos ?? this.radioInfos,
      deviceList: deviceList ?? this.deviceList,
      wanStatus: wanStatus ?? this.wanStatus,
      backhaulInfoData: backhaulInfoData ?? this.backhaulInfoData,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }

  Map<String, dynamic> toMap() {
    final wirelessConnectionMap = Map.fromEntries(wirelessConnections.entries
        .map((e) => MapEntry(e.key, e.value.toMap())));
    final radioInfoMap = Map.fromEntries(
        radioInfos.entries.map((e) => MapEntry(e.key, e.value.toMap())));
    return <String, dynamic>{
      'wirelessConnections': wirelessConnectionMap,
      'radioInfos': radioInfoMap,
      'deviceList': deviceList.map((x) => x.toMap()).toList(),
      'wanStatus': wanStatus?.toMap(),
      'backhaulInfoData': backhaulInfoData.map((x) => x.toMap()).toList(),
      'lastUpdateTime': lastUpdateTime,
    };
  }

  factory DeviceManagerState.fromMap(Map<String, dynamic> map) {
    return DeviceManagerState(
      wirelessConnections: Map<String, WirelessConnection>.fromEntries(
        (map['wirelessConnections'] as Map).entries.map(
              (e) => MapEntry(
                e.key,
                WirelessConnection.fromMap(e.value),
              ),
            ),
      ),
      radioInfos: Map<String, RouterRadio>.fromEntries(
          (map['radioInfos'] as Map).entries.map(
                (e) => MapEntry(
                  e.key,
                  RouterRadio.fromMap(e.value),
                ),
              )),
      deviceList: List<LinksysDevice>.from(
        map['deviceList'].map<LinksysDevice>(
          (x) => LinksysDevice.fromMap(x as Map<String, dynamic>),
        ),
      ),
      wanStatus: map['wanStatus'] != null
          ? RouterWANStatus.fromMap(map['wanStatus'] as Map<String, dynamic>)
          : null,
      backhaulInfoData: List<BackHaulInfoData>.from(
        map['backhaulInfoData'].map<BackHaulInfoData>(
          (x) => BackHaulInfoData.fromMap(x as Map<String, dynamic>),
        ),
      ),
      lastUpdateTime: map['lastUpdateTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceManagerState.fromJson(String source) =>
      DeviceManagerState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      wirelessConnections,
      radioInfos,
      deviceList,
      wanStatus,
      backhaulInfoData,
      lastUpdateTime,
    ];
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

enum WifiConnectionType {
  main('main'),
  guest('guest');

  final String value;
  const WifiConnectionType(this.value);
}
