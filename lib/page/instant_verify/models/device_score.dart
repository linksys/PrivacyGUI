import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';

enum DeviceScoreBucket { good, atRisk, issue }

/// Connection quality score for a single client device.
///
/// Score 0-100 computed from WiFi signal strength + TX link rate:
///   Signal component (0-50): maps -30dBm=50pts to -90dBm=0pts
///   Rate component  (0-50): maps 1200Mbps=50pts to 0Mbps=0pts
///
/// Buckets: ≥70 = Good, 40-69 = At Risk, <40 = Issue.
/// Wired devices always score 100.
class DeviceScore {
  final DiagnosticClient client;
  final int score;

  const DeviceScore({required this.client, required this.score});

  DeviceScoreBucket get bucket {
    if (score >= 70) return DeviceScoreBucket.good;
    if (score >= 40) return DeviceScoreBucket.atRisk;
    return DeviceScoreBucket.issue;
  }

  bool get isGood => bucket == DeviceScoreBucket.good;
  bool get isAtRisk => bucket == DeviceScoreBucket.atRisk;
  bool get isIssue => bucket == DeviceScoreBucket.issue;

  static DeviceScore compute(DiagnosticClient client) {
    if (!client.isWireless) return DeviceScore(client: client, score: 100);

    final signal = client.signalDecibels ?? -90;
    final txRate = client.txRateMbps ?? 0;

    // Signal: -30dBm=50, -65=~29, -75=~20, -85=~4, -90+=0
    final signalScore = ((signal + 90) / 60 * 50).clamp(0.0, 50.0).toInt();

    // Rate: band-aware ceiling. 2.4 GHz tops out far below 5/6 GHz (realistic
    // max ~300 vs ~1200 Mbps), so scoring a healthy 2.4 GHz link against 1200
    // dragged every 2.4 GHz device toward the Issue bucket even at fine signal —
    // contradicting the My Devices badge. Scale 2.4 GHz to its own ceiling.
    final rateCeiling = client.band.contains('2.4') ? 300.0 : 1200.0;
    final rateScore = (txRate / rateCeiling * 50).clamp(0.0, 50.0).toInt();

    var score = signalScore + rateScore;

    // Issue-bucket parity with My Devices' _badgeFor (my_devices_tab.dart): a
    // device the device list shows as "Good" — signal > -70 dBm AND rate >= 30
    // Mbps, with null fields skipped exactly as _badgeFor skips them — must NOT
    // land in the Issue bucket, or the Overview "weak WiFi" count contradicts
    // the My Devices badge for the same device (notably 2.4 GHz clients). Also
    // keep the original high-throughput rescue (>=200 Mbps regardless of signal,
    // e.g. -72 dBm @ 520 Mbps). Only rescues Issues; the At-Risk/Good boundary
    // is untouched. Keep this aligned with _badgeFor's thresholds.
    final rawSignal = client.signalDecibels;
    final rawRate = client.txRateMbps;
    final badgeGood = (rawSignal == null || rawSignal > -70) &&
        (rawRate == null || rawRate >= 30);
    if (score < 40 && (txRate >= 200 || badgeGood)) score = 40;

    return DeviceScore(client: client, score: score);
  }
}
