# AuthService Contract

**Branch:** `001-auth-service-extraction`
**Date:** 2025-12-10

## Overview

This document defines the public API contract for `AuthService`. The actual implementation in `lib/providers/auth/auth_service.dart` must match these signatures.

### Responsibilities

- **Session Token Management**: Validation, expiration checking, automatic refresh
- **Authentication Flows**: Cloud login, local login, RA login
- **Credential Persistence**: Save, update, delete credentials
- **Logout Operations**: Clear all authentication data

### Design Principles

- **Stateless**: No internal state, thread-safe
- **Dependency Injection**: All dependencies via constructor
- **Functional Error Handling**: Returns `AuthResult<T>` instead of throwing exceptions
- **Type Safety**: Uses sealed `AuthError` classes for type-safe error handling

---

## Session Token Management

### `getStoredSessionToken()`

Retrieves and validates the stored session token.

```dart
Future<AuthResult<SessionToken?>> getStoredSessionToken()
```

**Returns:**
- `AuthSuccess<SessionToken>` if valid token exists
- `AuthSuccess<null>` if no token stored
- `AuthFailure<StorageError>` if storage read fails

**Note:** Does NOT automatically refresh expired tokens. Use `getValidSessionToken()` for auto-refresh behavior.

---

### `getValidSessionToken()`

Retrieves a valid session token, refreshing if necessary.

```dart
Future<AuthResult<SessionToken?>> getValidSessionToken()
```

**Logic:**
1. Read stored token
2. Check expiration
3. If expired and refresh token exists, attempt refresh
4. If refresh succeeds, persist new token

**Returns:**
- `AuthSuccess<SessionToken>` with valid token
- `AuthSuccess<null>` if no token and no refresh possible
- `AuthFailure<TokenRefreshError>` if refresh fails
- `AuthFailure<StorageError>` if storage operations fail

---

### `isTokenExpired()`

Checks if the given session token is expired.

```dart
bool isTokenExpired(SessionToken token, int storedTimestamp)
```

**Parameters:**
- `token`: The session token to check
- `storedTimestamp`: Epoch milliseconds when token was stored

**Returns:** `true` if current time exceeds `(storedTimestamp + expiresIn * 1000)`

---

### `refreshSessionToken()`

Refreshes an expired session token using the refresh token.

```dart
Future<AuthResult<SessionToken>> refreshSessionToken(String refreshToken)
```

**Parameters:**
- `refreshToken`: The refresh token from expired session

**Returns:**
- `AuthSuccess<SessionToken>` with new token (also persisted to storage)
- `AuthFailure<TokenRefreshError>` if refresh API fails
- `AuthFailure<StorageError>` if persistence fails

---

## Authentication Flows

### `cloudLogin()`

Performs cloud login with username and password.

```dart
Future<AuthResult<LoginInfo>> cloudLogin({
  required String username,
  required String password,
  SessionToken? sessionToken,
})
```

**Parameters:**
- `username`: Cloud account username
- `password`: Cloud account password
- `sessionToken`: Optional pre-obtained token (skips API call if provided)

**Returns:**
- `AuthSuccess<LoginInfo>` with new credentials
- `AuthFailure<InvalidCredentialsError>` if login fails
- `AuthFailure<CloudApiError>` if API returns error
- `AuthFailure<StorageError>` if credential persistence fails

---

### `localLogin()`

Performs local router login with admin password.

```dart
Future<AuthResult<LoginInfo>> localLogin(
  String password, {
  bool pnp = false,
})
```

**Parameters:**
- `password`: Router admin password
- `pnp`: If true, uses PnP-specific JNAP action

**Returns:**
- `AuthSuccess<LoginInfo>` with local credentials
- `AuthFailure<InvalidCredentialsError>` if password incorrect
- `AuthFailure<JnapError>` if JNAP call fails
- `AuthFailure<StorageError>` if credential persistence fails

---

### `raLogin()`

Performs Remote Assistance (RA) login.

```dart
Future<AuthResult<LoginInfo>> raLogin(
  String sessionToken,
  String networkId,
  String serialNumber,
)
```

**Parameters:**
- `sessionToken`: RA session token
- `networkId`: Target network ID
- `serialNumber`: Target device serial number

