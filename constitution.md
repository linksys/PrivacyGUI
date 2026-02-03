# The Constitution of Linksys Flutter App Development

**Version:** 1.0
**Status:** Active
**Context:** Source of Truth for Architectural Discipline
**Ratified:** 2025-12-09
**Last Amended:** 2025-12-22

## Preamble
This document establishes the immutable principles governing the development process of the Linksys Flutter application. It serves as the architectural DNA of the system, ensuring consistency, simplicity, and quality across all implementations.

**Supremacy Clause:** These articles are non-negotiable and bind all AI agents and human developers. In the event of a conflict between this Constitution and any other project documentation, practice, or preference, **this Constitution shall supersede.**

---

## Article I: Test Requirement

**Section 1.1: Mandatory Test Coverage**
All business logic, state management, and service code MUST have corresponding unit tests. Test coverage is non-negotiable for production code.

**Section 1.2: Testing Standards**
All business logic, state management, and UI changes MUST have corresponding tests:
* **Unit tests** - Required for all Services and Providers before code review
* **Screenshot tests** - Required for UI changes (see `doc/screenshot_testing_guideline.md`)

**Refer to Article VIII: Testing Strategy for detailed testing strategies, tool usage, and organization methods.**

**Section 1.3: Test Scope Definition**

* ✅ Only test the scope of the current modification.
* ❌ Do not test the entire `lib/` directory.
* ❌ Do not test the entire `test/` directory.
* ❌ Do not fix unrelated lint warnings.
* Principle: Only write and execute tests for the current task; do not include other features.

**Test Scope Definition Examples**:

**Section 1.4: Expected Coverage**

| Level | Coverage | Description |
|:---|:---|:---|
| Service Layer | ≥90% | Most critical data layer |
| Provider Layer | ≥85% | Business logic coordination |
| State Layer | ≥90% | Data models must be complete |
| **Overall** | ≥80% | Weighted average |

**Measurement Tool**: Use `flutter test --coverage` to generate coverage reports.
**Failure to Meet Standards**: Explain the reason during code review; exemptions may be granted in special cases.

**Section 1.5: Test Organization**
Tests MUST be organized as follows:
* Unit tests:
  - Service tests: `test/page/[feature]/services/`
  - Provider tests: `test/page/[feature]/providers/`
* State tests: `test/page/[feature]/providers/` (same directory as Provider tests)
  - UI Model tests: `test/page/[feature]/models/` (only when there is an independent UI Model class)
* Mock classes: Created inline in test files or in `test/mocks/` for shared mocks
* Test data builders: `test/mocks/test_data/[feature_name]_test_data.dart`
* Screenshot tests: `test/page/[feature]/localizations/*_test.dart` (tool uses pattern `localizations/.*_test.dart`)
* Screenshot test tool: `dart tools/run_screenshot_tests.dart` automatically discovers all tests in `localizations/` subdirectories
* All test case names do not need numbering; they should only describe the purpose of the test.

**Section 1.6: Mock Creation**

**Section 1.6.1: Mock Classes (Mocktail)**

For Provider and Service mocking:
* Use Mocktail for creating mocks
* Create mock classes that extend the target class/interface with `Mock`
* For Riverpod Notifiers: `class MockNotifier extends Mock implements YourNotifier {}`
* For Services: `class MockService extends Mock implements YourService {}`
* Use `when(() => mock.method()).thenReturn(value)` for stubbing
* Use `verify(() => mock.method()).called(n)` for verification

**Section 1.6.2: Test Data Builder Pattern**

**Purpose**: To provide reusable JNAP mock responses for Service layer testing.

**File Organization**:
* Test data builders are unified in the `test/mocks/test_data/` directory.
* Naming convention: `[feature_name]_test_data.dart`.
* Class naming: `[FeatureName]TestData`.
* Do not create mock data temporarily when writing tests.
* If data adjustment is needed, use named parameters or the `copyWith()` method.

**Usage Scenarios**:
When testing a Service, the **return value of RouterRepository** (JNAP responses) is mocked, rather than the Service itself.

