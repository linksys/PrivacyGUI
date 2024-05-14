import 'package:flutter/foundation.dart';
import 'package:privacy_gui/page/devices/_devices.dart';

@immutable
class ExternalDeviceDetailState {
  final DeviceListItem item;

  const ExternalDeviceDetailState({
    required this.item,
  });

  ExternalDeviceDetailState copyWith({
    DeviceListItem? item,
  }) =>
      ExternalDeviceDetailState(
        item: item ?? this.item,
      );
}
