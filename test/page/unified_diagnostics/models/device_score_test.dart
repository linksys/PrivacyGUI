import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/device_score.dart';

void main() {
  group('DeviceScoreUIModel', () {
    group('signalScore', () {
      test('wired devices score 100 regardless of rssi', () {
        final wired = DeviceScoreUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          name: 'Desktop',
          rssiDbm: -90,
          isWireless: false,
        );
        expect(wired.signalScore, 100);
      });

      test('wireless with null rssi defaults to 100', () {
        final device = DeviceScoreUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          name: 'Phone',
        );
        expect(device.signalScore, 100);
      });

      test('rssi buckets map to correct scores', () {
        // Thresholds from wifi.dart: rssiExcellent=-65, rssiGood=-71, rssiFair=-78
        DeviceScoreUIModel makeAt(int rssi) => DeviceScoreUIModel(
              macAddress: 'AA',
              name: 'D',
              rssiDbm: rssi,
            );
        expect(makeAt(-40).signalScore, 100); // >= -65 → Excellent
        expect(makeAt(-65).signalScore, 100); // == -65 → Excellent (boundary)
        expect(makeAt(-66).signalScore, 80); // >= -71 → Good
        expect(makeAt(-71).signalScore, 80); // == -71 → Good (boundary)
        expect(makeAt(-72).signalScore, 60); // >= -78 → Fair
        expect(makeAt(-78).signalScore, 60); // == -78 → Fair (boundary)
        expect(makeAt(-79).signalScore, 40); // < -78 → Weak
        expect(makeAt(-90).signalScore, 40);
      });
    });

    group('dataRateScore', () {
      DeviceScoreUIModel makeAtKbps(int kbps) => DeviceScoreUIModel(
            macAddress: 'AA',
            name: 'D',
            downlinkKbps: kbps,
          );

      test('null downlinkKbps defaults to 100', () {
        expect(
            DeviceScoreUIModel(macAddress: 'A', name: 'B').dataRateScore, 100);
      });

      test('rate buckets map to correct scores', () {
        expect(makeAtKbps(150000).dataRateScore, 100);
        expect(makeAtKbps(60000).dataRateScore, 80);
        expect(makeAtKbps(25000).dataRateScore, 60);
        expect(makeAtKbps(15000).dataRateScore, 40);
        expect(makeAtKbps(5000).dataRateScore, 20);
      });
    });

    test('overallScore averages signal and data rate', () {
      // rssiGood=-71, so -72 is Fair (score=60), 60 Mbps = Good (score=80)
      final device = DeviceScoreUIModel(
        macAddress: 'A',
        name: 'B',
        rssiDbm: -72, // signal=60 (Fair)
        downlinkKbps: 60000, // data=80
      );
      expect(device.overallScore, 70); // (60+80)/2
    });

    test('hasIssue requires wireless and overall < 50', () {
      final wired = DeviceScoreUIModel(
        macAddress: 'A',
        name: 'B',
        rssiDbm: -90,
        downlinkKbps: 1000,
        isWireless: false,
      );
      expect(wired.hasIssue, isFalse);

      final wirelessIssue = DeviceScoreUIModel(
        macAddress: 'A',
        name: 'B',
        rssiDbm: -85, // signal=20
        downlinkKbps: 5000, // data=20 → overall=20
      );
      expect(wirelessIssue.hasIssue, isTrue);

      final wirelessOk = DeviceScoreUIModel(
        macAddress: 'A',
        name: 'B',
        rssiDbm: -50,
        downlinkKbps: 100000,
      );
      expect(wirelessOk.hasIssue, isFalse);
    });

    test('hasWeakSignal flags wireless rssi < rssiGood (-71) only', () {
      // rssiGood=-71, so -72 is weak, -71 is not weak
      expect(
          DeviceScoreUIModel(macAddress: 'A', name: 'B', rssiDbm: -72)
              .hasWeakSignal,
          isTrue);
      expect(
          DeviceScoreUIModel(macAddress: 'A', name: 'B', rssiDbm: -71)
              .hasWeakSignal,
          isFalse);
      expect(
          DeviceScoreUIModel(macAddress: 'A', name: 'B', rssiDbm: -50)
              .hasWeakSignal,
          isFalse);
      expect(
          DeviceScoreUIModel(
            macAddress: 'A',
            name: 'B',
            rssiDbm: -90,
            isWireless: false,
          ).hasWeakSignal,
          isFalse);
    });

    test('hasLowDataRate flags downlink < 20 Mbps', () {
      expect(
          DeviceScoreUIModel(macAddress: 'A', name: 'B', downlinkKbps: 19999)
              .hasLowDataRate,
          isTrue);
      expect(
          DeviceScoreUIModel(macAddress: 'A', name: 'B', downlinkKbps: 25000)
              .hasLowDataRate,
          isFalse);
      expect(DeviceScoreUIModel(macAddress: 'A', name: 'B').hasLowDataRate,
          isFalse);
    });

    group('signalLabel', () {
      test('returns Wired for non-wireless', () {
        expect(
          DeviceScoreUIModel(
            macAddress: 'A',
            name: 'B',
            isWireless: false,
          ).signalLabel,
          'Wired',
        );
      });

      test('returns Unknown when rssi is null', () {
        expect(DeviceScoreUIModel(macAddress: 'A', name: 'B').signalLabel,
            'Unknown');
      });

      test('returns bucketed labels by rssi', () {
        // Thresholds: rssiExcellent=-65, rssiGood=-71, rssiFair=-78
        DeviceScoreUIModel makeAt(int rssi) =>
            DeviceScoreUIModel(macAddress: 'A', name: 'B', rssiDbm: rssi);
        expect(makeAt(-45).signalLabel, 'Excellent'); // >= -65
        expect(makeAt(-65).signalLabel, 'Excellent'); // == -65 (boundary)
        expect(makeAt(-66).signalLabel, 'Good'); // >= -71
        expect(makeAt(-71).signalLabel, 'Good'); // == -71 (boundary)
        expect(makeAt(-72).signalLabel, 'Fair'); // >= -78
        expect(makeAt(-78).signalLabel, 'Fair'); // == -78 (boundary)
        expect(makeAt(-79).signalLabel, 'Weak'); // < -78
        expect(makeAt(-90).signalLabel, 'Weak');
      });
    });

    group('dataRateLabel', () {
      DeviceScoreUIModel makeAtKbps(int? kbps) => DeviceScoreUIModel(
            macAddress: 'A',
            name: 'B',
            downlinkKbps: kbps,
          );

      test('returns Unknown when downlinkKbps is null', () {
        expect(makeAtKbps(null).dataRateLabel, 'Unknown');
      });

      test('returns bucketed labels by mbps', () {
        expect(makeAtKbps(150000).dataRateLabel, 'Fast');
        expect(makeAtKbps(60000).dataRateLabel, 'Good');
        expect(makeAtKbps(25000).dataRateLabel, 'Moderate');
        expect(makeAtKbps(15000).dataRateLabel, 'Slow');
        expect(makeAtKbps(5000).dataRateLabel, 'Very Slow');
      });
    });

    test('copyWith preserves untouched fields', () {
      final base = DeviceScoreUIModel(
        macAddress: 'AA',
        name: 'Original',
        rssiDbm: -60,
        downlinkKbps: 50000,
      );
      final updated = base.copyWith(name: 'Renamed', rssiDbm: -50);
      expect(updated.name, 'Renamed');
      expect(updated.rssiDbm, -50);
      expect(updated.macAddress, base.macAddress);
      expect(updated.downlinkKbps, base.downlinkKbps);
    });

    test('Equatable equality covers all props', () {
      final a = DeviceScoreUIModel(macAddress: 'AA', name: 'D');
      final b = DeviceScoreUIModel(macAddress: 'AA', name: 'D');
      final c = DeviceScoreUIModel(macAddress: 'AA', name: 'E');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
