# Research: Router Password Service Layer Extraction

**Date**: 2025-12-15
**Feature**: Router Password Service Layer Extraction
**Status**: Complete

## Executive Summary

This document consolidates research findings for extracting router password business logic from RouterPasswordNotifier into a dedicated RouterPasswordService layer. Key decisions include exception-based error handling, comprehensive dependency injection (RouterRepository + FlutterSecureStorage), and dedicated service provider following the project's constitutional requirements.

---

## 1. JNAP Operations Analysis

### Current Implementation

**File**: `lib/page/instant_admin/providers/router_password_provider.dart`

**Methods and JNAP Operations**:

| Method | JNAP Actions | Lines | Complexity |
|--------|--------------|-------|------------|
| `fetch()` | `fetchIsConfigured()`, `getAdminPasswordHint` | 22-49 | High - Multiple JNAP calls, storage read |
| `setAdminPasswordWithResetCode()` | `setupSetAdminPassword` | 51-69 | Medium - Single JNAP call |
| `setAdminPasswordWithCredentials()` | `coreSetAdminPassword`, triggers `localLogin` | 71-91 | High - JNAP call + AuthProvider interaction |
| `checkRecoveryCode()` | `verifyRouterResetCode` | 93-119 | High - Complex error handling |

**FlutterSecureStorage Usage**:
- Line 40-41: Read `pLocalPassword` from secure storage during `fetch()`
- Direct instantiation: `const FlutterSecureStorage()` inline

**Decision**: All four methods will be extracted to service layer, including FlutterSecureStorage operations.

---

## 2. AuthService Pattern Study

### Reference Implementation

**File**: `lib/providers/auth/auth_service.dart`

**Key Patterns Identified**:

1. **Stateless Service Class**
   - ✅ Constructor injection of dependencies
   - ✅ No internal state management
   - ✅ Pure business logic methods

2. **Result<T> Sealed Classes**
   - ✅ Used in AuthService: `AuthResult<T>`, `AuthSuccess<T>`, `AuthFailure<T>`
   - ❌ **Decision**: NOT using for RouterPasswordService (see clarification below)

3. **Dedicated Provider**
   - ✅ `authServiceProvider` with dependency injection
   - ✅ Pattern: `Provider<ServiceClass>((ref) => ServiceClass(dependencies))`

4. **Error Handling**
   - AuthService: Returns `AuthResult<T>` with success/failure variants
   - **Decision for RouterPasswordService**: Use traditional exception throwing instead

### Rationale for Exception-Based Approach

**Decision**: Use traditional exception throwing rather than Result<T> sealed classes

**Reasoning**:
1. **Simplicity**: Spec clarification (Session 2025-12-15 Q1) explicitly chose exception throwing
2. **Existing Patterns**: Most of the codebase outside AuthService uses exceptions
3. **RouterPasswordNotifier Already Has Try-Catch**: Current implementation uses `.onError()` and error state management
4. **Consistency**: AuthService is an exception, not the rule in this codebase

**Trade-offs**:
- ✅ Simpler implementation
- ✅ Familiar pattern for team
- ✅ Easier refactoring (matches current notifier structure)
- ❌ Less type-safe than Result<T>
- ❌ Caller must remember to catch exceptions

---

## 3. Error Handling Strategy

### Exception Types

**JNAPError** (Existing):
- Already defined in `lib/core/jnap/result/jnap_result.dart`
- Used for: JNAP communication failures, invalid responses, authentication failures
- Properties: `result` (error code), `error` (error message JSON)

**StorageError** (Check if exists, or use generic exception):
- Used for: FlutterSecureStorage read/write failures
- Fallback: Can use generic `Exception` or create custom if needed

### Error Propagation Pattern

**Service Layer**:
```dart
Future<Map<String, dynamic>> fetchPasswordConfiguration() async {
  try {
    final results = await _routerRepository.fetchIsConfigured();
    // ... process results
    final password = await _secureStorage.read(key: pLocalPassword);
    // ... return data
  } on JNAPError {
    rethrow; // Let caller handle
  } catch (e) {
    throw StorageError('Failed to read password: $e');
  }
}
```

