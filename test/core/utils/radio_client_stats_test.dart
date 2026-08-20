import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/wifi.dart';

/// `aggregateRadioClientStats` — the per-radio client count and average SNR both
/// Channels surfaces render (#1271).
///
/// ## What these tests are protecting
///
/// The statistic shipped as two byte-for-byte copies of the same loop, one in
/// `stats_wifi_channels_section.dart` and one in `usp_wifi_performance_card.dart`.
/// The `noise == 0` guard was added to the card and not to the section, so the
/// same clients averaged *lower* on the Statistics page than on the dashboard —
/// and no test noticed, because every fixture in the repo gave every client
/// `noise: -95`.
///
/// So the fixtures here are chosen for the one property the old ones lacked: a
/// client with no noise reading sitting next to clients that have one. Each case
/// records what the unguarded loop would have produced, because "37, not 25" is
/// the assertion — `expect(37)` alone would also pass on a fixture where the
/// guard makes no difference, which is exactly how this bug survived.
void main() {
  /// The two radios both Channels surfaces render, in index order.
  const bands = ['2.4GHz', '5GHz'];

  RadioClientSample client(String band, int signal, int noise) =>
      (band: band, signalStrength: signal, noise: noise);

  group('average SNR', () {
    test('excludes clients with no noise reading, counts them as clients', () {
      // `computeSNR = signal - noise`: 40 dB and 35 dB, plus one client the
      // router reported no noise floor for.
      final stats = aggregateRadioClientStats(
        bands: bands,
        clients: [
          client('2.4GHz', -55, -95),
          client('2.4GHz', -60, -95),
          client('2.4GHz', -70, 0),
        ],
      );

      // (40 + 35) / 2 = 37.5. Unguarded it is (40 + 35 + 0) / 3 = 25.0 — one
      // client with no data costs the radio 12.5 dB of reported quality, and the
      // signal bar 25% of its fill.
      expect(stats.averageSnr(0), 37.5,
          reason: 'a client with noise == 0 contributes no SNR sample; '
              'including it as a 0 dB sample would report 25.0');
      expect(stats.clientCount(0), 3,
          reason: 'a client with no noise reading is still a client — it is '
              'excluded from the SNR average, not from the network');
    });

    test('is null when no client on the radio has a noise reading', () {
      final stats = aggregateRadioClientStats(
        bands: bands,
        clients: [client('5GHz', -50, 0), client('5GHz', -60, 0)],
      );

      // The empty state both surfaces render as `snrUnavailable`. `null` and not
      // 0.0: the unguarded loop returns 0.0 here, which renders as `SNR: 0 dB`
      // with an empty bar — a measurement claim about a radio nothing was
      // measured on.
      expect(stats.averageSnr(1), isNull);
      expect(stats.clientCount(1), 2);
    });

    test('is null for a radio with no clients at all', () {
      final stats = aggregateRadioClientStats(
        bands: bands,
        clients: [client('2.4GHz', -55, -95)],
      );

      expect(stats.averageSnr(1), isNull,
          reason: 'no clients means no measurement, which is the same '
              'unavailable state as clients without noise');
      expect(stats.clientCount(1), 0);
    });

    test('averages each radio independently', () {
      final stats = aggregateRadioClientStats(
        bands: bands,
        clients: [
          client('2.4GHz', -55, -95), // 40
          client('2.4GHz', -65, -95), // 30
          client('5GHz', -50, -95), // 45
        ],
      );

      expect(stats.averageSnr(0), 35.0);
      expect(stats.averageSnr(1), 45.0);
      expect(stats.clientCounts, {0: 2, 1: 1});
    });
  });

  group('band resolution', () {
    test('drops clients whose band belongs to no radio', () {
      // An unresolved band (`''`) is what a slave-node client has today, and
      // `6GHz` is a real band on a router this data did not come from. Neither
      // belongs to a rendered radio, so neither may land on one.
      final stats = aggregateRadioClientStats(
        bands: bands,
        clients: [
          client('', -55, -95),
          client('6GHz', -55, -95),
          client('2.4GHz', -55, -95),
        ],
      );

      expect(stats.clientCounts, {0: 1},
          reason: 'only the 2.4GHz client belongs to a rendered radio');
      expect(stats.averageSnr(0), 40.0);
    });

    test('no clients at all yields an empty result, not a crash', () {
      final stats = aggregateRadioClientStats(bands: bands, clients: const []);

      expect(stats.clientCounts, isEmpty);
      expect(stats.clientCount(0), 0);
      expect(stats.averageSnr(0), isNull);
    });

    test('no radios drops every client', () {
      final stats = aggregateRadioClientStats(
        bands: const [],
        clients: [client('2.4GHz', -55, -95)],
      );

      expect(stats.clientCounts, isEmpty);
    });
  });

  test('the returned maps are unmodifiable', () {
    // Both surfaces hand `clientCounts` straight to a donut widget, so it
    // outlives the aggregation call; a shared mutable map is a defect waiting for
    // its first caller.
    final stats = aggregateRadioClientStats(
      bands: bands,
      clients: [client('2.4GHz', -55, -95)],
    );

    expect(() => stats.clientCounts[1] = 7, throwsUnsupportedError);
  });
}
