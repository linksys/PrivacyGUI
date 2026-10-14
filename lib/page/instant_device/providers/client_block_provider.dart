import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';

enum ClientBlockOutcome {
  disconnectRequested,
  policyOnly,
  disconnectFailed,
  unverified
}

enum ClientBlockFailure {
  unavailable,
  protectedDevice,
  capacity,
  unsupportedPolicy,
  busy
}

class ClientBlockException implements Exception {
  const ClientBlockException(this.failure);
  final ClientBlockFailure failure;
}

final clientBlockProvider = Provider((ref) => ClientBlockService(ref));

/// Changes Wi-Fi admission first, then asks the router to deauthenticate the
/// station. A saved block remains in place if the immediate disconnect fails.
class ClientBlockService {
  ClientBlockService(this.ref);
  final Ref ref;
  bool _busy = false;

  DeviceListItem _target(String deviceId) {
    var item = ref
        .read(deviceListProvider)
        .devices
        .firstWhereOrNull((device) => device.deviceId == deviceId);
    final connectedDevice = ref
        .read(deviceManagerProvider)
        .externalDevices
        .firstWhereOrNull((device) => device.deviceID == deviceId);
    if (connectedDevice != null) {
      // Known interfaces can include Ethernet or an old randomized MAC. Use
      // the station actually connected now for both admission and deauth.
      final connection = connectedDevice.connections.firstOrNull;
      if (connection == null) {
        throw const ClientBlockException(ClientBlockFailure.unavailable);
      }
      item = item?.copyWith(macAddress: connection.macAddress);
    }
    if (item == null ||
        !item.isOnlineWireless ||
        !RegExp(r'^(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$')
            .hasMatch(item.macAddress) ||
        item.macAddress == '00:00:00:00:00:00' ||
        int.parse(item.macAddress.substring(0, 2), radix: 16).isOdd) {
      throw const ClientBlockException(ClientBlockFailure.unavailable);
    }
    return item;
  }

  bool _hasMac(LinksysDevice device, String mac) => [
        ...?device.knownMACAddresses,
        ...?device.knownInterfaces?.map((interface) => interface.macAddress),
        ...device.connections.map((connection) => connection.macAddress),
      ].any((address) => address.toUpperCase() == mac);

  Future<MACFilterSettings> _settings(RouterRepository repo) async =>
      MACFilterSettings.fromMap((await repo.send(
        JNAPAction.getMACFilterSettings,
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      ))
          .output);

  Future<ClientBlockOutcome> block(String deviceId) async {
    if (_busy) throw const ClientBlockException(ClientBlockFailure.busy);
    _busy = true;
    try {
      enforceAccess(
          ref, (policy) => policy.checkWrite(JNAPAction.setMACFilterSettings));
      final target = _target(deviceId);
      final mac = target.macAddress.toUpperCase();
      final manager = ref.read(deviceManagerProvider);
      if (manager.nodeDevices
          .any((node) => node.deviceID == deviceId || _hasMac(node, mac))) {
        throw const ClientBlockException(ClientBlockFailure.protectedDevice);
      }
      final repo = ref.read(routerRepositoryProvider);
      if (!ref.read(isRemoteLoginProvider)) {
        final local = await repo.send(JNAPAction.getLocalDevice,
            auth: true, fetchRemote: true, cacheLevel: CacheLevel.noCache);
        final localId = local.output['deviceID'];
        if (localId is! String || localId.isEmpty) {
          throw const ClientBlockException(ClientBlockFailure.unavailable);
        }
        if (localId == deviceId ||
            manager.deviceList.any((device) =>
                device.deviceID == localId && _hasMac(device, mac))) {
          throw const ClientBlockException(ClientBlockFailure.protectedDevice);
        }
      }
      if (serviceHelper.isSupportGetSTABSSID()) {
        final result = await repo.send(JNAPAction.getSTABSSIDs,
            auth: true, fetchRemote: true, cacheLevel: CacheLevel.noCache);
        if (List<String>.from(result.output['staBSSIDS'])
            .any((address) => address.toUpperCase() == mac)) {
          throw const ClientBlockException(ClientBlockFailure.protectedDevice);
        }
      }
      final before = await _settings(repo);
      final existing =
          before.macAddresses.map((address) => address.toUpperCase()).toSet();
      final String mode;
      final Set<String> addresses;
      switch (before.macFilterMode.toLowerCase()) {
        case 'disabled':
          mode = 'Deny';
          // Inactive entries may have come from an allow list. Enabling them
          // as a deny list would unexpectedly block other devices.
          addresses = {mac};
        case 'deny':
          mode = 'Deny';
          addresses = {...existing, mac};
        case 'allow':
          mode = 'Allow';
          addresses = {...existing}..remove(mac);
        default:
          throw const ClientBlockException(
              ClientBlockFailure.unsupportedPolicy);
      }
      if (addresses.length > before.maxMACAddresses) {
        throw const ClientBlockException(ClientBlockFailure.capacity);
      }
      // The client may have moved to Ethernet or disappeared during the reads.
      if (_target(deviceId).macAddress.toUpperCase() != mac) {
        throw const ClientBlockException(ClientBlockFailure.unavailable);
      }
      if (before.macFilterMode.toLowerCase() != mode.toLowerCase() ||
          !const SetEquality<String>().equals(existing, addresses)) {
        await repo.send(JNAPAction.setMACFilterSettings,
            data: {'macFilterMode': mode, 'macAddresses': addresses.toList()},
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache);
        if (ref.exists(instantPrivacyProvider)) {
          ref.invalidate(instantPrivacyProvider);
        }
        try {
          final applied = await _settings(repo);
          if (applied.macFilterMode.toLowerCase() != mode.toLowerCase() ||
              !const SetEquality<String>().equals(
                  applied.macAddresses
                      .map((address) => address.toUpperCase())
                      .toSet(),
                  addresses)) {
            return ClientBlockOutcome.unverified;
          }
        } catch (_) {
          return ClientBlockOutcome.unverified;
        }
      }
      var outcome = ClientBlockOutcome.policyOnly;
      if (serviceHelper.isSupportClientDeauth()) {
        try {
          await repo.send(JNAPAction.clientDeauth,
              data: {'macAddress': mac},
              auth: true,
              fetchRemote: true,
              cacheLevel: CacheLevel.noCache);
          outcome = ClientBlockOutcome.disconnectRequested;
        } catch (_) {
          outcome = ClientBlockOutcome.disconnectFailed;
        }
      }
      try {
        await ref.read(pollingProvider.notifier).forcePolling();
      } catch (_) {
        logger.w('Client block saved; device-list refresh failed.');
      }
      return outcome;
    } finally {
      _busy = false;
    }
  }
}