**Test Data Builder 範例**：
```dart
/// Test data builder for [FeatureName]Service tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class [FeatureName]TestData {
  /// Create default [SettingType]Success response
  static JNAPSuccess create[SettingType]Success({
    bool field1 = false,
    bool field2 = false,
    // ...
  }) => JNAPSuccess(
    result: 'ok',
    output: {
      'field1': field1,
      'field2': field2,
      // ...
    },
  );

  /// Create a complete successful JNAP transaction response
  ///
  /// Supports partial override design: only specify fields that need to change, others use default values.
  static JNAPTransactionSuccessWrap createSuccessfulTransaction({
    Map<String, dynamic>? setting1,
    Map<String, dynamic>? setting2,
  }) {
    // Define default values
    final defaultSetting1 = { /* ... */ };
    final defaultSetting2 = { /* ... */ };

    // Merge default and override values
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.getSetting1,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultSetting1, ...?setting1},
          ),
        ),
        MapEntry(
          JNAPAction.getSetting2,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultSetting2, ...?setting2},
          ),
        ),
      ],
    );
  }

  /// Create a partial error response (for error handling tests)
  static JNAPTransactionSuccessWrap createPartialErrorTransaction({
    required JNAPAction errorAction,
    String errorMessage = 'Operation failed',
  }) {
    // ... Returns a transaction containing an error
  }

  // Private helpers for default values
  static JNAPSuccess _createDefault[SettingType]() => JNAPSuccess(...);
}
```

**測試範例**：
```dart
// test/page/advanced_settings/dmz/services/dmz_service_test.dart
import 'package:test/mocks/test_data/dmz_test_data.dart';

void main() {
  late DMZService service;
  late MockRouterRepository mockRepo;

  setUp(() {
    mockRepo = MockRouterRepository();
    service = DMZService(mockRepo);
  });

  test('fetchSettings returns UI model on success', () async {
    // Arrange: Mock RouterRepository returns JNAP response
    when(() => mockRepo.send(any()))
        .thenAnswer((_) async => DMZTestData.createSuccessResponse());

    // Act: Call Service method
    final result = await service.fetchSettings();

    // Assert: Verify converted UI model
    expect(result, isA<DMZSettingsUIModel>());
  });
}
```

**Section 1.7: State Class and UI Model Testing**

Independent test files **MUST** be provided for State classes and UI Model classes used by Providers.

**Notes**:
* State class tests are located in the same `providers/` directory as Provider tests.
* Only independently created UI Model classes (names ending in `UIModel`) need to be placed in an independent `models/` directory.

---

## Article II: The Amendment Process

**Section 2.1: Stability of Principles**
The core principles of this constitution are intended to remain stable. However, evolution is permitted under strict governance.

**Section 2.2: Requirements for Modification**
Any modifications to this constitution require:
* Explicit documentation of the rationale for the change
* Review and approval by project maintainers
* A comprehensive assessment of backwards compatibility

---

## Article III: Naming Conventions

**Section 3.1: Basic Principles**
All names must comply with:
* **Descriptive** - Clearly express purpose and function.
* **Consistent** - Follow the project's unified pattern.
* **Explicit** - Avoid abbreviations unless they are widely understood terms (e.g., UI, ID, HTTP, JNAP, RA).

---

**Section 3.2: 檔案命名**

所有檔案必須使用 `snake_case`：

| 類型 | 命名模式 | 範例 |
|------|---------|------|
| Service | `[feature]_service.dart` | `auth_service.dart`, `dmz_service.dart` |
| Provider | `[feature]_provider.dart` | `auth_provider.dart`, `dmz_settings_provider.dart` |
| State | `[feature]_state.dart` | `auth_state.dart`, `dmz_settings_state.dart` |
| Model | 依照 class 名稱 | `dmz_settings.dart`, `dmz_ui_settings.dart` |
| Test | `[file_name]_test.dart` | `auth_service_test.dart` |
| Test Data Builder | `[feature]_test_data.dart` | `dmz_test_data.dart`, `auth_test_data.dart` |

**Note**: File names use the **singular** form (`service.dart`, not `services.dart`).

---

**Section 3.3: Class Naming**

All classes must use `UpperCamelCase`:

**3.3.1: Service Classes**
```dart
// 命名模式：[Feature]Service
class AuthService { ... }
class DMZService { ... }
class WirelessService { ... }
```

**3.3.2: Notifier Classes**
```dart
// 命名模式：[Feature]Notifier
class AuthNotifier extends AsyncNotifier<AuthState> { ... }
class DMZSettingsNotifier extends Notifier<DMZSettingsState> { ... }
```

**3.3.3: State Classes**
```dart
// 命名模式：[Feature]State
class AuthState extends Equatable { ... }
class DMZSettingsState extends FeatureState<DMZSettingsUIModel, DMZStatus> { ... }
```

**3.3.4: Model Classes**

**UI Models** (Presentation Layer):
```dart
// Naming pattern: [Feature][Type]UIModel (must end with UIModel)
class DMZSettingsUIModel extends Equatable { ... }
class WirelessConfigUIModel extends Equatable { ... }
class SpeedTestUIModel extends Equatable { ... }
class FirmwareUpdateUIModel extends Equatable { ... }
```