**Returns:**
- `AuthSuccess<LoginInfo>` for RA session
- `AuthFailure<StorageError>` if persistence fails

---

## Credential Management

### `updateCloudCredentials()`

Updates cloud credentials in secure storage.

```dart
Future<AuthResult<void>> updateCloudCredentials({
  SessionToken? sessionToken,
  String? username,
  String? password,
})
```

**Parameters:**
- `sessionToken`: New session token (optional)
- `username`: Cloud username (optional)
- `password`: Cloud password (optional)

**Returns:**
- `AuthSuccess<void>` on successful update
- `AuthFailure<StorageError>` if write fails

---

### `getStoredCredentials()`

Retrieves stored credentials from secure storage and SharedPreferences.

```dart
Future<AuthResult<StoredCredentials>> getStoredCredentials()
```

**Returns:**
- `AuthSuccess<StoredCredentials>` with all credential data
- `AuthFailure<StorageError>` if read fails

**StoredCredentials Structure:**
```dart
class StoredCredentials {
  final SessionToken? sessionToken;
  final String? sessionTokenTs;
  final String? localPassword;
  final String? username;
  final String? password;
  final String? currentSN;
  final String? selectedNetworkId;
  final bool raMode;
}
```

---

## Logout Operations

### `clearAllCredentials()`

Clears all authentication data from storage.

```dart
Future<AuthResult<void>> clearAllCredentials()
```

**Removes:**
- Session token and timestamp (FlutterSecureStorage)
- Local password (FlutterSecureStorage)
- Cloud username and password (FlutterSecureStorage)
- Network preferences: selectedNetworkId, currentSN (SharedPreferences)
- RA mode flag (SharedPreferences)
- Device token, GRA session ID (SharedPreferences)

**Returns:**
- `AuthSuccess<void>` on successful clear
- `AuthFailure<StorageError>` if any deletion fails

**Note:** Does NOT call `raLogout()` or reset providers - that remains in `AuthNotifier` to handle provider interactions.

---

## Utility Methods

### `getPasswordHint()`

Retrieves password hint from router via JNAP.

```dart
Future<AuthResult<String>> getPasswordHint()
```

**Returns:**
- `AuthSuccess<String>` with password hint (may be empty)
- `AuthFailure<JnapError>` if JNAP call fails

---

### `getAdminPasswordAuthStatus()`

Retrieves admin password auth status from router.

```dart
Future<AuthResult<Map<String, dynamic>?>> getAdminPasswordAuthStatus(
  List<String> services,
)
```

**Parameters:**
- `services`: List of supported service strings

**Returns:**
- `AuthSuccess<Map>` with status if supported, `null` otherwise
- `AuthFailure<JnapError>` if JNAP call fails

---

## Provider Definition

The `AuthService` singleton is provided via Riverpod:

```dart
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(routerRepositoryProvider),
    ref.watch(cloudRepositoryProvider),
    const FlutterSecureStorage(),
  );
});
```

**Usage Example:**

```dart
// In a Riverpod consumer
final authService = ref.read(authServiceProvider);
final result = await authService.cloudLogin(
  username: 'user@example.com',
  password: 'password',
);

result.when(
  success: (loginInfo) => handleSuccess(loginInfo),
  failure: (error) => handleError(error),
);
```

---

## Implementation Status

✅ **Implemented in:** `lib/providers/auth/auth_service.dart`
✅ **Test Coverage:** 100% (35 tests in `test/providers/auth/auth_service_test.dart`)
✅ **Documentation:** Complete with dartdoc comments
✅ **Error Handling:** Full `AuthResult<T>` pattern with sealed `AuthError` classes

---

## Related Files

- **Implementation:** [`lib/providers/auth/auth_service.dart`](../../../lib/providers/auth/auth_service.dart)
- **Tests:** [`test/providers/auth/auth_service_test.dart`](../../../test/providers/auth/auth_service_test.dart)
- **Error Types:** [`lib/providers/auth/auth_error.dart`](../../../lib/providers/auth/auth_error.dart)
- **Result Type:** [`lib/providers/auth/auth_result.dart`](../../../lib/providers/auth/auth_result.dart)
- **State Notifier:** [`lib/providers/auth/auth_provider.dart`](../../../lib/providers/auth/auth_provider.dart)
