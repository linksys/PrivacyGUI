import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/devices/_devices.dart';

final externalDeviceDetailProvider =
    NotifierProvider<ExternalDeviceDetailNotifier, ExternalDeviceDetailState>(
  () => ExternalDeviceDetailNotifier(),
);

class ExternalDeviceDetailNotifier extends Notifier<ExternalDeviceDetailState> {
  @override
  ExternalDeviceDetailState build() {
    final filteredDeviceList = ref.watch(deviceListProvider).devices;
    final targetId = ref.watch(deviceDetailIdProvider);
    return createState(filteredDeviceList, targetId);
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
    newState = newState.copyWith(
      item: targetItem,
    );
    return newState;
  }
}
