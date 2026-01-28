# Research: Auth Service Layer Extraction

**Branch**: `001-auth-service-extraction` | **Date**: 2025-12-10

## Research Summary

This document consolidates research findings for extracting authentication business logic into a dedicated AuthService.

---

## 1. Current AuthNotifier Implementation Analysis

### Decision: Extract business logic methods to AuthService

### Rationale
The current `AuthNotifier` (lib/providers/auth/auth_provider.dart:104-458) mixes state management with business logic, violating Article VI of the constitution. The following methods contain business logic that should be extracted:

**Business Logic Methods (to extract):**
- `checkSessionToken()` - Token validation and expiration checking (lines 180-202)
- `handleSessionTokenError()` - Error handling and refresh orchestration (lines 204-214)
- `refreshToken()` - Token refresh via CloudRepository (lines 216-223)
- `updateCloudCredentials()` - Credential persistence to FlutterSecureStorage (lines 272-306)
- `localLogin()` - JNAP authentication and storage (lines 312-352)
- `cloudLogin()` - Cloud authentication flow (lines 252-270)
- `logout()` - Credential cleanup (lines 388-423)
- `raLogin()` - Remote assistance login flow (lines 438-457)

**State Management Methods (to keep in AuthNotifier):**
- `build()` - Riverpod lifecycle (line 137)
- `init()` - State initialization (lines 139-178)
- `isCloudLogin()` - State query (line 425)

### Alternatives Considered
1. **Keep mixed approach**: Rejected - violates constitution Article VI
2. **Create multiple services**: Rejected - over-engineering, auth is cohesive domain

---

## 2. Result Type Implementation

### Decision: Create custom `Result<T, AuthError>` using sealed classes

### Rationale
The spec clarified using Result types for error handling. Dart 3 sealed classes provide exhaustive pattern matching. The codebase doesn't have an existing Result type, so we create one specific to auth.

### Implementation Pattern
```dart
sealed class AuthResult<T> {
  const AuthResult();
}

final class AuthSuccess<T> extends AuthResult<T> {
  final T value;
  const AuthSuccess(this.value);
}

final class AuthFailure<T> extends AuthResult<T> {
  final AuthError error;
  const AuthFailure(this.error);
}
```

### Alternatives Considered
1. **Use dartz package Either**: Rejected - adds external dependency
2. **Use fpdart package**: Rejected - adds external dependency
3. **Throw exceptions**: Rejected - spec clarified Result types preferred

---

## 3. AuthError Type Hierarchy

### Decision: Create sealed `AuthError` class with specific error types

### Rationale
Existing `AuthException` classes (auth_exception.dart) use exception pattern. For Result types, we need error values. Create parallel `AuthError` sealed class for Result returns while keeping exceptions for unexpected failures.

### Implementation Pattern
```dart
sealed class AuthError {
  final String message;
  const AuthError(this.message);
}

final class NoSessionTokenError extends AuthError {
  const NoSessionTokenError() : super('No session token found');
}

final class SessionTokenExpiredError extends AuthError {
  const SessionTokenExpiredError() : super('Session token expired');
}

final class InvalidCredentialsError extends AuthError {
  const InvalidCredentialsError() : super('Invalid credentials');
}

final class StorageError extends AuthError {
  final Object? cause;
  const StorageError(this.cause) : super('Storage operation failed');
}

final class NetworkError extends AuthError {
  final Object? cause;
  const NetworkError(this.cause) : super('Network operation failed');
}
```

### Alternatives Considered
1. **Reuse AuthException**: Rejected - mixing error values with exceptions
2. **String error codes**: Rejected - not type-safe, no exhaustive matching

---

## 4. Service Provider Pattern

### Decision: Use simple `Provider<AuthService>` (not Provider.family or autoDispose)

### Rationale
Following the pattern in `health_check_service.dart:19-21`:
```dart
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(routerRepositoryProvider),
    ref.watch(cloudRepositoryProvider),
    const FlutterSecureStorage(),
  );
});
```

Single instance is appropriate because:
- Service is stateless (FR-004)
- Dependencies are stable across app lifecycle
- Spec clarification confirmed singleton via Provider

### Alternatives Considered
1. **Provider.autoDispose**: Rejected - no benefit for stateless service
2. **Provider.family**: Rejected - no parameterization needed
3. **Manual instantiation**: Rejected - loses DI benefits

---

## 5. Dependency Injection Strategy

### Decision: Constructor injection for all dependencies

### Rationale
Following constitution Article VI.2 and existing service patterns:
- RouterRepository - for JNAP communication
- CloudRepository - for cloud API communication
- FlutterSecureStorage - for credential storage
- SharedPreferences - for non-sensitive preferences (obtained via getInstance())

