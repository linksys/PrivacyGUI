import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';

ChannelScanUIModel _channel({
  int channel = 36,
  int? utilization,
  bool isInUse = false,
  List<ChannelNeighborUIModel> neighbors = const [],
}) =>
    ChannelScanUIModel(
      channel: channel,
      utilization: utilization,
      isInUse: isInUse,
      neighbors: neighbors,
    );

void main() {
  group('ChannelScanUIModel', () {
    test('utilizationPercent scales 0-255 to a whole percent', () {
      expect(_channel(utilization: 0).utilizationPercent, 0);
      expect(_channel(utilization: 10).utilizationPercent, 4);
      expect(_channel(utilization: 128).utilizationPercent, 50);
      expect(_channel(utilization: 255).utilizationPercent, 100);
      expect(_channel().utilizationPercent, isNull);
    });

    test('strongestSignalDbm is the first neighbour, or null', () {
      expect(_channel().strongestSignalDbm, isNull);
      expect(
        _channel(neighbors: const [
          ChannelNeighborUIModel(ssid: 'a', bssid: 'x', signalDbm: -40),
          ChannelNeighborUIModel(ssid: 'b', bssid: 'y', signalDbm: -70),
        ]).strongestSignalDbm,
        -40,
      );
    });
  });

  group('ChannelBandScanUIModel', () {
    test('inUse is the row of the channel the radio is on', () {
      final band =
          ChannelBandScanUIModel(band: '5GHz', channelInUse: 48, channels: [
        _channel(channel: 36),
        _channel(channel: 48, isInUse: true),
      ]);
      expect(band.inUse?.channel, 48);
    });

    test('identifier keys are slugs of the band and channel', () {
      final band = ChannelBandScanUIModel(
          band: '2.4GHz', channelInUse: 1, channels: [_channel(channel: 1)]);
      expect(band.identifierKey, '2-4ghz');
      expect(band.channelIdentifierKey(_channel(channel: 11)), '2-4ghz-11');
      expect(
          const ChannelBandScanUIModel(
              band: '5GHz',
              channelInUse: null,
              channels: []).channelIdentifierKey(_channel(channel: 149)),
          '5ghz-149');
    });

    test('inUse is null when no row is in use', () {
      final band = ChannelBandScanUIModel(
          band: '5GHz', channelInUse: null, channels: [_channel(channel: 36)]);
      expect(band.inUse, isNull);
    });
  });
}
