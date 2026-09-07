import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/wifi.dart';

void main() {
  // ---------------------------------------------------------------------------
  // getWifiSignalLevel — RSSI/SNR grading, including the #1438 zero-reading fix.
  // ---------------------------------------------------------------------------

  group('getWifiSignalLevel', () {
    test('null is wired (no WiFi signal at all)', () {
      expect(getWifiSignalLevel(null), NodeSignalLevel.wired);
    });

    // linksys/PrivacyGUI#1438 (FWDEV#166 AC5): a `0` reading is "no reading",
    // not a real 0 dBm measurement. It must NOT grade as excellent
    // (0 >= rssiExcellent(-65) would otherwise clear the top band).
    test('zero grades as none (unknown), not excellent (#1438)', () {
      expect(getWifiSignalLevel(0), NodeSignalLevel.none);
    });

    test('RSSI thresholds grade correctly', () {
      expect(getWifiSignalLevel(-65), NodeSignalLevel.excellent);
      expect(getWifiSignalLevel(-71), NodeSignalLevel.good);
      expect(getWifiSignalLevel(-78), NodeSignalLevel.fair);
      expect(getWifiSignalLevel(-79), NodeSignalLevel.poor);
    });

    test('positive values are treated as SNR', () {
      // SNR thresholds are [40, 25, 10]; a healthy SNR still grades highly.
      expect(getWifiSignalLevel(45), NodeSignalLevel.excellent);
      expect(getWifiSignalLevel(30), NodeSignalLevel.good);
      expect(getWifiSignalLevel(15), NodeSignalLevel.fair);
      expect(getWifiSignalLevel(5), NodeSignalLevel.poor);
    });
  });
}
