import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';

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
    // Gone from the list: deleted, or dropped by the router while its page was
    // open. The page shows no device, as before one is picked.
    final targetItem = filteredDevices.firstWhereOrNull(
      (device) => device.deviceId == targetId,
    );
    if (targetItem == null) {
      return newState;
    }
    newState = newState.copyWith(
      item: targetItem,
    );
    logger.d('[State]:[ExternalDeviceDetail]:${newState.toJson()}');
    return newState;
  }
}
