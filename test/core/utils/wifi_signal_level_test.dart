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

  // ---------------------------------------------------------------------------
  // rcpiToRssi — the 802.11k reserved range (#1555, AC5)
  // ---------------------------------------------------------------------------
  //
  // Why this needs a guard at all: prplMesh declares the **STA**
  // `SignalStrength` field `check_maximum 255` (`sta.odl:55`), not
  // `check_range [0, 220]` like the backhaul field (`device.odl:168`), so
  // 221–255 are values the app can actually be handed. `(rcpi ~/ 2) - 110` turns
  // every one of them into a *positive* dBm figure, and `getWifiSignalLevel`
  // above grades a positive number as an SNR — so an unavailable measurement
  // would come out the top of the scale rather than off it.
  //
  // The asymmetry is the firmware's, and it is why the guard lives here rather
  // than at one call site: the controller rejects an out-of-range write to the
  // backhaul field, so only the STA path can deliver a reserved value, but both
  // paths converge on this one function.
  group('rcpiToRssi', () {
    test('the measurement range converts', () {
      expect(rcpiToRssi(180), -20); // (180 / 2) - 110
      expect(rcpiToRssi(110), -55);
      expect(rcpiToRssi(rcpiMax), 0, reason: '220 is the last valid value');
      expect(rcpiToRssi(1), -110);
    });

    test('absence is null, never a number', () {
      expect(rcpiToRssi(null), isNull);
      // 0 is firmware's "BackhaulStats not populated yet", not a 0 dBm reading.
      expect(rcpiToRssi(0), isNull);
      expect(rcpiToRssi(-1), isNull);
    });

    test('the reserved range 221–254 is null, not a positive dBm', () {
      for (final rcpi in [221, 222, 240, 254]) {
        expect(rcpiToRssi(rcpi), isNull,
            reason: 'RCPI $rcpi is reserved by 802.11k; the formula would read '
                'it as ${(rcpi ~/ 2) - 110} dBm — a signal stronger than any '
                'radio measures');
      }
    });

    test('255 — "measurement not available" — is null', () {
      expect(rcpiToRssi(255), isNull);
    });
  });
}
