import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/models/device_list_item.dart';

export 'package:privacy_gui/core/models/device_list_item.dart';

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
