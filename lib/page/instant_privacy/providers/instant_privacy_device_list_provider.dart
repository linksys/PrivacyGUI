import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

final instantPrivacyDeviceListProvider = Provider((ref) {
  final deviceListState = ref.watch(deviceListProvider);
  final macFilteringState = ref.watch(instantPrivacyProvider);
  final nodeList =
      ref.watch(deviceManagerProvider.select((state) => state.nodeDevices));
  final deviceList = deviceListState.devices;
  final macAddresses = macFilteringState.settings.current.macAddresses;
  final isEnable =
      macFilteringState.settings.current.mode == MacFilterMode.allow;
  return isEnable
      ? macAddresses
          .map((e) =>
              deviceList.firstWhereOrNull((device) => device.macAddress == e) ??
              DeviceListItem(macAddress: e))
          .where((device) =>
              !macFilteringState.settings.current.bssids
                  .contains(device.macAddress) &&
              deviceList.any((e) => e.macAddress == device.macAddress) &&
              !nodeList.any((e) => e.getMacAddress() == device.macAddress))
          .toList()
      : deviceList
          .where((device) => !device.isWired && device.isOnline)
          .toList();
});
