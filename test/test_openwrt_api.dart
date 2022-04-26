import 'package:moab_poc/packages/openwrt/model/command_reply/send_bootstrap_reply.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/page/landing_page/landing_page.dart';
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

    test('send dpp command', () async {
      final client = OpenWRTClient(device);
      final actual = await client
          .authenticate(input: identity)
          .then((value) => client.execute(value, [
                SendBootstrapReply(ReplyStatus.unknown,
                    bootstrap:
                        'DPP:V:2;K:MDkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDIgADOGZXzmKxZPwzr0ztoyglLs7bUPvqvDwGjFXYi0A3ymw=;;')
              ]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('test regex', () async {
      final testRege = WiFiCredential.parse(
          'WIFI:S:test_s  sid;T:WPA;P:Belkin;;;1H:jjj;23;;;!;H:;;');
    });
  });
}
