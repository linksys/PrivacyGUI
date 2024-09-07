// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';

class InstantPrivacyDeviceListState extends Equatable {
  final bool isEnable;
  final List<String> macAddresses;
  final List<DeviceListItem> deviceList;

  const InstantPrivacyDeviceListState({
    required this.isEnable,
    required this.macAddresses,
    required this.deviceList,
  });

  // Calculated properties
  List<DeviceListItem> get displayDevices {
    return isEnable
        ? deviceList
            .where((device) =>
                macAddresses.contains(device.macAddress.toUpperCase()))
            .toList()
        : deviceList.where((device) => device.isOnline).toList();
  }

  InstantPrivacyDeviceListState copyWith({
    bool? isEnable,
    List<String>? macAddresses,
    List<DeviceListItem>? deviceList,
  }) {
    return InstantPrivacyDeviceListState(
      isEnable: isEnable ?? this.isEnable,
      macAddresses: macAddresses ?? this.macAddresses,
      deviceList: deviceList ?? this.deviceList,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isEnable': isEnable,
      'macAddresses': macAddresses,
      'deviceList': deviceList.map((x) => x.toMap()).toList(),
    };
  }

  factory InstantPrivacyDeviceListState.fromMap(Map<String, dynamic> map) {
    return InstantPrivacyDeviceListState(
      isEnable: map['isEnable'] as bool,
      macAddresses: List<String>.from((map['macAddresses'] as List<String>)),
      deviceList: List<DeviceListItem>.from(
        map['deviceList'].map<DeviceListItem>(
          (x) => DeviceListItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory InstantPrivacyDeviceListState.fromJson(String source) =>
      InstantPrivacyDeviceListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isEnable, macAddresses, deviceList];
}
