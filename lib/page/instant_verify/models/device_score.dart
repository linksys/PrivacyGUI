import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';

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

    // Rate: 0=0, 100≈4, 400≈17, 866≈36, 1200+=50
    final rateScore = (txRate / 1200 * 50).clamp(0.0, 50.0).toInt();

    return DeviceScore(client: client, score: signalScore + rateScore);
  }
}
