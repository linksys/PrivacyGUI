# Data Model: Auth Service Layer Extraction

**Branch**: `001-auth-service-extraction` | **Date**: 2025-12-10

## Overview

This document defines the data models for the AuthService extraction. Most models already exist; new models are created for Result-based error handling.

---

## Existing Entities (No Changes)

### AuthState
**Location**: `lib/providers/auth/auth_provider.dart:34-99`
**Purpose**: Immutable state object for UI consumption

```dart
class AuthState extends Equatable {
  final String? username;
  final String? password;
  final String? localPassword;
  final String? localPasswordHint;
  final SessionToken? sessionToken;
  final LoginType loginType;
}
```

**Relationships**: Contains `SessionToken`, uses `LoginType` enum
**No changes required** - AuthNotifier continues to manage this state.

---

### SessionToken
**Location**: `lib/core/cloud/model/cloud_session_model.dart`
**Purpose**: Represents cloud authentication token

```dart
class SessionToken {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
}
```

**Validation Rules**:
- `accessToken` must not be empty
- `expiresIn` is seconds from token creation
- `refreshToken` is optional (not all tokens support refresh)

**No changes required** - Existing model is sufficient.

---

### LoginType
**Location**: `lib/providers/auth/auth_provider.dart:32`
**Purpose**: Enumeration of authentication modes

```dart
enum LoginType { none, local, remote }
```

**State Transitions**:
- `none` → `local` (via local login)
- `none` → `remote` (via cloud login)
- `local` → `none` (via logout)
- `remote` → `none` (via logout)

**No changes required**.

---

## New Entities

### AuthResult<T> (Sealed Class)
**Location**: `lib/providers/auth/auth_result.dart` (NEW)
**Purpose**: Functional error handling for AuthService methods

```dart
/// Result type for AuthService operations.
/// Use pattern matching for exhaustive handling.
sealed class AuthResult<T> {
  const AuthResult();

  /// Execute callback based on result type
  R when<R>({
    required R Function(T value) success,
    required R Function(AuthError error) failure,
  });

  /// Map success value, pass through failure
  AuthResult<R> map<R>(R Function(T value) transform);

  /// True if this is a successful result
  bool get isSuccess;

  /// True if this is a failure result
  bool get isFailure;
}

final class AuthSuccess<T> extends AuthResult<T> {
  final T value;
  const AuthSuccess(this.value);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AuthError error) failure,
  }) => success(value);

  @override
  AuthResult<R> map<R>(R Function(T value) transform) =>
      AuthSuccess(transform(value));

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;
}

final class AuthFailure<T> extends AuthResult<T> {
  final AuthError error;
  const AuthFailure(this.error);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AuthError error) failure,
  }) => failure(error);

  @override
  AuthResult<R> map<R>(R Function(T value) transform) => AuthFailure(error);

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;
}
```

---

### AuthError (Sealed Class)
**Location**: `lib/providers/auth/auth_error.dart` (NEW)
**Purpose**: Type-safe error values for Result returns

```dart
/// Base sealed class for authentication errors.
/// Enables exhaustive pattern matching.
sealed class AuthError {
  final String message;
  const AuthError(this.message);
}

/// No session token found in storage
final class NoSessionTokenError extends AuthError {
  const NoSessionTokenError() : super('No session token found');
}

/// Session token has expired and cannot be refreshed
final class SessionTokenExpiredError extends AuthError {
  const SessionTokenExpiredError() : super('Session token expired');
}

/// Token refresh failed
final class TokenRefreshError extends AuthError {
  final Object? cause;
  const TokenRefreshError([this.cause]) : super('Token refresh failed');
}

/// Invalid credentials provided (wrong password, etc.)
final class InvalidCredentialsError extends AuthError {
  final String? details;
  const InvalidCredentialsError([this.details])
      : super('Invalid credentials');
}

/// JNAP API returned an error
final class JnapError extends AuthError {
  final String resultCode;
  final Object? cause;
  const JnapError(this.resultCode, [this.cause])
      : super('JNAP error: $resultCode');
}

/// Cloud API returned an error
final class CloudApiError extends AuthError {
  final String? code;
  final Object? cause;
  const CloudApiError(this.code, [this.cause])
      : super('Cloud API error: $code');
}

/// Storage operation failed (read/write/delete)
final class StorageError extends AuthError {
  final Object? cause;
  const StorageError([this.cause]) : super('Storage operation failed');
}

/// Network request failed
final class NetworkError extends AuthError {
  final Object? cause;
  const NetworkError([this.cause]) : super('Network error');
}
```

---

### AuthCredentials (Value Object)
**Location**: `lib/providers/auth/auth_service.dart` (inline, private)
**Purpose**: Internal data transfer for credential operations

```dart
/// Internal value object for credential data.
/// Not exposed outside AuthService.
class _AuthCredentials {
  final String? username;
  final String? password;
  final String? localPassword;
  final SessionToken? sessionToken;

  const _AuthCredentials({
    this.username,
    this.password,
    this.localPassword,
    this.sessionToken,
  });
}
```

---

## Entity Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                      AuthNotifier                           │
│  (State Management - Riverpod AsyncNotifier)                │
├─────────────────────────────────────────────────────────────┤
│  state: AsyncValue<AuthState>                               │
│                                                             │
│  Delegates to:                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  AuthService                         │   │
│  │  (Business Logic - Stateless)                        │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Returns: AuthResult<T>                              │   │
│  │    ├── AuthSuccess<T>                                │   │
│  │    └── AuthFailure<AuthError>                        │   │
│  │          ├── NoSessionTokenError                     │   │
│  │          ├── SessionTokenExpiredError                │   │
│  │          ├── TokenRefreshError                       │   │
│  │          ├── InvalidCredentialsError                 │   │
│  │          ├── JnapError                               │   │
│  │          ├── CloudApiError                           │   │
│  │          ├── StorageError                            │   │
│  │          └── NetworkError                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                       AuthState                             │
│  (Immutable UI State)                                       │
├─────────────────────────────────────────────────────────────┤
│  username: String?                                          │
│  password: String?                                          │
│  localPassword: String?                                     │
│  localPasswordHint: String?                                 │
│  sessionToken: SessionToken? ──────────┐                    │
│  loginType: LoginType                  │                    │
└────────────────────────────────────────│────────────────────┘
                                         │
                                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     SessionToken                            │
├─────────────────────────────────────────────────────────────┤
│  accessToken: String                                        │
│  tokenType: String                                          │
│  expiresIn: int                                             │
│  refreshToken: String?                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Storage Schema

### FlutterSecureStorage Keys

| Key | Type | Description |
|-----|------|-------------|
| `pSessionToken` | JSON String | Serialized SessionToken |
| `pSessionTokenTs` | String (epoch ms) | Token creation timestamp |
| `pLocalPassword` | String | Local admin password |
| `pUsername` | String | Cloud username |
| `pUserPassword` | String | Cloud password |
| `pLinksysToken` | String | Linksys API token |
| `pLinksysTokenTs` | String (epoch ms) | Linksys token timestamp |

### SharedPreferences Keys

| Key | Type | Description |
|-----|------|-------------|
| `pSelectedNetworkId` | String | Currently selected network |
| `pCurrentSN` | String | Current device serial number |
| `pDeviceToken` | String | Push notification device token |
| `pGRASessionId` | String | Guardian RA session ID |
| `pRAMode` | bool | Remote assistance mode flag |
