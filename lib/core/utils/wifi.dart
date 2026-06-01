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

/// Signal quality tiers derived from RSSI (dBm).
enum SignalTier { excellent, good, fair, weak }

/// Map RSSI (dBm) to a signal tier.
SignalTier getSignalTier(int rssi) {
  if (rssi >= rssiExcellent) return SignalTier.excellent;
  if (rssi >= rssiGood) return SignalTier.good;
  if (rssi >= rssiFair) return SignalTier.fair;
  return SignalTier.weak;
}

/// Signal-to-Noise Ratio in dB.
int computeSNR(int signal, int noise) => noise == 0 ? 0 : signal - noise;

/// Normalize SNR to 0.0–1.0 for progress bar display.
/// Typical WiFi SNR range: 0–50 dB.
double normalizeSNR(int snr) => (snr / 50).clamp(0.0, 1.0);

/// Format kbps to human-readable speed string.
String formatSpeed(int kbps) {
  if (kbps >= 1000000) return '${(kbps / 1000000).toStringAsFixed(1)} Gbps';
  if (kbps >= 1000) return '${(kbps / 1000).toStringAsFixed(0)} Mbps';
  return '$kbps kbps';
}