**Data Models** (JNAP/Cloud):
```dart
// Naming pattern: According to JNAP domain name
class DMZSettings extends Equatable { ... }  // JNAP model
class WirelessSettings extends Equatable { ... }
class DeviceInfo extends Equatable { ... }
```

**3.3.5: Error Classes**
```dart
// 命名模式：[Type]Error (final class extending sealed base)
sealed class AuthError { ... }

final class InvalidCredentialsError extends AuthError { ... }
final class NetworkError extends AuthError { ... }
final class StorageError extends AuthError { ... }
```

**3.3.6: Result/Response Classes**
```dart
// 命名模式：[Feature]Result<T> (sealed class with Success/Failure)
sealed class AuthResult<T> { ... }

final class AuthSuccess<T> extends AuthResult<T> { ... }
final class AuthFailure<T> extends AuthResult<T> { ... }
```

**3.3.7: Test Data Builder Classes**
```dart
// 命名模式：[Feature]TestData
class AuthTestData {
  static SessionToken createValidToken() => ...;
  static JNAPSuccess createSuccessResponse() => ...;
}

class DMZTestData {
  static JNAPSuccess createDMZSettingsSuccess() => ...;
}
```

**3.3.8: Mock Classes**
```dart
// 命名模式：Mock[ClassName]
class MockAuthService extends Mock implements AuthService {}
class MockRouterRepository extends Mock implements RouterRepository {}
class MockAuthNotifier extends Mock implements AuthNotifier {}
```

---

**Section 3.4: Provider Naming**

All providers must use `lowerCamelCase`:

**3.4.1: Service Providers**
```dart
// 命名模式：[feature]ServiceProvider
final authServiceProvider = Provider<AuthService>((ref) => ...);
final dmzServiceProvider = Provider<DMZService>((ref) => ...);
```

**3.4.2: State Notifier Providers**
```dart
// Naming pattern: [feature]Provider (no "Notifier" suffix required)
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() => ...);
final dmzSettingsProvider = NotifierProvider<DMZSettingsNotifier, DMZSettingsState>(() => ...);
```

**3.4.3: Simple Providers**
```dart
// 命名模式：descriptive name + Provider
final routerRepositoryProvider = Provider<RouterRepository>((ref) => ...);
final cloudRepositoryProvider = Provider<LinksysCloudRepository>((ref) => ...);
```

---

**Section 3.5: Directory Naming**

All directories must use `snake_case`:

**3.5.1: Feature Directory**
```
lib/page/advanced_settings/     # Singular or plural based on semantics
lib/page/instant_setup/
lib/page/health_check/
```

**3.5.2: Component Directory**
```
lib/page/[feature]/views/       # Plural - Container directory
lib/page/[feature]/providers/   # Plural - Container directory
lib/page/[feature]/services/    # Plural - Container directory
lib/page/[feature]/models/      # Plural - Container directory
```

**3.5.3: Test Directory**
```
test/page/[feature]/services/
test/page/[feature]/providers/
test/mocks/
test/mocks/test_data/
```

---

**Section 3.6: Test Naming**

**3.6.1: Test Case Naming**
```dart
// ✅ Correct: Describe test purpose, no numbering
test('cloudLogin returns success with valid credentials', () { ... });
test('localLogin handles invalid password', () { ... });
test('fetchSettings transforms JNAP model to UI model', () { ... });

// ❌ Incorrect: Use numbering
test('TC001: login test', () { ... });
test('Test case 1', () { ... });
```

**3.6.2: Test Group Naming**
```dart
// 命名模式：[ClassName] - [Feature/Category]
group('AuthService - Session Token Management', () { ... });
group('AuthNotifier - Cloud Login', () { ... });
group('DMZService - Settings Transformation', () { ... });
```

**3.6.3: Test File Organization**
```dart
// test/page/advanced_settings/dmz/services/dmz_service_test.dart
void main() {
  group('DMZService - fetchSettings', () {
    test('returns UI model on success', () { ... });
    test('throws ServiceError on JNAP failure', () { ... });
  });

  group('DMZService - saveSettings', () {
    test('transforms UI model to JNAP model', () { ... });
    test('persists settings via RouterRepository', () { ... });
  });
}
```

---

## Article IV: Operations & Deployment (Reserved)
*Reserved for future definition of deployment policies, CI/CD pipelines, and runtime observability requirements.*

---

## Article V: Simplicity and Minimal Structure

**Section 5.1: The Simplicity Gate**
Complexity must be justified. Implementations must avoid "future-proofing" for speculative requirements.

**Section 5.2: Feature Structure**
Each feature should follow a consistent, minimal structure:
* `lib/page/[feature]/views/` - UI components
* `lib/page/[feature]/providers/` - State management
* `lib/page/[feature]/services/` - Business logic (when needed)
* `lib/page/[feature]/models/` - UI models (when needed)

