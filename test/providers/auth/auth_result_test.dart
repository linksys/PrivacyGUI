import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/providers/auth/auth_result.dart';

void main() {
  group('AuthSuccess', () {
    test('isSuccess is true', () {
      final result = AuthSuccess(42);
      expect(result.isSuccess, isTrue);
    });

    test('isFailure is false', () {
      final result = AuthSuccess('hello');
      expect(result.isFailure, isFalse);
    });

    test('when dispatches to success callback', () {
      final result = AuthSuccess(10);
      final value = result.when(
        success: (v) => v * 2,
        failure: (e) => -1,
      );
      expect(value, 20);
    });

    test('map transforms the value', () {
      final result = AuthSuccess(5);
      final mapped = result.map((v) => 'value=$v');
      expect(mapped, isA<AuthSuccess<String>>());
      expect((mapped as AuthSuccess<String>).value, 'value=5');
    });

    test('equality: same value', () {
      expect(AuthSuccess(42), AuthSuccess(42));
    });

    test('equality: different values', () {
      expect(AuthSuccess(1), isNot(AuthSuccess(2)));
    });

    test('hashCode matches value hashCode', () {
      expect(AuthSuccess('abc').hashCode, 'abc'.hashCode);
    });

    test('toString includes value', () {
      expect(AuthSuccess(99).toString(), 'AuthSuccess(99)');
    });
  });

  group('AuthFailure', () {
    final error = StorageError(originalError: 'oops');

    test('isSuccess is false', () {
      final result = AuthFailure<int>(error);
      expect(result.isSuccess, isFalse);
    });

    test('isFailure is true', () {
      final result = AuthFailure<int>(error);
      expect(result.isFailure, isTrue);
    });

    test('when dispatches to failure callback', () {
      final result = AuthFailure<int>(error);
      final value = result.when(
        success: (v) => 'ok',
        failure: (e) => 'error: ${e.runtimeType}',
      );
      expect(value, 'error: StorageError');
    });

    test('map preserves failure without calling transform', () {
      final result = AuthFailure<int>(error);
      var called = false;
      final mapped = result.map<String>((v) {
        called = true;
        return '$v';
      });
      expect(called, isFalse);
      expect(mapped, isA<AuthFailure<String>>());
      expect((mapped as AuthFailure<String>).error, error);
    });

    test('equality: same error', () {
      final e = StorageError(originalError: 'x');
      expect(AuthFailure<int>(e), AuthFailure<int>(e));
    });

    test('toString includes error', () {
      expect(AuthFailure<int>(error).toString(), contains('AuthFailure'));
    });
  });

  group('AuthResult type narrowing', () {
    test('success result is AuthSuccess', () {
      final AuthResult<int> result = AuthSuccess(1);
      expect(result, isA<AuthSuccess<int>>());
    });

    test('failure result is AuthFailure', () {
      final AuthResult<int> result =
          AuthFailure(StorageError(originalError: 'e'));
      expect(result, isA<AuthFailure<int>>());
    });
  });
}
