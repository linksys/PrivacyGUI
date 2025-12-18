# The Constitution of Linksys Flutter App Development

**Version:** 1.0
**Status:** Active
**Context:** Source of Truth for Architectural Discipline
**Ratified:** 2025-12-09
**Last Amended:** 2025-12-17

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

**詳細測試策略、工具使用、組織方式參見 Article VIII: Testing Strategy**

**Section 1.3: Test Scope Definition**

* ✅ 只測試當前正在進行修改工作的範圍即可
* ❌ 不測試整個 `lib/` 目錄
* ❌ 不測試整個 `test/` 目錄
* ❌ 不修復其他無關的 lint warnings
* 原則：只為當下的任務撰寫測試並且執行測試，不需要包括其他功能

**測試範圍界定範例**：

**場景：新增 DMZ Service**
- ✅ 必須測試：`lib/page/advanced_settings/dmz/services/dmz_service.dart`（新增的 Service）
- ✅ 必須測試：`lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart`（直接使用 DMZService）
- ✅ 必須測試：`lib/page/advanced_settings/dmz/models/dmz_ui_settings.dart`（如果是新增的 Model）
- ❌ 不需要測試：其他使用 RouterRepository 的 Services
- ❌ 不需要測試：DMZ 相關的 UI Views
- ❌ 不需要測試：整個 `advanced_settings` module 的其他功能

**Section 1.4: 預期覆蓋率**

| 層級 | 覆蓋率 | 說明 |
|:---|:---|:---|
| Service 層 | ≥90% | 資料層最關鍵 |
| Provider 層 | ≥85% | 業務邏輯協調 |
| State 層 | ≥90% | 資料模型必須完整 |
| **整體** | ≥80% | 加權平均 |

**測量工具**: 使用 `flutter test --coverage` 生成覆蓋率報告
**未達標處理**: Code review 時需說明原因，特殊情況可豁免

**Section 1.5: Test Organization**
Tests MUST be organized as follows:
* Unit tests:
  - Service tests: `test/page/[feature]/services/`
  - Provider tests: `test/page/[feature]/providers/`
* Mock classes: Created inline in test files or in `test/mocks/` for shared mocks
* Test data builders: `test/mocks/test_data/[feature_name]_test_data.dart`
* Screenshot tests: `test/page/[feature]/localizations/*_test.dart` (tool uses pattern `localizations/.*_test.dart`)
* Screenshot test tool: `dart tools/run_screenshot_tests.dart` automatically discovers all tests in `localizations/` subdirectories
* 所有的 test cases 的命名，不需要給予編號，只需要闡述測試的目的即可

**Section 1.6: Mock Creation**

**Section 1.6.1: Mock Classes (Mocktail)**

For Provider and Service mocking:
* Use Mocktail for creating mocks
* Create mock classes that extend the target class/interface with `Mock`
* For Riverpod Notifiers: `class MockNotifier extends Mock implements YourNotifier {}`
* For Services: `class MockService extends Mock implements YourService {}`
* Use `when(() => mock.method()).thenReturn(value)` for stubbing
* Use `verify(() => mock.method()).called(n)` for verification

**Section 1.6.2: Test Data Builder 模式**

**目的**：為 Service 層測試提供可重用的 JNAP mock responses

**檔案組織**：
* Test data builders 統一放在 `test/mocks/test_data/` 目錄
* 命名規則：`[feature_name]_test_data.dart`
* Class 命名：`[FeatureName]TestData`
* 不要在寫測試時臨時建立 mock data
* 如需調整資料，使用 named parameters 或 `copyWith()` 方法

