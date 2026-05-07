import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

void main() {
  group('AuthState', () {
    test('empty() creates state with LoginType.none and null fields', () {
      final state = AuthState.empty();
      expect(state.loginType, LoginType.none);
      expect(state.localPassword, isNull);
      expect(state.localPasswordHint, isNull);
    });

    test('copyWith replaces specified fields', () {
      final state = AuthState.empty();
      final updated = state.copyWith(
        localPassword: 'secret',
        loginType: LoginType.local,
      );
      expect(updated.localPassword, 'secret');
      expect(updated.loginType, LoginType.local);
      expect(updated.localPasswordHint, isNull);
    });

    test('copyWith preserves unspecified fields', () {
      final state = AuthState(
        localPassword: 'pass',
        localPasswordHint: 'hint',
        loginType: LoginType.local,
      );
      final updated = state.copyWith(localPassword: 'newpass');
      expect(updated.localPassword, 'newpass');
      expect(updated.localPasswordHint, 'hint');
      expect(updated.loginType, LoginType.local);
    });

    test('fromJson parses valid JSON', () {
      final json = {
        'localPassword': 'admin',
        'localPasswordHint': 'my hint',
        'loginType': 'local',
      };
      final state = AuthState.fromJson(json);
      expect(state.localPassword, 'admin');
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
      expect(state.localPassword, isNull);
    });

    test('equality: identical states are equal', () {
      final a = AuthState(localPassword: 'x', loginType: LoginType.local);
      final b = AuthState(localPassword: 'x', loginType: LoginType.local);
      expect(a, b);
    });

    test('equality: different states are not equal', () {
      final a = AuthState(localPassword: 'x', loginType: LoginType.local);
      final b = AuthState(localPassword: 'y', loginType: LoginType.local);
      expect(a, isNot(b));
    });
  });
}
