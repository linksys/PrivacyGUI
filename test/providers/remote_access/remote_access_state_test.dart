import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';

void main() {
  group('RemoteAccessState', () {
    test('can be instantiated with isRemoteReadOnly', () {
      const state = RemoteAccessState(isRemoteReadOnly: true);
      expect(state.isRemoteReadOnly, true);
    });

    test('can be instantiated with isRemoteReadOnly false', () {
      const state = RemoteAccessState(isRemoteReadOnly: false);
      expect(state.isRemoteReadOnly, false);
    });

    group('toMap / fromMap', () {
      test('toMap serializes correctly', () {
        const state = RemoteAccessState(isRemoteReadOnly: true);
        final map = state.toMap();
        expect(map, {'isRemoteReadOnly': true});
      });

      test('fromMap deserializes correctly', () {
        final map = {'isRemoteReadOnly': false};
        final state = RemoteAccessState.fromMap(map);
        expect(state.isRemoteReadOnly, false);
      });

      test('fromMap handles missing key with default false', () {
        final map = <String, dynamic>{};
        final state = RemoteAccessState.fromMap(map);
        expect(state.isRemoteReadOnly, false);
      });
    });

    group('toJson / fromJson', () {
      test('toJson serializes correctly', () {
        const state = RemoteAccessState(isRemoteReadOnly: true);
        final json = state.toJson();
        expect(json, '{"isRemoteReadOnly":true}');
      });

      test('fromJson deserializes correctly', () {
        const json = '{"isRemoteReadOnly":false}';
        final state = RemoteAccessState.fromJson(json);
        expect(state.isRemoteReadOnly, false);
      });
    });

    group('equality', () {
      test('two states with same isRemoteReadOnly are equal', () {
        const state1 = RemoteAccessState(isRemoteReadOnly: true);
        const state2 = RemoteAccessState(isRemoteReadOnly: true);
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('two states with different isRemoteReadOnly are not equal', () {
        const state1 = RemoteAccessState(isRemoteReadOnly: true);
        const state2 = RemoteAccessState(isRemoteReadOnly: false);
        expect(state1, isNot(equals(state2)));
      });
    });

    group('copyWith', () {
      test('preserves original value when no parameter provided', () {
        // Arrange
        const original = RemoteAccessState(isRemoteReadOnly: true);

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied.isRemoteReadOnly, true);
      });

      test('updates isRemoteReadOnly when provided', () {
        // Arrange
        const original = RemoteAccessState(isRemoteReadOnly: true);

        // Act
        final updated = original.copyWith(isRemoteReadOnly: false);

        // Assert
        expect(updated.isRemoteReadOnly, false);
      });

      test('creates new instance, not mutation', () {
        // Arrange
        const original = RemoteAccessState(isRemoteReadOnly: true);

        // Act
        final updated = original.copyWith(isRemoteReadOnly: false);

        // Assert
        expect(original.isRemoteReadOnly, true); // Original unchanged
        expect(updated.isRemoteReadOnly, false); // Updated changed
        expect(identical(original, updated), isFalse); // Different instances
      });
    });
  });
}
