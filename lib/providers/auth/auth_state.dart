import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

/// Represents the authentication state of the application.
///
/// This immutable class holds all authentication-related data including
/// cloud credentials (username, password, session token) and local
/// router credentials (local password).
///
/// Use [AuthState.empty] to create an initial unauthenticated state.
/// Use [copyWith] to create modified copies with updated values.
class AuthState extends Equatable {
  /// Cloud account username (email).
  final String? username;

  /// Cloud account password.
  final String? password;

  /// Local router admin password.
  final String? localPassword;

  /// Password hint for the local router admin password.
  final String? localPasswordHint;

  /// Cloud session token for authenticated API calls.
  final SessionToken? sessionToken;

  /// Current login type indicating authentication method.
  final LoginType loginType;

  const AuthState({
    this.username,
    this.password,
    this.localPassword,
    this.localPasswordHint,
    this.sessionToken,
    required this.loginType,
  });

  /// Creates an empty authentication state with [LoginType.none].
  ///
  /// Use this factory to initialize the auth state before any
  /// authentication has occurred.
  factory AuthState.empty() {
    return const AuthState(loginType: LoginType.none);
  }

  /// Creates an [AuthState] from a JSON map.
  ///
  /// The [json] map should contain the following keys:
  /// - `username`: String? - Cloud account username
  /// - `password`: String? - Cloud account password
  /// - `localPassword`: String? - Local router admin password
  /// - `localPasswordHint`: String? - Password hint
  /// - `sessionToken`: String? - JSON-encoded SessionToken
  /// - `loginType`: String? - Login type name (matches [LoginType] enum)
  factory AuthState.fromJson(Map<String, dynamic> json) {
    final sessionToken = json['sessionToken'] == null
        ? null
        : SessionToken.fromJson(jsonDecode(json['sessionToken']));
    final loginType =
        LoginType.values.firstWhereOrNull((e) => e.name == json['loginType']) ??
            LoginType.none;
    return AuthState(
      username: json['username'],
      password: json['password'],
      localPassword: json['localPassword'],
      localPasswordHint: json['localPasswordHint'],
      sessionToken: sessionToken,
      loginType: loginType,
    );
  }

  /// Creates a copy of this [AuthState] with the given fields replaced.
  ///
  /// Any parameter that is not provided will retain its current value.
  AuthState copyWith({
    String? username,
    String? password,
    String? localPassword,
    String? localPasswordHint,
    SessionToken? sessionToken,
    LoginType? loginType,
  }) {
    return AuthState(
      username: username ?? this.username,
      password: password ?? this.password,
      localPassword: localPassword ?? this.localPassword,
      localPasswordHint: localPasswordHint ?? this.localPasswordHint,
      sessionToken: sessionToken ?? this.sessionToken,
      loginType: loginType ?? this.loginType,
    );
  }

  @override
  List<Object?> get props => [
        username,
        password,
        localPassword,
        localPasswordHint,
        sessionToken,
        loginType,
      ];
}
