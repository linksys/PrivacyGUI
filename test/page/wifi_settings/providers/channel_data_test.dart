import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channel_data.dart';

void main() {
  group('ChannelDataInfo', () {
    test('creates instance with required fields', () {
      const info = ChannelDataInfo(
        band: '5GHz',
        channel: 36,
        frequency: '5180 MHz',
        dfs: false,
        unii: [1],
      );
      expect(info.band, '5GHz');
      expect(info.channel, 36);
      expect(info.frequency, '5180 MHz');
      expect(info.dfs, false);
      expect(info.unii, [1]);
    });

    test('copyWith updates specified fields', () {
      const original = ChannelDataInfo(
        band: '5GHz',
        channel: 36,
        frequency: '5180 MHz',
        dfs: false,
        unii: [1],
      );
      final copied = original.copyWith(channel: 40, dfs: true);
      expect(copied.channel, 40);
      expect(copied.dfs, true);
      expect(copied.band, '5GHz');
    });

    test('toMap converts to map correctly', () {
      const info = ChannelDataInfo(
        band: '2.4GHz',
        channel: 6,
        frequency: '2437 MHz',
        dfs: false,
        unii: [],
      );
      final map = info.toMap();
      expect(map['band'], '2.4GHz');
      expect(map['channel'], 6);
      expect(map['frequency'], '2437 MHz');
      expect(map['dfs'], false);
      expect(map['unii'], isEmpty);
    });

    test('fromMap creates instance from map', () {
      final map = {
        'band': '5GHz',
        'channel': 149,
        'frequency': '5745 MHz',
        'dfs': true,
        'unii': [3],
      };
      final info = ChannelDataInfo.fromMap(map);
      expect(info.band, '5GHz');
      expect(info.channel, 149);
      expect(info.dfs, true);
      expect(info.unii, [3]);
    });

    test('toJson/fromJson round-trip works', () {
      const original = ChannelDataInfo(
        band: '5GHz',
        channel: 36,
        frequency: '5180 MHz',
        dfs: false,
        unii: [1],
      );
      final json = original.toJson();
      final restored = ChannelDataInfo.fromJson(json);
      expect(restored, original);
    });

    test('equality comparison works', () {
      const info1 = ChannelDataInfo(
        band: '5GHz',
        channel: 36,
        frequency: '5180 MHz',
        dfs: false,
        unii: [1],
      );
      const info2 = ChannelDataInfo(
        band: '5GHz',
        channel: 36,
        frequency: '5180 MHz',
        dfs: false,
        unii: [1],
      );
      expect(info1, info2);
    });

    test('distinguishes different channels', () {
      const info1 = ChannelDataInfo(
        band: '5GHz',
        channel: 36,
        frequency: '5180 MHz',
        dfs: false,
        unii: [1],
      );
      const info2 = ChannelDataInfo(
        band: '5GHz',
        channel: 40,
        frequency: '5200 MHz',
        dfs: false,
        unii: [1],
      );
      expect(info1, isNot(info2));
    });

    test('props returns correct list', () {
      const info = ChannelDataInfo(
        band: '5GHz',
        channel: 36,
        frequency: '5180 MHz',
        dfs: false,
        unii: [1],
      );
      expect(info.props,
          [info.band, info.channel, info.frequency, info.dfs, info.unii]);
    });

    test('stringify returns true', () {
      const info = ChannelDataInfo(
        band: '5GHz',
        channel: 36,
        frequency: '5180 MHz',
        dfs: false,
        unii: [1],
      );
      expect(info.stringify, true);
    });
  });
}