**使用場景**：
當測試 Service 時，mock 的是 **RouterRepository 的返回值**（JNAP responses），而非 Service 本身。

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
  /// 支持部分覆蓋(partial override)設計：只指定需要改變的字段，其他字段使用預設值
  static JNAPTransactionSuccessWrap createSuccessfulTransaction({
    Map<String, dynamic>? setting1,
    Map<String, dynamic>? setting2,
  }) {
    // 定義預設值
    final defaultSetting1 = { /* ... */ };
    final defaultSetting2 = { /* ... */ };

    // 合併預設值和覆蓋值
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
    // ... 返回包含錯誤的交易
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
    // Arrange: Mock RouterRepository 返回 JNAP response
    when(() => mockRepo.send(any()))
        .thenAnswer((_) async => DMZTestData.createSuccessResponse());

    // Act: 調用 Service 方法
    final result = await service.fetchSettings();

    // Assert: 驗證轉換後的 UI model
    expect(result, isA<DMZSettingsUIModel>());
  });
}
```


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

## Article III: 命名規範 (Naming Conventions)

**Section 3.1: 基本原則**
所有命名必須遵守：
* **描述性** - 清楚表達目的和功能
* **一致性** - 遵循專案統一模式
* **明確性** - 避免縮寫，除非是廣泛理解的術語（如 UI, ID, HTTP, JNAP, RA）

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

**注意**：檔案名稱使用**單數**形式（`service.dart`，而非 `services.dart`）

---

**Section 3.3: Class 命名**

所有 class 必須使用 `UpperCamelCase`：

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
// 命名模式：[Feature][Type]UIModel（必須以 UIModel 結尾）
class DMZSettingsUIModel extends Equatable { ... }
class WirelessConfigUIModel extends Equatable { ... }
class SpeedTestUIModel extends Equatable { ... }
class FirmwareUpdateUIModel extends Equatable { ... }
```

**Data Models** (JNAP/Cloud):
```dart
// 命名模式：依照 JNAP domain 名稱
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

**Section 3.4: Provider 命名**

所有 provider 必須使用 `lowerCamelCase`：

**3.4.1: Service Providers**
```dart
// 命名模式：[feature]ServiceProvider
final authServiceProvider = Provider<AuthService>((ref) => ...);
final dmzServiceProvider = Provider<DMZService>((ref) => ...);
```

**3.4.2: State Notifier Providers**
```dart
// 命名模式：[feature]Provider（不需要 "Notifier" 後綴）
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

**Section 3.5: 目錄命名**

所有目錄必須使用 `snake_case`：

**3.5.1: Feature 目錄**
```
lib/page/advanced_settings/     # 單數或複數視語意
lib/page/instant_setup/
lib/page/health_check/
```

**3.5.2: 組件目錄**
```
lib/page/[feature]/views/       # 複數 - 容器目錄
lib/page/[feature]/providers/   # 複數 - 容器目錄
lib/page/[feature]/services/    # 複數 - 容器目錄
lib/page/[feature]/models/      # 複數 - 容器目錄
```

**3.5.3: 測試目錄**
```
test/page/[feature]/services/
test/page/[feature]/providers/
test/mocks/
test/mocks/test_data/
```

---

**Section 3.6: 測試命名**

**3.6.1: Test Case 命名**
```dart
// ✅ 正確：描述測試目的，無編號
test('cloudLogin returns success with valid credentials', () { ... });
test('localLogin handles invalid password', () { ... });
test('fetchSettings transforms JNAP model to UI model', () { ... });

// ❌ 錯誤：使用編號
test('TC001: login test', () { ... });
test('Test case 1', () { ... });
```

**3.6.2: Test Group 命名**
```dart
// 命名模式：[ClassName] - [Feature/Category]
group('AuthService - Session Token Management', () { ... });
group('AuthNotifier - Cloud Login', () { ... });
group('DMZService - Settings Transformation', () { ... });
```

**3.6.3: 測試檔案組織**
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

**Section 5.3: 架構層次與職責分離**

**原則**: 嚴格遵守三層架構，依賴方向**永遠向下**，不允許反向依賴。