**Notifier Layer**:
```dart
Future<void> fetch([bool force = false]) async {
  try {
    final service = ref.read(routerPasswordServiceProvider);
    final config = await service.fetchPasswordConfiguration();
    state = state.copyWith(
      isDefault: config['isDefault'],
      isSetByUser: config['isSetByUser'],
      // ...
    );
  } on JNAPError catch (error) {
    state = state.copyWith(error: error);
  } on StorageError catch (error) {
    state = state.copyWith(error: error);
  }
}
```

---

## 4. Dependency Injection Scope

### Decision: Full Dependency Injection

**Service Constructor**:
```dart
RouterPasswordService(
  this._routerRepository,
  this._secureStorage,
);

final RouterRepository _routerRepository;
final FlutterSecureStorage _secureStorage;
```

**Rationale**:
1. **Single Responsibility**: Service handles ALL password data access (JNAP + storage)
2. **Testability**: Both dependencies can be mocked in tests
3. **Consistency**: Matches spec clarification (Session 2025-12-15 Q2)
4. **Principle of Least Surprise**: Service is self-contained

**Alternative Rejected**: Keep FlutterSecureStorage in notifier
- ❌ Split responsibility (service handles JNAP, notifier handles storage)
- ❌ Less testable (notifier would need to mock storage)
- ❌ Violates single responsibility principle

---

## 5. Provider Architecture

### Decision: Dedicated Service Provider

**Provider Definition**:
```dart
// In router_password_service.dart
final routerPasswordServiceProvider = Provider<RouterPasswordService>((ref) {
  return RouterPasswordService(
    ref.watch(routerRepositoryProvider),
    const FlutterSecureStorage(),
  );
});
```

**Rationale**:
1. **Testability**: Enables provider override in tests
2. **Constitution Compliance**: Article VI Section 6.3 mandates provider for services
3. **Consistency**: Matches AuthService pattern
4. **Reusability**: Service can be accessed by other notifiers if needed

**Notifier Access Pattern**:
```dart
class RouterPasswordNotifier extends Notifier<RouterPasswordState> {
  Future<void> fetch([bool force = false]) async {
    final service = ref.read(routerPasswordServiceProvider);
    final config = await service.fetchPasswordConfiguration();
    // ...
  }
}
```

---

## 6. Technology Choices

### Mocking: Mocktail

**Decision**: Use Mocktail for all mocks

**Rationale**:
- Constitution Article I Section 1.6.1 mandates Mocktail
- Clean syntax: `when(() => mock.method()).thenReturn(value)`
- Null-safe and modern

**Mock Classes**:
```dart
// In test files
class MockRouterRepository extends Mock implements RouterRepository {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockRouterPasswordService extends Mock implements RouterPasswordService {}
```

### Test Data Builder

**Decision**: Implement Test Data Builder pattern

**Rationale**:
- Constitution Article I Section 1.6.2 mandates Test Data Builder
- Reduces test boilerplate
- Centralizes JNAP mock response creation
- Enables partial override pattern

**Implementation**: `RouterPasswordTestData` with static factory methods

---

## 7. Integration Points

### RouterRepository Integration

**Existing Interface**:
- `Future<List<MapEntry<JNAPAction, JNAPResult>>> fetchIsConfigured()`
- `Future<JNAPSuccess> send(JNAPAction action, {data, type, auth})`

**Service Usage**:
```dart
// Fetch operations
final results = await _routerRepository.fetchIsConfigured();
final isAdminDefault = JNAPTransactionSuccessWrap.getResult(
  JNAPAction.isAdminPasswordDefault,
  Map.fromEntries(results)
)?.output['isAdminPasswordDefault'] ?? false;

// Send operations
await _routerRepository.send(
  JNAPAction.coreSetAdminPassword,
  data: {'adminPassword': password, 'passwordHint': hint},
  type: CommandType.local,
  auth: true,
);
```

**Testing**:
- Mock: `MockRouterRepository`
- Test Data Builder: Provide pre-built `JNAPTransactionSuccessWrap` responses

