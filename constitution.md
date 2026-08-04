# The Constitution of Linksys Flutter App Development

**Version:** 2.0
**Status:** Active
**Context:** Source of Truth for Architectural Discipline
**Ratified:** 2025-12-09
**Last Amended:** 2026-07-28

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
* **Screenshot tests** - Deferred for USP pages until UI design is finalized and approved. Not currently required for `lib/page/`. UI Kit components have their own widget tests.

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

**Purpose**: To provide reusable USP codegen model instances for Service layer testing.

**File Organization**:
* Test data builders are unified in the `test/mocks/test_data/` directory.
* Naming convention: `[feature_name]_test_data.dart`.
* Class naming: `[FeatureName]TestData`.
* Do not create mock data temporarily when writing tests.
* If data adjustment is needed, use named parameters or the `copyWith()` method.

**Usage Scenarios**:
When testing a Service, **`UspService` is mocked** and the generated codegen API methods return pre-built model instances from the Test Data Builder, rather than mocking the Service itself.

**Test Data Builder Example**:
```dart
/// Test data builder for [FeatureName]Service tests
///
/// Provides factory methods to create USP codegen model instances with sensible defaults.
/// This centralizes test data and makes tests more readable.
class [FeatureName]TestData {
  /// Create a default [CodengenModel] instance
  static [CodengenModel] create[FeatureName]({
    String field1 = 'value',
    bool field2 = false,
    // ...
  }) => [CodengenModel](
    field1: field1,
    field2: field2,
    // ...
  );
}
```

**Test Example**:
```dart
// test/page/wifi/services/wifi_service_test.dart
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:test/mocks/test_data/wifi_test_data.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late WifiService service;
  late MockUspService mockUsp;

  setUp(() {
    mockUsp = MockUspService();
    service = WifiService(mockUsp);
  });

  test('fetchSettings returns UI model on success', () async {
    // Arrange: Mock UspService so codegen fetch returns a pre-built model
    when(() => WifiSsids.fetch(mockUsp))
        .thenAnswer((_) async => WifiTestData.createWifiSsids());

    // Act: Call Service method
    final result = await service.fetchSettings();

    // Assert: Verify converted UI model
    expect(result, isA<WifiSettingsUIModel>());
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
* **Explicit** - Avoid abbreviations unless they are widely understood terms (e.g., UI, ID, HTTP, USP, SSE).

---

**Section 3.2: File Naming**

All files MUST use `snake_case`:

| Type | Naming Pattern | Example |
|------|---------|------|
| Service | `[feature]_service.dart` | `auth_service.dart`, `dmz_service.dart` |
| Provider | `[feature]_provider.dart` | `auth_provider.dart`, `dmz_settings_provider.dart` |
| State | `[feature]_state.dart` | `auth_state.dart`, `dmz_settings_state.dart` |
| Model | Based on class name | `dmz_settings.dart`, `dmz_ui_settings.dart` |
| Test | `[file_name]_test.dart` | `auth_service_test.dart` |
| Test Data Builder | `[feature]_test_data.dart` | `dmz_test_data.dart`, `auth_test_data.dart` |

**Note**: File names use the **singular** form (`service.dart`, not `services.dart`).

---

**Section 3.3: Class Naming**

All classes must use `UpperCamelCase`:

**3.3.1: Service Classes**
```dart
// Naming pattern: [Feature]Service
class AuthService { ... }
class DMZService { ... }
class WirelessService { ... }
```

**3.3.2: Notifier Classes**
```dart
// Naming pattern: [Feature]Notifier
class AuthNotifier extends AsyncNotifier<AuthState> { ... }
class DMZSettingsNotifier extends Notifier<DMZSettingsState> { ... }
```

**3.3.3: State Classes**
```dart
// Naming pattern: [Feature]State
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

**Generated Models** (USP Codegen, `lib/generated/*.g.dart`):
```dart
// Naming pattern: According to TR-181 object name, generated by usp-codegen
class WiFiRadios { ... }    // generated from Device.WiFi.Radio.{i}.
class WifiSsids { ... }     // generated from Device.WiFi.SSID.{i}.
class DeviceInfo { ... }    // generated from Device.DeviceInfo.
```

**3.3.5: Error Classes**
```dart
// Naming pattern: [Type]Error (final class extending the sealed ServiceError)
// See Article XIII for the unified error hierarchy.
final class InvalidCredentialsError extends ServiceError { ... }
final class NetworkError extends ServiceError { ... }
final class StorageError extends ServiceError { ... }
```

**3.3.6: Result/Response Classes**
```dart
// Naming pattern: [Feature]Result<T> (sealed class with Success/Failure)
sealed class AuthResult<T> { ... }

final class AuthSuccess<T> extends AuthResult<T> { ... }
final class AuthFailure<T> extends AuthResult<T> { ... }
```

**3.3.7: Test Data Builder Classes**
```dart
// Naming pattern: [Feature]TestData
class AuthTestData {
  static SessionToken createValidToken() => ...;
}

class WifiTestData {
  static WifiSsids createWifiSsids() => ...;
}
```

**3.3.8: Mock Classes**
```dart
// Naming pattern: Mock[ClassName]
class MockAuthService extends Mock implements AuthService {}
class MockUspService extends Mock implements UspService {}
class MockAuthNotifier extends Mock implements AuthNotifier {}
```

---

**Section 3.4: Provider Naming**

All providers must use `lowerCamelCase`:

**3.4.1: Service Providers**
```dart
// Naming pattern: [feature]ServiceProvider
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
// Naming pattern: descriptive name + Provider
final uspServiceProvider = Provider<UspService>((ref) => ...);
final cloudRepositoryProvider = Provider<LinksysCloudRepository>((ref) => ...);
```

---

**Section 3.5: Directory Naming**

All directories must use `snake_case`:

**3.5.1: Feature Directory**
```
lib/page/dashboard/
lib/page/wifi/
lib/page/devices/
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

**3.5.4: Special Directories**

Two special infrastructure directories exist outside the normal feature structure. They are not feature pages.

**`lib/framework/`** — Provides the base infrastructure (`FeatureState`, `Preservable`, `PreservableNotifierMixin`) used by all Type A and Type B feature pages. Do not add feature-specific code here.

**`lib/page/_shared/`** — Holds assets shared across multiple feature modules. See **Article V Section 5.3** for usage rules.

---

**Section 3.6: Test Naming**

**3.6.1: Test Case Naming**
```dart
// ✅ Correct: Describe test purpose, no numbering
test('cloudLogin returns success with valid credentials', () { ... });
test('localLogin handles invalid password', () { ... });
test('fetchSettings transforms codegen model to UI model', () { ... });