### Implementation Pattern
```dart
class AuthService {
  final RouterRepository _routerRepository;
  final LinksysCloudRepository _cloudRepository;
  final FlutterSecureStorage _secureStorage;

  AuthService(
    this._routerRepository,
    this._cloudRepository,
    this._secureStorage,
  );
}
```

Note: SharedPreferences requires async initialization, so it's obtained via `SharedPreferences.getInstance()` within methods, matching existing pattern in auth_provider.dart.

### Alternatives Considered
1. **Service locator**: Rejected - violates DI principle
2. **Inject SharedPreferences**: Rejected - requires async provider setup

---

## 6. Storage Key Constants

### Decision: Reuse existing constants from pref_key.dart

### Rationale
Storage keys are already defined in `lib/constants/pref_key.dart`:
- `pSessionToken` - Cloud session token JSON
- `pSessionTokenTs` - Token timestamp
- `pLocalPassword` - Local admin password
- `pUsername` - Cloud username
- `pUserPassword` - Cloud password
- `pLinksysToken` / `pLinksysTokenTs` - Linksys token data
- `pSelectedNetworkId`, `pCurrentSN`, `pDeviceToken`, `pGRASessionId` - Other prefs

No new constants needed.

### Alternatives Considered
1. **Create service-specific constants**: Rejected - would duplicate existing

---

## 7. Corrupted Data Handling

### Decision: Clear corrupted data and return null/error (clean slate recovery)

### Rationale
Per spec clarification, corrupted data in secure storage should be treated as missing. Implementation:
1. Wrap JSON parsing in try-catch
2. On parse failure, delete the corrupted key(s)
3. Return appropriate error Result

### Implementation Pattern
```dart
Future<AuthResult<SessionToken?>> getStoredSessionToken() async {
  try {
    final json = await _secureStorage.read(key: pSessionToken);
    if (json == null) return const AuthSuccess(null);

    final decoded = jsonDecode(json);
    return AuthSuccess(SessionToken.fromJson(decoded));
  } on FormatException {
    // Corrupted JSON - clear and return null
    await _secureStorage.delete(key: pSessionToken);
    await _secureStorage.delete(key: pSessionTokenTs);
    return const AuthSuccess(null);
  } catch (e) {
    return AuthFailure(StorageError(e));
  }
}
```

### Alternatives Considered
1. **Return error on corruption**: Rejected - spec says treat as missing
2. **Attempt partial recovery**: Rejected - spec says clean slate

---

## 8. Testing Approach

### Decision: Use Mocktail for all mocks, test service in isolation

### Rationale
Constitution Article I mandates Mocktail. Service tests will:
1. Mock RouterRepository, CloudRepository, FlutterSecureStorage
2. Test each public method with success/error scenarios
3. Verify Result types returned correctly
4. Achieve 100% coverage of AuthService

### Test File Organization
```text
test/providers/auth/
├── auth_service_test.dart         # Main service tests
└── mocks/
    └── auth_service_mocks.dart    # Shared mock definitions
```

### Alternatives Considered
1. **Integration tests only**: Rejected - violates test pyramid
2. **Mockito**: Rejected - constitution specifies Mocktail

---

## 9. Backward Compatibility Strategy

### Decision: AuthNotifier maintains exact same public API

### Rationale
FR-012 requires full backward compatibility. Strategy:
1. Keep all existing public method signatures in AuthNotifier
2. Methods delegate to AuthService internally
3. AuthService Results are converted to AsyncValue states
4. Error handling preserves existing behavior

### AuthNotifier Refactor Pattern
```dart
Future cloudLogin({
  required String username,
  required String password,
  SessionToken? sessionToken,
}) async {
  state = const AsyncValue.loading();
  final result = await _authService.cloudLogin(
    username: username,
    password: password,
    existingToken: sessionToken,
  );
  state = result.when(
    success: (authState) => AsyncValue.data(authState),
    failure: (error) => AsyncValue.error(error, StackTrace.current),
  );
}
```

### Alternatives Considered
1. **Change public API**: Rejected - violates backward compatibility requirement
2. **Deprecation period**: Rejected - out of scope, not changing behavior

---

## 10. HTTP Error Handler Integration

### Decision: Keep HTTP error callback in AuthNotifier, delegate to service for token check

### Rationale
The current `LinksysHttpClient.onError` callback (auth_provider.dart:108-133) requires access to `logout()` which triggers state changes. Strategy:
1. Keep callback registration in AuthNotifier constructor
2. Callback calls AuthService for token validation
3. AuthNotifier handles logout decision based on service result

This preserves existing error handling flow while moving token validation logic to service.

### Alternatives Considered
1. **Move callback to service**: Rejected - service shouldn't trigger state changes
2. **Remove callback**: Rejected - breaks existing error recovery
