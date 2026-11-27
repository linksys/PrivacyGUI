/// Composed scenes for the Channel Finder dashboard card (#1778): one per state
/// the card renders, ready to hand to `channelFinderOverrides`.
///
/// [channelFinderDoneState] is the card's default fixture — the one
/// `kitchenSinkOverrides()` feeds every dashboard harness. The other three are
/// the layout gate's data profiles for this card (`card_data_profiles.dart`):
/// each renders a different tree, so a clean verdict on one says nothing about
/// the others.
library;

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';

/// A three-band result, at the card's widest: a 3-digit 6 GHz channel, one
/// band whose in-use channel was not measured (so it reads the longest
/// busyness string), and network counts of none, one and several.
///
/// The time is only ever shown as a time of day, and nothing compares it with
/// the clock, so a fixed one cannot go stale.
final channelFinderTriBandResult = ChannelFinderResultUIModel(
  scannedAt: DateTime(2026, 11, 26, 10, 54),
  bands: const [
    ChannelBandScanUIModel(band: '2.4GHz', channelInUse: 11, channels: [
      ChannelScanUIModel(
          channel: 1, utilization: 60, isInUse: false, neighbors: []),
      ChannelScanUIModel(
        channel: 11,
        // 72 %: over the 50 % line, so the bar takes the warning colour.
        utilization: 184,
        isInUse: true,
        neighbors: [
          ChannelNeighborUIModel(
              ssid: 'Cafe', bssid: 'aa:bb:cc:00:0b:01', signalDbm: -52),
          ChannelNeighborUIModel(
              ssid: '', bssid: 'aa:bb:cc:00:0b:02', signalDbm: -71),
          ChannelNeighborUIModel(
              ssid: 'Office', bssid: 'aa:bb:cc:00:0b:03', signalDbm: -80),
        ],
      ),
    ]),
    ChannelBandScanUIModel(band: '5GHz', channelInUse: 149, channels: [
      ChannelScanUIModel(
        channel: 149,
        // The channel scan did not reach it: "Busyness not measured".
        utilization: null,
        isInUse: true,
        neighbors: [
          ChannelNeighborUIModel(
              ssid: 'Lobby', bssid: 'aa:bb:cc:00:95:01', signalDbm: -45),
        ],
      ),
    ]),
    ChannelBandScanUIModel(band: '6GHz', channelInUse: 229, channels: [
      ChannelScanUIModel(
          channel: 229, utilization: 10, isInUse: true, neighbors: []),
    ]),
  ],
);

/// No scan this session: the card says so and offers the button.
const channelFinderIdleState = ChannelFinderState();

/// The last scan finished: one row per band. The default fixture.
final channelFinderDoneState = ChannelFinderState(
  phase: ChannelFinderPhase.done,
  lastResult: channelFinderTriBandResult,
);

/// A second scan measuring channels, the longer of the two stage strings, with
/// the first scan's rows still shown under the loader.
final channelFinderScanningState = ChannelFinderState(
  phase: ChannelFinderPhase.scanning,
  stage: ChannelFinderScanStage.channels,
  lastResult: channelFinderTriBandResult,
);

/// A second scan that failed: the error above the first scan's rows — the
/// card's tallest state.
final channelFinderFailedState = ChannelFinderState(
  phase: ChannelFinderPhase.failed,
  lastResult: channelFinderTriBandResult,
  error: const TimeoutError(detail: 'ChannelScanRequest() did not complete'),
);

/// A page-sized result, shaped after the M60 bench scan of 2026-11-26 (#1778):
/// every 2.4 GHz channel 1–11 and the eight US 5 GHz channels, with the
/// utilizations measured there, plus a 6 GHz band with 3-digit channels. One
/// 5 GHz channel was not measured, so its row reads the longest busyness
/// string. The neighbours are made up; their counts are the bench's.
final channelFinderPageResult = ChannelFinderResultUIModel(
  scannedAt: DateTime(2026, 11, 26, 14, 13),
  bands: [
    _band('2.4GHz', inUse: 1, rows: const [
      (1, 59, 4),
      (2, 42, 2),
      (3, 37, 0),
      (4, 107, 4),
      (5, 76, 0),
      (6, 97, 0),
      (7, 99, 6),
      (8, 141, 3),
      (9, 49, 0),
      (10, 70, 0),
      (11, 78, 2),
    ]),
    _band('5GHz', inUse: 48, rows: const [
      (36, 8, 3),
      (40, 3, 1),
      (44, 2, 0),
      (48, 13, 4),
      (149, 7, 2),
      (153, 10, 0),
      (157, 5, 2),
      (161, null, 0),
    ]),
    _band('6GHz', inUse: 229, rows: const [
      (197, 6, 0),
      (213, 18, 1),
      (229, 10, 0),
    ]),
  ],
);

/// A finished scan of [channelFinderPageResult]: the page's sweep fixture.
final channelFinderPageDoneState = ChannelFinderState(
  phase: ChannelFinderPhase.done,
  lastResult: channelFinderPageResult,
);

/// One band of [channelFinderPageResult] from (channel, utilization, networks)
/// rows; network i of a channel is -40 - 7i dBm, and every third one hides its
/// name.
ChannelBandScanUIModel _band(
  String band, {
  required int inUse,
  required List<(int, int?, int)> rows,
}) =>
    ChannelBandScanUIModel(
      band: band,
      channelInUse: inUse,
      channels: [
        for (final (channel, utilization, networks) in rows)
          ChannelScanUIModel(
            channel: channel,
            utilization: utilization,
            isInUse: channel == inUse,
            neighbors: [
              for (var i = 0; i < networks; i++)
                ChannelNeighborUIModel(
                  ssid: i % 3 == 2 ? '' : 'Neighbour $channel-${i + 1}',
                  bssid:
                      'aa:bb:cc:${channel.toRadixString(16).padLeft(2, '0')}:00:0${i + 1}',
                  signalDbm: -40 - 7 * i,
                ),
            ],
          ),
      ],
    );
