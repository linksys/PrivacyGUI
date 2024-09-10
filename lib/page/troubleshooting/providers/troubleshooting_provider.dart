import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/models/dhcp_lease.dart';
import 'package:privacy_gui/core/jnap/models/layer2_connection.dart';
import 'package:privacy_gui/core/jnap/models/node_wireless_connection.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/core/jnap/models/send_sysinfo_email.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';
import 'package:privacy_gui/page/troubleshooting/providers/troubleshooting_state.dart';
import 'package:privacy_gui/util/extensions.dart';

final troubleshootingProvider =
    NotifierProvider<TroubleshootingNotifier, TroubleshootingState>(
        () => TroubleshootingNotifier());

class TroubleshootingNotifier extends Notifier<TroubleshootingState> {
  @override
  TroubleshootingState build() {
    return const TroubleshootingState(deviceStatusList: [], dhcpClientList: []);
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
              device.isOnline())
          .toList();
      final deviceStatusList = [...slaves, ...externals]
          .fold<List<DeviceStatusModel>>([], (previousValue, device) {
        final name = device.getDeviceLocation();
        final ipv4 = device.connections.firstOrNull?.ipAddress;
        final ipv6 = device.connections.firstOrNull?.ipv6Address;
        final mac = device.getMacAddress();
        final isWired =
            device.getConnectionType() == DeviceConnectionType.wired;
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
                        ?.getConnectionType() ==
                    DeviceConnectionType.wired) ==
                true
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

  Future sendRouterInfo({required String userEmailList}) {
    if (kDebugMode) {}
    List<String> emailList = [
      kDebugMode
          ? 'routerinfo-internal@integrationtests.linksys.com'
          : 'routerinfo@linksys.com'
    ];
    userEmailList = userEmailList.replaceAll(RegExp(r' '), '');
    if (userEmailList.contains(',')) {
      emailList.addAll(userEmailList.split(','));
    } else if (userEmailList.isNotEmpty) {
      emailList.add(userEmailList);
    }

    return ref.read(routerRepositoryProvider).send(
          JNAPAction.sendSysinfoEmail,
          auth: true,
          data: SendSysinfoEmail(addressList: emailList).toJson(),
          timeoutMs: 30000,
        );
  }

  Future ping({required String host, required int? pingCount}) {
    return ref.read(routerRepositoryProvider).send(JNAPAction.startPing,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        auth: true,
        data: {'host': host, 'packetSizeBytes': 32, 'pingCount': pingCount}
          ..removeWhere((key, value) => value == null));
  }

  Stream<PingStatus> getPingStatus() {
    return ref
        .read(routerRepositoryProvider)
        .scheduledCommand(
          action: JNAPAction.getPinStatus,
          retryDelayInMilliSec: 100,
          condition: (result) {
            if (result is JNAPSuccess) {
              final status = PingStatus.fromMap(result.output);
              return !status.isRunning;
            } else {
              return false;
            }
          },
          auth: true,
        )
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
