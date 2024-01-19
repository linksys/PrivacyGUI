import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/actions/jnap_transaction.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/models/back_haul_info.dart';
import 'package:linksys_app/core/jnap/models/dhcp_lease.dart';
import 'package:linksys_app/core/jnap/models/layer2_connection.dart';
import 'package:linksys_app/core/jnap/models/node_wireless_connection.dart';
import 'package:linksys_app/core/jnap/models/ping_status.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/provider/troubleshooting/device_status.dart';
import 'package:linksys_app/provider/troubleshooting/dhcp_client.dart';
import 'package:linksys_app/provider/troubleshooting/troubleshooting_state.dart';
import 'package:linksys_app/util/extensions.dart';

final troubleshootingProvider =
    NotifierProvider<TroubleshootingNotifier, TroubleshootingState>(
        () => TroubleshootingNotifier());

class TroubleshootingNotifier extends Notifier<TroubleshootingState> {
  @override
  TroubleshootingState build() {
    return const TroubleshootingState(deviceStatusList: [], dhchClientList: []);
  }

  Future fetch({bool force = false}) async {
    // backhaul
    // node wireless connection
    // dhcp
    // devices
    final builder = JNAPTransactionBuilder(commands: [
      const MapEntry(JNAPAction.getDevices, {}),
      const MapEntry(JNAPAction.getDHCPClientLeases, {}),
      const MapEntry(JNAPAction.getBackhaulInfo, {}),
      const MapEntry(JNAPAction.getNodesWirelessNetworkConnections, {}),
      const MapEntry(JNAPAction.getTimeSettings, {}),
    ], auth: true);
    await ref
        .read(routerRepositoryProvider)
        .transaction(builder, fetchRemote: force)
        .then((value) => value.data.fold<Map<JNAPAction, JNAPSuccess>>({},
                (previousValue, element) {
              if (element.value is JNAPSuccess) {
                previousValue[element.key] = element.value as JNAPSuccess;
              }
              return previousValue;
            }))
        .then((results) {
      final devices = _handleDeviceData(results[JNAPAction.getDevices]);
      final dhcpLeases =
          _handleDhcpLeaseData(results[JNAPAction.getDHCPClientLeases]);
      final backHaulInfo =
          _handleBackhaulInfoData(results[JNAPAction.getBackhaulInfo]);
      final nodesWireless = _handleNodesWirelessConnectionData(
          results[JNAPAction.getNodesWirelessNetworkConnections]);
      final currentTime =
          _handleTimeSettings(results[JNAPAction.getTimeSettings]);
      final slaves =
          devices.where((device) => device.nodeType == 'Slave').toList();
      final externals = devices
          .where((device) =>
              !device.isAuthority &&
              device.nodeType == null &&
              device.connections.isNotEmpty)
          .toList();
      final deviceStatusList = [...slaves, ...externals]
          .fold<List<DeviceStatusModel>>([], (previousValue, device) {
        final name = device.getDeviceLocation();
        final ipv4 = device.connections.firstOrNull?.ipAddress;
        final ipv6 = device.connections.firstOrNull?.ipv6Address;
        final mac = device.getMacAddress();
        final isWired = device.isWiredConnection();
        if (ipv4 != null) {
          previousValue.add(DeviceStatusModel.ipv4(
              name: name,
              mac: mac,
              ipAddress: ipv4,
              connection: isWired ? 'LAN' : 'Wireless'));
        }
        if (ipv6 != null) {
          previousValue.add(DeviceStatusModel.ipv6(
              name: name,
              mac: mac,
              ipAddress: ipv6,
              connection: isWired ? 'LAN' : 'Wireless'));
        }
        return previousValue;
      });

      //

      final dhcpList = dhcpLeases.where((e) {
        return devices.any((device) => device.containsMacAddress(e.macAddress));
      }).map((e) {
        final device = devices.firstWhereOrNull(
            (element) => element.containsMacAddress(e.macAddress));
        final name = e.hostName ?? device?.getDeviceLocation() ?? 'Unknown';
        final ip = e.ipAddress;
        final mac = e.macAddress;
        final interface = (devices
                    .firstWhereOrNull(
                        (element) => element.getMacAddress() == mac)
                    ?.isWiredConnection() ??
                false)
            ? 'LAN'
            : 'Wireless';
        final isOnline = devices
                .firstWhereOrNull(
                    (device) => device.containsMacAddress(e.macAddress))
                ?.connections
                .isNotEmpty ??
            false;
        final expiresTime =
            DateTime.parse(e.expiration).millisecondsSinceEpoch -
                (currentTime?.millisecondsSinceEpoch ?? 0);
        final durationExpires = Duration(milliseconds: expiresTime);
        final expireTimeStr = durationExpires.convertToHMS();
        return DhcpClientModel(
          name: name,
          mac: mac,
          interface: isOnline ? interface : 'Offline',
          ipAddress: ip,
          expires: expireTimeStr,
        );
      }).toList()
        ..sort((a, b) => a.interface.compareTo(b.interface));
      state = state.copyWith(
          deviceStatusList: deviceStatusList, dhchClientList: dhcpList);
    });
  }

  Future ping({required String host, required int? pingCount}) {
    return ref.read(routerRepositoryProvider).send(JNAPAction.startPing,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        data: {'host': host, 'packetSizeBytes': 32, 'pingCount': pingCount}
          ..removeWhere((key, value) => value == null));
  }

  Stream<PingStatus> getPingStatus() {
    return ref
        .read(routerRepositoryProvider)
        .scheduledCommand(
            action: JNAPAction.getPinStatus,
            retryDelayInMilliSec: 10,
            condition: (result) {
              final status = PingStatus.fromMap(result.output);
              return !status.isRunning;
            })
        .map((event) {
      if (event is JNAPSuccess) {
        return PingStatus.fromMap(event.output);
      } else {
        throw event;
      }
    });
  }

  Future factoryReset() {
    return ref.read(routerRepositoryProvider).send(JNAPAction.factoryReset,
        fetchRemote: true, cacheLevel: CacheLevel.noCache);
  }

  List<LinksysDevice> _handleDeviceData(JNAPSuccess? data) {
    if (data == null) {
      return [];
    }
    return List.from(data.output['devices'])
        .map((e) => LinksysDevice.fromMap(e))
        .toList();
  }

  List<DhcpLease> _handleDhcpLeaseData(JNAPSuccess? data) {
    if (data == null) {
      return [];
    }
    return List.from(data.output['leases'])
        .map((e) => DhcpLease.fromMap(e))
        .toList();
  }

  List<BackHaulInfoData> _handleBackhaulInfoData(JNAPSuccess? data) {
    if (data == null) {
      return [];
    }
    return List.from(data.output['backhaulDevices'])
        .map((e) => BackHaulInfoData.fromMap(e))
        .toList();
  }

  List<Layer2Connection> _handleNodesWirelessConnectionData(JNAPSuccess? data) {
    if (data == null) {
      return [];
    }
    return List.from(data.output['nodeWirelessConnections']).fold([],
        (previousValue, element) {
      final nodeWirelessConnection = NodeWirelessConnections.fromMap(element);
      return previousValue..addAll(nodeWirelessConnection.connections);
    });
  }

  DateTime? _handleTimeSettings(JNAPSuccess? data) {
    if (data == null) {
      return null;
    }
    final timeStr = data.output['currentTime'];
    return DateTime.parse(timeStr);
  }
}
