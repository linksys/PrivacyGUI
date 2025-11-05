import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';

final macFilteringDeviceListProvider = Provider((ref) {
  final deviceListState = ref.watch(deviceListProvider);
  final wifiBundleState = ref.watch(wifiBundleProvider);
  final deviceList = deviceListState.devices.where((device) => !device.isWired);
  final macAddresses = wifiBundleState.current.privacy.denyMacAddresses;
  final bssidList = wifiBundleState.current.privacy.bssids;
  return (macAddresses.toSet())
      .difference(bssidList.toSet())
      .toList()
      .map((e) =>
          deviceList.firstWhereOrNull((device) => device.macAddress == e) ??
          DeviceListItem(macAddress: e, name: '--'))
      .toList();
});
