// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';

@immutable
class DeviceListState {
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
}
