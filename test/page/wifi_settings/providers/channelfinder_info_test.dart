import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channelfinder_info.dart';

void main() {
  group('Channel', () {
    test('creates instance with required fields', () {
      const channel =
          Channel(radioID: 'RADIO_2.4GHz', band: '2.4GHz', channel: 6);
      expect(channel.radioID, 'RADIO_2.4GHz');
      expect(channel.band, '2.4GHz');
      expect(channel.channel, 6);
      expect(channel.optimizedChannel, isNull);
      expect(channel.isOptimized, isNull);
      expect(channel.dfs, isNull);
    });

    test('creates instance with optional fields', () {
      const channel = Channel(
        radioID: 'RADIO_5GHz',
        band: '5GHz',
        channel: 36,
        optimizedChannel: 40,
        isOptimized: true,
        dfs: false,
      );
      expect(channel.optimizedChannel, 40);
      expect(channel.isOptimized, true);
      expect(channel.dfs, false);
    });

    test('copyWith updates specified fields', () {
      const original =
          Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      final copied = original.copyWith(optimizedChannel: 40, isOptimized: true);
      expect(copied.optimizedChannel, 40);
      expect(copied.isOptimized, true);
      expect(copied.channel, 36);
    });

    test('fromJson creates instance from json', () {
      final json = {'radioID': 'RADIO_5GHz', 'band': '5GHz', 'channel': 149};
      final channel = Channel.fromJson(json);
      expect(channel.radioID, 'RADIO_5GHz');
      expect(channel.channel, 149);
    });

    test('toJson converts to json correctly', () {
      const channel =
          Channel(radioID: 'RADIO_2.4GHz', band: '2.4GHz', channel: 6);
      final json = channel.toJson();
      expect(json['radioID'], 'RADIO_2.4GHz');
      expect(json['channel'], 6);
    });

    test('equality comparison works', () {
      const c1 = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const c2 = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      expect(c1, c2);
    });
  });

  group('SelectedChannels', () {
    test('creates instance with required fields', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const selected =
          SelectedChannels(deviceID: 'device1', channels: [channel]);
      expect(selected.deviceID, 'device1');
      expect(selected.channels, hasLength(1));
    });

    test('copyWith updates specified fields', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const original =
          SelectedChannels(deviceID: 'device1', channels: [channel]);
      final copied = original.copyWith(deviceID: 'device2');
      expect(copied.deviceID, 'device2');
      expect(copied.channels, hasLength(1));
    });

    test('fromJson creates instance from json', () {
      final json = {
        'deviceID': 'device1',
        'channels': [
          {'radioID': 'RADIO_5GHz', 'band': '5GHz', 'channel': 36}
        ],
      };
      final selected = SelectedChannels.fromJson(json);
      expect(selected.deviceID, 'device1');
      expect(selected.channels, hasLength(1));
    });

    test('equality comparison works', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const s1 = SelectedChannels(deviceID: 'device1', channels: [channel]);
      const s2 = SelectedChannels(deviceID: 'device1', channels: [channel]);
      expect(s1, s2);
    });
  });

  group('OptimizedSelectedChannel', () {
    test('creates instance with required fields', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const optimized = OptimizedSelectedChannel(
        deviceID: 'device1',
        channels: [channel],
        deviceName: 'My Router',
        deviceIcon: 'router_icon',
      );
      expect(optimized.deviceID, 'device1');
      expect(optimized.deviceName, 'My Router');
      expect(optimized.deviceIcon, 'router_icon');
    });

    test('copyWith updates specified fields', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const original =
          OptimizedSelectedChannel(deviceID: 'device1', channels: [channel]);
      final copied = original.copyWith(deviceName: 'Updated Name');
      expect(copied.deviceName, 'Updated Name');
      expect(copied.deviceID, 'device1');
    });

    test('fromJson creates instance from json', () {
      final json = {
        'deviceID': 'device1',
        'channels': [
          {'radioID': 'RADIO_5GHz', 'band': '5GHz', 'channel': 36}
        ],
      };
      final optimized = OptimizedSelectedChannel.fromJson(json);
      expect(optimized.deviceID, 'device1');
      expect(optimized.channels, hasLength(1));
    });

    test('equality comparison works', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const o1 =
          OptimizedSelectedChannel(deviceID: 'device1', channels: [channel]);
      const o2 =
          OptimizedSelectedChannel(deviceID: 'device1', channels: [channel]);
      expect(o1, o2);
    });

    test('props returns correct list', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const optimized = OptimizedSelectedChannel(
        deviceID: 'device1',
        channels: [channel],
        deviceName: 'Router',
        deviceIcon: 'icon',
      );
      expect(optimized.props, [
        optimized.deviceID,
        optimized.channels,
        optimized.deviceName,
        optimized.deviceIcon,
      ]);
    });
  });
}