// ❌ Incorrect: Use numbering
test('TC001: login test', () { ... });
test('Test case 1', () { ... });
```

**3.6.2: Test Group Naming**
```dart
// Naming pattern: [ClassName] - [Feature/Category]
group('AuthService - Session Token Management', () { ... });
group('AuthNotifier - Cloud Login', () { ... });
group('DMZService - Settings Transformation', () { ... });
```

**3.6.3: Test File Organization**
```dart
// test/page/wifi/services/wifi_service_test.dart
void main() {
  group('WifiService - fetchSettings', () {
    test('returns UI model on success', () { ... });
    test('throws ServiceError on USP error', () { ... });
  });

  group('WifiService - updateSsid', () {
    test('transforms UI model to codegen update', () { ... });
    test('calls UspService with correct parameters', () { ... });
  });
}
```

---

## Article IV: USP Provider Architecture

**Section 4.1: Two-Tier Provider Taxonomy**

USP pages follow a two-tier provider structure. Each tier has distinct responsibilities, lifecycle, and codegen import rules.

| Tier | Role | Lifecycle | Codegen Import |
|------|------|-----------|----------------|
| **L1 Domain Data Provider** | Session-wide cache: holds UI models, responds to SSE invalidation | **NOT autoDispose** | ❌ Prohibited |
| **L2 Feature Page Provider** | Holds editable working copy; coordinates save/revert | **AutoDispose** | ❌ Prohibited |

**L1 Service Layer**: Each L1 provider delegates codegen calls to a dedicated **L1 Service** (`Provider<T>`, stateless). The L1 Service owns all codegen fetch calls, error mapping (`mapUspErrorToServiceError`), and codegen→UI model transformation. This ensures that codegen types and `usp_error.dart` are confined to the Service layer.

```
L1 Provider  →  L1 Service  →  Codegen (lib/generated/)
                    ↑
              mapUspErrorToServiceError here
```

**L2 Immediate Mutations**: When Dashboard cards or other non-page views need to perform single-operation mutations (toggle, add, delete), they call **`immediate*` methods** on the L2 Notifier. These methods delegate to the L2 Service, then `ref.invalidate()` the corresponding L1 provider. This is distinct from the batch Save mode used on feature pages.

**Key Principle**: L1 and L2 serve different purposes:
- **L1** → Persistent session cache: shared across features, SSE target, no redundant re-fetches
- **L2** → Editable working copy: isolated per page, discarded when the page closes

---

**Section 4.2: Page Type Classification**

Before implementing a feature page, determine its type using the following decision tree:

```
Does the page have an edit form (fields or list) + Save/Cancel?
├── YES → Is the user editing a list (add/edit/delete items)?
│         ├── YES → Type B: CRUD List
│         └── NO  → Type A: Form
└── NO  → Type C: Read-Only / Toggle
```

**Type A — Form**

For pages with fixed editable fields and a single Save operation.

- State: `FeatureState<{Domain}Settings, {Domain}Status>`
- Mutations: `updateSetting({UIModel} Function({UIModel}) fn)`
- Save: `Service.update(current)` (direct)
- Requires L2: ✅ | Dirty Guard: ✅

Examples: DMZ, Firewall, WiFi Settings, Internet Settings

**Type B — CRUD List**

For pages where users add/edit/delete list items, saved all at once.

- State: `FeatureState<{Item}UIList, {Domain}ListStatus>`
- Mutations: `addItem()` / `editItem()` / `deleteItem()`
- Save: diff(original, current) → `addMultiple` + `set` + `delete`
- New item identification: `instancePath == null` (not yet written to router)
- Requires L2: ✅ | Dirty Guard: ✅

Examples: Port Forwarding, DHCP Reservations, Static Routing

**Type C — Read-Only / Toggle**

For display-only pages or instant-effect operations with no Save/Cancel flow.

- View consumes L1 directly: `ref.watch({domain}DataProvider)`
- Requires L2: ❌ — do not create an unnecessary L2 provider

Examples: System Info, WAN Status, Time Settings

**Dirty Guard Implementation (Type A and Type B)**:
- Use `PreservableAutoDisposeNotifierMixin` with the Notifier class
- State MUST extend `FeatureState<TSettings, TStatus>`
- Implement `performFetch()` and `performSave()` template methods
- Expose `preservableProvider` for route dirty check:

```dart
final preservable{Domain}Provider =
    AutoDisposeProvider<PreservableContract<{Domain}Settings, {Domain}Status>>(
  (ref) => ref.watch(usp{Domain}Provider.notifier),
);
```

**Route Configuration**:
```dart
LinksysRoute(
  path: '{domain}',
  builder: (context, state) => const {Domain}View(),
  enableDirtyCheck: true,
  preservableProvider: preservable{Domain}Provider,
)
```

Reference implementation: `lib/page/dmz/providers/usp_dmz_notifier.dart`
Detailed Guide: `doc/dirty_guard/dirty_guard_framework_guide.md`

---

**Section 4.3: Hard Rules**

The following rules are non-negotiable for all USP provider implementations:

**Rule 1: L1 Data Providers MUST NOT be `autoDispose`**

L1 Data Providers are the single source of truth for the entire connected session. They must persist for the app lifetime so that multiple features can share the same cached data, SSE updates have a stable target, and re-navigating to a page does not trigger redundant re-fetches.

```dart
// ✅ Correct
final xxxDataProvider = AsyncNotifierProvider<XxxDataNotifier, XxxData>(...);

// ❌ Wrong
final xxxDataProvider = AsyncNotifierProvider.autoDispose<XxxDataNotifier, XxxData>(...);
```

**Rule 2: L2 Notifiers MUST use `ref.read` (not `ref.watch`) when reading from L1**

`ref.watch` in `performFetch()` causes SSE updates to directly overwrite the user's in-progress edits. SSE updates must flow through the `onSseInvalidation()` dirty guard path instead.

```dart
// ✅ Correct — one-time clone, no live tracking
final data = await ref.read(xxxDataProvider.future);

