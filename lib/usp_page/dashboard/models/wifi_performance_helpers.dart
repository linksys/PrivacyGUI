import 'package:flutter/material.dart';

/// Signal quality tiers derived from RSSI (dBm).
enum SignalTier { excellent, good, fair, weak }

/// Pure computation helpers for WiFi performance analytics (F-024).
///
/// All methods are static and side-effect free — suitable for use
/// inside widget build methods.
class WifiPerformanceHelpers {
  WifiPerformanceHelpers._();

  /// Map RSSI (dBm) to a signal tier.
  ///
  /// Thresholds based on industry convention:
  /// - Excellent: >= -50 dBm
  /// - Good: >= -60 dBm
  /// - Fair: >= -70 dBm
  /// - Weak: < -70 dBm
  static SignalTier signalTier(int rssi) {
    if (rssi >= -50) return SignalTier.excellent;
    if (rssi >= -60) return SignalTier.good;
    if (rssi >= -70) return SignalTier.fair;
    return SignalTier.weak;
  }

  /// Signal-to-Noise Ratio in dB.
  static int computeSNR(int signal, int noise) =>
      noise == 0 ? 0 : signal - noise;

  /// Normalize SNR to 0.0–1.0 for progress bar display.
  /// Typical WiFi SNR range: 0–50 dB.
  static double normalizeSNR(int snr) => (snr / 50).clamp(0.0, 1.0);

  /// Format kbps to human-readable speed string.
  static String formatSpeed(int kbps) {
    if (kbps >= 1000000) return '${(kbps / 1000000).toStringAsFixed(1)} Gbps';
    if (kbps >= 1000) return '${(kbps / 1000).toStringAsFixed(0)} Mbps';
    return '$kbps kbps';
  }

  /// Human-readable tier label.
  static String tierLabel(SignalTier tier) => switch (tier) {
        SignalTier.excellent => 'Excellent',
        SignalTier.good => 'Good',
        SignalTier.fair => 'Fair',
        SignalTier.weak => 'Weak',
      };

  /// Tier-appropriate color from the current color scheme.
  static Color tierColor(SignalTier tier, ColorScheme cs) => switch (tier) {
        SignalTier.excellent => cs.primary,
        SignalTier.good => cs.tertiary,
        SignalTier.fair => Colors.orange,
        SignalTier.weak => cs.error,
      };

  /// Bar color based on RSSI value.
  static Color rssiColor(int rssi, ColorScheme cs) =>
      tierColor(signalTier(rssi), cs);
}
