// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class DeviceState extends Equatable {
  final DeviceListInfoScope selectedScope;
  final DeviceListInfoType selectedSegment;
  final List<DeviceDetailInfo> displayedDeviceList;
  final DeviceDetailInfo? selectedDeviceInfo;
  final List<DeviceDetailInfo> offlineDeviceList;
  final List<DeviceDetailInfo> mainDeviceList;
  final List<DeviceDetailInfo> guestDeviceList;
  final List<DeviceDetailInfo> iotDeviceList;
  final bool isLoading;

  const DeviceState({
    this.selectedScope = DeviceListInfoScope.today,
    this.selectedSegment = DeviceListInfoType.main,
    this.displayedDeviceList = const [],
    this.selectedDeviceInfo,
    this.offlineDeviceList = const [],
    this.mainDeviceList = const [],
    this.guestDeviceList = const [],
    this.iotDeviceList = const [],
    this.isLoading = false,
  });

  DeviceState.init()
      : selectedScope = DeviceListInfoScope.today,
        selectedSegment = DeviceListInfoType.main,
        displayedDeviceList = [],
        selectedDeviceInfo = null,
        offlineDeviceList = [],
        mainDeviceList = [],
        guestDeviceList = [],
        iotDeviceList = [],
        isLoading = false;

  DeviceState copyWith({
    DeviceListInfoScope? selectedScope,
    DeviceListInfoType? selectedSegment,
    List<DeviceDetailInfo>? displayedDeviceList,
    DeviceDetailInfo? selectedDeviceInfo,
    List<DeviceDetailInfo>? offlineDeviceList,
    List<DeviceDetailInfo>? mainDeviceList,
    List<DeviceDetailInfo>? guestDeviceList,
    List<DeviceDetailInfo>? iotDeviceList,
    bool? isLoading,
  }) {
    return DeviceState(
      selectedScope: selectedScope ?? this.selectedScope,
      selectedSegment: selectedSegment ?? this.selectedSegment,
      displayedDeviceList: displayedDeviceList ?? this.displayedDeviceList,
      selectedDeviceInfo: selectedDeviceInfo ?? this.selectedDeviceInfo,
      offlineDeviceList: offlineDeviceList ?? this.offlineDeviceList,
      mainDeviceList: mainDeviceList ?? this.mainDeviceList,
      guestDeviceList: guestDeviceList ?? this.guestDeviceList,
      iotDeviceList: iotDeviceList ?? this.iotDeviceList,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        selectedScope,
        selectedSegment,
        displayedDeviceList,
        selectedDeviceInfo,
        offlineDeviceList,
        mainDeviceList,
        guestDeviceList,
        iotDeviceList,
        isLoading,
      ];
}

enum DeviceListInfoScope {
  today,
  week,
  profile,
}

enum DeviceListInfoType {
  main,
  guest,
  iot,
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