```
┌─────────────────────────────────┐
│  Presentation (UI/頁面)          │  ← 只負責顯示和用戶互動
│  lib/page/*/views/              │
└────────────┬────────────────────┘
             │ 依賴
┌────────────▼────────────────────┐
│ Application (業務邏輯層)          │  ← 狀態管理與業務邏輯
│  - lib/page/*/providers/        │  ← Notifiers (狀態管理)
│  - lib/page/*/services/         │  ← Services (業務邏輯)
└────────────┬────────────────────┘
             │ 依賴
┌────────────▼────────────────────┐
│  Data (資料層)                   │  ← 數據獲取、本地存儲、解析
│  lib/core/jnap/, lib/core/cloud/│
└─────────────────────────────────┘
```

**每層職責**:
- **Presentation**: UI 呈現、用戶輸入、狀態觀察（只訪問 Provider）
- **Application**:
  - **Providers (Notifiers)**: 狀態管理、用戶交互協調
  - **Services**: 業務邏輯、API 通信、數據轉換
- **Data**: API 調用（JNAP、Cloud）、資料庫訪問、數據模型定義

**關鍵原則**: 不同層級應該使用**不同的數據模型**，每層的模型只在該層及下層使用。

**Section 5.3.1: 模型層級分類**

```
┌─────────────────────────────────────────┐
│  Presentation Layer Models (UI Models)  │
│  - 用於 UI 顯示、用戶輸入                  │
│  - ❌ 禁止直接依賴 JNAP Data Models       │
└────────────────┬────────────────────────┘
                 │ 轉換
┌────────────────▼───────────────────────────┐
│  Application Layer Models (DTO/State)      │
│  - 業務層的轉換模型                           │
│  - 橋接 Data Models 與 Presentation         │
│  - Service 進行 Data Models ↔ UI Models 轉換│
└────────────────┬───────────────────────────┘
                 │ 轉換
┌────────────────▼────────────────────────┐
│  Data Layer Models (Data Models)        │
│  - DMZSettings, DMZSourceRestriction    │
│  - JNAP、API 回應的直接映射                │
│  - ❌ 禁止在 Provider、UI 層出現           │
└─────────────────────────────────────────┘
```

**Section 5.3.2: 常見違規與修正**

**Provider 中直接使用 JNAP Models**

❌ **違規**:
```dart
// lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';

class DMZSettingsNotifier extends Notifier<DMZSettingsState> {
  Future<void> performSave() async {
    final domainSettings = DMZSettings(...);  // ❌ 不應該在這裡
    await repo.send(..., data: domainSettings.toMap());
  }
}
```

✅ **修正**:
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
    // Service 層會負責 UI Model 和 Data Model (JNAP Data) 的轉換
    final dataModel = DMZSettings(...);
    await _routerRepository.send(..., data: dataModel.toMap());
  }
}
```

**Section 5.3.3: 架構合規性檢查**

完成工作後，執行以下檢查：

```bash
# ═══════════════════════════════════════════════════════════════
# JNAP Models 層級隔離檢查
# ═══════════════════════════════════════════════════════════════

# 1️⃣ 檢查 Provider 層是否還有 JNAP models imports
grep -r "import.*jnap/models" lib/page/*/providers/
# ✅ 應該返回 0 結果

# 2️⃣ 檢查 UI 層是否還有 JNAP models imports
grep -r "import.*jnap/models" lib/page/*/views/
# ✅ 應該返回 0 結果

