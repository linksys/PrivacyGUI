import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_radio_band.dart';

import '../../../mocks/test_data/data_elements_test_data.dart';

void main() {
  // 802.11 Table E-4's global operating classes, as Linux maps them
  // (`ieee80211_operating_class_to_band`). Each range is pinned at both
  // edges and just outside them, so a shifted boundary fails here.
  group('meshBandOfOperatingClass', () {
    test('81-84 are 2.4 GHz', () {
      for (final c in [81, 82, 83, 84]) {
        expect(meshBandOfOperatingClass(c), '2.4GHz', reason: '$c');
      }
      expect(meshBandOfOperatingClass(80), isNull);
      expect(meshBandOfOperatingClass(85), isNull);
    });

    test('112 and 115-130 are 5 GHz', () {
      for (final c in [112, 115, 125, 127, 128, 130]) {
        expect(meshBandOfOperatingClass(c), '5GHz', reason: '$c');
      }
      for (final c in [111, 113, 114]) {
        expect(meshBandOfOperatingClass(c), isNull, reason: '$c');
      }
    });

    // 136 is the 6 GHz 20 MHz class for channel 2. Linux's
    // `ieee80211_operating_class_to_band` leaves it out, but its
    // `ieee80211_operating_class_to_chandef` maps it to 6 GHz.
    test('131-137 are 6 GHz, 136 included', () {
      for (final c in [131, 133, 135, 136, 137]) {
        expect(meshBandOfOperatingClass(c), '6GHz', reason: '$c');
      }
      expect(meshBandOfOperatingClass(130), '5GHz');
      expect(meshBandOfOperatingClass(138), isNull);
    });

    // A profile firmware has not filled reads 0; 180 is 60 GHz, which no
    // FL-WRT radio has and the app has no spelling for.
    test('0, 60 GHz and undefined classes have no band', () {
      for (final c in [0, 180, 255]) {
        expect(meshBandOfOperatingClass(c), isNull, reason: '$c');
      }
    });
  });

  group('meshRadioBand', () {
    final path = DataElementsTestData.nodePath('1');

    // The two radios as measured on 2.0.3.26101482.
    test('the measured 5 GHz and 2.4 GHz radios', () {
      expect(
          meshRadioBand(DataElementsTestData.radio(path,
              operatingClasses: [125, 127, 128])),
          '5GHz');
      expect(
          meshRadioBand(
              DataElementsTestData.radio(path, operatingClasses: [81])),
          '2.4GHz');
    });

    test('unfilled profiles are ignored beside a filled one', () {
      expect(
          meshRadioBand(
              DataElementsTestData.radio(path, operatingClasses: [0, 81, 0])),
          '2.4GHz');
    });

    test('no profile, or only unfilled ones, is no band', () {
      expect(meshRadioBand(DataElementsTestData.radio(path)), isNull);
      expect(
          meshRadioBand(
              DataElementsTestData.radio(path, operatingClasses: [0, 0])),
          isNull);
    });

    // A wrong band is shown; a missing one says nothing.
    test('profiles naming two bands are no band, not a guess', () {
      expect(
          meshRadioBand(
              DataElementsTestData.radio(path, operatingClasses: [81, 125])),
          isNull);
    });
  });
}
