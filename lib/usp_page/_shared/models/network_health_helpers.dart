import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/_shared/models/traffic_analysis_state.dart';

/// Health quality tiers derived from packet loss percentage.
enum HealthTier { excellent, good, fair, poor, critical }

/// Pure computation helpers for network health scoring (F-022).
///
/// All methods are static and side-effect free — suitable for use
/// inside widget build methods.
class NetworkHealthHelpers {
  NetworkHealthHelpers._();

  /// Compute a health score (0–100) from a WAN traffic snapshot.
  ///
  /// Score is based on the ratio of fault packets (errors + discards)
  /// to total packet throughput.
  static int computeHealthScore(InterfaceTrafficSnapshot wan) {
    final lossPercent = computeLossPercent(wan);
    return _scoreFromLoss(lossPercent);
  }

  static int _scoreFromLoss(double lossPercent) {
    if (lossPercent <= 0) return 100;
    if (lossPercent < 0.01) return 95;
    if (lossPercent < 0.1) return 85;
    if (lossPercent < 1.0) return 70;
    if (lossPercent < 5.0) return 45;
    return 20;
  }

  /// Map a numeric score to a named tier.
  static HealthTier tierFromScore(int score) {
    if (score >= 95) return HealthTier.excellent;
    if (score >= 80) return HealthTier.good;
    if (score >= 60) return HealthTier.fair;
    if (score >= 40) return HealthTier.poor;
    return HealthTier.critical;
  }

  /// Tier-appropriate color from the current color scheme.
  static Color tierColor(HealthTier tier, ColorScheme cs) => switch (tier) {
        HealthTier.excellent => cs.primary,
        HealthTier.good => cs.tertiary,
        HealthTier.fair => Colors.amber,
        HealthTier.poor => Colors.orange,
        HealthTier.critical => cs.error,
      };

  /// Human-readable tier label.
  static String tierLabel(HealthTier tier) => switch (tier) {
        HealthTier.excellent => 'Excellent',
        HealthTier.good => 'Good',
        HealthTier.fair => 'Fair',
        HealthTier.poor => 'Poor',
        HealthTier.critical => 'Critical',
      };

  /// Packet loss percentage from a single snapshot.
  ///
  /// Loss = faults / (goodPackets + faults) × 100
  /// where faults = errors + discards per second.
  static double computeLossPercent(InterfaceTrafficSnapshot wan) {
    final goodPkts = wan.totalPacketsPerSec;
    final faults = wan.totalFaultsPerSec;
    if (goodPkts + faults <= 0) return 0;
    return faults / (goodPkts + faults) * 100;
  }

  /// Format a fault rate for display.
  static String formatFaultRate(double faultsPerSec) {
    if (faultsPerSec < 0.01) return '0/s';
    if (faultsPerSec < 1) return '${faultsPerSec.toStringAsFixed(2)}/s';
    if (faultsPerSec < 100) return '${faultsPerSec.toStringAsFixed(1)}/s';
    return '${faultsPerSec.toStringAsFixed(0)}/s';
  }
}
