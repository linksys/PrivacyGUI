@Tags(['dashboard-card'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';

/// Selection rules for [CardDensity] (#1232).
///
/// These are written first and deliberately: the #1183 overflow gate asserts
/// only "does not overflow", so it cannot detect a *wrong* density. A card
/// rendering its popup form at 900px, or its normal form at 150px, is invisible
/// to the gate as long as nothing overflows. Every rule below is therefore
/// asserted here rather than left to the gate.
void main() {
  group('densityForWidth — no threshold declared', () {
    // #1232: "Its default is absent, not a number. A spec declaring no
    // threshold asserts 'this card needs no degraded form'." So absent is not
    // "degrade at some default width" — it opts the card out of degradation
    // entirely, popup included.
    for (final width in [0.0, 100.0, 191.0, 199.9, 200.0, 500.0, 1216.0]) {
      test('width $width selects normal when normalAbove is absent', () {
        expect(
          densityForWidth(width: width, normalAbove: null),
          CardDensity.normal,
        );
      });
    }
  });

  group('densityForWidth — threshold declared', () {
    test('below the popup constant selects popup', () {
      expect(
        densityForWidth(width: kPopupBelow - 0.1, normalAbove: 400),
        CardDensity.popup,
      );
    });

    test('exactly at the popup constant selects compact, not popup', () {
      // The band is `width < 200` for popup and `200 <= width` for compact, so
      // 200.0 itself belongs to compact. Pinned because an inclusive/exclusive
      // slip here is invisible at every width except this one.
      expect(
        densityForWidth(width: kPopupBelow, normalAbove: 400),
        CardDensity.compact,
      );
    });

    test('between the popup constant and normalAbove selects compact', () {
      expect(
          densityForWidth(width: 300, normalAbove: 400), CardDensity.compact);
    });

    test('exactly at normalAbove selects normal', () {
      // "normal: width >= normalAbove" — the threshold names the first width at
      // which the card is whole, so the boundary belongs to normal.
      expect(densityForWidth(width: 400, normalAbove: 400), CardDensity.normal);
    });

    test('above normalAbove selects normal', () {
      expect(
          densityForWidth(width: 1216, normalAbove: 400), CardDensity.normal);
    });
  });

  group('densityForWidth — degenerate thresholds', () {
    // A threshold at or below the popup constant leaves the compact band empty.
    // That is not an error, but it is worth pinning: popup still wins below 200,
    // so such a card degrades straight from normal to popup with nothing in
    // between. Declaring one is almost certainly a mistake, and this test is
    // where someone reading the behaviour will find out.
    test('normalAbove below the popup constant yields no compact band', () {
      expect(densityForWidth(width: 150, normalAbove: 180), CardDensity.popup);
      expect(densityForWidth(width: 190, normalAbove: 180), CardDensity.normal);
      expect(densityForWidth(width: 250, normalAbove: 180), CardDensity.normal);
    });

    test('normalAbove exactly at the popup constant yields no compact band',
        () {
      expect(
        densityForWidth(width: kPopupBelow - 0.1, normalAbove: kPopupBelow),
        CardDensity.popup,
      );
      expect(
        densityForWidth(width: kPopupBelow, normalAbove: kPopupBelow),
        CardDensity.normal,
      );
    });
  });

  test('the popup constant is 200px, in pixels and named', () {
    // §2.1 fixes the popup cut-off at 200px, and §1.5 forbids expressing any
    // density threshold in columns (a 3-column card spans 191.4-422.0px, a 2.2x
    // distortion). Pinned so the constant cannot drift silently.
    expect(kPopupBelow, 200.0);
  });
}
