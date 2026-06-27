import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';

DiagnosticClient _client({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String band = '5GHz',
  int? signal,
  int? txRate,
  int? rxRate,
  bool wireless = true,
}) {
  return DiagnosticClient(
    macAddress: mac,
    band: band,
    signalDecibels: signal,
    txRateMbps: txRate,
    rxRateMbps: rxRate,
    isWireless: wireless,
  );
}

void main() {
  group('DeviceScore — compute', () {
    test('wired device always scores 100', () {
      final client = _client(wireless: false, signal: -90, txRate: 0);
      final score = DeviceScore.compute(client);
      expect(score.score, 100);
      expect(score.isGood, isTrue);
    });

    test('excellent wireless: strong signal + high rate', () {
      final client = _client(signal: -30, txRate: 1200);
      final score = DeviceScore.compute(client);
      expect(score.score, 100); // 50 + 50
      expect(score.isGood, isTrue);
      expect(score.bucket, DeviceScoreBucket.good);
    });

    test('very weak wireless: -90 dBm signal + 0 rate', () {
      final client = _client(signal: -90, txRate: 0);
      final score = DeviceScore.compute(client);
      expect(score.score, 0); // 0 + 0
      expect(score.isIssue, isTrue);
      expect(score.bucket, DeviceScoreBucket.issue);
    });

    test('mid-range: -65 dBm + 400 Mbps', () {
      final client = _client(signal: -65, txRate: 400);
      final score = DeviceScore.compute(client);
      // Signal: (-65 + 90) / 60 * 50 = 25/60*50 ≈ 20
      // Rate: 400/1200*50 ≈ 16 → raw total ≈ 36, but badge-parity rescue
      // lifts it to 40 (signal > -70 AND rate >= 30 = badge "Good"), so it
      // sits at the At-Risk floor, not the Issue bucket.
      expect(score.score, greaterThanOrEqualTo(40));
      expect(score.score, lessThan(45));
      expect(score.isIssue, isFalse);
    });

    test('borderline at-risk: -50 dBm + 866 Mbps → 69 (just under good)', () {
      // Signal: (-50+90)/60*50 = 40/60*50 = 33
      // Rate: 866/1200*50 = 36
      // Total = 69 → atRisk (boundary is 70)
      final client = _client(signal: -50, txRate: 866);
      final score = DeviceScore.compute(client);
      expect(score.score, 69);
      expect(score.bucket, DeviceScoreBucket.atRisk);
    });

    test('just good: -45 dBm + 866 Mbps → 73 (above boundary)', () {
      // Signal: (-45+90)/60*50 = 45/60*50 = 37
      // Rate: 866/1200*50 = 36
      // Total = 73 → good
      final client = _client(signal: -45, txRate: 866);
      final score = DeviceScore.compute(client);
      expect(score.score, greaterThanOrEqualTo(70));
      expect(score.bucket, DeviceScoreBucket.good);
    });

    test('null signal defaults to -90', () {
      final client = _client(signal: null, txRate: 1200);
      final score = DeviceScore.compute(client);
      // Signal: (-90+90)/60*50 = 0, Rate: 50 → total 50
      expect(score.score, 50);
    });

    test('null txRate defaults to 0', () {
      final client = _client(signal: -30, txRate: null);
      final score = DeviceScore.compute(client);
      // Signal: 50, Rate: 0 → total 50
      expect(score.score, 50);
    });

    test('signal better than -30 clamps to 50', () {
      final client = _client(signal: -10, txRate: 0);
      final score = DeviceScore.compute(client);
      // (-10+90)/60*50 = 80/60*50 = 66.7 → clamp to 50
      expect(score.score, 50);
    });

    test('rate above 1200 clamps to 50', () {
      final client = _client(signal: -90, txRate: 2400);
      final score = DeviceScore.compute(client);
      // Signal: 0, Rate: 2400/1200*50 = 100 → clamp to 50
      expect(score.score, 50);
    });
  });

  // Regression for N3 (live-pass bug): the Overview "weak WiFi" count
  // (deviceScores.where(isIssue)) must agree with the My Devices badge
  // (_badgeFor: Good = signal > -70 dBm AND rate >= 30 Mbps). 2.4 GHz clients
  // top out far below 1200 Mbps, so without band-aware scoring + the parity
  // rescue they scored < 40 (Issue) while the badge showed "Good".
  group('DeviceScore — 2.4 GHz badge parity (N3)', () {
    test('2.4 GHz fair-signal healthy-rate device is NOT an issue', () {
      // -63 dBm / 35 Mbps: My Devices shows "Good" (>-70 AND >=30).
      final client = _client(band: '2.4 GHz', signal: -63, txRate: 35);
      final score = DeviceScore.compute(client);
      expect(score.isIssue, isFalse,
          reason: 'badge-Good 2.4 GHz device must not be flagged weak');
      expect(score.score, greaterThanOrEqualTo(40));
    });

    test('2.4 GHz band-aware rate scores higher than the 1200 ceiling would', () {
      // 150 Mbps on 2.4 GHz: 150/300*50 = 25 (vs 150/1200*50 ≈ 6 before).
      final client = _client(band: '2.4 GHz', signal: -55, txRate: 150);
      final score = DeviceScore.compute(client);
      // signal (-55): (35/60*50)=29; rate: 25 → ~54 → at-risk, not issue.
      expect(score.score, greaterThan(45));
      expect(score.isIssue, isFalse);
    });

    test('2.4 GHz weak signal still flagged issue (parity with badge weak)', () {
      // -72 dBm: badge = weak (<= -70); rescue must NOT apply.
      final client = _client(band: '2.4 GHz', signal: -72, txRate: 20);
      final score = DeviceScore.compute(client);
      expect(score.isIssue, isTrue);
    });

    test('2.4 GHz low rate still flagged issue (parity with badge weak)', () {
      // 25 Mbps: badge = weak (< 30); rescue must NOT apply.
      final client = _client(band: '2.4 GHz', signal: -65, txRate: 25);
      final score = DeviceScore.compute(client);
      expect(score.isIssue, isTrue);
    });

    test('null signal with healthy rate is rescued (badge skips null signal)', () {
      final client = _client(band: '2.4 GHz', signal: null, txRate: 50);
      final score = DeviceScore.compute(client);
      expect(score.isIssue, isFalse);
    });

    test('5 GHz high-throughput rescue still applies (>=200 Mbps)', () {
      // -72 dBm @ 520 Mbps: signal weak but moving real data — not an issue.
      final client = _client(band: '5GHz', signal: -72, txRate: 520);
      final score = DeviceScore.compute(client);
      expect(score.isIssue, isFalse);
    });
  });

  group('DeviceScore — buckets', () {
    test('score 100 → good', () {
      final client = _client(wireless: false);
      final score = DeviceScore.compute(client);
      expect(score.bucket, DeviceScoreBucket.good);
      expect(score.isGood, isTrue);
      expect(score.isAtRisk, isFalse);
      expect(score.isIssue, isFalse);
    });

    test('score 40 boundary → atRisk', () {
      const score = DeviceScore(
        client: DiagnosticClient(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          band: '5GHz',
          isWireless: true,
        ),
        score: 40,
      );
      expect(score.bucket, DeviceScoreBucket.atRisk);
      expect(score.isAtRisk, isTrue);
    });

    test('score 39 → issue', () {
      const score = DeviceScore(
        client: DiagnosticClient(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          band: '5GHz',
          isWireless: true,
        ),
        score: 39,
      );
      expect(score.bucket, DeviceScoreBucket.issue);
      expect(score.isIssue, isTrue);
    });

    test('score 69 → atRisk', () {
      const score = DeviceScore(
        client: DiagnosticClient(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          band: '5GHz',
          isWireless: true,
        ),
        score: 69,
      );
      expect(score.bucket, DeviceScoreBucket.atRisk);
    });

    test('score 70 → good', () {
      const score = DeviceScore(
        client: DiagnosticClient(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          band: '5GHz',
          isWireless: true,
        ),
        score: 70,
      );
      expect(score.bucket, DeviceScoreBucket.good);
    });
  });
}
