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
        DeviceScoreUIModel makeAt(int rssi) => DeviceScoreUIModel(
              macAddress: 'AA',
              name: 'D',
              rssiDbm: rssi,
            );
        expect(makeAt(-40).signalScore, 100);
        expect(makeAt(-50).signalScore, 100);
        expect(makeAt(-55).signalScore, 80);
        expect(makeAt(-65).signalScore, 60);
        expect(makeAt(-75).signalScore, 40);
        expect(makeAt(-90).signalScore, 20);
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
      final device = DeviceScoreUIModel(
        macAddress: 'A',
        name: 'B',
        rssiDbm: -75, // signal=40
        downlinkKbps: 60000, // data=80
      );
      expect(device.overallScore, 60);
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

    test('hasWeakSignal flags wireless rssi < -70 only', () {
      expect(
          DeviceScoreUIModel(macAddress: 'A', name: 'B', rssiDbm: -75)
              .hasWeakSignal,
          isTrue);
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
        DeviceScoreUIModel makeAt(int rssi) =>
            DeviceScoreUIModel(macAddress: 'A', name: 'B', rssiDbm: rssi);
        expect(makeAt(-45).signalLabel, 'Excellent');
        expect(makeAt(-55).signalLabel, 'Good');
        expect(makeAt(-65).signalLabel, 'Fair');
        expect(makeAt(-75).signalLabel, 'Weak');
        expect(makeAt(-90).signalLabel, 'Very Weak');
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