### FlutterSecureStorage Integration

**Existing Interface**:
- `Future<String?> read({required String key})`
- `Future<void> write({required String key, required String value})`

**Service Usage**:
```dart
// Read
final password = await _secureStorage.read(key: pLocalPassword);

// Write
await _secureStorage.write(key: pLocalPassword, value: password);
```

**Testing**:
- Mock: `MockFlutterSecureStorage`
- Stub: `when(() => mock.read(key: any(named: 'key'))).thenAnswer((_) async => 'password123')`

### AuthProvider Integration

**Important**: AuthProvider is accessed by **notifier**, NOT service

**Pattern**:
```dart
// In RouterPasswordNotifier
Future<void> setAdminPasswordWithCredentials(String? password, [String? hint]) async {
  final service = ref.read(routerPasswordServiceProvider);
  await service.setPasswordWithCredentials(password ?? '', hint);

  // AuthProvider interaction stays in notifier
  await ref
      .read(authProvider.notifier)
      .localLogin(password ?? '', guardError: false);

  await fetch(true);
}
```

**Rationale**: AuthProvider represents cross-feature state (authentication), which is a notifier-level concern, not service-level.

---

## 8. Data Transformation Strategy

### Service Return Types

**Decision**: Return simple `Map<String, dynamic>` from service, not full state objects

**Rationale**:
1. **Separation of Concerns**: Service provides data, notifier builds state
2. **Flexibility**: Notifier can combine service data with other sources
3. **Testability**: Simple return types easier to verify in tests

**Example**:
```dart
// Service
Future<Map<String, dynamic>> fetchPasswordConfiguration() async {
  // ... fetch from JNAP and storage
  return {
    'isDefault': isAdminDefault,
    'isSetByUser': isSetByUser,
    'hint': passwordHint,
    'storedPassword': password,
  };
}

// Notifier
Future<void> fetch([bool force = false]) async {
  final config = await service.fetchPasswordConfiguration();
  state = state.copyWith(
    isDefault: config['isDefault'] as bool,
    isSetByUser: config['isSetByUser'] as bool,
    adminPassword: config['storedPassword'] as String,
    hint: config['hint'] as String,
  );
}
```

---

## 9. Migration Strategy

### Incremental Approach

**Phase 1**: Create service with tests (isolated development)
1. Create `RouterPasswordService` class
2. Create `RouterPasswordTestData`
3. Write comprehensive service tests
4. Achieve ≥90% service coverage

**Phase 2**: Refactor notifier (integration)
1. Replace JNAP/storage calls with service calls
2. Add exception handling (try-catch)
3. Maintain public API

**Phase 3**: Test notifier (validation)
1. Write provider tests with mocked service
2. Achieve ≥85% provider coverage
3. Run existing integration tests
4. Manual testing

**Benefits**:
- Service can be developed and tested independently
- Notifier refactoring is mechanical (search-replace pattern)
- Rollback possible at each phase

---

## 10. Risk Mitigation

### Identified Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Breaking existing functionality | Medium | High | Maintain public API, comprehensive tests, manual testing |
| Test coverage not meeting targets | Low | Medium | Test Data Builder pattern, start with service tests |
| Performance regression | Low | Low | Unit tests run in-memory (no network), maintain existing performance |

### Backward Compatibility

**Guarantees**:
- ✅ RouterPasswordNotifier public API unchanged
- ✅ RouterPasswordState structure unchanged
- ✅ UI views require no modifications
- ✅ Existing integration tests should pass

**Breaking Changes**: None

---

## Conclusion

All research questions resolved. Key decisions:
1. ✅ Exception-based error handling (not Result<T>)
2. ✅ Full dependency injection (RouterRepository + FlutterSecureStorage)
3. ✅ Dedicated service provider
4. ✅ Mocktail for testing
5. ✅ Test Data Builder pattern
6. ✅ Service returns maps, notifier builds state

**Status**: ✅ Ready for Phase 1 (Design & Implementation)

**Next**: Proceed to data model and contract definition
