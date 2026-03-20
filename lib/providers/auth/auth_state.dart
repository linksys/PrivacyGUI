import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

/// Represents the authentication state of the application.
///
/// This immutable class holds local router authentication data.
///
/// Use [AuthState.empty] to create an initial unauthenticated state.
/// Use [copyWith] to create modified copies with updated values.
class AuthState extends Equatable {
  /// Local router admin password.
  final String? localPassword;

  /// Password hint for the local router admin password.
  final String? localPasswordHint;

  /// Current login type indicating authentication method.
  final LoginType loginType;

  const AuthState({
    this.localPassword,
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
      localPassword: json['localPassword'],
      localPasswordHint: json['localPasswordHint'],
      loginType: loginType,
    );
  }

  /// Creates a copy of this [AuthState] with the given fields replaced.
  AuthState copyWith({
    String? localPassword,
    String? localPasswordHint,
    LoginType? loginType,
  }) {
    return AuthState(
      localPassword: localPassword ?? this.localPassword,
      localPasswordHint: localPasswordHint ?? this.localPasswordHint,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  List<Object?> get props => [
        localPassword,
        localPasswordHint,
        loginType,
      ];
}
