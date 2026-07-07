import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

/// Represents the authentication state of the application.
///
/// This immutable class holds local router authentication data.
/// Password is never stored — only session tokens are persisted
/// via sessionStorage for page reload recovery.
///
/// Use [AuthState.empty] to create an initial unauthenticated state.
/// Use [copyWith] to create modified copies with updated values.
class AuthState extends Equatable {
  /// Password hint for the local router admin password.
  final String? localPasswordHint;

  /// Current login type indicating authentication method.
  final LoginType loginType;

  const AuthState({
    this.localPasswordHint,
    required this.loginType,
  });

  /// Creates an empty authentication state with [LoginType.none].
  factory AuthState.empty() {
    return const AuthState(loginType: LoginType.none);
  }

  /// Creates an [AuthState] from a JSON map.
  factory AuthState.fromJson(Map<String, dynamic> json) {
    final loginType =
        LoginType.values.firstWhereOrNull((e) => e.name == json['loginType']) ??
            LoginType.none;
    return AuthState(
      localPasswordHint: json['localPasswordHint'],
      loginType: loginType,
    );
  }

  /// Creates a copy of this [AuthState] with the given fields replaced.
  AuthState copyWith({
    String? localPasswordHint,
    LoginType? loginType,
  }) {
    return AuthState(
      localPasswordHint: localPasswordHint ?? this.localPasswordHint,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  List<Object?> get props => [
        localPasswordHint,
        loginType,
      ];
}
