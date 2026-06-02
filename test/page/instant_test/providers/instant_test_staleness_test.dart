// Tests for staleness tracking: completedAt is set when fetch completes,
// and state carries it correctly through copyWith.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_test/providers/instant_test_state.dart';

void main() {
  group('InstantTestState — completedAt', () {
    test('default state has null completedAt', () {
      const s = InstantTestState();
      expect(s.completedAt, isNull);
    });

    test('copyWith sets completedAt', () {
      const s = InstantTestState();
      final now = DateTime(2026, 6, 2, 10, 0, 0);
      final updated = s.copyWith(completedAt: now);
      expect(updated.completedAt, now);
    });

    test('copyWith without completedAt preserves existing value', () {
      final now = DateTime(2026, 6, 2, 10, 0, 0);
      final s = InstantTestState(completedAt: now);
      final updated = s.copyWith(phase: InstantTestLoadPhase.loading);
      expect(updated.completedAt, now);
    });

    test('completedAt is included in props equality', () {
      final t1 = DateTime(2026, 6, 2, 10, 0, 0);
      final t2 = DateTime(2026, 6, 2, 10, 5, 0);
      final s1 = InstantTestState(completedAt: t1);
      final s2 = InstantTestState(completedAt: t2);
      expect(s1, isNot(equals(s2)));
    });

    test('same completedAt → equal states (all else same)', () {
      final t = DateTime(2026, 6, 2, 10, 0, 0);
      final s1 = InstantTestState(completedAt: t);
      final s2 = InstantTestState(completedAt: t);
      expect(s1, equals(s2));
    });
  });
}
