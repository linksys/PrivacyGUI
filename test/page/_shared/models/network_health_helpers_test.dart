import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';

/// Builds an [InterfaceTrafficSnapshot] with configurable traffic/fault rates.
/// Defaults describe a healthy, loss-free link (loss 0% → score 100).
InterfaceTrafficSnapshot _snapshot({
  double packetsPerSec = 1000,
  double errorsPerSec = 0,
  double discardsPerSec = 0,
}) {
  return InterfaceTrafficSnapshot(
    uploadBytesPerSec: 0,
    downloadBytesPerSec: 0,
    uploadPacketsPerSec: packetsPerSec / 2,
    downloadPacketsPerSec: packetsPerSec / 2,
    totalBytesSent: 0,
    totalBytesReceived: 0,
    totalPacketsSent: 0,
    totalPacketsReceived: 0,
    errorsSentPerSec: errorsPerSec / 2,
    errorsReceivedPerSec: errorsPerSec / 2,
    discardsSentPerSec: discardsPerSec / 2,
    discardsReceivedPerSec: discardsPerSec / 2,
  );
}

void main() {
  group('NetworkHealthHelpers.computeWanScore (#1143)', () {
    test('WAN down forces score 0 (Critical) even with zero-loss traffic stats',
        () {
      // A disconnected WAN carries no traffic → loss 0% → loss-only scoring
      // would report 100 ("Excellent"). This is the exact #1143 bug.
      final healthyStats = _snapshot(packetsPerSec: 1000);
      expect(
        NetworkHealthHelpers.computeHealthScore(healthyStats),
        100,
        reason: 'sanity: loss-only score is 100 for a loss-free snapshot',
      );

      final score =
          NetworkHealthHelpers.computeWanScore(healthyStats, wanIsUp: false);
      expect(score, 0, reason: 'WAN down must score 0 regardless of traffic');
      expect(
        NetworkHealthHelpers.tierFromScore(score),
        HealthTier.critical,
        reason: 'score 0 maps to Critical, never Excellent',
      );
    });

    test('WAN down with null snapshot also scores 0', () {
      // Even before any traffic snapshot arrives, a down link must not
      // report the healthy default of 100.
      final score = NetworkHealthHelpers.computeWanScore(null, wanIsUp: false);
      expect(score, 0);
      expect(NetworkHealthHelpers.tierFromScore(score), HealthTier.critical);
    });

    test('WAN up delegates to loss-based scoring (healthy → 100/Excellent)',
        () {
      final score = NetworkHealthHelpers.computeWanScore(
        _snapshot(packetsPerSec: 1000),
        wanIsUp: true,
      );
      expect(score, 100);
      expect(NetworkHealthHelpers.tierFromScore(score), HealthTier.excellent);
    });

    test('WAN up with packet loss still degrades the score', () {
      // 5 faults / (1000 + 5) ≈ 0.5% loss → 70 (Fair) via _scoreFromLoss.
      final lossy = _snapshot(packetsPerSec: 1000, errorsPerSec: 5);
      final score = NetworkHealthHelpers.computeWanScore(lossy, wanIsUp: true);
      expect(score, lessThan(100));
      expect(
        score,
        NetworkHealthHelpers.computeHealthScore(lossy),
        reason: 'when up, computeWanScore must equal loss-based score',
      );
    });

    test('null snapshot but WAN up falls back to healthy default (100)', () {
      // Preserves prior behaviour: link up + no stats yet → treat as healthy
      // rather than falsely reporting a disconnect.
      final score = NetworkHealthHelpers.computeWanScore(null, wanIsUp: true);
      expect(score, 100);
    });

    test('wanIsUp defaults to true (loading link state ≠ disconnect)', () {
      // Default arg guards against a momentary provider-loading window
      // rendering a false "disconnected".
      final score =
          NetworkHealthHelpers.computeWanScore(_snapshot(packetsPerSec: 1000));
      expect(score, 100);
    });
  });
}