**Section 5.3: Architectural Layers and Separation of Concerns**

**Principle**: Strictly follow the three-tier architecture. The dependency direction must **always be downward**, and reverse dependencies are not allowed.

```
┌─────────────────────────────────┐
│  Presentation (UI/Pages)         │  ← Responsible only for display and user interaction
│  lib/page/*/views/              │
└────────────┬────────────────────┘
             │ Dependency
┌────────────▼────────────────────┐
│ Application (Business Logic Layer)│  ← State management and business logic
│  - lib/page/*/providers/        │  ← Notifiers (State Management)
│  - lib/page/*/services/         │  ← Services (Business Logic)
└────────────┬────────────────────┘
             │ Dependency
┌────────────▼────────────────────┐
│  Data (Data Layer)               │  ← Data acquisition, local storage, parsing
│  lib/core/jnap/, lib/core/cloud/│
└─────────────────────────────────┘
```

**Responsibilities of Each Layer**:
- **Presentation**: UI rendering, user input, state observation (access only Providers).
- **Application**:
  - **Providers (Notifiers)**: State management, user interaction coordination.
  - **Services**: Business logic, API communication, data transformation.
- **Data**: API calls (JNAP, Cloud), database access, data model definitions.

**Key Principle**: Different levels should use **different data models**, and the models for each layer should only be used in that layer and below.

**Section 5.3.1: Model Hierarchy Categorization**

```
┌─────────────────────────────────────────┐
│  Presentation Layer Models (UI Models)  │
│  - Used for UI display and user input     │
│  - ❌ Prohibition of direct dependency on JNAP Data Models │
└────────────────┬────────────────────────┘
                 │ Transformation
┌────────────────▼───────────────────────────┐
│  Application Layer Models (DTO/State)      │
│  - Business layer transformation models       │
│  - Bridge between Data Models and Presentation │
│  - Service layer performs Data Models ↔ UI Models transformation │
└────────────────┬───────────────────────────┘
                 │ Transformation
┌────────────────▼────────────────────────┐
│  Data Layer Models (Data Models)        │
│  - DMZSettings, DMZSourceRestriction    │
│  - Direct mapping of JNAP and API responses │
│  - ❌ Prohibition in Provider and UI layers │
└─────────────────────────────────────────┘
```

**Section 5.3.2: Common Violations and Fixes**

**Direct use of JNAP Models in Provider**

❌ **Violation**:
```dart
// lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';

class DMZSettingsNotifier extends Notifier<DMZSettingsState> {
  Future<void> performSave() async {
    final domainSettings = DMZSettings(...);  // ❌ Should not be here
    await repo.send(..., data: domainSettings.toMap());
  }
}
```

✅ **Fix**:
```dart
// lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart
class DMZSettingsNotifier extends Notifier<DMZSettingsState> {
  Future<void> performSave() async {
    final service = ref.read(dmzSettingsServiceProvider);
    await service.saveDmzSettings(ref, state.settings.current);  // UI Model
  }
}

// lib/page/advanced_settings/dmz/services/dmz_settings_service.dart
final dmzSettingsServiceProvider = Provider<DMZSettingsService>((ref) {
  return DMZSettingsService(ref.watch(routerRepositoryProvider));
});

class DMZSettingsService {
  final RouterRepository _routerRepository;

  DMZSettingsService(this._routerRepository);

  Future<void> saveDmzSettings(Ref ref, DMZSettingsUIModel settings) async {
    // Service layer is responsible for transformation between UI Model and Data Model (JNAP Data)
    final dataModel = DMZSettings(...);
    await _routerRepository.send(..., data: dataModel.toMap());
  }
}
```

**Section 5.3.3: Architecture Compliance Check**

After completing the work, execute the following checks:

```bash
# ═══════════════════════════════════════════════════════════════
# JNAP Models Tier Isolation Check
# ═══════════════════════════════════════════════════════════════

# 1️⃣ Check if JNAP models are still imported in the Provider layer
grep -r "import.*jnap/models" lib/page/*/providers/
# ✅ Should return 0 results

# 2️⃣ Check if JNAP models are still imported in the UI layer
grep -r "import.*jnap/models" lib/page/*/views/
# ✅ Should return 0 results

# 3️⃣ Check if Service layer has correct JNAP imports
grep -r "import.*jnap/models" lib/page/*/services/
# ✅ Should have results (Service layer should import JNAP models)

# ═══════════════════════════════════════════════════════════════
# Error Handling Tier Isolation Check (Article XIII)
# ═══════════════════════════════════════════════════════════════

# 4️⃣ Check if Provider layer has JNAPError or jnap_result imports
grep -r "import.*jnap/result" lib/page/*/providers/
grep -r "on JNAPError" lib/page/*/providers/
# ✅ Should return 0 results

# 5️⃣ Check if Service layer correctly imports ServiceError
grep -r "import.*core/errors/service_error" lib/page/*/services/
# ✅ Should have results (Service layer should import ServiceError)
```

