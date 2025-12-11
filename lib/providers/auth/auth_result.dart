import 'package:privacy_gui/providers/auth/auth_error.dart';

/// Result type for AuthService operations.
///
/// Provides functional error handling with exhaustive pattern matching.
/// Use [when] for result handling or [map] for value transformations.
///
/// Example:
/// ```dart
/// final result = await authService.validateSessionToken();
/// result.when(
///   success: (token) => print('Valid token: $token'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```
sealed class AuthResult<T> {
  const AuthResult();

  /// Execute callback based on result type (exhaustive pattern matching).
  R when<R>({
    required R Function(T value) success,
    required R Function(AuthError error) failure,
  });

  /// Map success value, pass through failure.
  AuthResult<R> map<R>(R Function(T value) transform);

  /// True if this is a successful result.
  bool get isSuccess;

  /// True if this is a failure result.
  bool get isFailure;
}

/// Successful result containing a value.
final class AuthSuccess<T> extends AuthResult<T> {
  /// The success value.
  final T value;

  const AuthSuccess(this.value);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AuthError error) failure,
  }) =>
      success(value);

  @override
  AuthResult<R> map<R>(R Function(T value) transform) =>
      AuthSuccess(transform(value));

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSuccess<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AuthSuccess($value)';
}

/// Failed result containing an error.
final class AuthFailure<T> extends AuthResult<T> {
  /// The error that occurred.
  final AuthError error;

  const AuthFailure(this.error);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AuthError error) failure,
  }) =>
      failure(error);

  @override
  AuthResult<R> map<R>(R Function(T value) transform) => AuthFailure(error);

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'AuthFailure($error)';
}
