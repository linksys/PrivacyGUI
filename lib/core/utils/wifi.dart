const signalThresholdSNR = [40, 25, 10];

/// RSSI threshold constants for signal quality classification.
///
/// These are the single source of truth for RSSI thresholds across the app.
/// - Excellent: >= [rssiExcellent] (-65 dBm)
/// - Good: >= [rssiGood] (-71 dBm)
/// - Fair: >= [rssiFair] (-78 dBm)
/// - Poor: < [rssiFair] (-78 dBm)
const int rssiExcellent = -65;
const int rssiGood = -71;
const int rssiFair = -78;

/// RSSI threshold array for signal level lookup (derived from constants above).
const signalThresholdRSSI = [rssiExcellent, rssiGood, rssiFair];

// ─── RCPI / RSSI Conversion ─────────────────────────────────────────────────

/// Convert RCPI (Received Channel Power Indicator) to RSSI (dBm).
///
/// RCPI is defined in IEEE 802.11k and ranges from 0–220.
/// Formula: RSSI (dBm) = (RCPI / 2) - 110
///
/// Returns null if [rcpi] is null or <= 0.
int? rcpiToRssi(int? rcpi) {
  if (rcpi == null || rcpi <= 0) return null;
  return (rcpi ~/ 2) - 110;
}

/// Convert RSSI (dBm) to RCPI (Received Channel Power Indicator).
///
/// Inverse of [rcpiToRssi].
/// Formula: RCPI = (RSSI + 110) * 2
///
/// Returns 0 if [rssiDbm] is null or 0.
int rssiToRcpi(int? rssiDbm) {
  if (rssiDbm == null || rssiDbm == 0) return 0;
  return (rssiDbm + 110) * 2;
}

// ─── Signal Level ───────────────────────────────────────────────────────────

/// WiFi signal level for **device/node connection display** (icon bars + label).
///
/// Derived from RSSI (dBm) or SNR by [getWifiSignalLevel]. This is the only
/// tier enum that models physical-link states: [wired] (no WiFi, Ethernet) and
/// [none] (no signal at all) — neither exists in [SignalTier] or `HealthTier`.
///
/// Sibling enums (similar names, different domains — do NOT merge):
/// - [SignalTier]: RSSI → performance analytics tier (no wired/none).
/// - `HealthTier` (network_health_helpers.dart): packet-loss → health score.
enum NodeSignalLevel {
  wired(displayTitle: 'Wired'),
  none(displayTitle: 'No signal'),
  poor(displayTitle: 'Poor'),
  good(displayTitle: 'Good'),
  fair(displayTitle: 'Fair'),
  excellent(displayTitle: 'Excellent');

  const NodeSignalLevel({
    required this.displayTitle,
  });

  final String displayTitle;
}

NodeSignalLevel getWifiSignalLevel(int? signalStrength) {
  if (signalStrength == null) {
    return NodeSignalLevel.wired;
  }
  // A `0` reading is not a real measurement. `Hosts.Host.{i}.SignalStrength`
  // uses `0` to mean "no reading" (present-but-absent), and a genuine 0 dBm
  // RSSI is not physically meaningful for these links. Treating it as a real
  // value would clear `rssiExcellent` (0 >= -65) and grade "Excellent" for a
  // device that has no signal. Grade it as [none] (unknown / no signal). See
  // linksys/PrivacyGUI#1438 (FWDEV#166 AC5).
  if (signalStrength == 0) {
    return NodeSignalLevel.none;
  }
  // A positive value here is an SNR reading, not RSSI, so compare against the
  // SNR thresholds. RCPI values are also positive, but they are converted to
  // (negative) dBm upstream by [rcpiToRssi] before reaching this call site, so
  // they never take this branch. The only positive values that arrive here are
  // true SNR figures. (No behaviour change — this branch is unchanged.)
  var signalThreshold =
      signalStrength > 0 ? signalThresholdSNR : signalThresholdRSSI;
  var index =
      signalThreshold.indexWhere((element) => signalStrength >= element);
  if (index == -1) {
    return NodeSignalLevel.poor;
  } else {
    switch (3 - index) {
      case 3:
        return NodeSignalLevel.excellent;
      case 2:
        return NodeSignalLevel.good;
      case 1:
        return NodeSignalLevel.fair;
      default:
        return NodeSignalLevel.poor;
    }
  }
}

// ─── Signal Tier (for performance analytics) ────────────────────────────────

/// Signal quality tier for **performance analytics** (charts, summaries).
///
/// Derived purely from RSSI (dBm) by [getSignalTier]. A coarser 4-level scale
/// than [NodeSignalLevel]: no physical-link states (wired/none), and the bottom
/// level is [weak] (not `poor`).
///
/// Sibling enums (similar names, different domains — do NOT merge):
/// - [NodeSignalLevel]: RSSI/SNR → connection display with icon bars.
/// - `HealthTier` (network_health_helpers.dart): packet-loss → health score.
enum SignalTier { excellent, good, fair, weak }

