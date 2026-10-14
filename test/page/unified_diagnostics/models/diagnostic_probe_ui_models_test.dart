import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_probe_ui_models.dart';

void main() {
  group('diagnostic probe UI model getters', () {
    test('DeviceSignalUIModel.signalLabel covers all RSSI bands', () {
      DeviceSignalUIModel d(int rssi) =>
          DeviceSignalUIModel(name: 'd', macAddress: 'mac', rssiDbm: rssi);
      // Thresholds from wifi.dart: rssiExcellent=-65, rssiGood=-71, rssiFair=-78
      expect(d(-40).signalLabel, 'Excellent'); // >= -65
      expect(d(-65).signalLabel, 'Excellent'); // == -65 (boundary)
      expect(d(-66).signalLabel, 'Good'); // >= -71
      expect(d(-71).signalLabel, 'Good'); // == -71 (boundary)
      expect(d(-72).signalLabel, 'Fair'); // >= -78
      expect(d(-78).signalLabel, 'Fair'); // == -78 (boundary)
      expect(d(-79).signalLabel, 'Weak'); // < -78
      expect(d(-90).signalLabel, 'Weak');
    });

    test('WifiSignalPerRadioUIModel aggregates totals across active radios',
        () {
      const radios = WifiSignalPerRadioUIModel(radios: [
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.1.',
          band: '2.4GHz',
          channel: 6,
          status: 'Up',
          clientCount: 2,
          averageRssi: -60,
          minRssi: -70,
        ),
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.2.',
          band: '5GHz',
          channel: 36,
          status: 'Up',
          clientCount: 3,
          averageRssi: -75, // weak
          minRssi: -85,
        ),
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.3.',
          band: '6GHz',
          channel: 161,
          status: 'Up',
          clientCount: 0,
          averageRssi: 0,
          minRssi: 0,
        ),
      ]);

      expect(radios.activeRadios.length, 2);
      expect(radios.totalClients, 5);
      // weighted: (-60*2 + -75*3) / 5 = (-120 + -225)/5 = -69
      expect(radios.weightedAverageRssi, -69);
      expect(radios.hasWeakRadio, isTrue);
      expect(radios.radios.first.hasClients, isTrue);
      expect(radios.radios[1].isWeakAverage, isTrue);
    });

    test('WifiSignalPerRadioUIModel returns 0 weighted RSSI with no clients',
        () {
      const radios = WifiSignalPerRadioUIModel(radios: [
        RadioSignalStatsUIModel(
          instancePath: 'Device.WiFi.Radio.1.',
          band: '2.4GHz',
          channel: 6,
          status: 'Up',
          clientCount: 0,
          averageRssi: 0,
          minRssi: 0,
        ),
      ]);
      expect(radios.weightedAverageRssi, 0);
      expect(radios.hasWeakRadio, isFalse);
    });

    test('IntermittentUIModel.uptimeFormatted handles seconds/min/hour/day',
        () {
      IntermittentUIModel m(int s) => IntermittentUIModel(
            uptimeSeconds: s,
            pingSuccessRate: 1,
            averageLatencyMs: 0,
            jitterMs: 0,
            hasHighJitter: false,
            hasPacketLoss: false,
            recentReboot: false,
          );
      expect(m(30).uptimeFormatted, '0m'); // < 1 minute
      expect(m(60 * 5).uptimeFormatted, '5m');
      expect(m(3600 * 2 + 60 * 30).uptimeFormatted, '2h 30m');
      expect(m(86400 * 3 + 3600 * 4).uptimeFormatted, '3d 4h');
    });
  });
}
