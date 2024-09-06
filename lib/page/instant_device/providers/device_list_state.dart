// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

class DeviceListState extends Equatable {
  final List<DeviceListItem> devices;

  const DeviceListState({
    this.devices = const [],
  });

  DeviceListState copyWith({
    List<DeviceListItem>? devices,
  }) {
    return DeviceListState(
      devices: devices ?? this.devices,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'devices': devices.map((x) => x.toMap()).toList(),
    };
  }

  factory DeviceListState.fromMap(Map<String, dynamic> map) {
    return DeviceListState(
      devices: List<DeviceListItem>.from(
        map['devices'].map(
          (x) => DeviceListItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceListState.fromJson(String source) =>
      DeviceListState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [devices];
}

class DeviceListItem extends Equatable {
  final String deviceId;
  final String name;
  final String icon;
  final String upstreamDevice;
  final String upstreamDeviceID;
  final String upstreamIcon;
  final String ipv4Address;
  final String ipv6Address;
  final String macAddress;
  final String manufacturer;
  final String model;
  final String operatingSystem;
  final String band;
  final int signalStrength;
  final bool isOnline;
  final bool isWired;
  final WifiConnectionType type;
  final String ssid;

  const DeviceListItem({
    this.deviceId = '',
    this.name = '',
    this.icon = '',
    this.upstreamDevice = '',
    this.upstreamDeviceID = '',
    this.upstreamIcon = '',
    this.ipv4Address = '',
    this.ipv6Address = '',
    this.macAddress = '',
    this.manufacturer = '',
    this.model = '',
    this.operatingSystem = '',
    this.band = '',
    this.signalStrength = 0,
    this.isOnline = false,
    this.isWired = false,
    this.type = WifiConnectionType.main,
    this.ssid = '',
  });

  DeviceListItem copyWith({
    String? deviceId,
    String? name,
    String? icon,
    String? upstreamDevice,
    String? upstreamDeviceID,
    String? upstreamIcon,
    String? ipv4Address,
    String? ipv6Address,
    String? macAddress,
    String? manufacturer,
    String? model,
    String? operatingSystem,
    String? band,
    int? signalStrength,
    bool? isOnline,
    bool? isWired,
    WifiConnectionType? type,
    String? ssid,
  }) {
    return DeviceListItem(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      upstreamDevice: upstreamDevice ?? this.upstreamDevice,
      upstreamDeviceID: upstreamDeviceID ?? this.upstreamDeviceID,
      upstreamIcon: upstreamIcon ?? this.upstreamIcon,
      ipv4Address: ipv4Address ?? this.ipv4Address,
      ipv6Address: ipv6Address ?? this.ipv6Address,
      macAddress: macAddress ?? this.macAddress,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      band: band ?? this.band,
      signalStrength: signalStrength ?? this.signalStrength,
      isOnline: isOnline ?? this.isOnline,
      isWired: isWired ?? this.isWired,
      type: type ?? this.type,
      ssid: ssid ?? this.ssid,
    );
  }

  @override
  List<Object> get props {
    return [
      deviceId,
      name,
      icon,
      upstreamDevice,
      upstreamDeviceID,
      upstreamIcon,
      ipv4Address,
      ipv6Address,
      macAddress,
      manufacturer,
      model,
      operatingSystem,
      band,
      signalStrength,
      isOnline,
      isWired,
      type,
      ssid,
    ];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'name': name,
      'icon': icon,
      'upstreamDevice': upstreamDevice,
      'upstreamDeviceID': upstreamDeviceID,
      'upstreamIcon': upstreamIcon,
      'ipv4Address': ipv4Address,
      'ipv6Address': ipv6Address,
      'macAddress': macAddress,
      'manufacturer': manufacturer,
      'model': model,
      'operatingSystem': operatingSystem,
      'band': band,
      'signalStrength': signalStrength,
      'isOnline': isOnline,
      'isWired': isWired,
      'type': type.value,
      'ssid': ssid,
    };
  }

  factory DeviceListItem.fromMap(Map<String, dynamic> map) {
    return DeviceListItem(
      deviceId: map['deviceId'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      upstreamDevice: map['upstreamDevice'] as String,
      upstreamDeviceID: map['upstreamDeviceID'] as String,
      upstreamIcon: map['upstreamIcon'] as String,
      ipv4Address: map['ipv4Address'] as String,
      ipv6Address: map['ipv6Address'] as String,
      macAddress: map['macAddress'] as String,
      manufacturer: map['manufacturer'] as String,
      model: map['model'] as String,
      operatingSystem: map['operatingSystem'] as String,
      band: map['band'] as String,
      signalStrength: map['signalStrength'] as int,
      isOnline: map['isOnline'] as bool,
      isWired: map['isWired'] as bool,
      type:
          WifiConnectionType.values.firstWhereOrNull((e) => e == map['type']) ??
              WifiConnectionType.main,
      ssid: map['ssid'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceListItem.fromJson(String source) =>
      DeviceListItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
