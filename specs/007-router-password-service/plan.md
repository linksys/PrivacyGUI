# Implementation Plan: Router Password Service Layer Extraction

**Branch**: `002-router-password-service` | **Date**: 2025-12-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-router-password-service/spec.md`

## Summary

Extract JNAP communication logic from RouterPasswordNotifier into a dedicated RouterPasswordService layer, establishing proper three-layer architecture separation. The service will encapsulate all password-related JNAP operations (fetch configuration, set password, verify recovery code) and FlutterSecureStorage access, delegating only state management to the notifier. This refactoring follows the established AuthService pattern with exception-based error handling and comprehensive unit test coverage (Service ≥90%, Provider ≥85%).

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.x
**Primary Dependencies**: flutter_riverpod (2.6.1), flutter_secure_storage (9.2.2), mocktail (1.0.0)
**Storage**: FlutterSecureStorage (password persistence), RouterRepository (JNAP communication)
**Testing**: flutter_test with Mocktail for mocking, Test Data Builder pattern for JNAP responses
**Target Platform**: iOS/Android (Flutter mobile app)
**Project Type**: Mobile (Flutter) - existing feature refactoring
**Performance Goals**: Unit tests execute in <5 seconds, maintain existing app performance
**Constraints**: Maintain backward compatibility, no UI changes, zero regression in functionality
**Scale/Scope**: Single feature refactoring (instant_admin module), ~600 lines of code affected

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Article I: Test Requirement ✅ **PASS**
- **Section 1.1**: Unit tests required for RouterPasswordService and RouterPasswordNotifier
- **Section 1.3**: Test scope limited to instant_admin/router_password only
- **Section 1.4**: Coverage targets: Service ≥90%, Provider ≥85%, Overall ≥80%
- **Section 1.5**: Test organization: `test/page/instant_admin/services/`, `test/page/instant_admin/providers/`
- **Section 1.6**: Use Mocktail for mocking, Test Data Builder for JNAP responses

### Article III: Naming Conventions ✅ **PASS**
- **Section 3.2**: Files: `router_password_service.dart`, `router_password_provider.dart`, `router_password_test_data.dart`
- **Section 3.3**: Classes: `RouterPasswordService`, `RouterPasswordNotifier`, `RouterPasswordTestData`
- **Section 3.4**: Providers: `routerPasswordServiceProvider`, `routerPasswordProvider`
- **Section 3.6**: Test names: descriptive, no numbering (e.g., `'fetchPasswordConfig returns UI model on success'`)

### Article V: Simplicity and Minimal Structure ✅ **PASS**
- **Section 5.2**: Follows standard structure: `services/`, `providers/`, existing `views/`
- **Section 5.3**: Three-layer architecture compliance:
  - Presentation: Views (no changes)
  - Application: RouterPasswordNotifier (state) + RouterPasswordService (logic)
  - Data: RouterRepository (JNAP), FlutterSecureStorage (persistence)
- **Section 5.4**: No over-engineering - service layer is justified and necessary

### Article VI: Service Layer Principle ✅ **PASS**
- **Section 6.1**: Service encapsulates JNAP communication and password persistence
- **Section 6.2**: Service responsibilities:
  - ✅ Handles JNAP API communication
  - ✅ Implements business logic and data transformations
  - ✅ Returns UI models (RouterPasswordState data)
  - ✅ Stateless with constructor injection
  - ❌ Does not manage UI state (delegated to notifier)
- **Section 6.3**: File organization: `lib/page/instant_admin/services/router_password_service.dart`
- **Section 6.4**: Clear provider-service separation maintained
- **Section 6.5**: Unit tests required with mocked dependencies

### Article VII: Anti-Abstraction Principle ✅ **PASS**
- **Section 7.1**: Uses Riverpod directly (no custom wrappers)
- **Section 7.2**: Service layer is legitimate abstraction for business logic
- **Section 7.3**: Proper model separation: JNAP models (data layer) vs RouterPasswordState (UI model)

### Article VIII: Testing Strategy ✅ **PASS**
- **Section 8.1**: Many fast unit tests (Service + Provider)
- **Section 8.2**: Mocktail for mocking, Test Data Builder for JNAP responses
- **Section 8.3**: No screenshot tests needed (no UI changes)

### Article XI: Data Models ✅ **PASS**
- **Section 11.1**: RouterPasswordState extends Equatable with `toJson()`/`fromJson()` (already exists)

### Article XII: State Management with Riverpod ✅ **PASS**
- **Section 12.1**: Uses Riverpod Notifier pattern
- **Section 12.2**: Notifier delegates to service, handles only state coordination

**Gate Status**: ✅ **ALL GATES PASS** - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/002-router-password-service/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (current)
├── research.md          # Phase 0 output (next)
├── data-model.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── router_password_service_contract.md
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Existing structure (Flutter mobile app)
lib/
├── page/
│   └── instant_admin/
│       ├── providers/
│       │   ├── router_password_provider.dart    # REFACTOR: delegate to service
│       │   └── router_password_state.dart       # NO CHANGE: existing UI model
│       ├── services/                            # CREATE: new directory
│       │   └── router_password_service.dart     # CREATE: new service
│       └── views/                               # NO CHANGE: UI components
│
└── core/
    └── jnap/                                    # NO CHANGE: data layer
        ├── models/                              # USED BY: service layer only
        └── router_repository.dart               # INJECTED INTO: service

test/
├── page/
│   └── instant_admin/
│       ├── providers/
│       │   └── router_password_provider_test.dart  # CREATE: provider tests
│       └── services/
│           └── router_password_service_test.dart   # CREATE: service tests
│
└── mocks/
    └── test_data/
        └── router_password_test_data.dart       # CREATE: Test Data Builder
```

