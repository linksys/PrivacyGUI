import 'dart:convert';

import 'package:equatable/equatable.dart';

enum MacFilterStatus {
  off,
  allow,
  deny,
}

class MacFilteringState extends Equatable {
  final MacFilterStatus status;
  final List<DeviceDetailInfo> selectedDevices;

  @override
  List<Object> get props => [status, selectedDevices];

  const MacFilteringState({
    required this.status,
    required this.selectedDevices,
  });

  factory MacFilteringState.init() {
    return const MacFilteringState(
      status: MacFilterStatus.off,
      selectedDevices: [],
    );
  }

  MacFilteringState copyWith({
    MacFilterStatus? status,
    List<DeviceDetailInfo>? selectedDevices,
  }) {
    return MacFilteringState(
      status: status ?? this.status,
      selectedDevices: selectedDevices ?? this.selectedDevices,
    );
  }
}

class DeviceDetailInfo extends Equatable {
  final String name;
  final String deviceID;
  final int uploadData;
  final int downloadData;
  final String connection;
  final int weeklyData;
  final String icon;
  final String ipAddress;
  final String macAddress;
  final String manufacturer;
  final String model;
  final String os;
  final int signal;
  final int lastChangeRevision;
  final String? profileId;
  final DeviceParentInfo? parentInfo;
  final bool isOnline;

  const DeviceDetailInfo({
    required this.name,
    required this.deviceID,
    this.uploadData = 0,
    this.downloadData = 0,
    this.connection = '',
    this.weeklyData = 0,
    this.icon = 'assets/images/icon_device.png',
    this.ipAddress = '',
    this.macAddress = '',
    this.manufacturer = '',
    this.model = '',
    this.os = '',
    this.signal = 0,
    this.lastChangeRevision = 0,
    this.profileId,
    this.parentInfo,
    this.isOnline = false,
  });

  DeviceDetailInfo copyWith({
    String? name,
    String? deviceID,
    String? place,
    int? uploadData,
    int? downloadData,
    String? connection,
    int? weeklyData,
    String? icon,
    String? ipAddress,
    String? macAddress,
    String? manufacturer,
    String? model,
    String? os,
    int? signal,
    int? lastChangeRevision,
    String? profileId,
    DeviceParentInfo? parentInfo,
    bool? isOnline,
  }) {
    return DeviceDetailInfo(
      name: name ?? this.name,
      deviceID: deviceID ?? this.deviceID,
      uploadData: uploadData ?? this.uploadData,
      downloadData: downloadData ?? this.downloadData,
      connection: connection ?? this.connection,
      weeklyData: weeklyData ?? this.weeklyData,
      icon: icon ?? this.icon,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      os: os ?? this.os,
      signal: signal ?? this.signal,
      lastChangeRevision: lastChangeRevision ?? this.lastChangeRevision,
      profileId: profileId ?? this.profileId,
      parentInfo: parentInfo ?? this.parentInfo,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
        name,
        deviceID,
        uploadData,
        downloadData,
        connection,
        weeklyData,
        icon,
        ipAddress,
        macAddress,
        manufacturer,
        model,
        os,
        signal,
        lastChangeRevision,
        profileId,
        parentInfo,
        isOnline,
      ];
}

class DeviceParentInfo extends Equatable {
  final String place;
  final String deviceId;
  final String icon;

  const DeviceParentInfo({
    required this.place,
    required this.deviceId,
    required this.icon,
  });

  DeviceParentInfo copyWith({
    String? place,
    String? deviceId,
    String? icon,
  }) {
    return DeviceParentInfo(
      place: place ?? this.place,
      deviceId: deviceId ?? this.deviceId,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'place': place,
      'deviceId': deviceId,
      'icon': icon,
    };
  }

  factory DeviceParentInfo.fromMap(Map<String, dynamic> map) {
    return DeviceParentInfo(
      place: map['place'] as String,
      deviceId: map['deviceId'] as String,
      icon: map['icon'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory DeviceParentInfo.fromJson(String source) =>
      DeviceParentInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        place,
        deviceId,
        icon,
      ];
}
