import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';

final macFilteringDeviceListProvider = Provider((ref) {
  final deviceListState = ref.watch(deviceListProvider);
  final macFilteringState = ref.watch(instantPrivacyProvider);
  final deviceList = deviceListState.devices.where((device) => !device.isWired);
  final macAddresses = macFilteringState.settings.denyMacAddresses;
  final bssidList = macFilteringState.settings.bssids;
  return (macAddresses.toSet()).difference(bssidList.toSet()).toList()
      .map((e) =>
          deviceList.firstWhereOrNull((device) => device.macAddress == e) ??
          DeviceListItem(macAddress: e, name: '--'))
      .toList();
});