**Section 5.3.4: UI Model Creation Decision Criteria**

**Principle**: Not all states require a standalone UI Model. Create a UI Model only when necessary to avoid over-engineering.

**Situations requiring a standalone UI Model**:

1. **Collection/List Data**
   - When a state needs to store `List<Something>`, Something should be a UI Model.
   - Example: `List<FirmwareUpdateUIModel>` (multiple node statuses), `List<SpeedTestUIModel>` (historical records).

2. **Data Reusability**
   - The same data structure is used in multiple places (list items, detail pages, popups, different state fields).
   - Example: `SpeedTestUIModel` in `HealthCheckState` is used for `result`, `latestSpeedTest`, and `historicalSpeedTests`.

3. **Complex Nested Structures**
   - The data itself contains multiple levels of nested objects (>5 fields or nesting).
   - Avoid states becoming too complex and difficult to maintain.

4. **Contains Calculation Logic or Formatting Methods**
   - UI Models can encapsulate getters, formatting methods, and validation logic.
   - Example: `speedTest.formattedDownloadSpeed`, `node.updateProgressPercentage`.

**Situations NOT requiring a standalone UI Model**:

1. **Flat Primitive Types**
   - Only basic fields like String, int, bool, enum, etc.
   - Example: `RouterPasswordState` (isDefault, isSetByUser, adminPassword, hint, etc.).

2. **Simple One-to-One Mapping**
   - Direct mapping from Service/JNAP data to state without complex transformation.

**Decision Flowchart**:
```
Is a standalone UI Model needed?
├─ Is it collection/list data? → YES → Use UI Model
├─ Will data be reused in multiple places? → YES → Use UI Model
├─ Is the data structure complex (>5 fields or nesting)? → YES → Consider UI Model
├─ Need to encapsulate business logic/computed properties? → YES → Use UI Model
└─ Otherwise → Use primitive types directly in State
```

**Practical Examples Comparison**:

✅ **No UI Model Needed** (`RouterPasswordState`):
```dart
class RouterPasswordState {
  final bool isDefault;           // Primitive type
  final bool isSetByUser;         // Primitive type
  final String adminPassword;     // Primitive type
  final String hint;              // Primitive type
  final int? remainingErrorAttempts;
  // Flat structure, no reuse requirement
}
```

✅ **UI Model Needed** (`HealthCheckState`):
```dart
class HealthCheckState {
  final SpeedTestUIModel? result;              // Reuse 1
  final SpeedTestUIModel? latestSpeedTest;     // Reuse 2
  final List<SpeedTestUIModel> historicalSpeedTests;  // Reuse 3 + Collection
  // SpeedTestUIModel is reused in multiple places and contains complex test data
}
```

✅ **UI Model Needed** (`FirmwareUpdateState`):
```dart
class FirmwareUpdateState {
  final List<FirmwareUpdateUIModel>? nodesStatus;  // Collection type
  // Each node is an independent entity with its own status, progress, and error message
}
```

**Section 5.4: Avoid Over-Engineering**
Do not create abstractions, interfaces, or layers until there is a concrete need. Start simple and refactor when patterns emerge.

---

## Article VI: The Service Layer Principle

**Section 6.1: Service Layer Mandate**
Complex business logic and external communication (JNAP protocol, Cloud APIs) MUST be encapsulated in Service classes. Services act as the bridge between Providers and external systems.

**Section 6.2: Service Responsibilities**
Services SHALL:
* Handle all JNAP API communication
* Implement business logic and data transformations
* Return domain/UI models, not raw API responses
* Be stateless (no internal state management)
* Accept dependencies via constructor injection

Services SHALL NOT:
* Manage UI state (use Providers for this)
* Directly call other services (compose via Providers)
* Handle navigation or UI concerns

**Section 6.3: File Organization**
Services MUST be organized as follows:
* Location: `lib/page/[feature]/services/`
* Folder: `services/` (plural folder name)
* File naming: Follow **Article III Section 3.2** (files use `snake_case`)
* Provider naming: Follow **Article III Section 3.4.1** (providers use `lowerCamelCase`)
* Provider type: Use `Provider<T>` (stateless, NOT `NotifierProvider` or `StateNotifierProvider`)
* Dependencies: Inject via `ref.watch()` in the provider definition
**Reference implementation:** `lib/page/instant_admin/services/router_password_service.dart`

