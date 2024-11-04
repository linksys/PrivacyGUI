// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/instant_device/_instant_device.dart';

class ExternalDeviceDetailState extends Equatable {
  final DeviceListItem item;

  const ExternalDeviceDetailState({
    required this.item,
  });

  ExternalDeviceDetailState copyWith({
    DeviceListItem? item,
  }) {
    return ExternalDeviceDetailState(
      item: item ?? this.item,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'item': item.toMap(),
    };
  }

  factory ExternalDeviceDetailState.fromMap(Map<String, dynamic> map) {
    return ExternalDeviceDetailState(
      item: DeviceListItem.fromMap(map['item'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory ExternalDeviceDetailState.fromJson(String source) =>
      ExternalDeviceDetailState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [item];
}
