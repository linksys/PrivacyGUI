import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_state.dart';

void main() {
  group('RouterPasswordState', () {
    group('init()', () {
      test('returns correct default values', () {
        // Act
        final state = RouterPasswordState.init();

        // Assert
        expect(state.adminPassword, '');
        expect(state.hint, '');
        expect(state.isValid, false);
        expect(state.isDefault, true);
        expect(state.isSetByUser, false);
        expect(state.hasEdited, false);
        expect(state.error, null);
        expect(state.remainingErrorAttempts, null);
      });
    });

    group('copyWith()', () {
      test('creates new instance with overridden values', () {
        // Arrange
        final original = RouterPasswordState.init();

        // Act
        final copied = original.copyWith(
          adminPassword: 'newPassword',
          hint: 'newHint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: 'someError',
          remainingErrorAttempts: 3,
        );

        // Assert
        expect(copied.adminPassword, 'newPassword');
        expect(copied.hint, 'newHint');
        expect(copied.isValid, true);
        expect(copied.isDefault, false);
        expect(copied.isSetByUser, true);
        expect(copied.hasEdited, true);
        expect(copied.error, 'someError');
        expect(copied.remainingErrorAttempts, 3);
      });

      test('preserves unchanged values', () {
        // Arrange
        final original = RouterPasswordState(
          adminPassword: 'originalPassword',
          hint: 'originalHint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: 'originalError',
          remainingErrorAttempts: 5,
        );

        // Act
        final copied = original.copyWith(adminPassword: 'newPassword');

        // Assert
        expect(copied.adminPassword, 'newPassword');
        expect(copied.hint, 'originalHint');
        expect(copied.isValid, true);
        expect(copied.isDefault, false);
        expect(copied.isSetByUser, true);
        expect(copied.hasEdited, true);
        expect(copied.error, 'originalError');
        expect(copied.remainingErrorAttempts, 5);
      });

      test('returns different instance', () {
        // Arrange
        final original = RouterPasswordState.init();

        // Act
        final copied = original.copyWith(adminPassword: 'newPassword');

        // Assert
        expect(identical(original, copied), false);
      });
    });

    group('toMap() / fromMap()', () {
      test('roundtrip preserves all values', () {
        // Arrange
        const original = RouterPasswordState(
          adminPassword: 'testPassword',
          hint: 'testHint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: 'testError',
          remainingErrorAttempts: 2,
        );

        // Act
        final map = original.toMap();
        final restored = RouterPasswordState.fromMap(map);

        // Assert
        expect(restored, original);
      });

      test('toMap() includes all fields', () {
        // Arrange
        const state = RouterPasswordState(
          adminPassword: 'pwd',
          hint: 'hint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: 'err',
          remainingErrorAttempts: 1,
        );

        // Act
        final map = state.toMap();

        // Assert
        expect(map['adminPassword'], 'pwd');
        expect(map['hint'], 'hint');
        expect(map['isValid'], true);
        expect(map['isDefault'], false);
        expect(map['isSetByUser'], true);
        expect(map['hasEdited'], true);
        expect(map['error'], 'err');
        expect(map['remainingErrorAttempts'], 1);
      });

      test('fromMap() handles null optional fields', () {
        // Arrange
        final map = {
          'adminPassword': 'pwd',
          'hint': 'hint',
          'isValid': false,
          'isDefault': true,
          'isSetByUser': false,
          'hasEdited': false,
          'error': null,
          'remainingErrorAttempts': null,
        };

        // Act
        final state = RouterPasswordState.fromMap(map);

        // Assert
        expect(state.error, null);
        expect(state.remainingErrorAttempts, null);
      });
    });

    group('toJson() / fromJson()', () {
      test('roundtrip preserves all values', () {
        // Arrange
        const original = RouterPasswordState(
          adminPassword: 'jsonPassword',
          hint: 'jsonHint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: false,
          error: 'jsonError',
          remainingErrorAttempts: 4,
        );

        // Act
        final json = original.toJson();
        final restored = RouterPasswordState.fromJson(json);

        // Assert
        expect(restored, original);
      });
    });

    group('Equatable', () {
      test('equal states have same hashCode', () {
        // Arrange
        const state1 = RouterPasswordState(
          adminPassword: 'pwd',
          hint: 'hint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: 'err',
          remainingErrorAttempts: 1,
        );
        const state2 = RouterPasswordState(
          adminPassword: 'pwd',
          hint: 'hint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: 'err',
          remainingErrorAttempts: 1,
        );

        // Assert
        expect(state1, state2);
        expect(state1.hashCode, state2.hashCode);
      });

      test('different states are not equal', () {
        // Arrange
        const state1 = RouterPasswordState(
          adminPassword: 'pwd1',
          hint: 'hint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: null,
          remainingErrorAttempts: null,
        );
        const state2 = RouterPasswordState(
          adminPassword: 'pwd2',
          hint: 'hint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: null,
          remainingErrorAttempts: null,
        );

        // Assert
        expect(state1, isNot(state2));
      });

      test('props includes all fields', () {
        // Arrange
        const state = RouterPasswordState(
          adminPassword: 'pwd',
          hint: 'hint',
          isValid: true,
          isDefault: false,
          isSetByUser: true,
          hasEdited: true,
          error: 'err',
          remainingErrorAttempts: 1,
        );

        // Assert
        expect(state.props, [
          'pwd',
          'hint',
          true,
          false,
          true,
          true,
          'err',
          1,
        ]);
      });
    });
  });
}