/// Map RSSI (dBm) to a signal tier.
SignalTier getSignalTier(int rssi) {
  if (rssi >= rssiExcellent) return SignalTier.excellent;
  if (rssi >= rssiGood) return SignalTier.good;
  if (rssi >= rssiFair) return SignalTier.fair;
  return SignalTier.weak;
}

/// Signal-to-Noise Ratio in dB.
///
/// `noise == 0` means "no noise reading", not "a perfectly silent channel", so
/// this returns 0 rather than a fictitious `signal - 0`. A 0 return is therefore
/// ambiguous — it is also what a client whose signal equals the noise floor
/// gives — which is why callers that *average* SNR must not feed unguarded
/// values in. Use [aggregateRadioClientStats] instead of rolling the loop by
/// hand (#1271).
int computeSNR(int signal, int noise) => noise == 0 ? 0 : signal - noise;

/// Normalize SNR to 0.0–1.0 for progress bar display.
/// Typical WiFi SNR range: 0–50 dB.
double normalizeSNR(int snr) => (snr / 50).clamp(0.0, 1.0);

// ─── Per-radio client aggregation ───────────────────────────────────────────

/// One client's contribution to [aggregateRadioClientStats]: the band it is
/// associated with, and the two readings its SNR is computed from.
///
/// A record rather than a class because both call sites already have their own
/// client type (`_ClientInfo`, twice, with different shapes) and neither should
/// have to adopt the other's.
typedef RadioClientSample = ({String band, int signalStrength, int noise});

/// Per-radio client counts and average SNR over one client list.
///
/// Built only by [aggregateRadioClientStats] — see there for why the two
/// surfaces that render this share one implementation.
class RadioClientStats {
  /// Clients per radio index. Radios with no clients are absent; use
  /// [clientCount] to read a radio's count as 0 instead.
  ///
  /// Exposed as a map because the band-distribution donuts on both surfaces
  /// consume it whole.
  final Map<int, int> clientCounts;

  /// Average SNR per radio index, absent when the radio has no client with a
  /// noise reading. Read through [averageSnr].
  final Map<int, double> _averageSnr;

  const RadioClientStats._(this.clientCounts, this._averageSnr);

  /// Clients associated with the radio at [radioIndex], including those with no
  /// noise reading — a client with no noise data is still a client.
  int clientCount(int radioIndex) => clientCounts[radioIndex] ?? 0;

  /// Average SNR in dB over the radio's clients that reported real noise, or
  /// `null` when **no** client did (including when the radio has no clients).
  ///
  /// `null`, not `0`: 0 dB is a measurement ("signal sits at the noise floor")
  /// and the caller renders it as one, bar and all. The absence of a reading has
  /// to be a distinguishable state or the UI claims the worst possible link
  /// quality for a radio it knows nothing about — which is exactly what #1271
  /// found on the Statistics page.
  double? averageSnr(int radioIndex) => _averageSnr[radioIndex];
}

/// Counts [clients] per radio and averages their SNR, keyed by each client's
/// [RadioClientSample.band] position in [bands].
///
/// Clients whose band is not in [bands] are dropped entirely (an unresolved or
/// foreign band belongs to no radio). Clients with `noise == 0` are counted but
/// **excluded from the SNR average**: [computeSNR] returns 0 for them, so
/// including them adds 0 to the sum and 1 to the divisor and drags the average
/// toward zero. Slave-node clients are the common case — they are absent from
/// `wifiClientMap`, so they have no noise reading at all — and the guard's reach
/// grows once #1118 gives them a resolved band, because today many are already
/// dropped by the band lookup above and never reach the aggregation.
///
/// ## Why this is shared code
///
/// The Statistics page's WiFi Channels section and the WiFi Performance card's
/// Channels tab render the same statistic from the same data. They carried
/// byte-for-byte copies of this loop until the guard was added to one of them
/// and not the other, so the two surfaces reported *different* average SNR for
/// the same clients (#1271). One implementation is what makes them agree; a
/// second copy is how they drifted.
RadioClientStats aggregateRadioClientStats({
  required List<String> bands,
  required Iterable<RadioClientSample> clients,
}) {
  final bandToRadioIndex = <String, int>{};
  for (var i = 0; i < bands.length; i++) {
    bandToRadioIndex[bands[i]] = i;
  }

  final counts = <int, int>{};
  final snrSum = <int, double>{};
  final snrCount = <int, int>{};

  for (final client in clients) {
    final radioIndex = bandToRadioIndex[client.band];
    if (radioIndex == null) continue;
    counts[radioIndex] = (counts[radioIndex] ?? 0) + 1;
    if (client.noise == 0) continue;
    snrSum[radioIndex] = (snrSum[radioIndex] ?? 0) +
        computeSNR(client.signalStrength, client.noise);
    snrCount[radioIndex] = (snrCount[radioIndex] ?? 0) + 1;
  }

  return RadioClientStats._(
    Map.unmodifiable(counts),
    Map.unmodifiable({
      for (final entry in snrSum.entries)
        entry.key: entry.value / snrCount[entry.key]!,
    }),
  );
}
