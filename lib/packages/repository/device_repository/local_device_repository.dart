import 'dart:convert';
import 'dart:io';

import 'package:moab_poc/packages/openwrt/model/command_reply/wan_status_reply.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/model/wan_staus.dart';
import 'package:moab_poc/util/connectivity.dart';

import 'base_device_repository.dart';
import 'model/model.dart';

class LocalDeviceRepository extends DeviceRepository {
  LocalDeviceRepository(OpenWRTClient client) : super(client);

  @override
  Future<SystemInfo> getSystemInfo() async {
    final result = await client.authenticate().then((value) => client.execute(
            value, [
          SystemBoardReply(ReplyStatus.unknown),
          SystemInfoReply(ReplyStatus.unknown)
        ]));
    return SystemInfo.fromJson(result[0].data);
  }

  @override
  Future<WirelessInfoList> getWirelessInfo() async {
    final result =
        await client.authenticate().then((value) => client.execute(value, [
              WirelessStateReply(ReplyStatus.unknown),
            ]));
    return WirelessInfoList.fromJson(result.first.data);
  }

  @override
  Future<NetworkInfo> getNetworkInfo() async {
    final result = await client.authenticate().then((value) =>
        client.execute(value, [NetworkStatusReply(ReplyStatus.unknown)]));
    return NetworkInfo.fromJson(result.first.data);
  }

  @override
  Future<bool> login(String username, String password) async {
    try {
      final authCode = await client.authenticate(
          input: Identity(username: username, password: password));
      if (authCode.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> sendBootstrap(String bootstrap) async {
    String ip = ConnectivityUtil.info.gatewayIp;

    try {
      Socket socket = await Socket.connect(ip, 8000);
      socket.write('"peer_bs_info":"$bootstrap"');
      await socket.flush();
      String _response = await utf8.decoder.bind(socket).join();
      print('Socket: $_response');
      await socket.close();
      return true;
    } catch (e) {
      print('Socket: not able to connect to $ip: $e');
      return false;
    }
  }

  @override
  Future<WanStatus> getWanStatus() async {
    final result = await client.authenticate().then((value) =>
        client.execute(value, [WanStatusReply(ReplyStatus.unknown)]));
    return WanStatus.fromJson(result.first.data);
  }
}
