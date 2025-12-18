import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

void main() {
  group('AuthState', () {
    // Test data helpers
    final testSessionToken = SessionToken(
      accessToken: 'test_access_token_123',
      tokenType: 'Bearer',
      expiresIn: 3600,
      refreshToken: 'test_refresh_token_456',
    );

    final testAuthState = AuthState(
      username: 'testuser@example.com',
      password: 'testpass123',
      localPassword: 'localpass456',
      localPasswordHint: 'My test hint',
      sessionToken: testSessionToken,
      loginType: LoginType.remote,
    );

    group('AuthState.empty()', () {
      test('creates state with LoginType.none and all null fields', () {
        // Act
        final state = AuthState.empty();

        // Assert
        expect(state.loginType, equals(LoginType.none));
        expect(state.username, isNull);
        expect(state.password, isNull);
        expect(state.localPassword, isNull);
        expect(state.localPasswordHint, isNull);
        expect(state.sessionToken, isNull);
      });
    });

    group('AuthState.fromJson()', () {
      test('deserializes all fields correctly with complete data', () {
        // Arrange
        final json = {
          'username': 'user@example.com',
          'password': 'password123',
          'localPassword': 'localpass',
          'localPasswordHint': 'hint',
          'sessionToken': jsonEncode(testSessionToken.toJson()),
          'loginType': 'remote',
        };

        // Act
        final state = AuthState.fromJson(json);

        // Assert
        expect(state.username, equals('user@example.com'));
        expect(state.password, equals('password123'));
        expect(state.localPassword, equals('localpass'));
        expect(state.localPasswordHint, equals('hint'));
        expect(state.sessionToken, equals(testSessionToken));
        expect(state.loginType, equals(LoginType.remote));
      });

      test('handles missing sessionToken (null handling)', () {
        // Arrange
        final json = {
          'username': 'user@example.com',
          'password': 'password123',
          'loginType': 'local',
        };

        // Act
        final state = AuthState.fromJson(json);

        // Assert
        expect(state.sessionToken, isNull);
        expect(state.username, equals('user@example.com'));
        expect(state.loginType, equals(LoginType.local));
      });

      test('handles null sessionToken value explicitly', () {
        // Arrange
        final json = {
          'username': 'user@example.com',
          'sessionToken': null,
          'loginType': 'local',
        };

        // Act
        final state = AuthState.fromJson(json);

        // Assert
        expect(state.sessionToken, isNull);
      });

      test('defaults to LoginType.none for invalid loginType', () {
        // Arrange
        final json = {
          'username': 'user@example.com',
          'loginType': 'invalid_login_type',
        };

        // Act
        final state = AuthState.fromJson(json);

        // Assert
        expect(state.loginType, equals(LoginType.none));
      });

      test('defaults to LoginType.none for missing loginType', () {
        // Arrange
        final json = {
          'username': 'user@example.com',
        };

        // Act
        final state = AuthState.fromJson(json);

        // Assert
        expect(state.loginType, equals(LoginType.none));
      });

      test('handles all valid LoginType values', () {
        // Test LoginType.none
        final jsonNone = {'loginType': 'none'};
        expect(
          AuthState.fromJson(jsonNone).loginType,
          equals(LoginType.none),
        );

        // Test LoginType.local
        final jsonLocal = {'loginType': 'local'};
        expect(
          AuthState.fromJson(jsonLocal).loginType,
          equals(LoginType.local),
        );

        // Test LoginType.remote
        final jsonRemote = {'loginType': 'remote'};
        expect(
          AuthState.fromJson(jsonRemote).loginType,
          equals(LoginType.remote),
        );
      });

      test('fromJson with complete data maintains data integrity', () {
        // Arrange
        final originalJson = {
          'username': 'complete@example.com',
          'password': 'pass123',
          'localPassword': 'localpass',
          'localPasswordHint': 'my hint',
          'sessionToken': jsonEncode(testSessionToken.toJson()),
          'loginType': 'remote',
        };

        // Act
        final state = AuthState.fromJson(originalJson);

        // Assert - Verify all fields are correctly deserialized
        expect(state.username, equals('complete@example.com'));
        expect(state.password, equals('pass123'));
        expect(state.localPassword, equals('localpass'));
        expect(state.localPasswordHint, equals('my hint'));
        expect(
            state.sessionToken?.accessToken, equals('test_access_token_123'));
        expect(state.sessionToken?.tokenType, equals('Bearer'));
        expect(state.sessionToken?.expiresIn, equals(3600));
        expect(
          state.sessionToken?.refreshToken,
          equals('test_refresh_token_456'),
        );
        expect(state.loginType, equals(LoginType.remote));
      });
    });

    group('AuthState.copyWith()', () {
      test('preserves all unchanged fields', () {
        // Arrange
        final original = testAuthState;

        // Act - copyWith without any parameters
        final copied = original.copyWith();

        // Assert
        expect(copied.username, equals(original.username));
        expect(copied.password, equals(original.password));
        expect(copied.localPassword, equals(original.localPassword));
        expect(copied.localPasswordHint, equals(original.localPasswordHint));
        expect(copied.sessionToken, equals(original.sessionToken));
        expect(copied.loginType, equals(original.loginType));
      });

      test('updates only username field', () {
        // Arrange
        final original = testAuthState;
        const newUsername = 'newuser@example.com';

        // Act
        final updated = original.copyWith(username: newUsername);

        // Assert
        expect(updated.username, equals(newUsername));
        expect(updated.password, equals(original.password));
        expect(updated.localPassword, equals(original.localPassword));
        expect(updated.localPasswordHint, equals(original.localPasswordHint));
        expect(updated.sessionToken, equals(original.sessionToken));
        expect(updated.loginType, equals(original.loginType));
      });

      test('updates only password field', () {
        // Arrange
        final original = testAuthState;
        const newPassword = 'newpass789';

        // Act
        final updated = original.copyWith(password: newPassword);

        // Assert
        expect(updated.password, equals(newPassword));
        expect(updated.username, equals(original.username));
      });

      test('updates only localPassword field', () {
        // Arrange
        final original = testAuthState;
        const newLocalPassword = 'newlocal123';

        // Act
        final updated = original.copyWith(localPassword: newLocalPassword);

        // Assert
        expect(updated.localPassword, equals(newLocalPassword));
        expect(updated.username, equals(original.username));
        expect(updated.password, equals(original.password));
      });

      test('updates only localPasswordHint field', () {
        // Arrange
        final original = testAuthState;
        const newHint = 'New hint text';

        // Act
        final updated = original.copyWith(localPasswordHint: newHint);

        // Assert
        expect(updated.localPasswordHint, equals(newHint));
        expect(updated.username, equals(original.username));
      });

      test('updates only sessionToken field', () {
        // Arrange
        final original = testAuthState;
        final newToken = SessionToken(
          accessToken: 'new_access',
          tokenType: 'Bearer',
          expiresIn: 7200,
          refreshToken: 'new_refresh',
        );

        // Act
        final updated = original.copyWith(sessionToken: newToken);

        // Assert
        expect(updated.sessionToken, equals(newToken));
        expect(updated.username, equals(original.username));
      });

      test('updates only loginType field', () {
        // Arrange
        final original = testAuthState;

        // Act
        final updated = original.copyWith(loginType: LoginType.local);

        // Assert
        expect(updated.loginType, equals(LoginType.local));
        expect(updated.username, equals(original.username));
        expect(updated.sessionToken, equals(original.sessionToken));
      });

      test('updates multiple fields simultaneously', () {
        // Arrange
        final original = testAuthState;
        const newUsername = 'multi@example.com';
        const newPassword = 'multipass';

        // Act
        final updated = original.copyWith(
          username: newUsername,
          password: newPassword,
          loginType: LoginType.local,
        );

        // Assert
        expect(updated.username, equals(newUsername));
        expect(updated.password, equals(newPassword));
        expect(updated.loginType, equals(LoginType.local));
        expect(updated.localPassword, equals(original.localPassword));
        expect(updated.sessionToken, equals(original.sessionToken));
      });
    });

    group('AuthState Equatable', () {
      test('two states with same values are equal', () {
        // Arrange
        final state1 = AuthState(
          username: 'user@example.com',
          password: 'pass123',
          localPassword: 'localpass',
          localPasswordHint: 'hint',
          sessionToken: testSessionToken,
          loginType: LoginType.remote,
        );

        final state2 = AuthState(
          username: 'user@example.com',
          password: 'pass123',
          localPassword: 'localpass',
          localPasswordHint: 'hint',
          sessionToken: testSessionToken,
          loginType: LoginType.remote,
        );

        // Assert
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('two states with different username are not equal', () {
        // Arrange
        final state1 = AuthState(
          username: 'user1@example.com',
          loginType: LoginType.remote,
        );

        final state2 = AuthState(
          username: 'user2@example.com',
          loginType: LoginType.remote,
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('two states with different password are not equal', () {
        // Arrange
        final state1 = AuthState(
          username: 'user@example.com',
          password: 'pass1',
          loginType: LoginType.remote,
        );

        final state2 = AuthState(
          username: 'user@example.com',
          password: 'pass2',
          loginType: LoginType.remote,
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('two states with different localPassword are not equal', () {
        // Arrange
        final state1 = AuthState(
          localPassword: 'local1',
          loginType: LoginType.local,
        );

        final state2 = AuthState(
          localPassword: 'local2',
          loginType: LoginType.local,
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('two states with different localPasswordHint are not equal', () {
        // Arrange
        final state1 = AuthState(
          localPasswordHint: 'hint1',
          loginType: LoginType.local,
        );

        final state2 = AuthState(
          localPasswordHint: 'hint2',
          loginType: LoginType.local,
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('two states with different sessionToken are not equal', () {
        // Arrange
        final token1 = SessionToken(
          accessToken: 'token1',
          tokenType: 'Bearer',
          expiresIn: 3600,
        );

        final token2 = SessionToken(
          accessToken: 'token2',
          tokenType: 'Bearer',
          expiresIn: 3600,
        );

        final state1 = AuthState(
          sessionToken: token1,
          loginType: LoginType.remote,
        );

        final state2 = AuthState(
          sessionToken: token2,
          loginType: LoginType.remote,
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('two states with different loginType are not equal', () {
        // Arrange
        final state1 = AuthState(
          username: 'user@example.com',
          loginType: LoginType.local,
        );

        final state2 = AuthState(
          username: 'user@example.com',
          loginType: LoginType.remote,
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('state with null field equals another state with same null field',
          () {
        // Arrange
        final state1 = AuthState(
          username: 'user@example.com',
          sessionToken: null,
          loginType: LoginType.remote,
        );

        final state2 = AuthState(
          username: 'user@example.com',
          sessionToken: null,
          loginType: LoginType.remote,
        );

        // Assert
        expect(state1, equals(state2));
      });

      test('state with null differs from state with non-null value', () {
        // Arrange
        final state1 = AuthState(
          username: null,
          loginType: LoginType.none,
        );

        final state2 = AuthState(
          username: 'user@example.com',
          loginType: LoginType.none,
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });
    });

    group('AuthState.props', () {
      test('props includes all fields in correct order', () {
        // Arrange
        final state = testAuthState;

        // Act
        final props = state.props;

        // Assert
        expect(props.length, equals(6));
        expect(props[0], equals(state.username));
        expect(props[1], equals(state.password));
        expect(props[2], equals(state.localPassword));
        expect(props[3], equals(state.localPasswordHint));
        expect(props[4], equals(state.sessionToken));
        expect(props[5], equals(state.loginType));
      });

      test('props includes null values', () {
        // Arrange
        final state = AuthState.empty();

        // Act
        final props = state.props;

        // Assert
        expect(props.length, equals(6));
        expect(props[0], isNull); // username
        expect(props[1], isNull); // password
        expect(props[2], isNull); // localPassword
        expect(props[3], isNull); // localPasswordHint
        expect(props[4], isNull); // sessionToken
        expect(props[5], equals(LoginType.none)); // loginType
      });

      test('props reflects changes made by copyWith', () {
        // Arrange
        final original = AuthState.empty();
        const newUsername = 'changed@example.com';

        // Act
        final updated = original.copyWith(username: newUsername);
        final props = updated.props;

        // Assert
        expect(props[0], equals(newUsername));
      });
    });

    group('AuthState Integration Tests', () {
      test('empty state can be updated with copyWith', () {
        // Arrange
        final empty = AuthState.empty();

        // Act
        final updated = empty.copyWith(
          username: 'user@example.com',
          password: 'password',
          loginType: LoginType.remote,
        );

        // Assert
        expect(updated.username, equals('user@example.com'));
        expect(updated.password, equals('password'));
        expect(updated.loginType, equals(LoginType.remote));
        expect(updated.localPassword, isNull);
      });

      test('deserialized state maintains equality', () {
        // Arrange
        final originalState = testAuthState;
        final json = {
          'username': originalState.username,
          'password': originalState.password,
          'localPassword': originalState.localPassword,
          'localPasswordHint': originalState.localPasswordHint,
          'sessionToken': jsonEncode(originalState.sessionToken!.toJson()),
          'loginType': originalState.loginType.name,
        };

        // Act
        final deserializedState = AuthState.fromJson(json);

        // Assert
        expect(deserializedState, equals(originalState));
      });

      test('copyWith creates new instance, not mutation', () {
        // Arrange
        final original = testAuthState;
        const newUsername = 'different@example.com';

        // Act
        final updated = original.copyWith(username: newUsername);

        // Assert
        expect(original.username, isNot(equals(newUsername)));
        expect(updated.username, equals(newUsername));
        expect(identical(original, updated), isFalse);
      });
    });
  });
}