**Structure Decision**: Standard Flutter feature structure. The `instant_admin/` feature directory follows constitution Article V Section 5.2 pattern with `services/`, `providers/`, and `views/` subdirectories. Tests mirror the source structure per Article I Section 1.5.

## Complexity Tracking

> **No violations detected** - This refactoring aligns with all constitutional principles. No complexity justification required.

---

## Phase 0: Research & Technical Decisions

### Research Tasks

1. **JNAP Operations Analysis**
   - **Task**: Analyze current RouterPasswordNotifier methods to identify all JNAP operations
   - **Current Implementation**: `lib/page/instant_admin/providers/router_password_provider.dart`
   - **Operations to Extract**:
     - `fetch()`: fetchIsConfigured(), getAdminPasswordHint
     - `setAdminPasswordWithResetCode()`: setupSetAdminPassword
     - `setAdminPasswordWithCredentials()`: coreSetAdminPassword
     - `checkRecoveryCode()`: verifyRouterResetCode
   - **FlutterSecureStorage Usage**: Line 40-41 (read pLocalPassword)

2. **AuthService Pattern Study**
   - **Reference**: `lib/providers/auth/auth_service.dart`
   - **Pattern Elements**:
     - ✅ Stateless service class
     - ✅ Constructor injection (RouterRepository, storage dependencies)
     - ❌ Result<T> sealed classes (clarified: use exceptions instead)
     - ✅ Dedicated service provider
   - **Key Difference**: AuthService uses Result<T>, but RouterPasswordService will use traditional exception throwing per clarification

3. **Error Handling Strategy**
   - **Decision**: Traditional exception throwing (clarified in spec Session 2025-12-15)
   - **Exception Types**:
     - `JNAPError`: JNAP communication failures, invalid responses
     - `StorageError`: FlutterSecureStorage read/write failures
   - **Error Propagation**: Service throws, notifier catches with try-catch
   - **Rationale**: Simpler than Result<T> pattern, maintains consistency with existing codebase patterns outside AuthService

4. **Dependency Injection Scope**
   - **Decision**: Service accepts both RouterRepository and FlutterSecureStorage (clarified in spec)
   - **Constructor Signature**:
     ```dart
     RouterPasswordService(this._routerRepository, this._secureStorage)
     ```
   - **Rationale**: Single responsibility - service handles ALL password data access (JNAP + storage)

5. **Provider Architecture**
   - **Decision**: Dedicated `routerPasswordServiceProvider` (clarified in spec, follows Article VI Section 6.3)
   - **Provider Definition**:
     ```dart
     final routerPasswordServiceProvider = Provider<RouterPasswordService>((ref) {
       return RouterPasswordService(
         ref.watch(routerRepositoryProvider),
         const FlutterSecureStorage(),
       );
     });
     ```
   - **Rationale**: Enables testability (provider override), matches AuthService pattern

### Technology Choices

**Mocking Library**: Mocktail
- **Rationale**: Constitution Article I Section 1.6.1 mandates Mocktail over Mockito
- **Usage**: Mock RouterRepository and FlutterSecureStorage in service tests, mock RouterPasswordService in provider tests

**Test Data Builder**: Custom builder class
- **Pattern**: Article I Section 1.6.2 test data builder pattern
- **Implementation**: `RouterPasswordTestData` with static factory methods for JNAP responses
- **Benefits**: Reusable mock data, readable tests, easy customization via named parameters

**Error Handling**: Exception-based
- **Pattern**: Traditional try-catch with specific exception types
- **Trade-off**: Simpler than Result<T> but less type-safe; acceptable per project decision

### Integration Points

1. **RouterRepository**: Existing JNAP communication layer
   - **Integration**: Constructor injection into service
   - **Methods Used**: `send()`, `fetchIsConfigured()`
   - **Testing**: Mock with Mocktail, use Test Data Builder for responses

