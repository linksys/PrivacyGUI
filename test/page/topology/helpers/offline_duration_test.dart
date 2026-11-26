// #1443: how long an offline extender has been offline, and the granularity it
// is shown at. The stamp is the 2026-11-23 bench's `ActiveLastChange`.
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/helpers/offline_duration.dart';

void main() {
  final wentOffline = DateTime.utc(2026, 11, 23, 9, 10, 8);

  /// The offline shape `MeshNetworkBuilder` builds: no DataElements ID.
  SlaveNode offlineNode(DateTime? since) => SlaveNode(
        deviceId: 'aa:bb:cc:dd:ee:08',
        model: '',
        backhaul: BackhaulInfo.none,
        offlineSince: since,
      );

  group('nodeOfflineDuration', () {
    test('an offline node reads now minus the stamp (AC1)', () {
      final now = wentOffline.add(const Duration(hours: 3, minutes: 7));

      expect(nodeOfflineDuration(offlineNode(wentOffline), now),
          const Duration(hours: 3, minutes: 7));
    });

    // A Hosts row is deleted 24 h after its host leaves, so a longer duration
    // can only come from a wrong stamp (one written before NTP set the clock).
    test('up to the retention plus an hour still reads as a duration', () {
      final now = wentOffline.add(kMaxOfflineDuration);

      expect(nodeOfflineDuration(offlineNode(wentOffline), now),
          kMaxOfflineDuration);
    });

    test('beyond the retention plus an hour reads unknown, not a figure', () {
      final now =
          wentOffline.add(kMaxOfflineDuration + const Duration(minutes: 1));

      expect(nodeOfflineDuration(offlineNode(wentOffline), now), isNull);
    });

    test('the cap follows the firmware retention of 24 h, plus an hour', () {
      expect(kMaxOfflineDuration, const Duration(hours: 25));
    });

    test('an offline node with no stamp is unknown, not zero (AC3)', () {
      expect(nodeOfflineDuration(offlineNode(null), wentOffline), isNull);
    });

    test('a stamp ahead of the browser clock reads zero, not negative', () {
      final now = wentOffline.subtract(const Duration(minutes: 1));

      expect(nodeOfflineDuration(offlineNode(wentOffline), now), Duration.zero);
    });

    test('a stamp up to an hour ahead still reads zero', () {
      final now = wentOffline.subtract(kMaxFutureSkew);

      expect(nodeOfflineDuration(offlineNode(wentOffline), now), Duration.zero);
    });

    // Otherwise a router clock far ahead, or TR-181's 9999-12-31 sentinel,
    // would read "1 min" for as long as the node stays offline.
    test('a stamp more than an hour ahead reads unknown', () {
      final now =
          wentOffline.subtract(kMaxFutureSkew + const Duration(minutes: 1));
      final sentinel = offlineNode(DateTime.utc(9999, 12, 31, 23, 59, 59));

      expect(nodeOfflineDuration(offlineNode(wentOffline), now), isNull);
      expect(nodeOfflineDuration(sentinel, wentOffline), isNull);
    });

    test('an online slave never gets a duration, even with a stamp', () {
      final online = SlaveNode(
        deviceId: 'aa:bb:cc:dd:ee:08',
        dataElementsId: 'aa:bb:cc:dd:ee:08',
        model: '',
        backhaul: BackhaulInfo.none,
        offlineSince: wentOffline,
      );

      expect(nodeOfflineDuration(online, wentOffline), isNull);
    });

    test('a slave whose liveness is unknown is online, so no duration', () {
      final unknownLiveness = SlaveNode(
        deviceId: 'aa:bb:cc:dd:ee:08',
        model: '',
        backhaul: BackhaulInfo.none,
        livenessKnown: false,
        offlineSince: wentOffline,
      );

      expect(nodeOfflineDuration(unknownLiveness, wentOffline), isNull);
    });

    test('the master never gets a duration (AC5)', () {
      final master = MasterNode(deviceId: 'AA:BB:CC:DD:EE:01', model: 'M60');

      expect(nodeOfflineDuration(master, wentOffline), isNull);
    });
  });

  group('offlineDurationParts (AC4)', () {
    final cases = <Duration, (int, OfflineDurationUnit)>{
      Duration.zero: (1, OfflineDurationUnit.minutes),
      const Duration(seconds: 20): (1, OfflineDurationUnit.minutes),
      const Duration(minutes: 1, seconds: 59): (1, OfflineDurationUnit.minutes),
      const Duration(minutes: 59, seconds: 59): (
        59,
        OfflineDurationUnit.minutes
      ),
      const Duration(hours: 1): (1, OfflineDurationUnit.hours),
      const Duration(hours: 47, minutes: 59): (47, OfflineDurationUnit.hours),
      const Duration(hours: 48): (2, OfflineDurationUnit.days),
      const Duration(days: 3, hours: 5): (3, OfflineDurationUnit.days),
    };

    cases.forEach((elapsed, expected) {
      test('$elapsed reads ${expected.$1} ${expected.$2.name}', () {
        final parts = offlineDurationParts(elapsed);

        expect((parts.count, parts.unit), expected);
      });
    });
  });
}