// ❌ Wrong — SSE will silently overwrite user edits
final data = await ref.watch(xxxDataProvider.future);
```

**Rule 3: All mutations MUST go through `uspMutationLockProvider.withLock()`**

The WASM USP client does not support concurrent calls. All write operations (add, update, delete) MUST acquire the global mutation lock.

```dart
await ref.read(uspMutationLockProvider).withLock(() async {
  await _svc.save(current);
});
```

**Rule 4: `PreservableContract` MUST NOT be duplicated**

`lib/framework/preservable_contract.dart` is the single definition of `PreservableContract`. All features MUST import it from this location. Duplicating the class elsewhere creates a type incompatibility that silently breaks `LinksysRoute`'s dirty check at runtime.

```dart
// ✅ Correct — import from the single source of truth
import 'package:privacy_gui/framework/preservable_contract.dart';

// ❌ Wrong — re-defining the class creates an incompatible type
class PreservableContract<T, S> { ... }
```

---

## Article V: Simplicity and Minimal Structure

**Section 5.1: The Simplicity Gate**
Complexity must be justified. Implementations must avoid "future-proofing" for speculative requirements.

**Section 5.2: Avoid Over-Engineering**
Do not create abstractions, interfaces, or layers until there is a concrete need. Start simple and refactor when patterns emerge.

**Section 5.3: Feature Structure**

The overall structure is:

```
lib/
├── framework/           # Infrastructure (FeatureState, Preservable, mixins)
└── page/
    ├── _shared/             # Cross-module shared assets
    │   ├── models/          # UI models used by 2+ feature modules
    │   ├── components/      # UI components used by 2+ feature modules
    │   ├── services/        # Services used by 2+ feature modules
    │   └── providers/       # Providers used by 2+ feature modules
    ├── dashboard/           # Dashboard page (orchestrator, cards)
    └── [feature]/           # Feature modules
        ├── views/
        ├── providers/
        ├── services/
        └── models/
```

Each feature module should follow a consistent, minimal structure:
* `lib/page/[feature]/views/` - UI components
* `lib/page/[feature]/providers/` - State management
* `lib/page/[feature]/services/` - Business logic (when needed)
* `lib/page/[feature]/models/` - UI models (when needed)

**`_shared/` Usage Rule**: Code belongs in `lib/page/_shared/` only when it is referenced by **two or more unrelated feature modules**. Do not move code to `_shared/` preemptively — wait until the second consumer exists.

**Section 5.4: Architectural Layers and Separation of Concerns**

**Principle**: Strictly follow the three-tier architecture. The dependency direction must **always be downward**, and reverse dependencies are not allowed.

```
┌─────────────────────────────────┐
│  Presentation (UI/Pages)        │  ← Responsible only for display and user interaction
│  lib/page/*/views/          │
└────────────┬────────────────────┘
             │ Dependency
┌────────────▼────────────────────┐
│ Application (Business Logic Layer)│  ← State management and business logic
│  - lib/page/*/providers/    │  ← Notifiers (State Management)
│  - lib/page/*/services/     │  ← Services (Business Logic)
└────────────┬────────────────────┘
             │ Dependency
┌────────────▼────────────────────┐
│  Data (Data Layer)               │  ← USP protocol communication, local storage
│  lib/generated/*.g.dart          │  ← usp-codegen generated API
│  lib/core/usp/                        │  ← UspService, transport layer
└─────────────────────────────────┘
```

**Responsibilities of Each Layer**:
- **Presentation**: UI rendering, user input, state observation (access only Providers).
- **Application**:
  - **Providers (Notifiers)**: State management, user interaction coordination.
  - **Services**: Business logic, data transformation (generated models → UI models).
- **Data**: Execute data operations via codegen API (`lib/generated/*.g.dart`); the underlying transport uses `UspService` for USP protocol communication with the router.

**Key Principle**: Different levels should use **different data models**, and the models for each layer should only be used in that layer and below.

**Section 5.4.1: Model Hierarchy Categorization**

```
┌─────────────────────────────────────────┐
│  Presentation Layer Models (UI Models)  │
│  - Used for UI display and user input     │
│  - ❌ Prohibition of direct dependency on Generated Models │
└────────────────┬────────────────────────┘
                 │ Transformation
┌────────────────▼───────────────────────────┐
│  Application Layer Models (DTO/State)      │
│  - Business layer transformation models       │
│  - Bridge between Generated Models and Presentation │
│  - Service layer performs Generated Models ↔ UI Models transformation │
└────────────────┬───────────────────────────┘
                 │ Transformation
┌────────────────▼────────────────────────┐
│  Data Layer Models (Generated Models)   │
│  - WiFiRadios, WifiSsids, DeviceInfo    │
│  - Auto-generated from TR-181 YAML definitions │
│  - ❌ Prohibition in Provider and UI layers │
└─────────────────────────────────────────┘
```

**Section 5.4.2: Common Violations and Fixes**

**Direct use of Generated Models in Provider**

❌ **Violation**:
```dart
// lib/page/wifi/providers/wifi_provider.dart
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';

class WifiNotifier extends AsyncNotifier<WifiState> {
  Future<void> build() async {
    final usp = ref.read(uspServiceProvider);
    final ssids = await WifiSsids.fetch(usp);  // ❌ Should not be here
    state = AsyncData(WifiState(ssids: ssids));
  }
}
```

✅ **Fix**:
```dart
// lib/page/wifi/providers/wifi_provider.dart
class WifiNotifier extends AsyncNotifier<WifiState> {
  @override
  Future<WifiState> build() async {
    final service = ref.read(wifiServiceProvider);
    return service.fetchSettings();  // Service returns UI models
  }
}

// lib/page/wifi/services/wifi_service.dart
final wifiServiceProvider = Provider<WifiService>((ref) {
  return WifiService(ref.watch(uspServiceProvider));
});

class WifiService {
  final UspService _usp;

  WifiService(this._usp);

  Future<WifiState> fetchSettings() async {
    // Service is responsible for fetching generated models and transforming to UI models
    final ssids = await WifiSsids.fetch(_usp);
    return WifiState(
      ssidModels: ssids.items.map(_toUIModel).toList(),
    );
  }
}
```

**Section 5.4.3: Architecture Compliance Check**

After completing the work, execute the following checks:

```bash
# ═══════════════════════════════════════════════════════════════
# Generated Models Tier Isolation Check
# ═══════════════════════════════════════════════════════════════

# 1️⃣ Check if generated models are imported in the Provider layer
grep -r "import.*generated/" lib/page/*/providers/
# ✅ Should return 0 results (both L1 and L2 providers delegate to Services)