**Section 6.4: Provider-Service Separation**
Clear separation of concerns MUST be maintained:

**Providers** (State Management):
* Manage UI state using Riverpod Notifiers
* Handle user interactions and lifecycle
* Call Service methods
* Transform service results into state updates
* Location: `lib/page/[feature]/providers/`

**Services** (Business Logic):
* Handle business logic and orchestration
* Communicate with JNAP API via RouterRepository
* Transform API data to UI models
* Provide pure, testable functions
* Location: `lib/page/[feature]/services/`

**Section 6.5: Testing Requirements**
Services MUST have unit tests that:
* Mock the RouterRepository and other dependencies
* Verify data transformations (JNAP models → UI models)
* Test error handling paths

**Test organization:** `test/page/[feature]/services/`

**Refer to Article VIII Section 8.2 (Unit Testing) for a detailed testing strategy.**

**Section 6.6: Reference Implementations**
See these existing services as examples:
* `lib/page/health_check/services/health_check_service.dart`
* `lib/page/instant_setup/services/pnp_service.dart`
* `lib/page/vpn/service/vpn_service.dart`

**Section 6.7: Distinction from Article VII**
The Service layer is a LEGITIMATE abstraction that:
* Adds semantic value by encapsulating business logic
* Provides testable interfaces
* Separates concerns between state and business logic
* Is NOT a wrapper around framework features (Article VII prohibits framework wrappers)

---

## Article VII: The Anti-Abstraction Principle

**Section 7.1: Framework Trust**
Developers and Agents MUST use framework features directly. Creating wrappers around standard framework functionality is prohibited unless strictly necessary for cross-platform compatibility.

Examples of PROHIBITED abstractions:
* Wrapping Flutter's Navigator with a custom navigation class
* Creating unnecessary wrappers around http.Client
* Reimplementing Riverpod's provider system

**Section 7.2: Legitimate Abstractions**
The following abstractions ARE permitted and encouraged:
* **Service layer classes for business logic** (see Article VI)
* JNAP protocol abstractions for router communication
* RouterRepository for centralizing JNAP command execution
* Data transformation functions that add semantic value

**Section 7.3: Data Representation**

**Consistent within layers, transformation between layers:**
- ✅ Within the same layer: Avoid creating redundant models with the same semantic meaning.
- ✅ Between layers: Must use different models, transformed by the Service layer.
- ❌ Prohibited: Defining multiple redundant DTOs within the same layer.

**Example:**
```dart
// ✅ Correct: Use different models across layers
// Data Layer
class DMZSettings { ... }  // JNAP model

// Application Layer (Service transformation)
DMZSettingsUIModel convertToUI(DMZSettings data) => ...

// Presentation Layer
class DMZSettingsUIModel { ... }  // UI model

// ❌ Incorrect: Redundant within the same layer
class DMZSettings1 { ... }
class DMZSettings2 { ... }  // Semantically identical to DMZSettings1
```

**Refer to Article V Section 5.3.1 (Cross-tier Model Transformation Specification) for detailed explanation.**

---

## Article VIII: Testing Strategy

**Section 8.1: Test Pyramid Approach**
Follow a balanced testing strategy:
* **Many fast unit tests** - Test Services and Providers in isolation with mocks
* **Moderate screenshot tests** - Verify UI rendering with golden files

**Section 8.2: Unit Testing**
Unit tests MUST:
* **Provided for all Services and Providers** before code review
* **Mock external dependencies** (RouterRepository, other services) using Mocktail
* **Test business logic in isolation** - No network calls, no real storage operations
* **Be fast and deterministic** - No flaky tests, no time-dependent assertions

**Mocking Requirements:**
* Use Mocktail for all mocks (see Article I Section 1.6.1 for detailed patterns)
* Mock RouterRepository when testing Services
* Mock Services when testing Providers
* Use Test Data Builders for JNAP responses (see Article I Section 1.6.2)

**Section 8.3: Screenshot Testing**

**When Required:**
* Screenshot tests (golden files) MUST be provided for all UI changes
* Required before code review to verify visual consistency

**File Organization:**
* MUST be placed in `test/page/**/localizations/` directories
* File path pattern: `localizations/.*_test.dart`
* The tool `dart tools/run_screenshot_tests.dart` automatically discovers tests by scanning for `localizations/` subdirectories

**Implementation Requirements:**
* Use `testLocalizations` helper function
* Wrap widgets with `testableSingleRoute` or `testableRouteShellWidget`
* Follow guidelines in `doc/screenshot_testing_guideline.md`

