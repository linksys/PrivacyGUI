import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/views/components/channel_finder_chart.dart';

ChannelScanUIModel _channel(int channel, int? utilization,
        {bool inUse = false}) =>
    ChannelScanUIModel(
        channel: channel,
        utilization: utilization,
        isInUse: inUse,
        neighbors: const []);

void main() {
  test('each channel lands in exactly one series, by what it is (#1778)', () {
    final bars = splitChannelBars(ChannelBandScanUIModel(
      band: '2.4GHz',
      channelInUse: 1,
      channels: [
        _channel(1, 200, inUse: true), // in use and busy: busy wins
        _channel(6, 128), // exactly 50 %: busy
        _channel(11, 127), // just under: other
        _channel(3, null), // no reading
        _channel(4, 40, inUse: true), // in use, not busy
      ],
    ));

    expect(bars.busy, [78, 50, 0, 0, 0]);
    expect(bars.inUse, [0, 0, 0, 0, 16]);
    expect(bars.other, [0, 0, 50, 0, 0]);
  });

  test('every series has one value per channel, so the bars line up', () {
    final bars = splitChannelBars(const ChannelBandScanUIModel(
        band: '5GHz', channelInUse: null, channels: []));
    expect([bars.inUse, bars.busy, bars.other], everyElement(isEmpty));
  });
}
