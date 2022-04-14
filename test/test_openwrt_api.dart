import 'package:moab_poc/packages/openwrt/model/command_reply/base/command_reply_base.dart';
import 'package:moab_poc/packages/openwrt/model/command_reply/base/reply_base.dart';
import 'package:moab_poc/packages/openwrt/model/command_reply/system_board_reply.dart';
import 'package:moab_poc/packages/openwrt/model/command_reply/system_info_reply.dart';
import 'package:moab_poc/packages/openwrt/model/command_reply/wireless_state_reply.dart';
import 'package:moab_poc/packages/openwrt/model/device.dart';
import 'package:moab_poc/packages/openwrt/model/identity.dart';
import 'package:moab_poc/packages/openwrt/openwrt_client.dart';
import 'package:test/test.dart';

void main() {
  const device = Device(address: '192.168.1.1', port: '80');
  const identity = Identity(username: 'root', password: 'Belkin123');
  group('test OpenWRT authentication', () {
    test('make authenticate', () async {
      final actual = await OpenWRTClient(device, identity).authenticate();
      print('auth: $actual');
      expect(actual, isA<String>());
    });
  });

  group('test uci command', () {
    test('uci state wireless', () async {
      final client = OpenWRTClient(device, identity);
      final actual = await client.authenticate().then((value) =>
          client.execute(value, [WirelessStateReply(ReplyStatus.unknown)]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('ubus system board', () async {
      final client = OpenWRTClient(device, identity);
      final actual = await client.authenticate().then((value) =>
          client.execute(value, [SystemBoardReply(ReplyStatus.unknown)]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('ubus system board', () async {
      final client = OpenWRTClient(device, identity);
      final actual = await client.authenticate().then((value) =>
          client.execute(value, [SystemInfoReply(ReplyStatus.unknown)]));
      expect(actual, isA<List<CommandReplyBase>>());
    });

    test('compose commands', () async {
      final client = OpenWRTClient(device, identity);
      final actual = await client.authenticate().then((value) => client.execute(
              value, [
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
  });
}
