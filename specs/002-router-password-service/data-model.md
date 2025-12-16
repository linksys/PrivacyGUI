# Data Model: Router Password Service Layer Extraction

**Date**: 2025-12-15
**Feature**: Router Password Service Layer Extraction

## Overview

This document defines the data models and transformations involved in the router password service layer extraction. The refactoring maintains three-layer architecture by clearly separating data layer models (JNAP), application layer models (service DTOs), and presentation layer models (UI state).

---

## 1. Presentation Layer (UI Models)

### RouterPasswordState

**Location**: `lib/page/instant_admin/providers/router_password_state.dart`

**Status**: ✅ **NO CHANGES** - Existing model, already well-designed

**Purpose**: UI model representing router password configuration and validation state

**Class Definition**:
```dart
class RouterPasswordState extends Equatable {
  final bool isDefault;           // Is password still factory default?
  final bool isSetByUser;         // Was password set by user (vs. system)?
  final String adminPassword;     // Stored admin password
  final String hint;              // Password hint text
  final bool hasEdited;           // Has user edited the form?
  final bool isValid;             // Is form validation passing?
  final int? remainingErrorAttempts;  // Recovery code attempts remaining
  final dynamic error;            // Error state (JNAPError, StorageError, etc.)

  const RouterPasswordState({
    required this.isDefault,
    required this.isSetByUser,
    required this.adminPassword,
    required this.hint,
    required this.hasEdited,
    required this.isValid,
    this.remainingErrorAttempts,
    this.error,
  });

  factory RouterPasswordState.init() => const RouterPasswordState(
    isDefault: false,
    isSetByUser: true,
    adminPassword: '',
    hint: '',
    hasEdited: false,
    isValid: false,
  );

  RouterPasswordState copyWith({...});
  Map<String, dynamic> toJson() => {...};
  @override
  List<Object?> get props => [...];
}
```

**Usage**:
- **Provider**: Manages state transitions
- **Views**: Observes state for UI rendering

---

## 2. Application Layer (Service DTOs)

### Service Method Return Types

**Design Decision**: Service methods return simple `Map<String, dynamic>` or `void`, NOT full state objects.

**Rationale**:
- Separation of concerns: Service provides raw data, notifier builds state
- Flexibility: Notifier can combine service data with other sources
- Simplicity: Avoids creating unnecessary DTO classes

### fetchPasswordConfiguration()

**Return Type**: `Future<Map<String, dynamic>>`

**Structure**:
```dart
{
  'isDefault': bool,           // Is password factory default?
  'isSetByUser': bool,         // Was password set by user?
  'hint': String,              // Password hint
  'storedPassword': String,    // Password from FlutterSecureStorage
}
```

**Transformation**: Notifier maps to RouterPasswordState fields

### setPasswordWithResetCode()

**Return Type**: `Future<void>`

**Side Effects**:
- Sets password via JNAP
- No return value (success implied, throws on error)

### setPasswordWithCredentials()

**Return Type**: `Future<void>`

**Side Effects**:
- Sets password via JNAP with authentication
- No return value (success implied, throws on error)

### verifyRecoveryCode()

**Return Type**: `Future<Map<String, dynamic>>`

**Structure**:
```dart
{
  'isValid': bool,              // Is code valid?
  'attemptsRemaining': int,     // Remaining attempts (from error response if invalid)
}
```

**Transformation**: Notifier updates `remainingErrorAttempts` state

### persistPassword()

**Return Type**: `Future<void>`

**Side Effects**:
- Writes password to FlutterSecureStorage
- No return value (success implied, throws on error)

---

## 3. Data Layer (JNAP Models)

### JNAP Response Models

**Location**: `lib/core/jnap/models/`, `lib/core/jnap/result/jnap_result.dart`

**Status**: ✅ **NO CHANGES** - Existing models, used by service layer only

#### JNAPTransactionSuccessWrap

**Purpose**: Wrapper for multiple JNAP action responses

**Structure**:
```dart
class JNAPTransactionSuccessWrap {
  final String result;  // 'ok'
  final List<MapEntry<JNAPAction, JNAPResult>> data;

  static JNAPResult? getResult(JNAPAction action, Map<JNAPAction, JNAPResult> map) { ... }
}
```

