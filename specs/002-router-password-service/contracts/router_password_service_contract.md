# Router Password Service Contract

**Version**: 1.0
**Date**: 2025-12-15
**Status**: Draft

## Overview

This document defines the API contract for `RouterPasswordService`, a stateless service responsible for encapsulating all router password-related JNAP communication and password persistence operations.

---

## Class: RouterPasswordService

### Purpose

Stateless service that separates router password business logic from state management. Handles JNAP protocol communication for password operations and FlutterSecureStorage access for password persistence.

### Location

`lib/page/instant_admin/services/router_password_service.dart`

### Dependencies

| Dependency | Type | Injection Method | Purpose |
|------------|------|------------------|---------|
| RouterRepository | Constructor | `ref.watch(routerRepositoryProvider)` | JNAP communication |
| FlutterSecureStorage | Constructor | `const FlutterSecureStorage()` | Password persistence |

### Constructor

```dart
RouterPasswordService(
  this._routerRepository,
  this._secureStorage,
);

final RouterRepository _routerRepository;
final FlutterSecureStorage _secureStorage;
```

**Parameters**:
- `_routerRepository`: RouterRepository instance for JNAP operations
- `_secureStorage`: FlutterSecureStorage instance for secure password storage

---

## Methods

### 1. fetchPasswordConfiguration()

**Purpose**: Retrieves current router password configuration from JNAP and secure storage.

**Signature**:
```dart
Future<Map<String, dynamic>> fetchPasswordConfiguration()
```

**Returns**:
```dart
{
  'isDefault': bool,           // True if password is still factory default
  'isSetByUser': bool,         // True if password was set by user (vs system)
  'hint': String,              // Password hint text (empty if not set)
  'storedPassword': String,    // Password from FlutterSecureStorage (empty if not found)
}
```

**JNAP Operations**:
1. Calls `_routerRepository.fetchIsConfigured()` for:
   - `JNAPAction.isAdminPasswordDefault`
   - `JNAPAction.isAdminPasswordSetByUser`
2. Conditionally calls `_routerRepository.send(JNAPAction.getAdminPasswordHint)` if `isSetByUser == true`
3. Reads password from `_secureStorage.read(key: pLocalPassword)`

**Throws**:
- `JNAPError`: JNAP communication failure or invalid response
- `Exception`: FlutterSecureStorage read failure (wrap as StorageError if custom exception exists)

**Example Usage**:
```dart
try {
  final config = await service.fetchPasswordConfiguration();
  print('Is default: ${config['isDefault']}');
  print('Hint: ${config['hint']}');
} on JNAPError catch (e) {
  print('JNAP error: ${e.result}');
} catch (e) {
  print('Storage error: $e');
}
```

---

### 2. setPasswordWithResetCode()

**Purpose**: Sets admin password using setup reset code (factory reset / first-time setup flow).

**Signature**:
```dart
Future<void> setPasswordWithResetCode(
  String password,
  String hint,
  String code,
)
```

**Parameters**:
- `password`: New admin password to set
- `hint`: Password hint for user reference
- `code`: Setup/factory reset code for authentication

**JNAP Operations**:
- Calls `_routerRepository.send()` with:
  - Action: `JNAPAction.setupSetAdminPassword`
  - Data: `{'adminPassword': password, 'passwordHint': hint, 'resetCode': code}`
  - Type: `CommandType.local`

**Returns**: `void` (success implied)

**Throws**:
- `JNAPError`: JNAP communication failure, invalid code, or authentication failure

**Side Effects**:
- Router admin password is updated
- Password hint is stored in router configuration

**Example Usage**:
```dart
try {
  await service.setPasswordWithResetCode('newPass123', 'My dog name', '12345678');
  // Success - password updated
} on JNAPError catch (e) {
  if (e.result == 'ErrorInvalidResetCode') {
    print('Invalid reset code');
  } else {
    print('JNAP error: ${e.result}');
  }
}
```

---

### 3. setPasswordWithCredentials()

**Purpose**: Sets admin password using current credentials (authenticated session).

**Signature**:
```dart
Future<void> setPasswordWithCredentials(
  String password, [
  String? hint,
])
```

**Parameters**:
- `password`: New admin password to set
- `hint`: (Optional) Password hint for user reference. If null, existing hint is preserved.

**JNAP Operations**:
- Calls `_routerRepository.send()` with:
  - Action: `JNAPAction.coreSetAdminPassword`
  - Data: `{'adminPassword': password, 'passwordHint': hint ?? existingHint}`
  - Type: `CommandType.local`
  - Auth: `true` (requires authentication)

**Returns**: `void` (success implied)

**Throws**:
- `JNAPError`: JNAP communication failure or authentication failure

**Side Effects**:
- Router admin password is updated
- Password hint is updated (if provided)

**Note**: Caller (notifier) is responsible for triggering `AuthProvider.localLogin()` after successful password change.

**Example Usage**:
```dart
try {
  await service.setPasswordWithCredentials('newSecurePass', 'Updated hint');
  // Caller must trigger re-authentication:
  // await authProvider.notifier.localLogin(password);
} on JNAPError catch (e) {
  print('Failed to set password: ${e.result}');
}
```

---

### 4. verifyRecoveryCode()

**Purpose**: Verifies router recovery/reset code validity.

**Signature**:
```dart
Future<Map<String, dynamic>> verifyRecoveryCode(String code)
```

**Parameters**:
- `code`: Recovery code to verify

**Returns**:
```dart
{
  'isValid': bool,              // True if code is valid
  'attemptsRemaining': int,     // Remaining verification attempts (from error response if invalid)
}
```

