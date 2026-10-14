import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';

final clientAccessPolicyProvider = FutureProvider.autoDispose((ref) async {
  final result = await ref.read(routerRepositoryProvider).send(
        JNAPAction.getMACFilterSettings,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
  return MACFilterSettings.fromMap(result.output);
});

/// Policy restrictions and connection status are independent. In deny mode,
/// retain every saved MAC even if its device record has been forgotten.
/// Allow mode can enumerate only Wi-Fi interfaces known to the router.
final restrictedDevicesProvider = Provider.autoDispose((ref) {
  final policy = ref.watch(clientAccessPolicyProvider);
  final devices = ref.watch(deviceListProvider).devices;
  final rawDevices = ref.watch(deviceManagerProvider).externalDevices;
  return policy.whenData((settings) {
    final named = <String, DeviceListItem>{};
    final wireless = <String>{};
    for (final device in devices) {
      final mac = device.macAddress.toUpperCase();
      if (mac.isEmpty) continue;
      named[mac] = device;
      if (device.isOnlineWireless) wireless.add(mac);
    }
    for (final raw in rawDevices) {
      final device =
          devices.firstWhereOrNull((d) => d.deviceId == raw.deviceID);
      if (device == null) continue;
      for (final mac in [
        ...?raw.knownMACAddresses,
        ...?raw.knownInterfaces?.map((i) => i.macAddress),
        ...raw.connections.map((c) => c.macAddress),
      ]) {
        named[mac.toUpperCase()] = device;
      }
      for (final interface in raw.knownInterfaces ?? []) {
        if (interface.interfaceType == 'Wireless') {
          wireless.add(interface.macAddress.toUpperCase());
        }
      }
    }
    final addresses = settings.macAddresses.map((a) => a.toUpperCase()).toSet();
    final Set<String> restricted;
    switch (settings.macFilterMode.toLowerCase()) {
      case 'disabled':
        restricted = {};
      case 'deny':
        restricted = addresses;
      case 'allow':
        restricted = wireless.difference(addresses);
      default:
        throw StateError('Unsupported MAC access policy');
    }
    return restricted.map((mac) {
      final device = named[mac] ?? DeviceListItem(name: mac);
      return device.copyWith(macAddress: mac);
    }).toList();
  });
});
