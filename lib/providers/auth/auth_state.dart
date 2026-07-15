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

  /// The single source of truth for login state: `none` / `local` / `remote`.
  ///
  /// The [isLoggedIn] and [isRemoteAssistance] getters are just named shortcuts
  /// derived from this value for the two most common yes/no questions — they are
  /// not a separate mechanism. Read [loginType] directly only when the full
  /// three-state value is needed (e.g. detecting a transition between kinds, or
  /// branching specifically on `local`); prefer the getters otherwise.
  final LoginType loginType;

  const AuthState({
    this.localPasswordHint,
    required this.loginType,
  });

  /// Creates an empty authentication state with [LoginType.none].
  factory AuthState.empty() {
    return const AuthState(loginType: LoginType.none);
  }

  /// Whether the user is logged in (local OR Remote Assistance).
  ///
  /// Shortcut for `loginType != LoginType.none`. This is login *intent* —
  /// distinct from the transport-layer [UspClient.isAuthenticated] (a WASM flag
  /// that stays false in RA mode). Canonical replacement for scattered inline
  /// `loginType != LoginType.none` checks; use [isRemoteAssistance] when the
  /// login *kind* matters.
  bool get isLoggedIn => loginType != LoginType.none;

  /// Whether this is a Remote Assistance session.
  ///
  /// Shortcut for `loginType == LoginType.remote`. In RA mode the WASM client
  /// is pre-authorized via authToken, so [UspClient.isAuthenticated] stays false
  /// by design — RA must be detected from login intent (this getter), not from
  /// the client's login state. Canonical replacement for scattered inline
  /// `loginType == LoginType.remote` checks.
  bool get isRemoteAssistance => loginType == LoginType.remote;

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