**Used By**: `fetchPasswordConfiguration()` to extract multiple responses

#### JNAPSuccess

**Purpose**: Successful JNAP action response

**Structure**:
```dart
class JNAPSuccess extends JNAPResult {
  final String result;  // 'ok'
  final Map<String, dynamic> output;  // Response data
}
```

**Used By**: All service methods for individual JNAP responses

#### JNAPError

**Purpose**: Failed JNAP action response

**Structure**:
```dart
class JNAPError extends JNAPResult implements Exception {
  final String result;  // Error code (e.g., 'ErrorInvalidResetCode')
  final String? error;  // Error details JSON
}
```

**Used By**: Service layer throws, notifier layer catches

---

## 4. Test Data Models

### RouterPasswordTestData

**Location**: `test/mocks/test_data/router_password_test_data.dart`

**Status**: 🆕 **NEW** - To be created

**Purpose**: Test Data Builder for JNAP mock responses

**Class Definition**:
```dart
/// Test data builder for RouterPasswordService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// Supports partial override pattern via named parameters.
class RouterPasswordTestData {
  /// Create successful fetchIsConfigured response
  static JNAPTransactionSuccessWrap createFetchConfiguredSuccess({
    bool isAdminPasswordDefault = false,
    bool isAdminPasswordSetByUser = true,
  }) {
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.isAdminPasswordDefault,
          JNAPSuccess(
            result: 'ok',
            output: {'isAdminPasswordDefault': isAdminPasswordDefault},
          ),
        ),
        MapEntry(
          JNAPAction.isAdminPasswordSetByUser,
          JNAPSuccess(
            result: 'ok',
            output: {'isAdminPasswordSetByUser': isAdminPasswordSetByUser},
          ),
        ),
      ],
    );
  }

  /// Create successful getAdminPasswordHint response
  static JNAPSuccess createPasswordHintSuccess({
    String hint = '',
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {'passwordHint': hint},
    );
  }

  /// Create successful password set response (generic)
  static JNAPSuccess createSetPasswordSuccess() {
    return JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create successful recovery code verification response
  static JNAPSuccess createVerifyCodeSuccess() {
    return JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create error response for invalid recovery code
  static JNAPError createVerifyCodeError({
    int attemptsRemaining = 2,
    String errorCode = 'ErrorInvalidResetCode',
  }) {
    return JNAPError(
      result: errorCode,
      error: jsonEncode({'attemptsRemaining': attemptsRemaining}),
    );
  }

  /// Create error response for exhausted recovery code attempts
  static JNAPError createVerifyCodeExhaustedError() {
    return JNAPError(
      result: 'ErrorConsecutiveInvalidResetCodeEntered',
      error: null,
    );
  }

  /// Create generic JNAP error
  static JNAPError createGenericError({
    String errorCode = 'ErrorUnknown',
    String? errorMessage,
  }) {
    return JNAPError(
      result: errorCode,
      error: errorMessage,
    );
  }
}
```

**Usage Pattern**:
```dart
// In service tests
test('fetchPasswordConfiguration returns correct data', () async {
  // Arrange
  when(() => mockRepository.fetchIsConfigured())
      .thenAnswer((_) async => [
        ...RouterPasswordTestData.createFetchConfiguredSuccess(
          isAdminPasswordDefault: true,
        ).data,
      ]);

  when(() => mockRepository.send(JNAPAction.getAdminPasswordHint))
      .thenAnswer((_) async => RouterPasswordTestData.createPasswordHintSuccess(
        hint: 'Test hint',
      ));

  when(() => mockStorage.read(key: pLocalPassword))
      .thenAnswer((_) async => 'stored_password');

  // Act
  final result = await service.fetchPasswordConfiguration();

  // Assert
  expect(result['isDefault'], true);
  expect(result['hint'], 'Test hint');
  expect(result['storedPassword'], 'stored_password');
});
```

---

## 5. Data Flow Diagram

