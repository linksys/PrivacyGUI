import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/page/health_check/models/smart_qos_recommendation.dart';

/// These expectations are pinned to the router's own recommendation endpoint
/// (`backend/smartqos.cgi` → GetSmartQoSRecommendation). The canonical case is a
/// real measurement taken off the lab unit — 347337/7464 kbps — which the router
/// committed to `/etc/config/smartqos` as upload 6717, download 312603,
/// mode UploadOnly. If these tests fail, the GUI and the router have diverged.
///
/// The JNAP [SpeedTestResult] reports bandwidth in kbps directly (no bps→kbps
/// conversion), so the helper passes the kbps figures straight through.
void main() {
  SpeedTestResult resultFor(
      {required int downKbps, required int upKbps, int? latency}) {
    return SpeedTestResult(
      resultID: 1,
      exitCode: 'Success',
      downloadBandwidth: downKbps,
      uploadBandwidth: upKbps,
      latency: latency,
    );
  }

  group('SmartQosRecommendation.fromResult', () {
    test('reproduces the values the router committed for the lab measurement',
        () {
      final rec = SmartQosRecommendation.fromResult(
        resultFor(downKbps: 347337, upKbps: 7464, latency: 22),
      );

      expect(rec.uploadKbps, 6717);
      expect(rec.downloadKbps, 312603);
      expect(rec.mode, SmartQosMode.uploadOnly);
      expect(rec.overheadBytes, 18);
      expect(rec.latencyMs, 22);
    });

    test('shapes to 90% of measured bandwidth', () {
      final rec = SmartQosRecommendation.fromResult(
        resultFor(downKbps: 100000, upKbps: 10000),
      );

      expect(rec.uploadKbps, 9000);
      expect(rec.downloadKbps, 90000);
    });

    test('uses uploadOnly above the 200000 kbps download threshold', () {
      final fast = SmartQosRecommendation.fromResult(
        resultFor(downKbps: 200001, upKbps: 5000),
      );
      expect(fast.mode, SmartQosMode.uploadOnly);
      expect(fast.isDownloadUnlimited, isTrue);
    });

    test('uses both at or below the threshold', () {
      final slow = SmartQosRecommendation.fromResult(
        resultFor(downKbps: 200000, upKbps: 5000),
      );
      expect(slow.mode, SmartQosMode.both);
      expect(slow.isDownloadUnlimited, isFalse);
    });

    test('handles a missing/zero result without throwing', () {
      final empty = SmartQosRecommendation.fromResult(
        const SpeedTestResult(resultID: 0, exitCode: 'Success'),
      );

      expect(empty.uploadKbps, 0);
      expect(empty.downloadKbps, 0);
      expect(empty.mode, SmartQosMode.both);
    });

    test('exposes Mbps conversions for display', () {
      final rec = SmartQosRecommendation.fromResult(
        resultFor(downKbps: 347337, upKbps: 7464),
      );

      expect(rec.uploadMbps, closeTo(6.717, 0.001));
      expect(rec.downloadMbps, closeTo(312.603, 0.001));
    });
  });

  group('equality', () {
    test('two recommendations from the same result are equal', () {
      final a = SmartQosRecommendation.fromResult(
        resultFor(downKbps: 347337, upKbps: 7464),
      );
      final b = SmartQosRecommendation.fromResult(
        resultFor(downKbps: 347337, upKbps: 7464),
      );

      expect(a, equals(b));
    });

    test('copyWith changes only the named field', () {
      final base = SmartQosRecommendation.fromResult(
        resultFor(downKbps: 347337, upKbps: 7464),
      );
      final edited = base.copyWith(overheadBytes: 44);

      expect(edited.overheadBytes, 44);
      expect(edited.uploadKbps, base.uploadKbps);
      expect(edited, isNot(equals(base)));
    });
  });
}