**Execution:**
Run `dart tools/run_screenshot_tests.dart` with optional flags:
* `-c` - Customization mode (enables language and resolution selection)
* `-l` - Languages (e.g., `en,zh`)
* `-s` - Screen resolutions (e.g., `480,1280`)
* `-f` - Filter specific test files by keyword
* Default (without `-c`): runs with `en` language and `480,1280` resolutions

---

## Article IX: Documentation Standards

**Section 9.1: API Contract Documentation**
API contracts and interface specifications MUST be documented in Markdown (.md) format, not as executable code files.

**Section 9.2: Contract File Format**
Contract documentation SHALL:
* Use `.md` file extension for clarity that they are documentation, not code
* Be stored in `specs/[feature-id]/contracts/` directories
* Include method signatures, parameter descriptions, return types, and usage examples
* Use Markdown code blocks for code examples
* NOT be written as `.dart` files, even if they contain Dart code examples

**Section 9.3: Rationale**
Contract files serve as specification documents, not executable code:
* Markdown format clearly indicates the file is documentation
* `.dart` files may be mistaken for executable source code
* Markdown provides better formatting options for documentation
* IDEs and tools handle documentation differently from source code

**Section 9.4: Examples**
* ✅ Acceptable: `specs/001-auth-service-extraction/contracts/auth_service_contract.md`
* ❌ Prohibited: `specs/001-auth-service-extraction/contracts/auth_service_contract.dart`

---

## Article X: Code Review Standards

**Section 10.1: 評審檢查清單**

**Lint 與格式檢查**:
- ✅ `flutter analyze` 整個專案無錯誤（不引入新問題）
- ✅ 只針對修改的檔案執行 `dart format`，需符合格式規範

**測試與覆蓋**:
- ✅ 新增/修改的代碼有對應單元測試
- ✅ 測試覆蓋率達標 (Service ≥90%, Provider ≥85%, 整體 ≥80%)

**代碼品質**:
- ✅ 遵守三層架構，無跨層依賴
- ✅ Public APIs 有 DartDoc 註解
- ✅ 邊界情況處理完善（null 檢查、錯誤處理）

**兼容性**:
- ✅ 所有現有測試通過

---

## Article XI: Data Models

**Section 11.1: Model 強制要求**

所有 Models（Data Models、UI Models、State 等）**必須**:
1. ✅ 實作 `Equatable` 接口
2. ✅ 提供 `toJson()` 和 `fromJson()` 方法
3. ✅ 提供 `toMap()` 和 `fromMap()` 方法
4. ✅ 可選：使用 `freezed` 或 `json_serializable` 進行代碼生成

---

## Article XII: State Management with Riverpod

**Section 12.1: Riverpod 使用原則**

**原則**:
- ✅ 使用 Riverpod 管理所有可變狀態
- ✅ 使用 `Notifier` 進行狀態操作

**Section 12.2: Notifier 職責定義**

**Notifier 職責**:
- 只做**業務邏輯協調** (不涉及 API 細節)
- **依賴** Service/Repository (不直接依賴底層 API)
- **不涉及** UI 層決策（如導航、Toast）

**正確範例**:
```dart
class MyFeatureNotifier extends Notifier<MyFeatureState> {
  @override
  MyFeatureState build() => MyFeatureState.initial();

  Future<void> loadData() async {
    final service = ref.read(myFeatureServiceProvider);
    final result = await service.fetchData();

    state = state.copyWith(
      data: result,
      isLoading: false,
    );
  }
}
```

**Section 12.3: Dirty Guard 功能**

**使用場景**: 當開發者要求實作 Dirty Guard 功能時，參考以下說明

**實作方式**:
- 使用 `PreservableNotifierMixin` 混入 Notifier class
- State 需繼承 `FeatureState<Settings, Status>`
- 實作 `performFetch()` 和 `performSave()` 方法

**參考範例**:
- `lib/page/instant_privacy/providers/instant_privacy_provider.dart`
- `lib/providers/notifier_mixin.dart` (PreservableNotifierMixin definition)

**詳細指南**: `doc/dirty_guard/dirty_guard_framework_guide.md`

**路由配置**:
```dart
LinksysRoute(
  path: 'feature',
  builder: (context, state) => const FeatureView(),
  preservableProvider: featureProvider,  // 指定要檢查的 provider
  enableDirtyCheck: true,  // 啟用 dirty guard
)
```

---

## Article XIII: Error Handling Strategy

**Section 13.1: 統一錯誤處理原則**

**原則**: 所有來自資料層的錯誤（JNAP、Cloud API、未來資料系統）必須在 Service 層轉換為統一的 `ServiceError` 類型，Provider 層不得直接處理資料層特定的錯誤類型。