2. **FlutterSecureStorage**: Existing secure storage
   - **Integration**: Constructor injection into service
   - **Methods Used**: `read()`, `write()`
   - **Testing**: Mock with Mocktail, stub success/failure scenarios

3. **AuthProvider**: Existing authentication provider
   - **Integration**: Accessed by notifier (not service) for `localLogin()` after password change
   - **Testing**: Mock in provider tests only

**Research Output**: See [research.md](./research.md) for consolidated findings.

---

## Phase 1: Design & Contracts

### Data Model

**Key Models** (see [data-model.md](./data-model.md) for details):

1. **RouterPasswordState** (Existing UI Model)
   - Fields: `isDefault`, `isSetByUser`, `adminPassword`, `hint`, `hasEdited`, `isValid`, `remainingErrorAttempts`, `error`
   - No changes required - already serves as UI model
   - Used by: Provider and Views

2. **JNAP Response Models** (Existing Data Layer)
   - Used by service for transformation
   - Sources: `JNAPTransactionSuccessWrap`, `JNAPSuccess`, `JNAPError`
   - Not exposed to provider layer

3. **RouterPasswordTestData** (New Test Data Builder)
   - Factory methods for mock JNAP responses
   - Supports partial override pattern
   - Methods:
     - `createFetchConfiguredSuccess()`
     - `createPasswordHintSuccess()`
     - `createSetPasswordSuccess()`
     - `createVerifyCodeSuccess()`
     - `createVerifyCodeError()`

### API Contracts

**RouterPasswordService Contract** (see [contracts/router_password_service_contract.md](./contracts/router_password_service_contract.md)):

```dart
/// Stateless service for router password operations
///
/// Encapsulates JNAP communication and password persistence logic,
/// separating business logic from state management (RouterPasswordNotifier).
class RouterPasswordService {
  /// Constructor injection of dependencies
  RouterPasswordService(
    this._routerRepository,
    this._secureStorage,
  );

  final RouterRepository _routerRepository;
  final FlutterSecureStorage _secureStorage;

  /// Fetches router password configuration from JNAP
  ///
  /// Returns: Map with keys 'isDefault', 'isSetByUser', 'hint', 'storedPassword'
  /// Throws: JNAPError on JNAP communication failure
  /// Throws: StorageError on FlutterSecureStorage read failure
  Future<Map<String, dynamic>> fetchPasswordConfiguration();

  /// Sets admin password using setup reset code
  ///
  /// Parameters:
  ///   - password: New admin password
  ///   - hint: Password hint
  ///   - code: Setup reset code
  ///
  /// Throws: JNAPError on JNAP communication failure or invalid code
  Future<void> setPasswordWithResetCode(
    String password,
    String hint,
    String code,
  );

  /// Sets admin password with current credentials
  ///
  /// Parameters:
  ///   - password: New admin password
  ///   - hint: Password hint (optional)
  ///
  /// Throws: JNAPError on JNAP communication failure or authentication failure
  Future<void> setPasswordWithCredentials(
    String password, [
    String? hint,
  ]);

  /// Verifies router recovery code
  ///
  /// Parameters:
  ///   - code: Recovery code to verify
  ///
  /// Returns: Map with keys 'isValid', 'attemptsRemaining'
  /// Throws: JNAPError on JNAP communication failure
  Future<Map<String, dynamic>> verifyRecoveryCode(String code);

  /// Persists password to secure storage
  ///
  /// Parameters:
  ///   - password: Password to store
  ///
  /// Throws: StorageError on FlutterSecureStorage write failure
  Future<void> persistPassword(String password);
}
```

**RouterPasswordNotifier Refactored Contract**:

```dart
/// State management notifier for router password
///
/// Delegates all JNAP operations and storage to RouterPasswordService,
/// focusing solely on state coordination and UI interaction handling.
class RouterPasswordNotifier extends Notifier<RouterPasswordState> {
  @override
  RouterPasswordState build() => RouterPasswordState.init();

  /// Fetches password configuration via service
  ///
  /// Catches exceptions and updates error state accordingly.
  Future<void> fetch([bool force = false]);

  /// Sets password using reset code via service
  ///
  /// Catches exceptions and updates error state accordingly.
  Future<void> setAdminPasswordWithResetCode(
    String password,
    String hint,
    String code,
  );

  /// Sets password with credentials via service
  ///
  /// Delegates to service, then triggers AuthProvider.localLogin.
  /// Catches exceptions and updates error state accordingly.
  Future<void> setAdminPasswordWithCredentials(
    String? password, [
    String? hint,
  ]);

  /// Verifies recovery code via service
  ///
  /// Updates remainingErrorAttempts state based on service response.
  Future<bool> checkRecoveryCode(String code);

  /// Updates hasEdited state flag
  void setEdited(bool hasEdited);

  /// Updates isValid state flag
  void setValidate(bool isValid);
}
```