# 2️⃣ Check if generated models are imported in the UI layer
grep -r "import.*generated/" lib/page/*/views/
# ✅ Should return 0 results

# 3️⃣ Check if Service layer correctly imports generated models
grep -r "import.*generated/" lib/page/*/services/
# ✅ Should have results (Service layer should import generated models)

# ═══════════════════════════════════════════════════════════════
# Error Handling Tier Isolation Check (Article XIII)
# ═══════════════════════════════════════════════════════════════

# 4️⃣ Check if Provider layer has ServiceError imports (correct)
grep -r "import.*core/errors/service_error" lib/page/*/providers/
# ✅ Should have results when providers handle errors

# 5️⃣ Check if Service layer correctly imports ServiceError
grep -r "import.*core/errors/service_error" lib/page/*/services/
# ✅ Should have results (Service layer should import ServiceError)
```

**Section 5.4.4: UI Model Creation Decision Criteria**

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
   - Direct mapping from Service (USP codegen) data to state without complex transformation.

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

---

## Article VI: The Service Layer Principle

**Section 6.1: Service Layer Mandate**
Complex business logic and external communication (USP protocol via codegen API, Cloud APIs) MUST be encapsulated in Service classes. Services act as the bridge between Providers and external systems.

**Section 6.2: Service Responsibilities**
Services SHALL:
* Call codegen API (`lib/generated/`) via `UspService` to fetch and update router data
* Implement business logic and data transformations
* Return domain/UI models, not raw codegen models
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

**Reference implementation:** `lib/page/dmz/services/usp_dmz_service.dart`

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
* Call codegen API via `UspService`
* Transform generated models to UI models
* Provide pure, testable functions
* Location: `lib/page/[feature]/services/`

**Section 6.5: Testing Requirements**
Services MUST have unit tests that:
* Mock `UspService` and other dependencies
* Verify data transformations (generated models → UI models)
* Test error handling paths

**Test organization:** `test/page/[feature]/services/`

**Refer to Article VIII Section 8.2 (Unit Testing) for a detailed testing strategy.**

**Section 6.6: Reference Implementations**
See these existing services as examples:
* L2 Service: `lib/page/dmz/services/usp_dmz_service.dart`
* L1 Service: `lib/page/admin/services/usp_time_data_service.dart`

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
* USP codegen API (`lib/generated/`) for type-safe router communication
* `UspService` for centralizing USP protocol communication
* Data transformation functions that add semantic value

**Section 7.3: Data Representation**

**Consistent within layers, transformation between layers:**
- ✅ Within the same layer: Avoid creating redundant models with the same semantic meaning.
- ✅ Between layers: Must use different models, transformed by the Service layer.
- ❌ Prohibited: Defining multiple redundant DTOs within the same layer.

**Example:**
```dart
// ✅ Correct: Use different models across layers
// Data Layer (lib/generated/)
class WiFiRadios { ... }  // generated model

// Application Layer (Service transformation)
WifiRadioUIModel convertToUI(WiFiRadio radio) => ...

// Presentation Layer
class WifiRadioUIModel { ... }  // UI model

