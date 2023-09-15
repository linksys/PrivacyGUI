import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/device_list_provider.dart';
import 'package:linksys_app/provider/devices/device_list_state.dart';
import 'package:linksys_app/provider/devices/external_device_detail_state.dart';

final externalDeviceDetailProvider =
    NotifierProvider<ExternalDeviceDetailNotifier, ExternalDeviceDetailState>(
  () => ExternalDeviceDetailNotifier(),
);

class ExternalDeviceDetailNotifier extends Notifier<ExternalDeviceDetailState> {
  @override
  ExternalDeviceDetailState build() {
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    final targetId = ref.watch(deviceDetailIdProvider);
    return createState(filteredDeviceList.$2, targetId);
  }

  ExternalDeviceDetailState createState(
    List<DeviceListItem> filteredDevices,
    String targetId,
  ) {
    var newState = const ExternalDeviceDetailState(item: DeviceListItem());
    // The target Id should never be empty
    if (targetId.isEmpty) {
      return newState;
    }
    final targetItem = filteredDevices.firstWhere(
      (device) => device.deviceId == targetId,
    );
    return newState.copyWith(
      item: targetItem,
    );
  }
}