### Implementation Sequence

1. **Phase 1.1**: Create RouterPasswordService skeleton
   - File: `lib/page/instant_admin/services/router_password_service.dart`
   - Define class structure, constructor, method signatures
   - Define `routerPasswordServiceProvider`

2. **Phase 1.2**: Create Test Data Builder
   - File: `test/mocks/test_data/router_password_test_data.dart`
   - Implement factory methods for JNAP responses
   - Follow Article I Section 1.6.2 pattern

3. **Phase 1.3**: Implement RouterPasswordService methods
   - Extract logic from RouterPasswordNotifier
   - Transform JNAP responses to simple maps (not full state objects)
   - Implement exception handling

4. **Phase 1.4**: Write RouterPasswordService unit tests
   - File: `test/page/instant_admin/services/router_password_service_test.dart`
   - Mock RouterRepository and FlutterSecureStorage
   - Use Test Data Builder for responses
   - Target ≥90% coverage

5. **Phase 1.5**: Refactor RouterPasswordNotifier
   - Replace direct JNAP/storage calls with service calls
   - Add try-catch blocks for exception handling
   - Maintain public API (no breaking changes)

6. **Phase 1.6**: Write RouterPasswordNotifier unit tests
   - File: `test/page/instant_admin/providers/router_password_provider_test.dart`
   - Mock RouterPasswordService
   - Test state management logic
   - Target ≥85% coverage

7. **Phase 1.7**: Verification
   - Run architectural compliance checks (grep for JNAP imports in providers/)
   - Run full test suite
   - Manual testing of password functionality
   - Generate coverage report

### Testing Strategy

**Service Layer Tests** (`router_password_service_test.dart`):
- Mock: RouterRepository, FlutterSecureStorage
- Test Data Builder: RouterPasswordTestData
- Coverage: All JNAP operations, all error scenarios, FlutterSecureStorage operations
- Test Groups:
  - "RouterPasswordService - fetchPasswordConfiguration"
  - "RouterPasswordService - setPasswordWithResetCode"
  - "RouterPasswordService - setPasswordWithCredentials"
  - "RouterPasswordService - verifyRecoveryCode"
  - "RouterPasswordService - persistPassword"

**Provider Layer Tests** (`router_password_provider_test.dart`):
- Mock: RouterPasswordService, AuthProvider
- Test Data Builder: Not needed (service returns simple types)
- Coverage: State transitions, exception handling, all public methods
- Test Groups:
  - "RouterPasswordNotifier - fetch"
  - "RouterPasswordNotifier - setAdminPasswordWithResetCode"
  - "RouterPasswordNotifier - setAdminPasswordWithCredentials"
  - "RouterPasswordNotifier - checkRecoveryCode"
  - "RouterPasswordNotifier - state flags (setEdited, setValidate)"

### Post-Design Constitution Re-Check

**Article V Section 5.3.3 Compliance**:
```bash
# Verify Provider layer has no JNAP imports
grep -r "import.*jnap/models" lib/page/instant_admin/providers/
# Expected: 0 results ✅

# Verify UI layer has no JNAP imports
grep -r "import.*jnap/models" lib/page/instant_admin/views/
# Expected: 0 results ✅ (no changes to views)

# Verify Service layer has JNAP imports
grep -r "import.*jnap/models" lib/page/instant_admin/services/
# Expected: Results found ✅
```

**Final Gate Status**: ✅ **ALL GATES PASS** - Proceed to Phase 2 (tasks generation)

---

## Success Criteria Validation

| Criterion | Validation Method | Target |
|-----------|-------------------|--------|
| SC-001: No regression | Manual testing + existing integration tests | All functionality works |
| SC-002: Service coverage | `flutter test --coverage` for service | ≥90% |
| SC-003: Provider coverage | `flutter test --coverage` for provider | ≥85% |
| SC-004: Architecture compliance | `grep -r "import.*jnap/models" lib/page/*/providers/` | 0 results |
| SC-005: Separation of concerns | Code review | Service=logic, Notifier=state |
| SC-006: Test performance | `flutter test` execution time | <5 seconds |

---

## Quickstart

For developers implementing this refactoring, see [quickstart.md](./quickstart.md) for step-by-step instructions.

---

## Next Steps

1. ✅ **Phase 0 Complete**: Research and technical decisions documented
2. ✅ **Phase 1 Complete**: Design, contracts, and implementation sequence defined
3. ⏭️ **Phase 2**: Run `/speckit.tasks` to generate actionable task list
4. ⏭️ **Phase 3**: Run `/speckit.implement` to execute tasks

**Command**: `/speckit.tasks` (generate tasks.md from this plan)
