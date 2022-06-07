import 'dart:convert';
import 'dart:io';

import 'package:moab_poc/packages/openwrt/model/command_reply/wan_status_reply.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/util/connectivity.dart';
import 'package:moab_poc/util/wifi_credential.dart';
import 'package:test/test.dart';

void main() {
  const device = Device(address: '192.168.1.10', port: '80');
  const identity = Identity(username: 'root', password: 'Belkin123');
  group('test OpenWRT authentication', () {
    test('make authenticate', () async {
      final actual = await OpenWRTClient(device).authenticate(input: identity);
      print('auth: $actual');
      expect(actual, isA<String>());
    });
  });

  group('test uci command', () {
    test('uci state wireless', () async {
      final client = OpenWRTClient(device);
      final actual = await client.authenticate(input: identity).then((value) =>
          client.execute(value, [WirelessStateReply(ReplyStatus.unknown)]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('ubus system board', () async {
      final client = OpenWRTClient(device);
      final actual = await client.authenticate(input: identity).then((value) =>
          client.execute(value, [SystemBoardReply(ReplyStatus.unknown)]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('ubus system info', () async {
      final client = OpenWRTClient(device);
      final actual = await client.authenticate(input: identity).then((value) =>
          client.execute(value, [SystemInfoReply(ReplyStatus.unknown)]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('ubus network.device and targeting to eth1', () async {
      final client = OpenWRTClient(device);
      final actual = await client.authenticate(input: identity).then((value) =>
          client.execute(value, [NetworkStatusReply(ReplyStatus.unknown)]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('compose commands', () async {
      final client = OpenWRTClient(device);
      final actual = await client.authenticate(input: identity).then((value) =>
          client.execute(value, [
            SystemInfoReply(ReplyStatus.unknown),
            SystemBoardReply(ReplyStatus.unknown)
          ]));
      expect(
          actual,
          isA<List<CommandReplyBase>>()
              .having((response) => response.length, 'response size', 2)
              .having((response) => response[0] is SystemInfoReply,
                  'first response', true)
              .having((response) => response[1] is SystemBoardReply,
                  'second respond', true));
    });

    test('test wan status', () async {
      final client = OpenWRTClient(device);
      final actual = await client.authenticate(input: identity).then((value) =>
          client.execute(value, [WanStatusReply(ReplyStatus.unknown)]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('test regex', () async {
      final testRege = WiFiCredential.parse(
          'WIFI:S:test_s  sid;T:WPA;P:Belkin;;;1H:jjj;23;;;!;H:;;');
    });
    test('test socket', () async {
      // final channel = WebSocketChannel.connect(Uri.parse('ws://192.168.1.10'));
      // channel.stream.listen((event) {
      //   print(event);
      // });
      // channel.sink.add('data');
      //
      // print("socket:: ${channel.closeCode ?? '-1'}");
      // Future.delayed(Duration(seconds: 10));

      const bootstrap =
          'DPP:V:2;K:MDkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDIgADJNlVv3IkDhtDAmypbYrk+MXMmYnfJmVjNJDlFcZEN2U=;;';
      Socket socket = await Socket.connect('192.168.1.10', 8000);
      socket.write('"peer_bs_info":"$bootstrap"');
      await socket.flush();
      String _response = await utf8.decoder.bind(socket).join();
      print('Socket: $_response');
      await socket.close();
    });
  });
}