// ❌ Incorrect: Redundant within the same layer
class WifiRadioUIModel1 { ... }
class WifiRadioUIModel2 { ... }  // Semantically identical to WifiRadioUIModel1
```

**Refer to Article V Section 5.4.1 (Cross-tier Model Transformation Specification) for detailed explanation.**

---

## Article VIII: Testing Strategy

**Section 8.1: Test Pyramid Approach**
Follow a balanced testing strategy:
* **Many fast unit tests** - Test Services and Providers in isolation with mocks
* **Screenshot tests** - Only required for pages with finalized UI design. Currently deferred for all `lib/page/` pages — see **Section 1.2**.

**Section 8.2: Unit Testing**
Unit tests MUST:
* **Provided for all Services and Providers** before code review
* **Mock external dependencies** (UspService, other services) using Mocktail
* **Test business logic in isolation** - No network calls, no real storage operations
* **Be fast and deterministic** - No flaky tests, no time-dependent assertions

**Mocking Requirements:**
* Use Mocktail for all mocks (see Article I Section 1.6.1 for detailed patterns)
* Mock UspService when testing Services
* Mock Services when testing Providers
* Use Test Data Builders for USP codegen model instances (see Article I Section 1.6.2)

**Section 8.3: Screenshot Testing**

**USP Pages Exception**: Screenshot tests for `lib/page/` are currently deferred until UI design is finalized. See **Section 1.2**.

**When Required:**
* Screenshot tests (golden files) MUST be provided for all UI changes with finalized design
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

## Article IX: (Reserved)
*Reserved for future definition.*

---

## Article X: Code Review Standards

**Section 10.1: Review Checklist**

**Lint and Format Checks**:
- ✅ `flutter analyze` entire project with no errors (no new issues introduced)
- ✅ Run `dart format .` to ensure all code complies with formatting standards

**Testing and Coverage**:
- ✅ Added/modified code has corresponding unit tests
- ✅ Test coverage meets standards (Service ≥90%, Provider ≥85%, Overall ≥80%)

**Code Quality**:
- ✅ Follows three-tier architecture with no cross-layer dependencies
- ✅ Public APIs have DartDoc comments
- ✅ Edge cases handled properly (null checks, error handling)

**Compatibility**:
- ✅ All unit tests within the modified scope pass

---

## Article XI: Data Models

**Section 11.1: Model Requirements**

Developer-written UI Models and State classes **MUST**:
1. ✅ Implement `Equatable` interface (required for Riverpod state comparison)
2. ⚠️ Provide `toJson()` and `fromJson()` only when local persistence is required (e.g., `shared_preferences`)
3. ✅ Optional: Use `freezed` or `json_serializable` for code generation

**Note**: Generated Models (`lib/generated/*.g.dart`) are exempt from these requirements — their structure is managed by `usp-codegen`. `toMap()`/`fromMap()` are no longer required; USP codegen handles all protocol-level data conversion.

---

## Article XII: State Management with Riverpod

**Section 12.1: Riverpod Usage Principles**

**Principles**:
- ✅ Use Riverpod to manage all mutable state
- ✅ USP pages use `AsyncNotifier`: `build()` is async fetch itself — no manual trigger needed

**Section 12.2: Notifier Responsibility Definition**

**Notifier Responsibilities**:
- Only perform **business logic coordination** (no API details)
- **Depend on** Service (no direct dependency on low-level APIs or Generated Models)
- **No involvement** in UI layer decisions (e.g., navigation, Toast)

**Correct Example**:
```dart
// USP standard pattern: use AsyncNotifier, build() auto-fetches
class WifiNotifier extends AsyncNotifier<WifiState> {
  @override
  Future<WifiState> build() async {
    final service = ref.read(wifiServiceProvider);
    return service.fetchSettings();  // build() returns data directly, no manual trigger
  }

  Future<void> updateSsid(String newName) async {
    final service = ref.read(wifiServiceProvider);
    await service.updateSsid(newName);
    ref.invalidateSelf();  // re-triggers build() to refresh state
  }
}
```

---

## Article XIII: Error Handling Strategy

**Section 13.1: Unified Error Handling Principle**

**Principle**: All errors from the data layer (USP protocol, Cloud API) MUST be caught in the **Service layer** and converted to a unified `ServiceError` type. The Provider and UI layers MUST NOT directly depend on data-layer-specific error types.

`ServiceError` acts as the **isolation boundary** between the data layer and the application layer:

| Layer | Allowed error types | Description |
|-------|------|------|
| **Service layer** | Any underlying exception (for conversion) | The only place allowed to `catch (e)` |
| **Provider layer** | `ServiceError` only | MUST NOT import or catch underlying exceptions |
| **UI layer** | `ServiceError` only | Localizes via the central `localizeServiceError` mapper (Section 13.6) |

**Purpose**:
- **Isolate data layer implementation**: When the underlying protocol changes (e.g., USP → something else), only the Service layer's conversion logic needs updating — Provider and UI layers are unaffected
- **Type-safe error handling**: Use sealed classes to provide compile-time checks and exhaustiveness verification
- **Consistent error contract**: Provider and UI layers use a unified error interface

---

**Section 13.2: ServiceError Definition**

**File Location**: `lib/core/errors/service_error.dart`

**Structure**:
```dart
sealed class ServiceError implements Exception {
  /// Diagnostic raw fault code (firmware 7xxx/9xxx, WASM 9999, codegen 9998…).
  /// For logging/debugging only — `null` when there is no code.
  final int? code;

  /// Raw technical message (firmware text / WASM string). For logging/debugging.
  /// Most subtypes derive their UI message from the type alone and ignore this;
  /// fallback types like `UnexpectedError` may surface it.
  final String? detail;

  const ServiceError({this.code, this.detail});
}

// All error types extend ServiceError. Most carry no extra fields — the type
// itself is the semantic. They pass code/detail through to the base.
final class ResourceNotFoundError extends ServiceError {
  const ResourceNotFoundError({super.code, super.detail});
}

final class NetworkError extends ServiceError {
  const NetworkError({super.code, super.detail});
}

// Fallback for unmapped errors — the one type whose UI message can't be derived
// from the type alone, so it may surface `detail`.
final class UnexpectedError extends ServiceError {
  final Object? originalError;
  const UnexpectedError({this.originalError, super.code, super.detail});
}
```

**`code` / `detail` are diagnostic only**: they carry firmware/WASM technical
context for logging and are NOT shown to users — the UI derives a localized
message from the subtype (Section 13.6). `UnexpectedError` is the sole exception.

**Adding Error Types**: define them in `service_error.dart` following the
`[ErrorType]Error` naming convention. Because `ServiceError` is `sealed`, the
central UI mapper (Section 13.6) emits a compile-time warning until the new
subtype is given a localization.

---

**Section 13.3: Service Layer Error Handling**

**Responsibility**: The Service layer is the **only** place allowed to directly catch underlying exceptions (USP/WASM), and is responsible for converting them to `ServiceError`.

> **Important — USP errors are raw `String`, not `Exception`:**
> The WASM client throws plain `String` values across the JS→Dart interop boundary, not `Exception` or `Error` objects. Therefore, Service methods MUST use `catch (e)` (catch-all), **not** `on Exception catch (e)` — the latter silently misses all USP errors.

**Standard Pattern — use `mapUspErrorToServiceError()`**

All USP Service methods MUST use the centralized `mapUspErrorToServiceError()` utility. This function parses the structured USP error string, extracts fault codes and HTTP status, and maps to the appropriate `ServiceError` subtype. Do NOT manually parse USP error strings.

```dart
import 'package:privacy_gui/core/usp/errors/usp_error.dart';

// ✅ Correct: USP Service uses mapUspErrorToServiceError()
Future<DmzSettings> fetchSettings() async {
  try {
    final dmz = await Dmz.fetch(_usp);
    return _toUIModel(dmz);
  } catch (e) {
    throw mapUspErrorToServiceError(e);
  }
}

Future<void> update({required String instancePath, required DmzUIModel model}) async {
  try {
    await Dmz.update(_usp, DmzEntryUpdate(...));
  } catch (e) {
    throw mapUspErrorToServiceError(e);
  }
}
```

**Wrong Example**:
```dart
// ❌ Wrong: No catch — underlying exception leaks directly to Provider layer
Future<WifiState> fetchSettings() async {
  final ssids = await WifiSsids.fetch(_usp);  // ❌ If this fails, raw exception propagates up
  return WifiState(ssidModels: ssids.items.map(_toUIModel).toList());
}
```

---

**Section 13.4: Provider Layer Error Handling**

**Responsibility**: The Provider layer only handles `ServiceError` types. MUST NOT catch generic exceptions or underlying error types.

**13.4.1: AsyncNotifier Pattern (Type C pages)**

`build()` exceptions are automatically wrapped as `AsyncError` state by `AsyncNotifier`; mutation methods require explicit error handling.

```dart
// lib/page/wifi/providers/wifi_notifier.dart
import 'package:privacy_gui/core/errors/service_error.dart';

// build() needs no try-catch — AsyncNotifier handles it automatically
@override
Future<WifiState> build() async {
  final svc = ref.read(wifiServiceProvider);
  return svc.fetchSettings();  // ServiceError automatically becomes AsyncError state
}

// Mutation methods require explicit handling
Future<void> updatePassword(String newPassword) async {
  try {
    final svc = ref.read(wifiServiceProvider);
    await svc.updatePassword(newPassword);
  } on InvalidInputError {
    // ✅ Handle a known ServiceError subtype specially
    state = AsyncError(const InvalidInputError(), StackTrace.current);
  } on ServiceError catch (e) {
    // ✅ Handle other ServiceErrors
    state = AsyncError(e, StackTrace.current);
  }
  // ❌ Do NOT catch generic Exception — unknown errors should bubble up
}
```

**13.4.2: Preservable Pattern (Type A / Type B pages)**

Pages using `PreservableAutoDisposeNotifierMixin` handle errors in `performFetch()` and `performSave()`:

```dart
import 'package:privacy_gui/core/errors/service_error.dart';

// performFetch: catch ServiceError → return (null, errorStatus)
// Do NOT rethrow — the mixin's fetch() handles null settings gracefully.
// Store the TYPED ServiceError in state (NOT '$e') so the View can localize it.
@override
Future<(DmzSettings?, DmzStatus?)> performFetch({
  bool forceRemote = false,
  bool updateStatusOnly = false,
}) async {
  try {
    final (settings, status) = await _svc.fetch();
    return (settings, status);
  } on ServiceError catch (e) {
    logger.e('[USP][DMZ] Fetch failed', error: e);
    return (null, DmzStatus(isLoading: false, error: e));  // typed, not '$e'
  }
}

// performSave: catch ServiceError → log + rethrow
// The mixin's save() will catch the rethrown error and handle UI state.
@override
Future<void> performSave() async {
  try {
    await ref.read(uspMutationLockProvider).withLock(() async {
      await _svc.update(instancePath: path, model: pending);
    });
  } on ServiceError catch (e) {
    logger.e('[USP][DMZ] Save failed', error: e);
    rethrow;
  }
}
```

**Wrong Example**:
```dart
// ❌ Wrong: Provider swallows generic exceptions without converting
Future<void> performSave() async {
  try {
    await _svc.update(...);
  } catch (e) {  // ❌ Catches everything — bypasses ServiceError contract
    logger.e(e);
  }
}
```

---

**Section 13.5: USP Error Handling Infrastructure**

All USP error parsing and `ServiceError` mapping is centralized in a single utility file. Individual USP Services MUST NOT implement their own parsing logic.

**File Location**: `lib/core/usp/errors/usp_error.dart`

**Key utilities**:

| Function | Purpose |
|----------|---------|
| `parseUspError(Object error)` | Parses raw USP error string into structured `UspError` (operation, category, fault code, HTTP status) |
| `mapUspErrorToServiceError(Object error)` | Parses + maps to `ServiceError` subtype — **the only function USP Services need to call** |

**Mapping summary**:

| USP Error Category | Mapped ServiceError |
|--------------------|---------------------|
| Authentication (Invalid credentials) | `InvalidCredentialsError` |
| Authentication (Session expired) | `SessionTokenExpiredError` |
| Authentication (Permission denied) | `UnauthorizedError` |
| Transport (HTTP 401) | `NotAuthenticatedError` |
| Transport (HTTP 5xx, timeout) | `NetworkError` |
| Transport (Connection refused) | `ConnectivityError` |
| Protocol (fault 7026, 9005) | `ResourceNotFoundError` |
| Protocol (fault 7004, 9008) | `InvalidInputError` |
| Protocol (fault 9001) | `UnauthorizedError` |
| Validation | `InvalidInputError` |
| Unrecognized | `UnexpectedError` |

**Reference implementation**: `lib/page/dmz/services/usp_dmz_service.dart`

---

**Section 13.6: UI Layer Error Display**

The UI layer is the **only** place that turns a `ServiceError` into a user-facing
string, and it does so through one central mapper — never by stringifying the error.

**Rules**:
- **Localize via `localizeServiceError(context, error)`** — the single mapper that
  switches on the sealed `ServiceError` and returns a localized message. Never show
  `'$e'`, `error.toString()`, `code`, or `detail` to the user (those are diagnostic).
- **Fetch failure** → render the shared `ServiceErrorView` (it localizes internally).
- **Save failure** → `showFailedSnackBar(context, localizeServiceError(context, e))`.
- **Adding a subtype** requires adding its localization to the mapper (the `sealed`
  switch enforces this at compile time) plus an ARB key.

**Files**: `lib/components/localizations/service_error_localizations.dart` (mapper),
`lib/components/views/service_error_view.dart` (shared fetch-failure widget).

> **Full implementation guidance** — per-layer patterns, what to show vs. hide,
> batch-failure handling, and a pre-PR checklist — lives in
> `doc/error-handling/error-handling-implementation-guide.md`.
> This Constitution states the principle; that guide is the how-to.

---

## Article XIV: Layout Composition Patterns

**Section 14.1: Definition and Scope**

Layout Composition Patterns are **project-level layout conventions** built on top of UI Kit's Design System. They are NOT a Design System — that responsibility belongs to `ui_kit_library`. These patterns provide consistent visual grouping and hierarchy across feature pages.

**Key Distinction**:
- **UI Kit (Design System)**: Atomic components (buttons, text, cards, inputs) with design tokens
- **Layout Composition Patterns**: Page-level layout conventions for arranging UI Kit components

**Section 14.2: The Block Pattern**

`Block` is a **layout helper container** that creates visual grouping within cards or as standalone list items. It provides a subtle background to distinguish content sections without adding visual weight.

**Visual Parameters** (defined in `BlockConstants`):
| Property | Value | Notes |
|----------|-------|-------|
| Background | `surfaceContainerHighest @ 50%` | Subtle grouping, not prominent |
| Border Radius | `AppSpacing.sm` | Consistent with UI Kit |
| Border | None | Avoid visual clutter from excessive lines |
| Padding | `AppSpacing.md` (default) | Configurable per use case |

**Section 14.3: Usage Patterns**

Three canonical patterns for combining Card and Block:

**Pattern A: Card + Block** (Detail/Settings Pages)
```
AppCard
├── CardHeader (optional)
├── Block (setting row 1)
├── Block (setting row 2)
└── Block (setting row 3)
```
Use for: Settings pages, detail views, form sections.

**Pattern B: Block Alone** (List Items)
```
Column
├── Block (list item 1)
├── Block (list item 2)
└── Block (list item 3)
```
Use for: Device lists, network lists, any repeating items without outer container.

**Pattern C: Card Alone** (Simple Cards)
```
AppCard
├── content
└── ...
```
Use for: Dashboard cards, summary panels, standalone content without internal grouping.

**Section 14.4: Shared Block Components**

Reusable block components live in `lib/page/_shared/components/layout_blocks/`:

| Component | Purpose | Example Use |
|-----------|---------|-------------|
| `Block` | Base container with background | Any grouped content |
| `SwitchBlock` | Toggle setting row | Firewall toggles, WiFi enable |
| `SettingBlock` | Label + value + optional action | WiFi name, security mode |
| `NavLinkBlock` | Navigation link with description | "IPv6 Port Service" link |
| `DeviceRow` | Device list item | Connected devices |
| `StatTile` | Dashboard statistic | Device count, speed stats |

**Section 14.5: Implementation Rules**

1. **Use BlockConstants**: All block components MUST use values from `BlockConstants` for consistency
2. **Prefer shared components**: Before creating a new block pattern, check if `setting_blocks.dart` or `row_blocks.dart` already provides it
3. **Card vs Block decision**: Use Card for top-level containers; use Block for internal grouping or list items
4. **No borders on Blocks**: Blocks use background color only — borders create visual noise

**File Organization**:
```
lib/page/_shared/components/layout_blocks/
├── index.dart              # Barrel export
├── block_constants.dart    # Design tokens
├── base_blocks.dart        # Block, CardHeader
├── setting_blocks.dart     # SwitchBlock, SettingBlock, NavLinkBlock
├── row_blocks.dart         # DeviceRow, NetworkBadge
├── list_blocks.dart        # List-specific blocks
└── stat_blocks.dart        # StatTile, EmptyState
```

---

## Article XV: UI Kit Library Principle

**Section 15.1: Mandatory UI Component Usage**

When developing screens or features, all UI component usage MUST follow these two rules:

**Rule 1: UI Kit First**

All UI components MUST be searched for and used from `ui_kit_library` first.

```dart
// ✅ Correct: Use ui_kit_library components
import 'package:ui_kit_library/ui_kit.dart';

AppButton.primary(
  label: 'Save',
  onTap: () => save(),
)

// ❌ Wrong: Implementing existing UI components yourself
class CustomButton extends StatelessWidget {
  // Don't write your own button, ui_kit already has one
}
```

**Common ui_kit components**:
- Buttons: `AppButton.primary()`, `AppButton.text()`, `AppButton.primaryOutline()`
- Text: `AppText.titleLarge()`, `AppText.bodyMedium()`, `AppText.labelLarge()`
- Cards: `AppCard()`
- Containers: `AppSurface()` (use instead of Container for consistent styling)
- Input: `AppTextFormField()`
- Selection: `AppCheckbox()`, `AppSwitch()`
- Dialogs: `showSimpleAppDialog()`, `showAppSpinnerDialog()`
- Spacing: `AppGap.md()`, `AppGap.lg()`, `AppSpacing.xl`
- Colors: `Theme.of(context).extension<AppColorScheme>()`

**Rule 2: Stop and Ask When Missing**

If ui_kit_library does not have the UI component you need:

1. **Stop development** - Do not implement it yourself or continue
2. **Report to user** - Use AskUserQuestion tool to ask the user how to proceed
3. **Wait for decision** - Let the user decide next steps (propose to ui_kit, use alternatives, or other)

```dart
// ❌ Wrong: Found ui_kit doesn't have a component, so write it yourself
class NewCustomWidget extends StatelessWidget {
  // Don't do this! Stop and ask the user first
}

// ✅ Correct: Stop and use AskUserQuestion to ask the user
// "I need a component that [describe functionality], but couldn't find it in ui_kit_library.
//  How should I proceed?"
```

**Section 15.2: Import Specification**

Use the unified import approach when possible:

```dart
// ✅ Preferred: Use unified import when available
import 'package:ui_kit_library/ui_kit.dart';

// ⚠️ Acceptable: Subpath imports allowed when APIs are not exported from ui_kit.dart
// (e.g., accessibility utilities, foundation modules)
import 'package:ui_kit_library/src/foundation/accessibility/accessibility.dart';
```

**Section 15.3: Code Review Checklist**

Code Review MUST check:
- ✅ All UI components prioritize using ui_kit_library
- ✅ No duplicate implementation of ui_kit provided components
- ✅ If there are custom components, confirm they have user approval

---

## Article XVI: E2E Test Hooks (Semantics Identifiers)

**Rationale**: The app is a Flutter CanvasKit web build tested end-to-end with Playwright. CanvasKit renders to a single canvas, so tests can only reach a widget through the Semantics tree it projects to the DOM. When a control has no stable, unique anchor, tests fall back to positional selectors (`.nth()`, row index) that silently break when copy, order, or layout changes. This Article makes the stable anchor a first-class, reviewable property of E2E-critical widgets.

**Section 16.1: `identifier` is the Preferred E2E Anchor — Not `semanticLabel`**

For a control that an E2E test must target, the stable hook SHOULD be the `identifier` parameter, NOT `semanticLabel`.

| Property | DOM projection | Screen reader | Couples to | Correct use |
|:---|:---|:---|:---|:---|
| `identifier` | `flt-semantics-identifier` attribute | **Silent** — not announced | Nothing (pure automation hook) | **E2E selectors** |
| `semanticLabel` | accessible name (`aria-label`) | **Announced aloud** | Localized display copy | Genuine accessibility only |

```dart
// ✅ Correct: identifier is a silent, copy-independent automation hook
AppIconButton(
  icon: AppIcon.font(Icons.add),
  identifier: 'pf-add-single-port',
  onTap: _add,
)

// ❌ Wrong: the host widget forwards `identifier`, yet a test slug is placed
// in semanticLabel — read aloud by screen readers and coupled to display copy.
AppIconButton(
  icon: AppIcon.font(Icons.add),
  semanticLabel: 'pf-add-single-port', // pollutes a11y; breaks on copy change
  onTap: _add,
)
```

**Rule 16.1.1 — When the host widget forwards `identifier`**: The test hook MUST be `identifier`. A test slug MUST NOT be placed in `semanticLabel`, and a widget MUST NOT carry both an `identifier` and a redundant test-slug `semanticLabel` — remove the `semanticLabel`. On such a widget, `semanticLabel` is reserved for genuine, localized, human-readable accessibility text only.

**Rule 16.1.2 — When the host widget exposes only `semanticLabel`** (no `identifier` passthrough — e.g. `AppMenuCard` / `AppSectionItemData`): a kebab-case `semanticLabel` test slug is a **tolerated interim hook**, because it is the only anchor available. It is nonetheless **tech debt**: the slug is announced aloud by assistive technology. Per Article XV Rule 2, the standing resolution is to add `identifier` passthrough to that widget in `ui_kit_library` (stop and ask), then migrate the hook to `identifier`. New E2E-critical widgets SHOULD forward `identifier` from the outset so this fallback is never reached.

> The E2E selector map (`identifiers.generated.ts`) reflects both mechanisms — `IDS` (identifier → `byId`) and `LABELS` (semanticLabel → `getByRole name`). `LABELS` exists to serve Rule 16.1.2 fallbacks; it is not licence to prefer `semanticLabel` where `identifier` is available.

**Section 16.2: When an `identifier` Is Required**

An `identifier` MUST be added when, and only when, a control lacks a stable, unique anchor that a test can already reach:

* ✅ **Required** — icon-only buttons (`AppIconButton`) whose accessible name is a generic fallback (e.g. "Icon button"), making sibling instances indistinguishable.
* ✅ **Required** — toggles/switches, and form inputs, that a test must set or read but that carry no unique role+name.
* ✅ **Required** — any control a test currently reaches only via `.nth()` / positional index.
* ❌ **Not required** — controls already uniquely addressable by role + accessible name, or by stable visible content text (e.g. a labelled `AppButton`, a device row keyed on its name). Do not add redundant identifiers to anchorable controls.

**Locale caveat**: "addressable by accessible name" counts as a stable anchor **only while the E2E suite is locked to a single locale**. An accessible name is localized display copy — `getByRole(role, { name: 'Save' })` targets the English string. The current suite has no locale lock (`playwright.config.ts` sets none) and matches localized names directly, so it is implicitly English-only. The moment E2E must run across locales — or the app's default locale changes — such a control is reachable only through copy that varies, which is the same silent-break failure mode this Article exists to kill (locale-triggered rather than layout-triggered). In that case the control moves back to ✅ **Required**: give it an `identifier`. A cross-locale test matrix is therefore a trigger to re-audit every ❌ decision made under this section.

**Principle**: The `identifier` exists to eliminate selectors that break on things unrelated to identity — positional index, and (under a cross-locale matrix) localized copy. If a control is already stably anchorable *for the locales the suite runs*, adding an `identifier` is noise — Article V (Simplicity) applies.

**Section 16.3: Naming Convention**

Identifier values MUST be `kebab-case` and follow `{page-or-feature}-{control}[-{instance-key}]`:

```dart
'pf-add-single-port'   // {feature: pf}-{control: add-single-port}
'wifi-quick-setup'     // {feature: wifi}-{control: quick-setup}
'pf-edit-web-server'   // {feature}-{control}-{instance-key}
```

**Per-instance controls** (list rows, dynamic CRUD items) MUST embed a **stable key derived from the item's data**, NOT a row index. The key is a slug of a stable identifying field, with a deterministic fallback chain when that field is empty:

```dart
// Stable key: description slug → trailing instance number → 'unnamed'
// e.g. "Web Server" → 'web-server'; empty desc on Device.NAT.PortMapping.2 → '2'
identifier: 'pf-edit-${rule.identifierKey}'
identifier: 'pf-delete-${rule.identifierKey}'
```

The derivation helper (e.g. `ruleIdentifierKey`) MUST be a pure, unit-tested function (Article I). A row-index-based identifier (`pf-edit-0`) is a violation — it is a positional selector wearing an identifier's clothes.

**Raw `Semantics` is also a legal hook host.** The hook need not sit on a ui_kit widget: wrapping any subtree in `Semantics(identifier: '…')` is a valid anchor and is preferred over `Semantics(label: '…')` for a test-only slug (a bare `label` is announced aloud, same as `semanticLabel`). One generator constraint governs this: the E2E generator (`scripts/gen-identifiers.mts`) matches on the **attribute name**, not the host widget — it scans for the literal attributes `identifier:` and `semanticLabel:`. Consequently `Semantics(label: '…')` is **invisible to the generator** (the attribute is `label`, not `semanticLabel`) and produces no selector entry. Use `Semantics(identifier: '…')` so the hook is both silent and discoverable.

**Section 16.4: Layer Responsibility & SSOT**

* **ui_kit_library** owns `identifier` passthrough on shared widgets (`AppIconButton`, `AppSwitch`, `AppTextField`, …). If a widget a test must target does not forward `identifier`, **stop and ask** per Article XV Rule 2 to add passthrough; a `semanticLabel` slug is only the tolerated interim per Rule 16.1.2 until it lands.
* **PrivacyGUI (`lib/`)** owns the identifier *values* on feature controls, including values placed on raw `Semantics(identifier:)` nodes where no ui_kit passthrough exists.
* **E2E repo** owns the generated selector map (`identifiers.generated.ts`), produced by scanning app Dart source. App source is the single source of truth; the E2E map is derived. Renaming an identifier in `lib/` is a contract change — regenerate the map.

**A `semanticLabel` → `identifier` migration is a contract change even when the slug value is unchanged.** Moving a hook between the two attributes changes the *mechanism*, not the string: the slug relocates from `LABELS` (located via `getByRole(role, { name })`) to `IDS` (located via `byIdentifier()`). Every spec that reached the control by its old mechanism MUST be migrated to the new locator in the same change — "the slug didn't change" is not evidence that E2E is unaffected. Regenerate the map and grep the specs for the old mechanism. (The generator errors if a single slug is declared as *both* `identifier` and `semanticLabel`, but that guard does not catch an attribute swap where the old and new coexist across a mid-migration diff — the spec-side migration is a manual obligation.)

**Section 16.5: Code Review Checklist**

Code Review MUST check:
- ✅ Every E2E-critical control (icon buttons, toggles, targeted inputs, CRUD row actions) has a stable hook — `identifier` where the host widget forwards it (Rule 16.1.1)
- ✅ Where a widget forwards `identifier`, no test slug appears in `semanticLabel`, and no widget carries both an `identifier` and a redundant test-slug `semanticLabel`
- ✅ A `semanticLabel` test slug appears only where the host widget exposes no `identifier` passthrough (Rule 16.1.2), and such cases are flagged as tech debt to migrate
- ✅ Identifier values are `kebab-case`, follow `{page}-{control}[-{instance-key}]`, and per-instance keys derive from data (not row index)
- ✅ Per-instance key derivation is a pure, unit-tested function
- ✅ No redundant identifier added to a control already anchorable by role+name or stable content text — but any ❌-"not required" call is sound only for the locales the suite runs; a cross-locale matrix re-opens it (16.2 locale caveat)
- ✅ Raw `Semantics` test hooks use `identifier:`, not `label:` (a bare `label` is announced aloud AND invisible to the generator)
- ✅ Any `semanticLabel`→`identifier` migration — even with an unchanged slug — regenerated the map AND migrated every spec from `getByRole({name})` to `byIdentifier()` (16.4)

---