# 3️⃣ 檢查 Service 層是否有正確的 JNAP imports
grep -r "import.*jnap/models" lib/page/*/services/
# ✅ 應該有結果（Service 層應該 import JNAP models）

# ═══════════════════════════════════════════════════════════════
# Error Handling 層級隔離檢查 (Article XIII)
# ═══════════════════════════════════════════════════════════════

# 4️⃣ 檢查 Provider 層是否有 JNAPError 或 jnap_result imports
grep -r "import.*jnap/result" lib/page/*/providers/
grep -r "on JNAPError" lib/page/*/providers/
# ✅ 應該返回 0 結果

# 5️⃣ 檢查 Service 層是否正確 import ServiceError
grep -r "import.*core/errors/service_error" lib/page/*/services/
# ✅ 應該有結果（Service 層應該 import ServiceError）
```

**Section 5.3.4: UI Model 創建決策標準**

**原則**: 不是所有的 State 都需要獨立的 UI Model。只在必要時創建 UI Model，避免過度設計。

**需要獨立 UI Model 的情況**:

1. **集合/列表數據**
   - 當 State 需要存儲 `List<Something>` 時，Something 應該是一個 UI Model
   - 範例：`List<FirmwareUpdateUIModel>` (多個節點狀態)、`List<SpeedTestUIModel>` (歷史記錄)

2. **數據重用性**
   - 同一個數據結構在多個地方使用（列表項、詳情頁、彈窗、不同 State 字段）
   - 範例：`HealthCheckState` 中的 `SpeedTestUIModel` 用於 `result`、`latestSpeedTest`、`historicalSpeedTests`

3. **複雜的嵌套結構**
   - 數據本身包含多個層級的嵌套對象（>5 個字段或有嵌套）
   - 避免 State 變得過於複雜和難以維護

4. **包含計算邏輯或格式化方法**
   - UI Model 可以封裝 getter、格式化方法、驗證邏輯
   - 範例：`speedTest.formattedDownloadSpeed`、`node.updateProgressPercentage`

**不需要獨立 UI Model 的情況**:

1. **扁平的基本類型**
   - 只有 String, int, bool, enum 等簡單字段
   - 範例：`RouterPasswordState` (isDefault, isSetByUser, adminPassword, hint 等基本類型)

2. **簡單的一對一映射**
   - 從 Service/JNAP 返回的數據到 State 是直接映射，沒有複雜轉換

**決策流程圖**:
```
是否需要獨立的 UI Model？
├─ 是集合/列表數據？ → YES → 使用 UI Model
├─ 數據會在多處重用？ → YES → 使用 UI Model
├─ 數據結構複雜（>5個字段或有嵌套）？ → YES → 考慮 UI Model
├─ 需要封裝業務邏輯/計算屬性？ → YES → 使用 UI Model
└─ 否則 → State 直接持有基本類型即可
```

**實際範例對比**:

✅ **不需要 UI Model** (`RouterPasswordState`):
```dart
class RouterPasswordState {
  final bool isDefault;           // 基本類型
  final bool isSetByUser;         // 基本類型
  final String adminPassword;     // 基本類型
  final String hint;              // 基本類型
  final int? remainingErrorAttempts;
  // 扁平結構，無重用需求
}
```

✅ **需要 UI Model** (`HealthCheckState`):
```dart
class HealthCheckState {
  final SpeedTestUIModel? result;              // 重用 1
  final SpeedTestUIModel? latestSpeedTest;     // 重用 2
  final List<SpeedTestUIModel> historicalSpeedTests;  // 重用 3 + 集合
  // SpeedTestUIModel 在多處重用，且包含複雜測試數據
}
```

✅ **需要 UI Model** (`FirmwareUpdateState`):
```dart
class FirmwareUpdateState {
  final List<FirmwareUpdateUIModel>? nodesStatus;  // 集合類型
  // 每個節點是獨立實體，有自己的狀態、進度、錯誤信息
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

**詳細測試策略參見 Article VIII Section 8.2 (Unit Testing)**

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

**同層內統一，跨層間轉換：**
- ✅ 同一層內：避免創建語義相同的重複 models
- ✅ 跨層之間：必須使用不同的 models，由 Service 層轉換
- ❌ 禁止：在同一層內定義多個功能重複的 DTOs

**範例：**
```dart
// ✅ 正確：跨層使用不同 models
// Data Layer
class DMZSettings { ... }  // JNAP model

// Application Layer (Service 轉換)
DMZSettingsUIModel convertToUI(DMZSettings data) => ...

// Presentation Layer
class DMZSettingsUIModel { ... }  // UI model

// ❌ 錯誤：同層內重複
class DMZSettings1 { ... }
class DMZSettings2 { ... }  // 與 DMZSettings1 語義相同
```

**詳細說明參見 Article V Section 5.3.1（跨層模型轉換規範）**

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
