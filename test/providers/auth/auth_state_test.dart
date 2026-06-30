import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

void main() {
  group('AuthState', () {
    test('empty() creates state with LoginType.none and null fields', () {
      final state = AuthState.empty();
      expect(state.loginType, LoginType.none);
      expect(state.localPasswordHint, isNull);
    });

    test('copyWith replaces specified fields', () {
      final state = AuthState.empty();
      final updated = state.copyWith(
        localPasswordHint: 'hint',
        loginType: LoginType.local,
      );
      expect(updated.localPasswordHint, 'hint');
      expect(updated.loginType, LoginType.local);
    });

    test('copyWith preserves unspecified fields', () {
      final state = AuthState(
        localPasswordHint: 'hint',
        loginType: LoginType.local,
      );
      final updated = state.copyWith(loginType: LoginType.remote);
      expect(updated.localPasswordHint, 'hint');
      expect(updated.loginType, LoginType.remote);
    });

    test('fromJson parses valid JSON', () {
      final json = {
        'localPasswordHint': 'my hint',
        'loginType': 'local',
      };
      final state = AuthState.fromJson(json);
      expect(state.localPasswordHint, 'my hint');
      expect(state.loginType, LoginType.local);
    });

    test('fromJson defaults to LoginType.none for unknown type', () {
      final json = {'loginType': 'cloud'};
      final state = AuthState.fromJson(json);
      expect(state.loginType, LoginType.none);
    });

    test('fromJson defaults to LoginType.none for missing type', () {
      final state = AuthState.fromJson({});
      expect(state.loginType, LoginType.none);
    });

    test('equality: identical states are equal', () {
      final a = AuthState(localPasswordHint: 'x', loginType: LoginType.local);
      final b = AuthState(localPasswordHint: 'x', loginType: LoginType.local);
      expect(a, b);
    });

    test('equality: different states are not equal', () {
      final a = AuthState(localPasswordHint: 'x', loginType: LoginType.local);
      final b = AuthState(localPasswordHint: 'y', loginType: LoginType.local);
      expect(a, isNot(b));
    });
  });
}