**目的**:
- **隔離資料層實作**: 當更換資料來源時（如 JNAP → 新系統），只需修改 Service 層
- **Type-safe 錯誤處理**: 使用 sealed class 提供編譯時檢查和窮盡性驗證
- **一致的錯誤契約**: Provider 和 UI 層使用統一的錯誤介面

---

**Section 13.2: ServiceError 定義**

**檔案位置**: `lib/core/errors/service_error.dart`

**結構**:
```dart
sealed class ServiceError implements Exception {
  const ServiceError();
}

// 各類錯誤繼承 ServiceError
final class InvalidAdminPasswordError extends ServiceError {
  const InvalidAdminPasswordError();
}

final class InvalidResetCodeError extends ServiceError {
  final int? attemptsRemaining;  // 可攜帶額外資訊
  const InvalidResetCodeError({this.attemptsRemaining});
}

final class UnexpectedError extends ServiceError {
  final Object? originalError;
  final String? message;
  const UnexpectedError({this.originalError, this.message});
}
```

**新增錯誤類型**: 如需新增錯誤類型，必須在 `service_error.dart` 中定義，遵循 `[ErrorType]Error` 命名規範。

---

**Section 13.3: Service 層錯誤處理**

**職責**: Service 層負責捕獲所有資料層錯誤並轉換為 `ServiceError`。

**正確範例**:
```dart
// lib/page/instant_admin/services/router_password_service.dart
Future<Map<String, dynamic>> verifyRecoveryCode(String code) async {
  try {
    await _routerRepository.send(JNAPAction.verifyRouterResetCode, ...);
    return {'isValid': true};
  } on JNAPError catch (e) {
    // ✅ 在 Service 層轉換為 ServiceError
    throw _mapJnapError(e);
  }
}

ServiceError _mapJnapError(JNAPError error) {
  return switch (error.result) {
    'ErrorInvalidResetCode' => InvalidResetCodeError(
        attemptsRemaining: _parseAttempts(error),
      ),
    'ErrorAdminAccountLocked' => const AdminAccountLockedError(),
    'ErrorInvalidAdminPassword' => const InvalidAdminPasswordError(),
    _ => UnexpectedError(originalError: error),
  };
}
```

**錯誤範例**:
```dart
// ❌ 錯誤：直接 rethrow JNAPError
Future<void> someMethod() async {
  try {
    await _routerRepository.send(...);
  } on JNAPError {
    rethrow;  // ❌ 不應該讓 JNAPError 洩漏到 Provider 層
  }
}
```

---

**Section 13.4: Provider 層錯誤處理**

**職責**: Provider 層只處理 `ServiceError` 類型，不得 import 或處理 JNAP 相關錯誤。

**正確範例**:
```dart
// lib/page/instant_admin/providers/router_password_provider.dart
import 'package:privacy_gui/core/errors/service_error.dart';

Future<bool> checkRecoveryCode(String code) async {
  try {
    final result = await service.verifyRecoveryCode(code);
    return result['isValid'];
  } on InvalidResetCodeError catch (e) {
    // ✅ 處理 ServiceError 子類
    state = state.copyWith(remainingAttempts: e.attemptsRemaining);
    return false;
  } on AdminAccountLockedError {
    // ✅ 處理 ServiceError 子類
    state = state.copyWith(isLocked: true);
    return false;
  } on ServiceError catch (e) {
    // ✅ 處理其他 ServiceError
    logger.e('Unexpected error: $e');
    return false;
  }
}
```

**錯誤範例**:
```dart
// ❌ 錯誤：Provider 直接處理 JNAPError
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

Future<bool> checkRecoveryCode(String code) async {
  try {
    ...
  } on JNAPError catch (e) {  // ❌ 不應該在 Provider 層出現
    if (e.result == 'ErrorInvalidResetCode') { ... }
  }
}
```

---

**Section 13.5: 未來資料來源遷移**

當更換資料來源（如 JNAP → 新系統）時：

| 層級 | 影響 |
|-----|------|
| **ServiceError** | ✅ 不變（契約/介面） |
| **Service 實作** | ⚠️ 修改 error mapping 邏輯 |
| **Provider** | ✅ 不變 |
| **UI** | ✅ 不變 |

**範例**:
```dart
// 未來：新資料系統的 error mapping
ServiceError _mapNewSystemError(NewSystemError error) {
  return switch (error.code) {
    ErrorCode.invalidCode => InvalidResetCodeError(...),
    ErrorCode.accountLocked => const AdminAccountLockedError(),
    _ => UnexpectedError(originalError: error),
  };
}
```

---

**Version**: 1.0.0 | **Ratified**: 2025-12-09 | **Last Amended**: 2025-12-17