```
┌───────────────────────────────────────────────────────────┐
│                   Presentation Layer                      │
│  ┌──────────────────────────────────────────────────┐    │
│  │         RouterPasswordState (UI Model)           │    │
│  │  - isDefault, isSetByUser, adminPassword, hint   │    │
│  │  - hasEdited, isValid, remainingErrorAttempts    │    │
│  └──────────────────────────────────────────────────┘    │
└────────────────────┬─────────────────────────────────────┘
                     │ copyWith()
                     │
┌────────────────────▼─────────────────────────────────────┐
│                 Application Layer                         │
│  ┌──────────────────────────────────────────────────┐    │
│  │    RouterPasswordNotifier (State Management)     │    │
│  │  - fetch() → calls service → updates state       │    │
│  │  - setPassword*() → calls service → updates state│    │
│  └────────────────┬────────────────────────────────┘    │
│                   │ ref.read(service)                     │
│  ┌────────────────▼────────────────────────────────┐    │
│  │  RouterPasswordService (Business Logic)         │    │
│  │  - fetchPasswordConfiguration()                  │    │
│  │    Returns: Map<String, dynamic>                 │    │
│  │  - setPasswordWithResetCode() → void             │    │
│  │  - setPasswordWithCredentials() → void           │    │
│  │  - verifyRecoveryCode()                          │    │
│  │    Returns: Map<String, dynamic>                 │    │
│  └────────────────┬────────────────────────────────┘    │
└────────────────────┼─────────────────────────────────────┘
                     │ await _routerRepository.send()
                     │ await _secureStorage.read/write()
┌────────────────────▼─────────────────────────────────────┐
│                     Data Layer                            │
│  ┌──────────────────────────────────────────────────┐    │
│  │    JNAP Models (JNAPSuccess, JNAPError, etc.)    │    │
│  │  - Used by service for transformation             │    │
│  │  - NOT exposed to notifier or views              │    │
│  └──────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────┐    │
│  │         RouterRepository (JNAP Client)           │    │
│  │  - send(), fetchIsConfigured()                   │    │
│  └──────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────┐    │
│  │     FlutterSecureStorage (Persistence)           │    │
│  │  - read(), write()                               │    │
│  └──────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────┘
```

---

## 6. Validation Rules

### State Validation (Notifier Layer)

**Existing Logic** (maintained):
- `hasEdited`: Set by user interaction, cleared on fetch/save
- `isValid`: Validated by views/form logic, updated via `setValidate()`
- `remainingErrorAttempts`: Updated from service verification response

**No Changes Required**: Validation remains in notifier/view layers

---

## 7. Error State Management

### Exception Handling

**Service Layer**:
- Throws: `JNAPError`, `StorageError` (or generic `Exception`)
- Does NOT manage error state

**Notifier Layer**:
- Catches: Exceptions from service
- Updates: `state.error` field with caught exception
- Maintains: Error state for UI display

**Example**:
```dart
// Notifier
try {
  final config = await service.fetchPasswordConfiguration();
  state = state.copyWith(
    isDefault: config['isDefault'],
    error: null,  // Clear previous errors
  );
} on JNAPError catch (error) {
  state = state.copyWith(error: error);
} on StorageError catch (error) {
  state = state.copyWith(error: error);
}
```

---

## 8. Migration Compatibility

### Backward Compatibility Guarantees

| Component | Change | Compatibility |
|-----------|--------|---------------|
| RouterPasswordState | ✅ No changes | 100% compatible |
| RouterPasswordNotifier API | ✅ No changes | 100% compatible |
| Views | ✅ No changes required | 100% compatible |
| JNAP Models | ✅ No changes | 100% compatible |

**Breaking Changes**: ❌ None

**New Components**:
- ✅ RouterPasswordService (new file)
- ✅ routerPasswordServiceProvider (new provider)
- ✅ RouterPasswordTestData (new test data builder)

---

## Summary

| Layer | Model | Purpose | Status |
|-------|-------|---------|--------|
| Presentation | `RouterPasswordState` | UI state | ✅ No changes |
| Application | Service DTOs (Maps) | Data transfer | 🆕 New pattern |
| Application | `RouterPasswordService` | Business logic | 🆕 New class |
| Data | JNAP Models | API responses | ✅ No changes |
| Test | `RouterPasswordTestData` | Mock data builder | 🆕 New class |

**Architecture Compliance**: ✅ Three-layer separation maintained, no cross-layer violations
