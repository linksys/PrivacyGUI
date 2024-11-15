import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

final instantPrivacyDeviceListProvider = Provider((ref) {
  final deviceListState = ref.watch(deviceListProvider);
  final macFilteringState = ref.watch(instantPrivacyProvider);
  final deviceList = deviceListState.devices;
  final macAddresses = macFilteringState.macAddresses;
  final isEnable = macFilteringState.mode == MacFilterMode.allow;
  return isEnable
      ? deviceList
          .where((device) =>
              macAddresses.contains(device.macAddress.toUpperCase()))
          .toList()
      : deviceList
          .where((device) => !device.isWired && device.isOnline)
          .toList();
});
