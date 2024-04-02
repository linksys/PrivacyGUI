import 'package:flutter/foundation.dart';
import 'package:linksys_app/page/devices/_devices.dart';

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