**JNAP Operations**:
- Calls `_routerRepository.send()` with:
  - Action: `JNAPAction.verifyRouterResetCode`
  - Data: `{'resetCode': code}`

**Throws**:
- `JNAPError`: JNAP communication failure (caller extracts attempt info from error)

**Behavior**:
- **Valid code**: Returns `{' isValid': true, 'attemptsRemaining': null}`
- **Invalid code**: Throws `JNAPError` with `result = 'ErrorInvalidResetCode'` and `error` JSON containing `{'attemptsRemaining': N}`
- **Exhausted attempts**: Throws `JNAPError` with `result = 'ErrorConsecutiveInvalidResetCodeEntered'`

**Example Usage**:
```dart
try {
  final result = await service.verifyRecoveryCode('12345678');
  if (result['isValid']) {
    print('Code is valid');
  }
} on JNAPError catch (e) {
  if (e.result == 'ErrorInvalidResetCode') {
    final errorData = jsonDecode(e.error!);
    final remaining = errorData['attemptsRemaining'];
    print('Invalid code. $remaining attempts remaining.');
  } else if (e.result == 'ErrorConsecutiveInvalidResetCodeEntered') {
    print('Too many failed attempts. Code locked.');
  }
}
```

---

### 5. persistPassword()

**Purpose**: Persists password to secure storage for later retrieval.

**Signature**:
```dart
Future<void> persistPassword(String password)
```

**Parameters**:
- `password`: Password to store securely

**Storage Operations**:
- Calls `_secureStorage.write(key: pLocalPassword, value: password)`

**Returns**: `void` (success implied)

**Throws**:
- `Exception`: FlutterSecureStorage write failure

**Example Usage**:
```dart
try {
  await service.persistPassword('myPassword123');
  // Password stored securely
} catch (e) {
  print('Failed to persist password: $e');
}
```

---

## Provider

### routerPasswordServiceProvider

**Definition**:
```dart
final routerPasswordServiceProvider = Provider<RouterPasswordService>((ref) {
  return RouterPasswordService(
    ref.watch(routerRepositoryProvider),
    const FlutterSecureStorage(),
  );
});
```

**Location**: Same file as RouterPasswordService

**Purpose**: Provides RouterPasswordService instance with dependency injection

**Usage**:
```dart
// In notifier
final service = ref.read(routerPasswordServiceProvider);
final config = await service.fetchPasswordConfiguration();
```

**Testing**: Override provider in tests
```dart
container.read(routerPasswordServiceProvider.overrideWithValue(mockService));
```

---

## Error Handling

### Exception Types

| Exception | Source | Meaning |
|-----------|--------|---------|
| `JNAPError` | RouterRepository | JNAP operation failed (network, protocol, authentication) |
| `Exception` | FlutterSecureStorage | Storage operation failed (read/write) |

### Error Propagation

Service does NOT catch exceptions - it propagates them to the caller (notifier).

**Pattern**:
```dart
// Service throws
Future<Map<String, dynamic>> fetchPasswordConfiguration() async {
  final results = await _routerRepository.fetchIsConfigured();  // May throw JNAPError
  final password = await _secureStorage.read(key: pLocalPassword);  // May throw Exception
  return {...};
}

// Notifier catches
Future<void> fetch() async {
  try {
    final config = await service.fetchPasswordConfiguration();
    state = state.copyWith(...);
  } on JNAPError catch (error) {
    state = state.copyWith(error: error);
  } catch (error) {
    state = state.copyWith(error: error);
  }
}
```

---

## Design Principles

### Statelessness

Service has NO internal state:
- ✅ All methods are pure (same inputs → same outputs)
- ✅ No member variables beyond dependencies
- ✅ No caching or memoization

### Single Responsibility

Service is responsible for:
- ✅ JNAP communication (password operations)
- ✅ FlutterSecureStorage access (password persistence)
- ✅ Data transformation (JNAP models → simple maps)

Service is NOT responsible for:
- ❌ State management (delegated to notifier)
- ❌ UI concerns (delegated to views)
- ❌ Navigation or error display (delegated to notifier/views)

### Dependency Injection

All dependencies injected via constructor:
- ✅ Enables mocking in tests
- ✅ No direct instantiation of dependencies
- ✅ Follows constitution Article VI Section 6.2

---

## Testing Contract

### Unit Test Requirements

**Location**: `test/page/instant_admin/services/router_password_service_test.dart`

**Mocks**:
- `MockRouterRepository extends Mock implements RouterRepository`
- `MockFlutterSecureStorage extends Mock implements FlutterSecureStorage`

**Test Data Builder**: `RouterPasswordTestData` provides pre-built JNAP responses

**Coverage Target**: ≥90% (per constitution Article I Section 1.4)

**Test Groups**:
1. fetchPasswordConfiguration
   - Success scenarios (default/user-set passwords, with/without hints)
   - JNAP failure scenarios
   - Storage failure scenarios

2. setPasswordWithResetCode
   - Success scenario
   - Invalid code error
   - JNAP communication failure

3. setPasswordWithCredentials
   - Success scenario (with/without hint)
   - Authentication failure
   - JNAP communication failure

4. verifyRecoveryCode
   - Valid code scenario
   - Invalid code with attempts remaining
   - Exhausted attempts scenario
   - JNAP communication failure

5. persistPassword
   - Success scenario
   - Storage write failure

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-15 | Initial contract definition |

---

## Approval

**Specification**: [spec.md](../spec.md)
**Plan**: [plan.md](../plan.md)
**Status**: ✅ Ready for implementation
