import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/topology/helpers/topology_edge_strength.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// One mapping from a radio reading to an edge's strength.
///
/// There were two, and they disagreed: the topology builder mapped `good`→`good`
/// and `fair`→`weak`, while the AI section's copy shifted a rank brighter
/// (`good`→`strong`, `fair`→`good`). Both were renamed during the 3.4.0 migration
/// without being reconciled, so the same device could read one strength on the
/// topology page and another in a generated card.
///
/// The 1:1 mapping is the one that survives, because `wifi_ui.dart` already
/// renders `excellent`→"Excellent", `good`→"Good", `fair`→"Fair" — an edge drawn a
/// rank stronger than the label beside it is a disagreement a viewer notices.
void main() {
  group('every level maps, and the mapping is 1:1 where it can be', () {
    test('excellent, good and fair keep their rank', () {
      expect(edgeStrengthFromLevel(NodeSignalLevel.excellent),
          EdgeStrength.strong);
      expect(edgeStrengthFromLevel(NodeSignalLevel.good), EdgeStrength.good);
      expect(edgeStrengthFromLevel(NodeSignalLevel.fair), EdgeStrength.weak);
    });

    test('poor and none both land on the neutral grade', () {
      // `EdgeStrength` has four members, so a reading too weak to grade and a
      // reading absent share the neutral one. This is what shipped before 3.4.0.
      expect(edgeStrengthFromLevel(NodeSignalLevel.poor), EdgeStrength.unknown);
      expect(edgeStrengthFromLevel(NodeSignalLevel.none), EdgeStrength.unknown);
    });

    test('wired maps to no strength at all', () {
      // Wiredness is the kind axis (`EdgeKind.direct`), which is why 3.4.0 deleted
      // the old `stable` member from the strength enum.
      expect(edgeStrengthFromLevel(NodeSignalLevel.wired), isNull);
    });

    test('every enum member is covered', () {
      // The switch is exhaustive by the compiler; this guards the *test* against a
      // new member arriving with no expectation written for it.
      for (final level in NodeSignalLevel.values) {
        expect(() => edgeStrengthFromLevel(level), returnsNormally,
            reason: level.name);
      }
    });
  });

  group('from a raw dBm reading', () {
    test('an absent reading is unknown, not null', () {
      // Null means "wired" on the level axis, so an absent reading must not
      // collapse into it: the caller would stop drawing a strength for a wireless
      // edge it simply has no number for.
      expect(edgeStrengthFromRssi(null), EdgeStrength.unknown);
    });

    test('the thresholds are wifi.dart\'s, not this file\'s', () {
      // Boundary values from `signalThresholdRSSI` = [-65, -71, -78].
      expect(edgeStrengthFromRssi(rssiExcellent), EdgeStrength.strong);
      expect(edgeStrengthFromRssi(rssiGood), EdgeStrength.good);
      expect(edgeStrengthFromRssi(rssiFair), EdgeStrength.weak);
      expect(edgeStrengthFromRssi(rssiFair - 1), EdgeStrength.unknown);
    });

    test('a strong reading is strong', () {
      expect(edgeStrengthFromRssi(-40), EdgeStrength.strong);
    });
  });
}
