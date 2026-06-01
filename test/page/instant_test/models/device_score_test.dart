import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/instant_test/models/device_score.dart';

DeviceUIModel _device({
  String mac = 'AA:BB:CC:DD:EE:FF',
  String? band = '5GHz',
  int? signal,
  int? downlinkMbps,
  bool wifi = true,
}) {
  return DeviceUIModel(
    mac: mac,
    ip: '192.168.1.100',
    hostName: mac,
    isWifi: wifi,
    band: band,
    signalStrength: signal,
    downlinkRate: downlinkMbps != null ? downlinkMbps * 1000000 : null,
    layer1Interface: wifi
        ? 'Device.WiFi.AccessPoint.1.AssociatedDevice.1'
        : 'Device.Ethernet.Interface.1',
    isActive: true,
  );
}

void main() {
  group('DeviceScore — compute', () {
    test('wired device always scores 100', () {
      final device = _device(wifi: false, signal: -90, downlinkMbps: 0);
      final score = DeviceScore.compute(device);
      expect(score.score, 100);
      expect(score.isGood, isTrue);
    });

    test('excellent wireless: strong signal + high rate', () {
      final device = _device(signal: -30, downlinkMbps: 1200);
      final score = DeviceScore.compute(device);
      expect(score.score, 100); // 50 + 50
      expect(score.isGood, isTrue);
      expect(score.bucket, DeviceScoreBucket.good);
    });

    test('very weak wireless: -90 dBm signal + 0 rate', () {
      final device = _device(signal: -90, downlinkMbps: 0);
      final score = DeviceScore.compute(device);
      expect(score.score, 0);
      expect(score.isIssue, isTrue);
      expect(score.bucket, DeviceScoreBucket.issue);
    });

    test('mid-range: -65 dBm + 400 Mbps', () {
      final device = _device(signal: -65, downlinkMbps: 400);
      final score = DeviceScore.compute(device);
      // Signal: (-65 + 90) / 60 * 50 = 25/60*50 ≈ 20
      // Rate: 400/1200*50 ≈ 16
      // Total ≈ 36-37 → issue bucket (<40)
      expect(score.score, greaterThan(30));
      expect(score.score, lessThan(45));
    });

    test('borderline at-risk: -50 dBm + 866 Mbps', () {
      // Signal: (-50+90)/60*50 = 40/60*50 = 33
      // Rate: 866/1200*50 = 36
      // Total ≈ 69 → at-risk (40-69)
      final device = _device(signal: -50, downlinkMbps: 866);
      final score = DeviceScore.compute(device);
      expect(score.score, greaterThanOrEqualTo(60));
      expect(score.score, lessThan(75));
    });
  });

  group('DeviceScore — bucket getters', () {
    test('score >= 70 → good', () {
      final d = _device(signal: -30, downlinkMbps: 1200);
      expect(DeviceScore.compute(d).isGood, isTrue);
      expect(DeviceScore.compute(d).isAtRisk, isFalse);
      expect(DeviceScore.compute(d).isIssue, isFalse);
    });

    test('score < 40 → issue', () {
      final d = _device(signal: -90, downlinkMbps: 0);
      expect(DeviceScore.compute(d).isIssue, isTrue);
      expect(DeviceScore.compute(d).isGood, isFalse);
    });
  });

  group('DeviceScore — null signal/rate', () {
    test('null signal treated as -90', () {
      final d = _device(signal: null, downlinkMbps: 0);
      final score = DeviceScore.compute(d);
      // signalScore = 0 (null → -90), rateScore = 0
      expect(score.score, 0);
    });

    test('null downlink treated as 0', () {
      final d = _device(signal: -30, downlinkMbps: null);
      final score = DeviceScore.compute(d);
      // signalScore = 50, rateScore = 0
      expect(score.score, 50);
    });
  });
}
